--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testcase1_top_level is
    port (
        -- Clock and reset
        clk              : in std_logic;
        reset            : in std_logic;
        
        -- Input/Output ports
        InPort0_en       : in std_logic;
        InPort1_en       : in std_logic;
        InPort0_in       : in std_logic_vector(9 downto 0);
        InPort1_in       : in std_logic_vector(9 downto 0);
        OutPort_out      : out std_logic_vector(31 downto 0)
    );
end testcase1_top_level;

architecture STR_TOP of testcase1_top_level is
-- Control signals between controller and datapath
signal PCWrite       : std_logic;
signal PCWriteCond   : std_logic;
signal IorD          : std_logic;
signal MemRead       : std_logic;
signal MemWrite      : std_logic;
signal MemToReg      : std_logic;
signal IRWrite       : std_logic;
signal JumpAndLink   : std_logic;
signal IsSigned      : std_logic;
signal PCSource      : std_logic_vector(1 downto 0);
signal ALUOp         : std_logic_vector(2 downto 0);
signal ALUSrcA       : std_logic;
signal ALUSrcB       : std_logic_vector(1 downto 0);
signal RegWrite      : std_logic;
signal RegDst        : std_logic;
signal BranchTaken   : std_logic;

-- Instruction fields from datapath to controller
signal IR_opcode     : std_logic_vector(5 downto 0);
signal IR_funct      : std_logic_vector(5 downto 0);
signal IR_rt_field   : std_logic_vector(4 downto 0);
signal IR_150        : std_logic_vector(15 downto 0);

-- Full Instruction Register (need to modify datapath to expose this)
signal IR_full       : std_logic_vector(31 downto 0);

begin
-- Modified datapath component declaration (would need to update the datapath entity)
datapath_unit: entity work.testcase1_datapath
    port map (
        clk             => clk,
        reset           => reset,
        PCWrite         => PCWrite,
        PCWriteCond     => PCWriteCond,
        IorD            => IorD,
        MemRead         => MemRead,
        MemWrite        => MemWrite,
        MemToReg        => MemToReg,
        IRWrite         => IRWrite,
        JumpAndLink     => JumpAndLink,
        IsSigned        => IsSigned,
        PCSource        => PCSource,
        ALUOp           => ALUOp,
        ALUSrcA         => ALUSrcA,
        ALUSrcB         => ALUSrcB,
        RegWrite        => RegWrite,
        RegDst          => RegDst,
        BranchTaken     => BranchTaken,
        IR_out_3126     => IR_opcode,
        IR_out_50       => IR_funct,    -- Added output
        IR_out_2016     => IR_rt_field, -- Added output
        IR_out_150      => IR_150,
        InPort0_en      => InPort0_en,
        InPort1_en      => InPort1_en,
        InPort0_in      => InPort0_in,
        InPort1_in      => InPort1_in,
        OutPort_out     => OutPort_out
    );

-- Instantiate the controller
controller_unit: entity work.controller
    port map (
        clk             => clk,
        reset           => reset,
        opcode          => IR_opcode,
        funct           => IR_funct,
        rt_field        => IR_rt_field,
        instreg_150     => IR_150,
        PCWrite         => PCWrite,
        PCWriteCond     => PCWriteCond,
        IorD            => IorD,
        MemRead         => MemRead,
        MemWrite        => MemWrite,
        MemToReg        => MemToReg,
        IRWrite         => IRWrite,
        JumpAndLink     => JumpAndLink,
        IsSigned        => IsSigned,
        PCSource        => PCSource,
        ALUOp           => ALUOp,
        ALUSrcA         => ALUSrcA,
        ALUSrcB         => ALUSrcB,
        RegWrite        => RegWrite,
        RegDst          => RegDst
    );
end STR_TOP;