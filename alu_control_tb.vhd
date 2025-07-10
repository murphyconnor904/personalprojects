--Connor Murphy
--Section 11092

-- ALU Control Testbench
-- Tests the functionality of the ALU control unit with assert statements

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu_control_tb is
    -- Empty entity
end alu_control_tb;

architecture test of alu_control_tb is
    -- Component declaration for the Unit Under Test (UUT)
    component alu_control is
        port (
            ALUOp       : in std_logic_vector(2 downto 0);
            Funct       : in std_logic_vector(5 downto 0);
            OPSelect    : out std_logic_vector(4 downto 0);
            HI_en       : out std_logic;
            LO_en       : out std_logic;
            ALU_LO_HI   : out std_logic_vector(1 downto 0)
        );
    end component;
    
    -- Test signals
    signal tb_ALUOp     : std_logic_vector(2 downto 0) := "000";
    signal tb_Funct     : std_logic_vector(5 downto 0) := "000000";
    signal tb_OPSelect  : std_logic_vector(4 downto 0);
    signal tb_HI_en     : std_logic;
    signal tb_LO_en     : std_logic;
    signal tb_ALU_LO_HI : std_logic_vector(1 downto 0);
    
    -- Constants for expected ALU operations (same as in alu_control.vhd)
    constant ALU_ADD    : std_logic_vector(4 downto 0) := "00000";
    constant ALU_ADDI   : std_logic_vector(4 downto 0) := "00001";
    constant ALU_SUB    : std_logic_vector(4 downto 0) := "00010";
    constant ALU_SUBI   : std_logic_vector(4 downto 0) := "00011";
    constant ALU_MULT   : std_logic_vector(4 downto 0) := "00100";
    constant ALU_MULTU  : std_logic_vector(4 downto 0) := "00101";
    constant ALU_AND    : std_logic_vector(4 downto 0) := "00110";
    constant ALU_ANDI   : std_logic_vector(4 downto 0) := "00111";
    constant ALU_OR     : std_logic_vector(4 downto 0) := "01000";
    constant ALU_ORI    : std_logic_vector(4 downto 0) := "01001";
    constant ALU_XOR    : std_logic_vector(4 downto 0) := "01010";
    constant ALU_XORI   : std_logic_vector(4 downto 0) := "01011";
    constant ALU_SRL    : std_logic_vector(4 downto 0) := "01100";
    constant ALU_SLL    : std_logic_vector(4 downto 0) := "01101";
    constant ALU_SRA    : std_logic_vector(4 downto 0) := "01110";
    constant ALU_SLT    : std_logic_vector(4 downto 0) := "01111";
    constant ALU_SLTI   : std_logic_vector(4 downto 0) := "10000";
    constant ALU_SLTIU  : std_logic_vector(4 downto 0) := "10001";
    constant ALU_SLTU   : std_logic_vector(4 downto 0) := "10010";
    constant ALU_MFHI   : std_logic_vector(4 downto 0) := "10011";
    constant ALU_MFLO   : std_logic_vector(4 downto 0) := "10100";
    constant ALU_BEQ    : std_logic_vector(4 downto 0) := "10101";
    constant ALU_BNE    : std_logic_vector(4 downto 0) := "10110";
    constant ALU_BLEZ   : std_logic_vector(4 downto 0) := "10111";
    constant ALU_BGTZ   : std_logic_vector(4 downto 0) := "11000";
    constant ALU_BLTZ   : std_logic_vector(4 downto 0) := "11001";
    constant ALU_BGEZ   : std_logic_vector(4 downto 0) := "11010";
    constant ALU_J      : std_logic_vector(4 downto 0) := "11011";
    constant ALU_JAL    : std_logic_vector(4 downto 0) := "11100";
    constant ALU_JR     : std_logic_vector(4 downto 0) := "11101";

begin
    -- Instantiate the Unit Under Test (UUT)
    uut: alu_control port map (
        ALUOp => tb_ALUOp,
        Funct => tb_Funct,
        OPSelect => tb_OPSelect,
        HI_en => tb_HI_en,
        LO_en => tb_LO_en,
        ALU_LO_HI => tb_ALU_LO_HI
    );
    
    -- Stimulus process
    stim_proc: process
    begin
        -- Allow some time for initialization
        wait for 10 ns;
        
        -- Test Case 1: Load/Store Instructions
        tb_ALUOp <= "000"; -- ALUOP_LOAD_STORE
        tb_Funct <= "000000"; -- Doesn't matter for non-R-type
        wait for 10 ns;
        assert tb_OPSelect = ALU_ADD
            report "TC1 Failed: Load/Store should use ALU_ADD operation" severity error;
        assert tb_HI_en = '0' and tb_LO_en = '0'
            report "TC1 Failed: HI/LO registers should not be enabled for Load/Store" severity error;
        assert tb_ALU_LO_HI = "00"
            report "TC1 Failed: Should select ALU output for Load/Store" severity error;
        
        -- Test Case 2: Branch Equal
        tb_ALUOp <= "001"; -- ALUOP_BRANCH_EQ
        tb_Funct <= "000000"; -- Doesn't matter for branches
        wait for 10 ns;
        assert tb_OPSelect = ALU_BEQ
            report "TC2 Failed: Branch Equal should use ALU_BEQ operation" severity error;
        
        -- Test Case 3: R-Type ADD
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "100000"; -- FUNC_ADD
        wait for 10 ns;
        assert tb_OPSelect = ALU_ADD
            report "TC3 Failed: R-Type ADD should use ALU_ADD operation" severity error;
        
        -- Test Case 4: R-Type ADDU
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "100001"; -- FUNC_ADDU
        wait for 10 ns;
        assert tb_OPSelect = ALU_ADD
            report "TC4 Failed: R-Type ADDU should use ALU_ADD operation" severity error;
        
        -- Test Case 5: R-Type SUB
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "100010"; -- FUNC_SUB
        wait for 10 ns;
        assert tb_OPSelect = ALU_SUB
            report "TC5 Failed: R-Type SUB should use ALU_SUB operation" severity error;
        
        -- Test Case 6: R-Type SUBU
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "100011"; -- FUNC_SUBU
        wait for 10 ns;
        assert tb_OPSelect = ALU_SUB
            report "TC6 Failed: R-Type SUBU should use ALU_SUB operation" severity error;
        
        -- Test Case 7: R-Type AND
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "100100"; -- FUNC_AND
        wait for 10 ns;
        assert tb_OPSelect = ALU_AND
            report "TC7 Failed: R-Type AND should use ALU_AND operation" severity error;
        
        -- Test Case 8: R-Type OR
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "100101"; -- FUNC_OR
        wait for 10 ns;
        assert tb_OPSelect = ALU_OR
            report "TC8 Failed: R-Type OR should use ALU_OR operation" severity error;
        
        -- Test Case 9: R-Type XOR
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "100110"; -- FUNC_XOR
        wait for 10 ns;
        assert tb_OPSelect = ALU_XOR
            report "TC9 Failed: R-Type XOR should use ALU_XOR operation" severity error;
        
        -- Test Case 10: R-Type SLT
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "101010"; -- FUNC_SLT
        wait for 10 ns;
        assert tb_OPSelect = ALU_SLT
            report "TC10 Failed: R-Type SLT should use ALU_SLT operation" severity error;
        
        -- Test Case 11: R-Type SLTU
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "101011"; -- FUNC_SLTU
        wait for 10 ns;
        assert tb_OPSelect = ALU_SLTU
            report "TC11 Failed: R-Type SLTU should use ALU_SLTU operation" severity error;
        
        -- Test Case 12: R-Type SLL
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "000000"; -- FUNC_SLL
        wait for 10 ns;
        assert tb_OPSelect = ALU_SLL
            report "TC12 Failed: R-Type SLL should use ALU_SLL operation" severity error;
        
        -- Test Case 13: R-Type SRL
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "000010"; -- FUNC_SRL
        wait for 10 ns;
        assert tb_OPSelect = ALU_SRL
            report "TC13 Failed: R-Type SRL should use ALU_SRL operation" severity error;
        
        -- Test Case 14: R-Type SRA
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "000011"; -- FUNC_SRA
        wait for 10 ns;
        assert tb_OPSelect = ALU_SRA
            report "TC14 Failed: R-Type SRA should use ALU_SRA operation" severity error;
        
        -- Test Case 15: R-Type MULT
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "011000"; -- FUNC_MULT
        wait for 10 ns;
        assert tb_OPSelect = ALU_MULT
            report "TC15 Failed: R-Type MULT should use ALU_MULT operation" severity error;
        assert tb_HI_en = '1' and tb_LO_en = '1'
            report "TC15 Failed: HI and LO registers should be enabled for MULT" severity error;
        
        -- Test Case 16: R-Type MULTU
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "011001"; -- FUNC_MULTU
        wait for 10 ns;
        assert tb_OPSelect = ALU_MULTU
            report "TC16 Failed: R-Type MULTU should use ALU_MULTU operation" severity error;
        assert tb_HI_en = '1' and tb_LO_en = '1'
            report "TC16 Failed: HI and LO registers should be enabled for MULTU" severity error;
        
        -- Test Case 17: R-Type MFHI
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "010000"; -- FUNC_MFHI
        wait for 10 ns;
        assert tb_OPSelect = ALU_MFHI
            report "TC17 Failed: R-Type MFHI should use ALU_MFHI operation" severity error;
        assert tb_ALU_LO_HI = "10"
            report "TC17 Failed: MFHI should select HI register (10)" severity error;
        
        -- Test Case 18: R-Type MFLO
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "010010"; -- FUNC_MFLO
        wait for 10 ns;
        assert tb_OPSelect = ALU_MFLO
            report "TC18 Failed: R-Type MFLO should use ALU_MFLO operation" severity error;
        assert tb_ALU_LO_HI = "01"
            report "TC18 Failed: MFLO should select LO register (01)" severity error;
        
        -- Test Case 19: R-Type JR
        tb_ALUOp <= "010"; -- ALUOP_R_TYPE
        tb_Funct <= "001000"; -- FUNC_JR
        wait for 10 ns;
        assert tb_OPSelect = ALU_JR
            report "TC19 Failed: R-Type JR should use ALU_JR operation" severity error;
        
        -- Test Case 20: ADDI
        tb_ALUOp <= "011"; -- ALUOP_ADDI
        tb_Funct <= "000000"; -- Doesn't matter for I-type
        wait for 10 ns;
        assert tb_OPSelect = ALU_ADDI
            report "TC20 Failed: ADDI should use ALU_ADDI operation" severity error;
        
        -- Test Case 21: Branch Compare (BLEZ, BGTZ, etc.)
        tb_ALUOp <= "100"; -- ALUOP_BRANCH_CMP
        tb_Funct <= "000000"; -- Doesn't matter for branches
        wait;
    end process;
end test;