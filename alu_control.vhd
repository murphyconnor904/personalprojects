--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_control is
    port(
        -- Inputs
        ALUOp       : in std_logic_vector(2 downto 0); -- From main controller
        Funct       : in std_logic_vector(5 downto 0); -- Function field for R-type instructions
        
        -- Outputs
        OPSelect    : out std_logic_vector(4 downto 0); -- ALU operation select (updated to 5 bits to match ALU)
        HI_en       : out std_logic;                   -- Enable HI register
        LO_en       : out std_logic;                   -- Enable LO register
        ALU_LO_HI   : out std_logic_vector(1 downto 0) -- Select between ALU, LO, or HI outputs
    );
end alu_control;

architecture behavioral of alu_control is
    -- Constant definitions for ALU operations (aligned with ALU implementation)
    constant ALU_ADD    : std_logic_vector(4 downto 0) := "00000"; -- Addition
    constant ALU_ADDI   : std_logic_vector(4 downto 0) := "00001"; -- Add immediate
    constant ALU_SUB    : std_logic_vector(4 downto 0) := "00010"; -- Subtraction
    constant ALU_SUBI   : std_logic_vector(4 downto 0) := "00011"; -- Subtract immediate
    constant ALU_MULT   : std_logic_vector(4 downto 0) := "00100"; -- Multiplication (signed)
    constant ALU_MULTU  : std_logic_vector(4 downto 0) := "00101"; -- Multiplication (unsigned)
    constant ALU_AND    : std_logic_vector(4 downto 0) := "00110"; -- AND operation
    constant ALU_ANDI   : std_logic_vector(4 downto 0) := "00111"; -- AND immediate
    constant ALU_OR     : std_logic_vector(4 downto 0) := "01000"; -- OR operation
    constant ALU_ORI    : std_logic_vector(4 downto 0) := "01001"; -- OR immediate
    constant ALU_XOR    : std_logic_vector(4 downto 0) := "01010"; -- XOR operation
    constant ALU_XORI   : std_logic_vector(4 downto 0) := "01011"; -- XOR immediate
    constant ALU_SRL    : std_logic_vector(4 downto 0) := "01100"; -- Shift right logical
    constant ALU_SLL    : std_logic_vector(4 downto 0) := "01101"; -- Shift left logical
    constant ALU_SRA    : std_logic_vector(4 downto 0) := "01110"; -- Shift right arithmetic
    constant ALU_SLT    : std_logic_vector(4 downto 0) := "01111"; -- Set on less than (signed)
    constant ALU_SLTI   : std_logic_vector(4 downto 0) := "10000"; -- Set on less than immediate (signed)
    constant ALU_SLTIU  : std_logic_vector(4 downto 0) := "10001"; -- Set on less than immediate (unsigned)
    constant ALU_SLTU   : std_logic_vector(4 downto 0) := "10010"; -- Set on less than (unsigned)
    constant ALU_MFHI   : std_logic_vector(4 downto 0) := "10011"; -- Move from HI
    constant ALU_MFLO   : std_logic_vector(4 downto 0) := "10100"; -- Move from LO
    constant ALU_BEQ    : std_logic_vector(4 downto 0) := "10101"; -- Branch equal
    constant ALU_BNE    : std_logic_vector(4 downto 0) := "10110"; -- Branch not equal
    constant ALU_BLEZ   : std_logic_vector(4 downto 0) := "10111"; -- Branch less equal zero
    constant ALU_BGTZ   : std_logic_vector(4 downto 0) := "11000"; -- Branch greater than zero
    constant ALU_BLTZ   : std_logic_vector(4 downto 0) := "11001"; -- Branch less than zero
    constant ALU_BGEZ   : std_logic_vector(4 downto 0) := "11010"; -- Branch greater equal zero
    constant ALU_J      : std_logic_vector(4 downto 0) := "11011"; -- Jump
    constant ALU_JAL    : std_logic_vector(4 downto 0) := "11100"; -- Jump and link
    constant ALU_JR     : std_logic_vector(4 downto 0) := "11101"; -- Jump register
    
    -- R-type function codes from the instruction set (only those actually used in the ALU)
    constant FUNC_SLL    : std_logic_vector(5 downto 0) := "000000";
    constant FUNC_SRL    : std_logic_vector(5 downto 0) := "000010";
    constant FUNC_SRA    : std_logic_vector(5 downto 0) := "000011";
    constant FUNC_JR     : std_logic_vector(5 downto 0) := "001000";
    constant FUNC_MFHI   : std_logic_vector(5 downto 0) := "010000";
    constant FUNC_MFLO   : std_logic_vector(5 downto 0) := "010010";
    constant FUNC_MULT   : std_logic_vector(5 downto 0) := "011000";
    constant FUNC_MULTU  : std_logic_vector(5 downto 0) := "011001";
    constant FUNC_ADD    : std_logic_vector(5 downto 0) := "100000";
    constant FUNC_ADDU   : std_logic_vector(5 downto 0) := "100001";
    constant FUNC_SUB    : std_logic_vector(5 downto 0) := "100010";
    constant FUNC_SUBU   : std_logic_vector(5 downto 0) := "100011";
    constant FUNC_AND    : std_logic_vector(5 downto 0) := "100100";
    constant FUNC_OR     : std_logic_vector(5 downto 0) := "100101";
    constant FUNC_XOR    : std_logic_vector(5 downto 0) := "100110";
    constant FUNC_SLT    : std_logic_vector(5 downto 0) := "101010";
    constant FUNC_SLTU   : std_logic_vector(5 downto 0) := "101011";
    
    -- ALUOp control signals from main controller
    constant ALUOP_LOAD_STORE   : std_logic_vector(2 downto 0) := "000"; -- Load/Store (Address = base + offset)
    constant ALUOP_BRANCH_EQ    : std_logic_vector(2 downto 0) := "001"; -- Branch equal
    constant ALUOP_R_TYPE       : std_logic_vector(2 downto 0) := "010"; -- R-type instruction, use function field
    constant ALUOP_ADDI         : std_logic_vector(2 downto 0) := "011"; -- Add immediate
    constant ALUOP_BRANCH_CMP   : std_logic_vector(2 downto 0) := "100"; -- Branch compare operations
    constant ALUOP_SLTI         : std_logic_vector(2 downto 0) := "101"; -- Set on less than immediate
    constant ALUOP_ANDI         : std_logic_vector(2 downto 0) := "110"; -- AND immediate
    constant ALUOP_ORI          : std_logic_vector(2 downto 0) := "111"; -- OR immediate

begin
    process(ALUOp, Funct)
        variable op_sel : std_logic_vector(4 downto 0);
        variable hi_enable : std_logic;
        variable lo_enable : std_logic;
        variable alu_lo_hi_sel : std_logic_vector(1 downto 0);
    begin
        -- Default values
        op_sel := ALU_ADD;            -- Default to ADD operation
        hi_enable := '0';             -- Default HI register disable
        lo_enable := '0';             -- Default LO register disable
        
        case ALUOp is
            when ALUOP_LOAD_STORE =>
                -- For load/store instructions, we need to compute address
                op_sel := ALU_ADD;
                
            when ALUOP_BRANCH_EQ =>
                -- For branch equal/not equal, we need to subtract and check zero
                op_sel := ALU_BEQ;
                
            when ALUOP_R_TYPE =>
                -- R-type instructions, use function field to determine operation
                case Funct is
                    when FUNC_ADD =>
                        op_sel := ALU_ADD;
                        alu_lo_hi_sel := "00";        -- Default to ALU output (00=ALU, 01=LO, 10=HI)
                        
                    when FUNC_ADDU =>
                        op_sel := ALU_ADD;
                        alu_lo_hi_sel := "00";        -- Default to ALU output (00=ALU, 01=LO, 10=HI)
                        
                    when FUNC_SUB =>
                        op_sel := ALU_SUB;
                        alu_lo_hi_sel := "00";        -- Default to ALU output (00=ALU, 01=LO, 10=HI)
                        
                    when FUNC_SUBU =>
                        op_sel := ALU_SUB;
                        alu_lo_hi_sel := "00";        -- Default to ALU output (00=ALU, 01=LO, 10=HI)
                        
                    when FUNC_AND =>
                        op_sel := ALU_AND;
                        alu_lo_hi_sel := "00";        -- Default to ALU output (00=ALU, 01=LO, 10=HI)
                        
                    when FUNC_OR =>
                        op_sel := ALU_OR;
                        alu_lo_hi_sel := "00";        -- Default to ALU output (00=ALU, 01=LO, 10=HI)
                        
                    when FUNC_XOR =>
                        op_sel := ALU_XOR;
                        alu_lo_hi_sel := "00";        -- Default to ALU output (00=ALU, 01=LO, 10=HI)
                        
                    when FUNC_SLT =>
                        op_sel := ALU_SLT;
                        alu_lo_hi_sel := "00";        -- Default to ALU output (00=ALU, 01=LO, 10=HI)
                        
                    when FUNC_SLTU =>
                        op_sel := ALU_SLTU;
                        alu_lo_hi_sel := "00";        -- Default to ALU output (00=ALU, 01=LO, 10=HI)
                        
                    when FUNC_SLL =>
                        op_sel := ALU_SLL;
                        alu_lo_hi_sel := "00";        -- Default to ALU output (00=ALU, 01=LO, 10=HI)
                        
                    when FUNC_SRL =>
                        op_sel := ALU_SRL;
                        alu_lo_hi_sel := "00";        -- Default to ALU output (00=ALU, 01=LO, 10=HI)
                        
                    when FUNC_SRA =>
                        op_sel := ALU_SRA;
                        alu_lo_hi_sel := "00";        -- Default to ALU output (00=ALU, 01=LO, 10=HI)
                        
                    when FUNC_MULT =>
                        op_sel := ALU_MULT;
                        hi_enable := '1';
                        lo_enable := '1';
                        
                    when FUNC_MULTU =>
                        op_sel := ALU_MULTU;
                        hi_enable := '1';
                        lo_enable := '1';
                        
                    when FUNC_MFHI =>
                        -- Move from HI register to destination register
                        op_sel := ALU_MFHI;
                        alu_lo_hi_sel := "10";  -- Select HI register
                        
                    when FUNC_MFLO =>
                        -- Move from LO register to destination register
                        op_sel := ALU_MFLO;
                        alu_lo_hi_sel := "01";  -- Select LO register
                        
                    when FUNC_JR =>
                        -- Jump register
                        op_sel := ALU_JR;
                        
                    when others => 
                        op_sel := ALU_ADD; -- Default
                end case;
                
            when ALUOP_ADDI =>
                -- Add immediate
                op_sel := ALU_ADDI;
                
            when ALUOP_BRANCH_CMP =>
                -- Branch compare (bgtz, blez, etc.)
                -- Note: This will need further decoding based on specific branch type
                op_sel := ALU_BLEZ; -- Default, should be refined based on specific branch instruction
                
            when ALUOP_SLTI =>
                -- Set on less than immediate
                op_sel := ALU_SLTI;
                
            when ALUOP_ANDI =>
                -- AND immediate
                op_sel := ALU_ANDI;
                
            when ALUOP_ORI =>
                -- OR immediate
                op_sel := ALU_ORI;
                
            when others =>
                op_sel := ALU_ADD; -- Default
        end case;
        
        -- Assign outputs
        OPSelect <= op_sel;
        HI_en <= hi_enable;
        LO_en <= lo_enable;
        ALU_LO_HI <= alu_lo_hi_sel;
    end process;
end behavioral;