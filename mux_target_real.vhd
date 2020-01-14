LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;


entity mux_target_real is port (
	target_x, target_y, real_x, real_y		: in std_logic_vector(3 downto 0);	-- Target and real coordinates
	x_sel, y_sel									: in std_logic := '0';					-- Push buttons
	out_x, out_y									: out std_logic_vector(3 downto 0)	-- Which coordinates to display
);
end entity;


architecture design of mux_target_real is

	signal temp 	: std_logic;

begin

	temp <= x_sel OR y_sel;

with temp select
	out_x <= real_x when '1',
				target_x when others;

with temp select
	out_y <= real_y when '1',
				target_y when others;

end design;