library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Mealy_XY is port (
	CLK		     							: in  std_logic := '0';
   RESET_n      							: in  std_logic := '0';
	X_BUTTON, Y_BUTTON					: in	std_logic := '0';
	X_COMPARE, Y_COMPARE					: in 	std_logic_vector(2 downto 0);		-- Result of Compx4 (Target vs Real coordinates)
	EXT_OUT									: in 	std_logic := '0';		-- Determines whether error state reached.
	xc_clk_en, yc_clk_en					: out std_logic;		-- Enable/disable counter.
	x_u1_d0, y_u1_d0						: out std_logic;		-- Tells counters to increment or decrement.
	ERROR_ON									: out std_logic
);
end entity;
 

Architecture move of Mealy_XY is
	TYPE STATE_NAMES IS (NO_CHANGE, CX, CY, CXY, ERROR);   -- State values depending on whether X OR Y coordinates made to change.
	SIGNAL current_state, next_state	:  STATE_NAMES;     	-- signals of type STATE_NAMES


BEGIN
 
 --------------------------------------------------------------------------------
 --State Machine: Mealy Type
 --------------------------------------------------------------------------------

REGISTER_SECTION: PROCESS(CLK, RESET_n) -- creates sequential logic to store the state. The rst_n is used to asynchronously clear the register
BEGIN
	IF (RESET_n = '0') THEN
		current_state <= NO_CHANGE;
	
	ELSIF (rising_edge(CLK)) then
		current_state <= next_state; -- on the rising edge of clock the current state is updated with next state
				
	END IF;
END PROCESS;


TRANSITION_LOGIC: PROCESS(X_BUTTON, Y_BUTTON, X_COMPARE, Y_COMPARE, EXT_OUT, current_state) -- logic to determine next state. 
BEGIN
	CASE current_state IS
		WHEN NO_CHANGE => 	-- No coordinates change.
			IF (EXT_OUT = '1' AND (X_BUTTON = '1' OR Y_BUTTON = '1') AND (NOT(X_COMPARE = "010") OR NOT(Y_COMPARE = "010"))) THEN
				next_state <= ERROR;
			
			ELSIF (NOT(Y_COMPARE = "010") AND Y_BUTTON = '1') AND (NOT(X_COMPARE = "010") AND X_BUTTON = '1') THEN	-- Condition takes precedence.
				next_state <= CXY;
			
			ELSIF NOT(X_COMPARE = "010") AND X_BUTTON = '1' THEN
				next_state <= CX;
			
			ELSIF NOT(Y_COMPARE = "010") AND Y_BUTTON = '1' THEN
				next_state <= CY;
			
			ELSE
				next_state <= NO_CHANGE;
			
			END IF;
			
		WHEN CX => 			-- Only X coordinate changes
			IF (EXT_OUT = '1' AND (X_BUTTON = '1' OR Y_BUTTON = '1') AND (NOT(X_COMPARE = "010") OR NOT(Y_COMPARE = "010"))) THEN
				next_state <= ERROR;
			
			ELSIF  (X_COMPARE = "010") OR (X_BUTTON = '0') THEN 	-- Condition takes precedence.
				next_state <= NO_CHANGE;
			
			ELSIF NOT(Y_COMPARE = "010") AND Y_BUTTON = '1' THEN
				next_state <= CXY;
			
			ELSE
				next_state <= CX;
			
			END IF;
		
		WHEN CY => 			-- Only X coordinate changes
			IF (EXT_OUT = '1' AND (X_BUTTON = '1' OR Y_BUTTON = '1') AND (NOT(X_COMPARE = "010") OR NOT(Y_COMPARE = "010"))) THEN
				next_state <= ERROR;
			
			ELSIF (Y_COMPARE = "010") OR (Y_BUTTON = '0') THEN	-- Condition takes precedence.
				next_state <= NO_CHANGE;
			
			ELSIF NOT(X_COMPARE = "010") AND X_BUTTON = '1' THEN
				next_state <= CXY;
			
			ELSE
				next_state <= CY;
			
			END IF;
			
		WHEN CXY =>
			IF (EXT_OUT = '1' AND (X_BUTTON = '1' OR Y_BUTTON = '1') AND (NOT(X_COMPARE = "010") OR NOT(Y_COMPARE = "010"))) THEN
				next_state <= ERROR;
			
			ELSIF (Y_COMPARE = "010" AND X_COMPARE = "010") OR (X_BUTTON = '0' AND Y_BUTTON = '0') THEN	-- Condition takes precedence.
				next_state <= NO_CHANGE;
				
			ELSIF (Y_COMPARE = "010") OR Y_BUTTON = '0' THEN
				next_state <= CX;
				
			ELSIF (X_COMPARE = "010") OR X_BUTTON = '0' THEN
				next_state <= CY;
		
			ELSE
				next_state <= CXY;
				
			END IF;
				
		WHEN ERROR =>
			IF EXT_OUT = '0' THEN
				next_state <= NO_CHANGE;
				
			ELSE
				next_state <= ERROR;
				
			END IF;
		
		WHEN OTHERS =>
			next_state <= NO_CHANGE;

	END CASE;
END PROCESS;


MEALY_DECODER: PROCESS(current_state, X_COMPARE, Y_COMPARE) 			-- logic to determine outputs from state machine states and inputs.
BEGIN
	CASE current_state IS 
		WHEN NO_CHANGE =>
			ERROR_ON <= '0';
			xc_clk_en <= '0';
			yc_clk_en <= '0';
			x_u1_d0 <= '0';
			y_u1_d0 <= '0';
			
		WHEN CX =>
			ERROR_ON <= '0';
			xc_clk_en <= NOT X_COMPARE(1);			-- Immediately disable counter if target reaches actual in this state.
			yc_clk_en <= '0';
			y_u1_d0 <= '0';
			
			IF X_COMPARE = "100" THEN	-- Target Coordinate Less Than Actual. (T LT R).
				x_u1_d0 <= '0';
			
			ELSIF X_COMPARE = "001" THEN	-- T GT R.
				x_u1_d0 <= '1';
							
			END IF;
		
		WHEN CY =>
			ERROR_ON <= '0';
			xc_clk_en <= '0';
			yc_clk_en <= NOT Y_COMPARE(1);
			x_u1_d0 <= '0';
			
			IF Y_COMPARE = "100" THEN	-- T LT R
				y_u1_d0 <= '0';
			
			ELSIF Y_COMPARE = "001" THEN	-- T GT R.
				y_u1_d0 <= '1';
			
			END IF;
		
		WHEN CXY =>
			ERROR_ON <= '0';
			xc_clk_en <= NOT X_COMPARE(1);
			yc_clk_en <= NOT Y_COMPARE(1);
			
			-- Make comparisons for both X and Y coordinates.
			IF Y_COMPARE = "100" THEN	
				y_u1_d0 <= '0';
			
			ELSIF Y_COMPARE = "001" THEN	
				y_u1_d0 <= '1';
			
			END IF;
			
			IF X_COMPARE = "100" THEN
				x_u1_d0 <= '0';
			
			ELSIF X_COMPARE = "001" THEN	
				x_u1_d0 <= '1';
			
			END IF;
			
		WHEN ERROR =>
			xc_clk_en <= '0';
			yc_clk_en <= '0';
			x_u1_d0 <= '0';
			y_u1_d0 <= '0';
			ERROR_ON <= '1';
		
		WHEN OTHERS =>			-- Includes error state.
			xc_clk_en <= '0';
			yc_clk_en <= '0';
			x_u1_d0 <= '0';
			y_u1_d0 <= '0';
			ERROR_ON <= '0';

		
	END CASE;
END PROCESS;

END ARCHITECTURE move;
