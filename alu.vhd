--Connor Murphy
--Section 11092

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    generic (WIDTH : positive := 32);
    port (
        input1 : in std_logic_vector(WIDTH-1 downto 0);
        input2 : in std_logic_vector(WIDTH-1 downto 0);
        shift_amount : in std_logic_vector(4 downto 0);
        OPSelect : in std_logic_vector(4 downto 0); -- Operation select
        result : out std_logic_vector(WIDTH-1 downto 0);
        branch_taken : out std_logic;
        result_HI : out std_logic_vector(WIDTH-1 downto 0)
    );
end alu;

architecture behavioral of alu is
begin
    process(input1, input2, shift_amount, OPSelect)
        variable temp_result : unsigned(WIDTH downto 0); -- Extra bit for carry detection
        variable temp_overflow : std_logic;
        variable reversed_vec: std_logic_vector(WIDTH-1 downto 0);
        variable temp_mult_result : unsigned((2*WIDTH) - 1 downto 0);
        variable temp_signed_mult_result : signed((2*WIDTH) - 1 downto 0);
        variable temp_input1 : unsigned(WIDTH-1 downto 0);
        variable signed_input1 : signed(WIDTH-1 downto 0);
        variable signed_input2 : signed(WIDTH-1 downto 0);
        variable count: unsigned(WIDTH-1 downto 0);
        variable temp_branch : std_logic;
        variable temp_result_HI : std_logic_vector(WIDTH-1 downto 0);
        variable log2_count : integer;
    begin
        -- Initialize outputs and variables
        temp_branch := '0';
        temp_overflow := '0';
        temp_result := (others => '0');
        temp_result_HI := (others => '0');
        
        case OPSelect is
            -- Arithmetic Operations
            when "00000" => -- ADD/ADDU (unsigned)
                temp_result := ('0' & unsigned(input1)) + ('0' & unsigned(input2)); 
                temp_overflow := temp_result(WIDTH);
                
            when "00001" => -- ADDI/ADDIU (immediate unsigned)
                temp_result := ('0' & unsigned(input1)) + ('0' & unsigned(input2)); 
                temp_overflow := temp_result(WIDTH);
                
            when "00010" => -- SUB/SUBU (unsigned)
                temp_result := ('0' & unsigned(input1)) - ('0' & unsigned(input2)); 
                
            when "00011" => -- SUBIU (immediate unsigned)
                temp_result := ('0' & unsigned(input1)) - ('0' & unsigned(input2)); 
                
            when "00100" => -- MULT (signed)
                signed_input1 := signed(input1);
                signed_input2 := signed(input2);
                temp_signed_mult_result := signed_input1 * signed_input2;
                temp_result(WIDTH-1 downto 0) := unsigned(temp_signed_mult_result(WIDTH-1 downto 0));
                temp_result_HI := std_logic_vector(temp_signed_mult_result(2*WIDTH-1 downto WIDTH));
                
            when "00101" => -- MULTU (unsigned)
                temp_mult_result := unsigned(input1) * unsigned(input2);
                temp_result(WIDTH-1 downto 0) := temp_mult_result(WIDTH-1 downto 0);
                temp_result_HI := std_logic_vector(temp_mult_result(2*WIDTH-1 downto WIDTH));
                
            -- Logical Operations
            when "00110" => -- AND
                temp_result(WIDTH-1 downto 0) := unsigned(input1 and input2);
                
            when "00111" => -- ANDI
                temp_result(WIDTH-1 downto 0) := unsigned(input1 and input2);
                
            when "01000" => -- OR
                temp_result(WIDTH-1 downto 0) := unsigned(input1 or input2);
                
            when "01001" => -- ORI
                temp_result(WIDTH-1 downto 0) := unsigned(input1 or input2);
                
            when "01010" => -- XOR
                temp_result(WIDTH-1 downto 0) := unsigned(input1 xor input2);
                
            when "01011" => -- XORI
                temp_result(WIDTH-1 downto 0) := unsigned(input1 xor input2);
                
            -- Shift Operations
            when "01100" => -- SRL (shift right logical)
                temp_result(WIDTH-1 downto 0) := shift_right(unsigned(input1), to_integer(unsigned(shift_amount)));
                
            when "01101" => -- SLL (shift left logical)
                temp_result(WIDTH-1 downto 0) := shift_left(unsigned(input1), to_integer(unsigned(shift_amount)));
                
            when "01110" => -- SRA (shift right arithmetic)
                signed_input1 := signed(input1);
                temp_result(WIDTH-1 downto 0) := unsigned(shift_right(signed_input1, to_integer(unsigned(shift_amount))));
                
            -- Comparison Operations
            when "01111" => -- SLT (Set on Less Than) - Signed
                signed_input1 := signed(input1);
                signed_input2 := signed(input2);
                if signed_input1 < signed_input2 then
                    temp_result(WIDTH-1 downto 0) := to_unsigned(1, WIDTH);
                else
                    temp_result(WIDTH-1 downto 0) := to_unsigned(0, WIDTH);
                end if;
                
            when "10000" => -- SLTI (Set on Less Than Immediate) - Signed
                signed_input1 := signed(input1);
                signed_input2 := signed(input2);
                if signed_input1 < signed_input2 then
                    temp_result(WIDTH-1 downto 0) := to_unsigned(1, WIDTH);
                else
                    temp_result(WIDTH-1 downto 0) := to_unsigned(0, WIDTH);
                end if;
                
            when "10001" => -- SLTU (Set on Less Than) - Unsigned
                if unsigned(input1) < unsigned(input2) then
                    temp_result(WIDTH-1 downto 0) := to_unsigned(1, WIDTH);
                else
                    temp_result(WIDTH-1 downto 0) := to_unsigned(0, WIDTH);
                end if;
                
            when "10010" => -- SLTIU (Set on Less Than Immediate) - Unsigned
                if unsigned(input1) < unsigned(input2) then
                    temp_result(WIDTH-1 downto 0) := to_unsigned(1, WIDTH);
                else
                    temp_result(WIDTH-1 downto 0) := to_unsigned(0, WIDTH);
                end if;
                
            -- Register Movement Operations
            when "10011" => -- MFHI (Move From HI)
                -- Just pass input1 as-is (will be HI register in datapath)
                temp_result(WIDTH-1 downto 0) := unsigned(input1);
                
            when "10100" => -- MFLO (Move From LO)
                -- Just pass input1 as-is (will be LO register in datapath)
                temp_result(WIDTH-1 downto 0) := unsigned(input1);
                
            -- Branch Operations
            when "10101" => -- BEQ (Branch if Equal)
                if input1 = input2 then
                    temp_branch := '1';
                end if;
                
            when "10110" => -- BNE (Branch if Not Equal)
                if input1 /= input2 then
                    temp_branch := '1';
                end if;
                
            when "10111" => -- BLEZ (Branch if Less Than or Equal to Zero)
                signed_input1 := signed(input1);
                if signed_input1 <= 0 then
                    temp_branch := '1';
                end if;
                
            when "11000" => -- BGTZ (Branch if Greater Than Zero)
                signed_input1 := signed(input1);
                if signed_input1 > 0 then
                    temp_branch := '1';
                end if;
                
            when "11001" => -- BLTZ (Branch if Less Than Zero)
                signed_input1 := signed(input1);
                if signed_input1 < 0 then
                    temp_branch := '1';
                end if;
                
            when "11010" => -- BGEZ (Branch if Greater Than or Equal to Zero)
                signed_input1 := signed(input1);
                if signed_input1 >= 0 then
                    temp_branch := '1';
                end if;
                
            -- Additional Operations for Completeness
            when "11011" => -- NOT 
                temp_result(WIDTH-1 downto 0) := unsigned(not input1);
                
            when "11100" => -- NOR 
                temp_result(WIDTH-1 downto 0) := unsigned(not (input1 or input2));
            
            when "11101" => -- Swap high and low halves
                temp_result(WIDTH-1 downto 0) := unsigned(input1(WIDTH/2-1 downto 0) & input1(WIDTH-1 downto WIDTH/2));
                
            when "11110" => -- Bit reversal
                for i in 0 to WIDTH-1 loop
                    reversed_vec(i) := input1(WIDTH-1-i);
                end loop;
                temp_result(WIDTH-1 downto 0) := unsigned(reversed_vec);
                
            when "11111" => -- Floor log 2 of input 1
                log2_count := 0;
                if unsigned(input1) = 0 then
                    temp_result(WIDTH-1 downto 0) := (others => '0');
                else
                    temp_input1 := unsigned(input1);
                    while temp_input1 > 1 loop
                        temp_input1 := shift_right(temp_input1, 1);
                        log2_count := log2_count + 1;
                    end loop;
                    temp_result(WIDTH-1 downto 0) := to_unsigned(log2_count, WIDTH);
                end if;
                
            when others => -- Default case
                temp_result(WIDTH-1 downto 0) := (others => '0');
                
        end case;
        
        -- Assign outputs
        result <= std_logic_vector(temp_result(WIDTH-1 downto 0));
        result_HI <= temp_result_HI;
        branch_taken <= temp_branch;
        
    end process;
end behavioral;