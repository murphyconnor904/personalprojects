--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity alu_tb is
end alu_tb;

architecture behavioral of alu_tb is
    -- Component Declaration for the ALU
    component alu
        generic (WIDTH : positive := 32);
        port (
            input1 : in std_logic_vector(WIDTH-1 downto 0);
            input2 : in std_logic_vector(WIDTH-1 downto 0);
            shift_amount : in std_logic_vector(4 downto 0);
            OPSelect : in std_logic_vector(4 downto 0);
            result : out std_logic_vector(WIDTH-1 downto 0);
            branch_taken : out std_logic;
            result_HI : out std_logic_vector(WIDTH-1 downto 0)
        );
    end component;

    -- Test Bench Signals
    constant WIDTH : positive := 32;
    constant CLK_PERIOD : time := 10 ns;
    
    signal tb_input1 : std_logic_vector(WIDTH-1 downto 0);
    signal tb_input2 : std_logic_vector(WIDTH-1 downto 0);
    signal tb_shift_amount : std_logic_vector(4 downto 0);
    signal tb_OPSelect : std_logic_vector(4 downto 0);
    signal tb_result : std_logic_vector(WIDTH-1 downto 0);
    signal tb_branch_taken : std_logic;
    signal tb_result_HI : std_logic_vector(WIDTH-1 downto 0);
    
    -- Helper function to convert std_logic_vector to hex string
    function to_hex_string(signal_in : std_logic_vector) return string is
        variable hex_val : string(1 to signal_in'length/4);
        variable val : std_logic_vector(3 downto 0);
        variable index : integer := 1;
    begin
        for i in (signal_in'length/4) downto 1 loop
            val := signal_in(4*i-1 downto 4*i-4);
            case val is
                when "0000" => hex_val(index) := '0';
                when "0001" => hex_val(index) := '1';
                when "0010" => hex_val(index) := '2';
                when "0011" => hex_val(index) := '3';
                when "0100" => hex_val(index) := '4';
                when "0101" => hex_val(index) := '5';
                when "0110" => hex_val(index) := '6';
                when "0111" => hex_val(index) := '7';
                when "1000" => hex_val(index) := '8';
                when "1001" => hex_val(index) := '9';
                when "1010" => hex_val(index) := 'A';
                when "1011" => hex_val(index) := 'B';
                when "1100" => hex_val(index) := 'C';
                when "1101" => hex_val(index) := 'D';
                when "1110" => hex_val(index) := 'E';
                when "1111" => hex_val(index) := 'F';
                when others => hex_val(index) := 'X';
            end case;
            index := index + 1;
        end loop;
        return hex_val;
    end function;
    
    -- Helper Procedure for Printing Results
    procedure print_test_case(test_name : string) is
    begin
        report "------------------------------------------------------";
        report "Test Case: " & test_name;
        report "Input1: 0x" & to_hex_string(tb_input1);
        report "Input2: 0x" & to_hex_string(tb_input2);
        report "Shift Amount: " & integer'image(to_integer(unsigned(tb_shift_amount)));
        report "Result: 0x" & to_hex_string(tb_result);
        report "Result_HI: 0x" & to_hex_string(tb_result_HI);
        report "Branch Taken: " & std_logic'image(tb_branch_taken);
        report "------------------------------------------------------";
    end procedure;

begin
    -- Unit Under Test (UUT) Instance
    uut: alu
        generic map (WIDTH => WIDTH)
        port map (
            input1 => tb_input1,
            input2 => tb_input2,
            shift_amount => tb_shift_amount,
            OPSelect => tb_OPSelect,
            result => tb_result,
            branch_taken => tb_branch_taken,
            result_HI => tb_result_HI
        );

    -- Stimulus Process
    stimulus: process
    begin
        -- Initialize inputs
        tb_input1 <= (others => '0');
        tb_input2 <= (others => '0');
        tb_shift_amount <= (others => '0');
        tb_OPSelect <= (others => '0');
        wait for CLK_PERIOD;
        
        -- 1. Test Addition: A + B (10 + 15)
        tb_input1 <= std_logic_vector(to_unsigned(10, WIDTH));
        tb_input2 <= std_logic_vector(to_unsigned(15, WIDTH));
        tb_OPSelect <= "00000"; -- ADD/ADDU operation
        wait for CLK_PERIOD;
        print_test_case("Addition 10 + 15 (should be 25)");
        
        -- 2. Test Subtraction: A - B (25 - 10)
        tb_input1 <= std_logic_vector(to_unsigned(25, WIDTH));
        tb_input2 <= std_logic_vector(to_unsigned(10, WIDTH));
        tb_OPSelect <= "00010"; -- SUB/SUBU operation
        wait for CLK_PERIOD;
        print_test_case("Subtraction 25 - 10 (should be 15)");
        
        -- 3. Test Signed Multiplication: A * B (10 * -4)
        tb_input1 <= std_logic_vector(to_signed(10, WIDTH));
        tb_input2 <= std_logic_vector(to_signed(-4, WIDTH));
        tb_OPSelect <= "00100"; -- MULT (signed)
        wait for CLK_PERIOD;
        print_test_case("Signed Multiplication 10 * -4 (should be -40)");
        
        -- 4. Test Unsigned Multiplication: A * B (65536 * 131072)
        tb_input1 <= std_logic_vector(to_unsigned(65536, WIDTH));
        tb_input2 <= std_logic_vector(to_unsigned(131072, WIDTH));
        tb_OPSelect <= "00101"; -- MULTU (unsigned)
        wait for CLK_PERIOD;
        print_test_case("Unsigned Multiplication 65536 * 131072 (should overflow)");
        
        -- 5. Test AND: A AND B (0x0000FFFF AND 0xFFFF1234)
        tb_input1 <= x"0000FFFF";
        tb_input2 <= x"FFFF1234";
        tb_OPSelect <= "00110"; -- AND
        wait for CLK_PERIOD;
        print_test_case("AND 0x0000FFFF AND 0xFFFF1234 (should be 0x00001234)");
        
        -- 6. Test Shift Right Logical: Shift 0x0000000F right by 4
        tb_input1 <= x"0000000F";
        tb_shift_amount <= "00100"; -- Shift by 4
        tb_OPSelect <= "01100"; -- SRL
        wait for CLK_PERIOD;
        print_test_case("Shift Right Logical 0x0000000F by 4 (should be 0x00000000)");
        
        -- 7. Test Shift Right Arithmetic: Shift 0xF0000008 right by 1
        tb_input1 <= x"F0000008";
        tb_shift_amount <= "00001"; -- Shift by 1
        tb_OPSelect <= "01110"; -- SRA
        wait for CLK_PERIOD;
        print_test_case("Shift Right Arithmetic 0xF0000008 by 1 (should be 0xF8000004)");
        
        -- 8. Test Shift Right Arithmetic: Shift 0x00000008 right by 1
        tb_input1 <= x"00000008";
        tb_shift_amount <= "00001"; -- Shift by 1
        tb_OPSelect <= "01110"; -- SRA
        wait for CLK_PERIOD;
        print_test_case("Shift Right Arithmetic 0x00000008 by 1 (should be 0x00000004)");
        
        -- 9. Test SLT: A < B (10 < 15)
        tb_input1 <= std_logic_vector(to_signed(10, WIDTH));
        tb_input2 <= std_logic_vector(to_signed(15, WIDTH));
        tb_OPSelect <= "01111"; -- SLT
        wait for CLK_PERIOD;
        print_test_case("SLT 10 < 15 (should be 1)");
        
        -- 10. Test SLT: A < B (15 < 10)
        tb_input1 <= std_logic_vector(to_signed(15, WIDTH));
        tb_input2 <= std_logic_vector(to_signed(10, WIDTH));
        tb_OPSelect <= "01111"; -- SLT
        wait for CLK_PERIOD;
        print_test_case("SLT 15 < 10 (should be 0)");
        
        -- 11. Test BLEZ: A <= 0 (A = 5, should be false)
        tb_input1 <= std_logic_vector(to_signed(5, WIDTH));
        tb_OPSelect <= "10111"; -- BLEZ
        wait for CLK_PERIOD;
        print_test_case("BLEZ A=5 (branch_taken should be 0)");
        
        -- 12. Test BGTZ: A > 0 (A = 5, should be true)
        tb_input1 <= std_logic_vector(to_signed(5, WIDTH));
        tb_OPSelect <= "11000"; -- BGTZ
        wait for CLK_PERIOD;
        print_test_case("BGTZ A=5 (branch_taken should be 1)");
    
        -- End simulation
        wait;
    end process;
end behavioral;