library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Compx4 is port (
	hex_A, hex_B 	: in std_logic_vector(3 downto 0);
	result: out std_logic_vector(2 downto 0)
);
end Compx4;


architecture Compx4_logic of Compx4 is
-- Define components to be used:

component Compx1 port (

	A, B : in std_logic;
	A_lt_B, A_eq_B, A_gt_B: out std_logic 

);
end component;



-- Define temp vars (signals) here.
	signal result0, result1, result2, result3	: std_logic_vector(2 downto 0);
	signal temp1, temp2 : std_logic_vector(2 downto 0);


begin 
	-- Compare each bit, and output to each result. (A<, A=B, A>B)
	INST0: Compx1 port map(hex_A(3), hex_B(3), result3(2), result3(1), result3(0));
	INST1: Compx1 port map(hex_A(2), hex_B(2), result2(2), result2(1), result2(0)); 
	INST2: Compx1 port map(hex_A(1), hex_B(1), result1(2), result1(1), result1(0)); 
	INST3: Compx1 port map(hex_A(0), hex_B(0), result0(2), result0(1), result0(0));

	-- Assign resultant value to output using a combination of gates.
	result(2) <= result3(2) OR (result3(1) AND result2(2)) OR (result3(1) AND result2(1) AND result1(2)) OR (result3(1) AND result2(1) AND result3(1) AND result0(2));
	result(1) <= result3(1) AND result2(1) AND result1(1) AND result0(1);	-- All elements must be equal
	result(0) <= result3(0) OR (result3(1) AND result2(0)) OR (result3(1) AND result2(1) AND result1(0)) OR (result3(1) AND result2(1) AND result3(1) AND result0(0));


end Compx4_logic;

-- Compute the output for this chip by comparing the result values, starting with result0 (for the leftmost bits)
-- If result1 (From comparing A1 and B1) results in A1=B1, then take whatever value result0 (A0 and B0) is. Else take result1.
-- Repeat above with temp variables until result3 reached.
-- NOTE: We originally used a nested implementation starting with result3 at the top level.


--with result1 select
--	temp1 <= result0 when "010", 
--				result1 when others;
--
--with result2 select
--	temp2 <= temp1 when "010",
--	         result2 when others;
--				 
--
--with result3 select
--	result <= temp2 when "010",
--				 result3 when others;
