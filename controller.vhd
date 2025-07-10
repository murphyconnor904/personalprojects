--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller is
    port(
        -- Inputs
        clk          : in std_logic;
        reset        : in std_logic;
        opcode       : in std_logic_vector(5 downto 0); -- IR(31-26)
        funct        : in std_logic_vector(5 downto 0); -- IR(5-0) for R-type instructions
        rt_field     : in std_logic_vector(4 downto 0); -- IR(20-16) needed for BLTZ/BGEZ
        instreg_150  : in std_logic_vector(15 downto 0); --IR(15-0) needed for lw from inport 0 and/or 1 vs RAM
        
        -- Control signals for datapath
        PCWrite      : out std_logic;
        PCWriteCond  : out std_logic;
        IorD         : out std_logic;
        MemRead      : out std_logic;
        MemWrite     : out std_logic;
        MemToReg     : out std_logic;
        IRWrite      : out std_logic;
        JumpAndLink  : out std_logic;
        IsSigned     : out std_logic;
        PCSource     : out std_logic_vector(1 downto 0);
        ALUOp        : out std_logic_vector(2 downto 0);
        ALUSrcA      : out std_logic;
        ALUSrcB      : out std_logic_vector(1 downto 0);
        RegWrite     : out std_logic;
        RegDst       : out std_logic
    );
end controller;

architecture behavioral of controller is
    -- Define states for the FSM
    type state_type is (
        FETCH,              -- Fetch instruction
        DECODE,             -- Decode instruction and read registers
        EXECUTE_R_TYPE,     -- Execute R-type instruction
        COMPLETE_R_TYPE,    -- Complete R-type instruction
        EXECUTE_I_TYPE,     -- Execute I-type instruction
        MEMORY_ADDR_COMP,   -- Compute memory address
        MEMORY_READ,        -- Read from memory
        MEMORY_WAIT,        -- Wait for synch read
        MEMORY_WRITE,       -- Write to memory
        MEMORY_WRITE_WAIT,
        WRITEBACK_REG_MEM,  -- Write back to register from memory
        WRITEBACK_REG_ALU,  -- Write back to register from ALU
        BRANCH_COMPLETE,    -- Complete branch execution
        JUMP_COMPLETE,      -- Complete jump execution
        MFHI_EXECUTE,       -- Execute MFHI instruction
        MFLO_EXECUTE        -- Execute MFLO instruction
    );
    
    -- Current and next state signals
    signal current_state, next_state : state_type;
    
    --I/O port addresses
    constant INPORT0_ADDR : std_logic_vector(15 downto 0) := x"FFF8";
    constant INPORT1_ADDR : std_logic_vector(15 downto 0) := x"FFFC";
    constant OUTPORT_ADDR : std_logic_vector(15 downto 0) := x"FFFC";
    
    -- Opcodes (from project description)
    constant OP_R_TYPE     : std_logic_vector(5 downto 0) := "000000"; -- R-type instructions
    constant OP_BLTZ_BGEZ  : std_logic_vector(5 downto 0) := "000001"; -- BLTZ, BGEZ
    constant OP_J          : std_logic_vector(5 downto 0) := "000010"; -- Jump
    constant OP_JAL        : std_logic_vector(5 downto 0) := "000011"; -- Jump and link
    constant OP_BEQ        : std_logic_vector(5 downto 0) := "000100"; -- Branch if equal
    constant OP_BNE        : std_logic_vector(5 downto 0) := "000101"; -- Branch if not equal
    constant OP_BLEZ       : std_logic_vector(5 downto 0) := "000110"; -- Branch if less than or equal to zero
    constant OP_BGTZ       : std_logic_vector(5 downto 0) := "000111"; -- Branch if greater than zero
    constant OP_ADDI       : std_logic_vector(5 downto 0) := "001000"; -- Add immediate
    constant OP_ADDIU      : std_logic_vector(5 downto 0) := "001001"; -- Add immediate unsigned
    constant OP_SLTI       : std_logic_vector(5 downto 0) := "001010"; -- Set on less than immediate
    constant OP_SLTIU      : std_logic_vector(5 downto 0) := "001011"; -- Set on less than immediate unsigned
    constant OP_ANDI       : std_logic_vector(5 downto 0) := "001100"; -- AND immediate
    constant OP_ORI        : std_logic_vector(5 downto 0) := "001101"; -- OR immediate
    constant OP_XORI       : std_logic_vector(5 downto 0) := "001110"; -- XOR immediate
    constant OP_SUBIU      : std_logic_vector(5 downto 0) := "010000"; -- Subtract immediate unsigned (custom)
    constant OP_LW         : std_logic_vector(5 downto 0) := "100011"; -- Load word
    constant OP_SW         : std_logic_vector(5 downto 0) := "101011"; -- Store word
    constant OP_HALT       : std_logic_vector(5 downto 0) := "111111"; -- Halt (custom)
    
    -- RT field constants for BLTZ/BGEZ instructions
    constant RT_BLTZ       : std_logic_vector(4 downto 0) := "00000"; -- RT field for BLTZ
    constant RT_BGEZ       : std_logic_vector(4 downto 0) := "00001"; -- RT field for BGEZ
    
    -- ALUOp values
    constant ALUOP_LOAD_STORE   : std_logic_vector(2 downto 0) := "000"; -- Load/Store (address calculation)
    constant ALUOP_BRANCH_EQ    : std_logic_vector(2 downto 0) := "001"; -- Branch equal/not equal
    constant ALUOP_R_TYPE       : std_logic_vector(2 downto 0) := "010"; -- R-type instructions
    constant ALUOP_ADDI         : std_logic_vector(2 downto 0) := "011"; -- Add immediate
    constant ALUOP_BRANCH_CMP   : std_logic_vector(2 downto 0) := "100"; -- Branch comparison
    constant ALUOP_SLTI         : std_logic_vector(2 downto 0) := "101"; -- Set on less than immediate
    constant ALUOP_ANDI         : std_logic_vector(2 downto 0) := "110"; -- AND immediate
    constant ALUOP_ORI          : std_logic_vector(2 downto 0) := "111"; -- OR immediate
    
    -- Function codes for R-type instructions
    constant FUNC_JR     : std_logic_vector(5 downto 0) := "001000"; -- Jump Register
    constant FUNC_MFHI   : std_logic_vector(5 downto 0) := "010000"; -- Move From HI
    constant FUNC_MFLO   : std_logic_vector(5 downto 0) := "010010"; -- Move From LO

begin
    -- Process to update the current state on clock edge
    process(clk, reset)
    begin
        if reset = '1' then
            current_state <= FETCH;
        elsif rising_edge(clk) then
            current_state <= next_state;
        end if;
    end process;
    
    -- Process to determine the next state based on current state and inputs
    process(current_state, opcode, funct, rt_field)
    begin
        -- Default next state (to avoid latches)
        next_state <= current_state;
        
        case current_state is
            when FETCH =>
                -- After fetching, always go to decode
                next_state <= DECODE;
                
            when DECODE =>
                -- Determine next state based on opcode
                case opcode is
                    when OP_R_TYPE =>
                        -- R-type instruction
                        if funct = FUNC_MFHI then
                            next_state <= MFHI_EXECUTE;
                        elsif funct = FUNC_MFLO then
                            next_state <= MFLO_EXECUTE;
                        elsif funct = FUNC_JR then
                            next_state <= JUMP_COMPLETE;
                        else
                            next_state <= EXECUTE_R_TYPE;
                        end if;
                        
                    when OP_LW =>
                        -- Load word
                        next_state <= MEMORY_ADDR_COMP;
                        
                    when OP_SW =>
                        -- Store word
                        next_state <= MEMORY_ADDR_COMP;
                        
                    when OP_BEQ | OP_BNE | OP_BLEZ | OP_BGTZ =>
                        -- Branch instructions
                        next_state <= BRANCH_COMPLETE;
                    
                    when OP_BLTZ_BGEZ =>
                        -- BLTZ/BGEZ instructions (shared opcode, different rt fields)
                        next_state <= BRANCH_COMPLETE;
                        
                    when OP_J | OP_JAL =>
                        -- Jump instructions
                        next_state <= JUMP_COMPLETE;
                        
                    when OP_ADDI | OP_ADDIU | OP_SLTI | OP_SLTIU | 
                         OP_ANDI | OP_ORI | OP_XORI | OP_SUBIU =>
                        -- I-type ALU instructions
                        next_state <= EXECUTE_I_TYPE;
                        
                    when others =>
                        -- Unknown instruction or HALT
                        next_state <= FETCH;
                end case;
                
            when EXECUTE_R_TYPE =>
                -- After execution, go to register writeback
                next_state <= COMPLETE_R_TYPE;
            
            when COMPLETE_R_TYPE =>
                -- After execution, go to register writeback
                next_state <= FETCH;
                
            when EXECUTE_I_TYPE =>
                -- After execution, go to register writeback
                next_state <= WRITEBACK_REG_ALU;
                
            when MEMORY_ADDR_COMP =>
                -- After computing address, go to memory read/write
                if opcode = OP_LW then
                    next_state <= MEMORY_READ;
                else
                    next_state <= MEMORY_WRITE;
                end if;
                
            when MEMORY_READ =>
                -- After reading memory, write to register
                next_state <= MEMORY_WAIT;

            when MEMORY_WAIT =>
                -- Wait for synchronous read
                next_state <= WRITEBACK_REG_MEM;
                
            when MEMORY_WRITE =>
                -- After writing to memory, fetch next instruction
                next_state <= MEMORY_WRITE_WAIT;

            when MEMORY_WRITE_WAIT =>
                next_state <= FETCH;
                
            when WRITEBACK_REG_MEM =>
                -- After writing to register, fetch next instruction
                next_state <= FETCH;
                
            when WRITEBACK_REG_ALU =>
                -- After writing to register, fetch next instruction
                next_state <= FETCH;
                
            when BRANCH_COMPLETE =>
                -- After branch, fetch next instruction
                next_state <= FETCH;
                
            when JUMP_COMPLETE =>
                -- After jump, fetch next instruction
                next_state <= FETCH;
                
            when MFHI_EXECUTE | MFLO_EXECUTE =>
                -- After MFHI/MFLO execute, write to register
                next_state <= WRITEBACK_REG_ALU;
                
            when others =>
                -- Undefined state, go to fetch (should never happen)
                next_state <= FETCH;
        end case;
    end process;
    
    -- Process to generate control signals based on current state and inputs
    process(current_state, opcode, funct, rt_field)
    begin
        -- Default control signal values (to avoid latches)
        PCWrite <= '0';
        PCWriteCond <= '0';
        IorD <= '0';
        MemRead <= '0';
        MemWrite <= '0';
        MemToReg <= '0';
        IRWrite <= '0';
        JumpAndLink <= '0';
        IsSigned <= '1';  -- Default to signed
        PCSource <= "00";
        ALUOp <= "000";   -- Default to load/store operation
        ALUSrcA <= '0';
        ALUSrcB <= "00";
        RegWrite <= '0';
        RegDst <= '0';
        -- Removed ALU_LO_HI <= "00"; -- Now handled by ALU controller
        
        case current_state is
            when FETCH =>
                -- Fetch instruction from memory
                MemRead <= '1';       -- Read from memory
                IRWrite <= '1';       -- Write to instruction register
                ALUSrcA <= '0';       -- ALU input A = PC
                ALUSrcB <= "01";      -- ALU input B = 4
                ALUOp <= ALUOP_ADDI;  -- ALU operation = Add
                PCSource <= "00";     -- PC source = ALU output
                PCWrite <= '1';       -- Write to PC
                
            when DECODE =>
                -- Decode instruction and read registers
                -- In this state, we're reading registers and computing branch target
                ALUSrcA <= '0';       -- ALU input A = PC
                ALUSrcB <= "11";      -- ALU input B = Sign-extended immediate << 2
                ALUOp <= ALUOP_ADDI;  -- ALU operation = Add
                
            when EXECUTE_R_TYPE =>
                -- Execute R-type instruction
                ALUSrcA <= '1';       -- ALU input A = Register A
                ALUSrcB <= "00";      -- ALU input B = Register B
                ALUOp <= ALUOP_R_TYPE; -- ALU operation = R-type

            when COMPLETE_R_TYPE =>
                -- Complete R-type instruction
                RegDst <= '1';
                RegWrite <= '1';
                MemToReg <= '0';
                
            when EXECUTE_I_TYPE =>
                -- Execute I-type instruction
                ALUSrcA <= '1';       -- ALU input A = Register A
                ALUSrcB <= "10";      -- ALU input B = Sign/Zero-extended immediate
                
                -- Set ALUOp based on opcode
                case opcode is
                    when OP_ADDI | OP_ADDIU =>
                        ALUOp <= ALUOP_ADDI;
                    when OP_SLTI | OP_SLTIU =>
                        ALUOp <= ALUOP_SLTI;
                    when OP_ANDI =>
                        ALUOp <= ALUOP_ANDI;
                        IsSigned <= '0';  -- Zero extend for logical operations
                    when OP_ORI | OP_XORI =>
                        ALUOp <= ALUOP_ORI;
                        IsSigned <= '0';  -- Zero extend for logical operations
                    when OP_SUBIU =>
                        ALUOp <= ALUOP_BRANCH_EQ; -- Using subtract operation
                    when others =>
                        ALUOp <= ALUOP_ADDI;
                end case;
                
            when MEMORY_ADDR_COMP =>
                -- Compute memory address
                ALUSrcA <= '1';       -- ALU input A = Register A
                ALUSrcB <= "10";      -- ALU input B = Sign-extended immediate
                ALUOp <= ALUOP_LOAD_STORE; -- ALU operation = Add
                
            when MEMORY_READ =>
                -- Read from memory
                IorD <= '1';          -- Memory address = ALU out
                MemRead <= '1';       -- Read from memory

            when MEMORY_WAIT =>
                MemRead <= '1';       --Redundant
                MemToReg <= '1';      -- Register write data = Memory data
                RegWrite <= '1';
                
            when MEMORY_WRITE =>
                -- Write to memory
                IorD <= '1';          -- Memory address = ALU out
                MemWrite <= '1';      -- Write to memory

            when MEMORY_WRITE_WAIT =>
                IorD <= '0';
                
            when WRITEBACK_REG_MEM =>
                -- Write to register from memory
                RegDst <= '0';        -- Register destination = rt field (I-type)
                MemToReg <= '1';      -- Register write data = Memory data
                if instreg_150 = INPORT0_ADDR then
                    RegWrite <= '0';
                elsif instreg_150 = INPORT1_ADDR then
                    RegWrite <= '0';
                else
                    RegWrite <= '1';      -- Write to register file
                end if;
                
            when WRITEBACK_REG_ALU =>
                -- Write to register from ALU
                if opcode = OP_R_TYPE then
                    RegDst <= '1';    -- Register destination = rd field (R-type)
                else
                    RegDst <= '0';    -- Register destination = rt field (I-type)
                end if;
                MemToReg <= '0';      -- Register write data = ALU out
                RegWrite <= '1';      -- Write to register file
                
            when BRANCH_COMPLETE =>
                -- Complete branch execution
                ALUSrcA <= '1';       -- ALU input A = Register A
                ALUSrcB <= "00";      -- ALU input B = Register B
                
                case opcode is
                    when OP_BEQ | OP_BNE =>
                        ALUOp <= ALUOP_BRANCH_EQ; -- ALU operation = Subtract for equality check
                    when OP_BLEZ | OP_BGTZ | OP_BLTZ_BGEZ =>
                        ALUOp <= ALUOP_BRANCH_CMP; -- ALU operation = Compare with zero
                    when others =>
                        ALUOp <= ALUOP_BRANCH_EQ;
                end case;
                
                PCSource <= "01";     -- PC source = Branch target
                PCWriteCond <= '1';   -- Conditional PC write
                
            when JUMP_COMPLETE =>
                -- Complete jump execution
                if opcode = OP_JAL then
                    JumpAndLink <= '1'; -- Set JAL flag for register write
                    RegWrite <= '1';    -- Write PC+4 to $ra (register 31)
                end if;
                
                PCSource <= "10";     -- PC source = Jump target
                if opcode = OP_R_TYPE and funct = FUNC_JR then
                    -- Jump register uses ALU to pass register value to PC
                    ALUSrcA <= '1';   -- ALU input A = Register A (ra)
                    ALUSrcB <= "00";  -- Doesn't matter for JR
                    ALUOp <= ALUOP_ADDI; -- Just pass through Register A
                    PCSource <= "00"; -- PC source = ALU output (which is just Register A)
                end if;
                PCWrite <= '1';       -- Write to PC
                
            when MFHI_EXECUTE | MFLO_EXECUTE =>
                -- For MFHI/MFLO, we maintain the same ALUOp to use r-type
                -- The specific operation will be decoded by the ALU controller
                ALUOp <= ALUOP_R_TYPE;
                -- Removed references to ALU_LO_HI here
                
            when others =>
                -- Default case (should never happen)
                null;
        end case;
    end process;
end behavioral;