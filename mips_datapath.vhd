--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mips_datapath is
    port (
        clk              : in std_logic;
        reset            : in std_logic;
        
        -- Control signals
        PCWrite          : in std_logic;
        PCWriteCond      : in std_logic;
        IorD             : in std_logic;
        MemRead          : in std_logic;
        MemWrite         : in std_logic;
        MemToReg         : in std_logic;
        IRWrite          : in std_logic;
        JumpAndLink      : in std_logic;
        IsSigned         : in std_logic;
        PCSource         : in std_logic_vector(1 downto 0);
        ALUOp            : in std_logic_vector(2 downto 0);
        ALUSrcA          : in std_logic;
        ALUSrcB          : in std_logic_vector(1 downto 0);
        RegWrite         : in std_logic;
        RegDst           : in std_logic;
        BranchTaken      : out std_logic;
        
        -- Instruction fields output to controller
        IR_out_3126      : out std_logic_vector(5 downto 0);  -- opcode
        IR_out_50        : out std_logic_vector(5 downto 0);  -- function code
        IR_out_2016      : out std_logic_vector(4 downto 0);  -- rt field
        IR_out_150       : out std_logic_vector(15 downto 0);
        
        --Memory I/O
        InPort0_en       : in std_logic;
        InPort1_en       : in std_logic;
        InPort0_in       : in std_logic_vector(9 downto 0);
        InPort1_in       : in std_logic_vector(9 downto 0);
        OutPort_out      : out std_logic_vector(31 downto 0)
    );
end mips_datapath;

architecture structural of mips_datapath is
    -- Internal signals
    
    -- Memory Signals
    signal inport0_input_signal : std_logic_vector(31 downto 0);
    signal inport1_input_signal : std_logic_vector(31 downto 0);
    signal MemDataIn : std_logic_vector(31 downto 0);

    -- Register outputs
    signal PC_q : std_logic_vector(31 downto 0);
    signal IR_q : std_logic_vector(31 downto 0);
    signal MDR_q : std_logic_vector(31 downto 0);
    signal A_q : std_logic_vector(31 downto 0);
    signal B_q : std_logic_vector(31 downto 0);
    signal ALUOut_q : std_logic_vector(31 downto 0);
    signal HI_q : std_logic_vector(31 downto 0);
    signal LO_q : std_logic_vector(31 downto 0);
    
    -- ALU signals
    signal ALU_result : std_logic_vector(31 downto 0);
    signal ALU_result_HI : std_logic_vector(31 downto 0);
    --signal ALU_branch_taken : std_logic;
    signal ALU_op_select : std_logic_vector(4 downto 0);

    -- ALU control signals
    signal HI_en : std_logic;
    signal LO_en : std_logic;
    signal ALU_LO_Hi : std_logic_vector(1 downto 0);
    
    -- Multiplexer outputs
    signal IorD_out : std_logic_vector(31 downto 0);
    signal RegDst_out : std_logic_vector(4 downto 0);
    signal MemToReg_out : std_logic_vector(31 downto 0);
    signal ALUSrcA_out : std_logic_vector(31 downto 0);
    signal ALUSrcB_out : std_logic_vector(31 downto 0);
    signal PCSource_out : std_logic_vector(31 downto 0);
    signal Alu_LO_HI_out : std_logic_vector(31 downto 0);
    
    -- Register file signals
    signal RF_read_data1 : std_logic_vector(31 downto 0);
    signal RF_read_data2 : std_logic_vector(31 downto 0);
    --signal RF_write_reg : std_logic_vector(4 downto 0);
    
    -- Sign extender output
    signal sign_extend_out : std_logic_vector(31 downto 0);
    
    -- Shifted sign extended immediate
    signal shift_left_2_part1_out : std_logic_vector(31 downto 0);
    signal shift_left_2_part2_out : std_logic_vector(27 downto 0);

    -- Concat Output
    signal concat_out : std_logic_vector(31 downto 0);
    
    -- Constants
    signal const_4 : std_logic_vector(31 downto 0) := x"00000004";
    
begin
    
    -- PC Register
    PC_Register: entity work.reg_32bit
        port map (
            clk => clk,
            reset => reset,
            enable => PCWrite,
            d => PCSource_out,
            q => PC_q
        );
    
    -- IorD MUX
    IorD_MUX: entity work.mux_2to1
        generic map (WIDTH => 32)
        port map (
            sel => IorD,
            in0 => PC_q,
            in1 => ALUOut_q,
            output => IorD_out
        );

    -- Memory Module
    memory_module: entity work.memory_module
            port map (
                clk => clk,
                reset => reset,
                addr => IorD_out,
                data_in => B_q, 
                data_out => MemDataIn,
                mem_read => MemRead,
                mem_write => MemWrite,
                inport0_in => inport0_input_signal,
                inport0_en => InPort0_en,
                inport1_in => inport1_input_signal,
                inport1_en => InPort1_en,
                outport => OutPort_out
            );

    -- Zero Extends
    Zero_Extend_0: entity work.zero_extend
        port map (
            input => InPort0_in,
            output => inport0_input_signal
        );

    Zero_Extend_1: entity work.zero_extend
    port map (
        input => InPort1_in,
        output => inport1_input_signal
    );
    
    -- Instruction Register
    IR_Register: entity work.reg_32bit
        port map (
            clk => clk,
            reset => reset,
            enable => IRWrite,
            d => MemDataIn,
            q => IR_q
        );
    
    -- Memory Data Register
    MDR_Register: entity work.reg_32bit
        port map (
            clk => clk,
            reset => reset,
            enable => '1', -- Always enabled for memory read
            d => MemDataIn,
            q => MDR_q
        );
     
    -- RegDst MUX
    RegDst_MUX: entity work.mux_2to1
        generic map (WIDTH => 5)
        port map (
            sel => RegDst,
            in0 => IR_q(20 downto 16), -- rt
            in1 => IR_q(15 downto 11), -- rd
            output => RegDst_out
        );

     -- MemToReg MUX
     MemToReg_MUX: entity work.mux_2to1
     generic map (WIDTH => 32)
     port map (
         sel => MemToReg,
         in0 => Alu_LO_HI_out,
         in1 => MDR_q,
         output => MemToReg_out
     );

    -- Register File
    Register_File_unit: entity work.register_file
    port map (
        clk => clk,
        reset => reset,
        read_reg1 => IR_q(25 downto 21), -- rs
        read_reg2 => IR_q(20 downto 16), -- rt
        write_reg => RegDst_out,
        write_data => MemToReg_out,
        reg_write => RegWrite,
        jump_and_link => JumpAndLink,
        read_data1 => RF_read_data1,
        read_data2 => RF_read_data2
    );

    -- Sign Extender
    Sign_Extend_unit: entity work.sign_extend
        port map (
            input => IR_q(15 downto 0),
            is_signed => IsSigned,
            output => sign_extend_out
        );

    -- Register A
    A_Register: entity work.reg_32bit
        port map (
            clk => clk,
            reset => reset,
            enable => '1', -- Always enabled
            d => RF_read_data1,
            q => A_q
        );
    
    -- Register B
    B_Register: entity work.reg_32bit
        port map (
            clk => clk,
            reset => reset,
            enable => '1', -- Always enabled
            d => RF_read_data2,
            q => B_q
        );
    
    -- Shift Left 2 Part 1
    Shift_Left2_Part1: entity work.shift_left_2
    port map (
        input => sign_extend_out,
        output => shift_left_2_part1_out
    );

    -- ALUSrcA MUX
    ALUSrcA_MUX: entity work.mux_2to1
        generic map (WIDTH => 32)
        port map (
            sel => ALUSrcA,
            in0 => PC_q,
            in1 => A_q,
            output => ALUSrcA_out
        );
    
    -- ALUSrcB MUX
    ALUSrcB_MUX: entity work.mux_4to1
        generic map (WIDTH => 32)
        port map (
            sel => ALUSrcB,
            in0 => B_q,
            in1 => const_4,
            in2 => sign_extend_out,
            in3 => shift_left_2_part1_out,
            output => ALUSrcB_out
        );

    -- Shift Left 2 Part 2
    Shift_Left2_Part2: entity work.shift_left_2_28bit
    port map (
        input => IR_q(25 downto 0),
        output => shift_left_2_part2_out
    );

    -- Concat
    Concat: entity work.concat
    port map (
        input1 => shift_left_2_part2_out,
        input2 => IR_q(31 downto 28),
        output => concat_out
    );

    -- ALU
    ALU_unit: entity work.alu
        generic map (WIDTH => 32)
        port map (
            input1 => ALUSrcA_out,
            input2 => ALUSrcB_out,
            shift_amount => IR_q(10 downto 6),
            OPSelect => ALU_op_select,
            result => ALU_result,
            branch_taken => BranchTaken,
            result_HI => ALU_result_HI
        );
    
    -- ALU Control Unit
    ALU_Control_unit: entity work.alu_control
        port map (
            ALUOp => ALUOp,
            Funct => IR_q(5 downto 0),
            OPSelect => ALU_op_select,
            ALU_LO_HI => ALU_LO_HI,
            HI_en => HI_en,
            LO_en => LO_en
        );

    -- PCSource MUX
    PCSource_MUX: entity work.mux_3to1
        generic map (WIDTH => 32)
        port map (
            sel => PCSource,
            in0 => ALU_result,
            in1 => ALUOut_q,
            in2 => concat_out,
            output => PCSource_out
        );

    -- ALU Output Register
    ALUOut_Register: entity work.reg_32bit
        port map (
            clk => clk,
            reset => reset,
            enable => '1', -- Always enabled
            d => ALU_result,
            q => ALUOut_q
        );
    
    -- LO Register
    LO_Register: entity work.reg_32bit
        port map (
            clk => clk,
            reset => reset,
            enable => LO_en,
            d => ALU_result,
            q => LO_q
        );

    -- HI Register
    HI_Register: entity work.reg_32bit
        port map (
            clk => clk,
            reset => reset,
            enable => HI_en,
            d => ALU_result_HI,
            q => HI_q
        );
    
    -- ALU/LO/HI MUX
    Alu_LO_HI_MUX: entity work.mux_3to1
        generic map (WIDTH => 32)
        port map (
            sel => Alu_LO_HI,
            in0 => ALUOut_q, -- Normal result path
            in1 => LO_q,     -- MFLO
            in2 => HI_q,     -- MFHI
            output => Alu_LO_HI_out
        );
    
    -- Output instruction fields to controller
    IR_out_3126 <= IR_q(31 downto 26);  -- opcode
    IR_out_50 <= IR_q(5 downto 0);      -- function code
    IR_out_2016 <= IR_q(20 downto 16);  -- rt field
    IR_out_150 <= IR_q(15 downto 0);
    
end structural;