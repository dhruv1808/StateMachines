library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity Compx1 is port (

	A, B : in std_logic;
	A_lt_B, A_eq_B, A_gt_B: out std_logic 

);
end Compx1;

architecture compare_logic of Compx1 is

begin

A_lt_B <= NOT(A) AND B;
		 
A_eq_B <= A XNOR B;		    

A_gt_B <= A AND NOT(B);

end architecture compare_logic; 