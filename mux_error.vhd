LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;


entity mux_error is port (
	CLK						: in	std_logic := '0';
	RESET_n      			: in  std_logic := '0';
	ERROR_ON 				: in 	std_logic := '0';
	Digit1, Digit2			: in 	std_logic_vector(6 downto 0);		-- SevenSegment representation of digits.
	Dig1_out, Dig2_out	: out std_logic_vector(6 downto 0)
);
end entity mux_error;


architecture one of mux_error is
	signal counter		: UNSIGNED(1 downto 0);
	
begin

process (CLK, RESET_n) is

begin

	if (RESET_n = '0' OR ERROR_ON = '0') then
		Dig1_out <= Digit1;
		Dig2_out <= Digit2;
		counter <= "00";
		
	elsif (rising_edge(CLK)) then		-- Executes if ERROR_ON is true.
		counter <= (counter + 1);		-- Activate flashing of digits.
		
		if (counter = "01" OR counter = "11") then
			Dig1_out <= "0000000";
			Dig2_out <= "0000000";
		
		elsif (counter = "10" OR counter = "00") then
			Dig1_out <= Digit1;
			Dig2_out <= Digit2;
			
		end if;
	end if;
end process;

end one;