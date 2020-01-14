library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY MOORE_SM1 IS PORT (
   CLK		     							: in  std_logic := '0';
   RESET_n      							: in  std_logic := '0';
	EXT_BUTTON								: in  std_logic := '0';
	EXT_ENABLE								: in 	std_logic := '0';		-- If both X and Y coordinate has reached its target, enable extender functionality.
	EXT_STATE								: in  std_logic_vector(3 downto 0);	-- Input from Bit shifting.
	LEFT0_RIGHT1, BDR_CLK_EN			: out std_logic;				-- Both used for Bit shifting component.
	EXT_OUT, GRAP_ENBL					: out std_logic				-- EXT_OUT used by MEALY_XY to see if X and Y should change state. GRAP_ENBL Used by Grappler to determine if it can change state.
);
END ENTITY;

ARCHITECTURE SM OF MOORE_SM1 IS

-- list all the STATES  
   TYPE STATES IS (INIT, RETRACTED, EXTENDING, EFULL, RETRACTING);   

   SIGNAL current_state, next_state			:  STATES;       -- current_state, next_state signals are of type STATES
	
BEGIN


-- STATE MACHINE: MOORE Type

REGISTER_SECTION: PROCESS(CLK, RESET_n) -- creates sequential logic to store the state. The rst_n is used to asynchronously clear the register
   BEGIN
		IF (RESET_n = '0') THEN
	         current_state <= INIT;
				
		ELSIF (rising_edge(CLK)) then
				current_state <= next_state; -- on the rising edge of clock the current state is updated with next state
				
		END IF;
   END PROCESS;
	

TRANSITION_LOGIC: PROCESS(EXT_ENABLE, EXT_BUTTON, EXT_STATE, current_state) -- logic to determine next state. 
   BEGIN
		CASE current_state IS
			WHEN INIT =>		
				IF (EXT_ENABLE='1') THEN 
               next_state <= RETRACTED;
					
				ELSE
               next_state <= INIT;
					
            END IF;
				
			WHEN RETRACTED =>					-- Extend Extender.
            IF ((EXT_ENABLE='1') AND (EXT_BUTTON='1')) THEN 
               next_state <= EXTENDING;

				ELSE
               next_state <= RETRACTED;
					
            END IF;
			
			WHEN EXTENDING =>					-- In extension mode.
            IF (EXT_STATE = "1111") THEN 
               next_state <= EFULL;
					
				ELSE
               next_state <= EXTENDING;
					
            END IF;
				
			WHEN EFULL =>
				IF (EXT_BUTTON='1') THEN
					next_state <= RETRACTING;			-- Retract Extender if button pressed and fully extended state reached.
					
				ELSE
					next_state <= EFULL;
					
				END IF;
			
			WHEN RETRACTING =>					-- In extension mode.
            IF (EXT_STATE = "0000") THEN 
               next_state <= RETRACTED;
					
				ELSE
               next_state <= RETRACTING;
					
            END IF;
			
			WHEN OTHERS =>
            next_state <= INIT;
					
 		END CASE;
 END PROCESS;

MOORE_DECODER: PROCESS(current_state) 			-- logic to determine outputs from state machine states
	BEGIN		
		CASE current_state IS
			WHEN INIT =>
				LEFT0_RIGHT1 <= '1';
				BDR_CLK_EN <= '0';
				EXT_OUT <= '0';	-- Important.
				GRAP_ENBL <= '0';

			WHEN RETRACTED =>	
				LEFT0_RIGHT1 <= '1';
				BDR_CLK_EN <= '0';-- Important.
				EXT_OUT <= '0';	-- Important.
				GRAP_ENBL <= '0';
				
			WHEN EXTENDING =>		
				LEFT0_RIGHT1 <= '1';	-- Important.
				BDR_CLK_EN <= '1';	-- Important.
				EXT_OUT <= '1';		-- Important.
				GRAP_ENBL <= '0';
			 			 
			WHEN EFULL =>
				LEFT0_RIGHT1 <= '1';
				BDR_CLK_EN <= '0';	-- Important.
				EXT_OUT <= '1';		-- Important.
				GRAP_ENBL <= '1';		-- Important. Only allow Grapple to enable when the extender is fully out.
			 
			WHEN RETRACTING =>		
				LEFT0_RIGHT1 <= '0';	-- Important. Left shift.
				BDR_CLK_EN <= '1';	-- Important.
				EXT_OUT <= '1';		-- Important.
				GRAP_ENBL <= '0';
				
			WHEN OTHERS =>
				LEFT0_RIGHT1 <= '0';
				BDR_CLK_EN <= '0';
				EXT_OUT <= '0';
				GRAP_ENBL <= '0';
				
		END CASE;
	END PROCESS;
END SM;
