
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY LogicalStep_Lab4_top IS
   PORT
	(
   clkin_50		: in	std_logic;
	rst_n			: in	std_logic;
	pb				: in	std_logic_vector(3 downto 0);	-- 3: X Drive Enable, 2: Y Drive Enable, 1: Extender Toggle (in/out), 0: Grappler Toggle
 	sw   			: in  std_logic_vector(7 downto 0); -- The switch inputs
   leds			: out std_logic_vector(7 downto 0);	-- for displaying the switch content. [7:4]: Extender Position, 3: Grappler ON (Closed), [2:1]: Custom (X and Y reached), 0: System Error.
   seg7_data 	: out std_logic_vector(6 downto 0); -- 7-bit outputs to a 7-segment
	seg7_char1  : out	std_logic;							-- seg7 digi selectors
	seg7_char2  : out	std_logic							-- seg7 digi selectors
	);
END LogicalStep_Lab4_top;

ARCHITECTURE SimpleCircuit OF LogicalStep_Lab4_top IS

-- COMPONENTS:
component Bidir_shift_reg port (
	CLK				: in	std_logic := '0';
	RESET_n			: in	std_logic := '0';
	CLK_EN			: in	std_logic := '0';
	LEFT0_RIGHT1	: in	std_logic := '0';
	REG_BITS			: out std_logic_vector(3 downto 0)
);
end component;

component U_D_Bin_Counter4bit port (
	CLK				: in	std_logic := '0';
	RESET_n			: in	std_logic := '0';
	CLK_EN			: in	std_logic := '0';
	UP1_DOWN0		: in	std_logic := '0';
	COUNTER_BITS	: out std_logic_vector(3 downto 0)
);
end component;

component Compx4 port (
	hex_A, hex_B 	: in std_logic_vector(3 downto 0);
	result			: out std_logic_vector(2 downto 0)
);
end component;

component SevenSegment port (
   hex	   	:  in  std_logic_vector(3 downto 0);   -- The 4 bit data to be displayed
   sevenseg :  out std_logic_vector(6 downto 0)    -- 7-bit outputs to a 7-segment
); 
end component;

component segment7_mux port (
	clk        : in  std_logic := '0';
	DIN2 		: in  std_logic_vector(6 downto 0);	
	DIN1 		: in  std_logic_vector(6 downto 0);
	DOUT			: out	std_logic_vector(6 downto 0);
	DIG2			: out	std_logic;
	DIG1			: out	std_logic
);
end component;

component mux_target_real port (
	target_x, target_y, real_x, real_y		: in std_logic_vector(3 downto 0);	-- Target and real coordinates
	x_sel, y_sel									: in std_logic := '0';					-- Push buttons
	out_x, out_y									: out std_logic_vector(3 downto 0)	-- Which coordinates to display
);
end component;

component mux_error port (
	CLK						: in	std_logic := '0';
	RESET_n      			: in  std_logic := '0';
	ERROR_ON 				: in 	std_logic := '0';
	Digit1, Digit2			: in 	std_logic_vector(6 downto 0);		-- SevenSegment representation of digits.
	Dig1_out, Dig2_out	: out std_logic_vector(6 downto 0)
);
end component;

component Mealy_XY port (
	CLK		     							: in  std_logic := '0';
   RESET_n      							: in  std_logic := '0';
	X_BUTTON, Y_BUTTON					: in	std_logic := '0';
	X_COMPARE, Y_COMPARE					: in 	std_logic_vector(2 downto 0);		-- Result of Compx4 (Target vs Real coordinates)
	EXT_OUT									: in 	std_logic := '0';		-- Determines whether error state reached.
	xc_clk_en, yc_clk_en					: out std_logic;		-- Enable/disable counter.
	x_u1_d0, y_u1_d0						: out std_logic;		-- Tells counters to increment or decrement.
	ERROR_ON									: out std_logic
);
end component;

component MOORE_SM1 port (
	CLK		     							: in  std_logic := '0';
   RESET_n      							: in  std_logic := '0';
	EXT_BUTTON								: in  std_logic := '0';
	EXT_ENABLE								: in 	std_logic := '0';		-- If both X and Y coordinate has reached its target, enable extender functionality.
	EXT_STATE								: in  std_logic_vector(3 downto 0);	-- Input from Bit shifting.
	LEFT0_RIGHT1, BDR_CLK_EN			: out std_logic;				-- Both used for Bit shifting component.
	EXT_OUT, GRAP_ENBL					: out std_logic				-- EXT_OUT used by MEALY_XY to see if X and Y should change state. GRAP_ENBL Used by Grappler to determine if it can change state.
);
end component;

component MOORE_SM2 port (
	CLK		     		: in  std_logic := '0';
   RESET_n      		: in  std_logic := '0';
	GRAP_BUTTON			: in  std_logic := '0';
	GRAP_ENBL			: in  std_logic := '0';
	GRAP_ON			   : out std_logic
);
end component;

-- SIGNALS AND CONSTANTS
----------------------------------------------------------------------------------------------------
	CONSTANT	SIM							:  boolean := FALSE; 	-- set to TRUE for simulation runs otherwise keep at 0.
   CONSTANT CLK_DIV_SIZE				: 	INTEGER := 26;    -- size of vectors for the counters

   SIGNAL 	Main_CLK						:  STD_LOGIC; 			-- main clock to drive sequencing of State Machine

	SIGNAL 	bin_counter					:  UNSIGNED(CLK_DIV_SIZE-1 downto 0); -- := to_unsigned(0,CLK_DIV_SIZE); -- reset binary counter to zero
	
	SIGNAL 	target_x_coord, target_y_coord	: std_logic_vector(3 downto 0);	-- For the switches.
		
	-- X and Y Counters.
	SIGNAL	xc_clk_en, yc_clk_en		: std_logic;
	SIGNAL	x_u1_d0, y_u1_d0			: std_logic;
	SIGNAL	real_x_coord, real_y_coord			: std_logic_vector(3 downto 0);
	
	-- MEALY_XY
	SIGNAL	result_x, result_y		: std_logic_vector(2 downto 0); 	-- TARGET_LT_REAL, TARGET_EQ_REAL, TARGET_GT_REAL.
	SIGNAL 	ERROR_ON						: std_logic;
	
	-- Display Digits for 7-segments.
	SIGNAL 	display_X, display_Y		: 	std_logic_vector(3 downto 0);
	SIGNAL 	Digit1_temp, Digit2_temp: 	std_logic_vector(6 downto 0);		-- Seven segment displays.
	
	-- Error Mux:
	SIGNAL 	Digit1, Digit2				: std_logic_vector(6 downto 0);		-- Seven segment displays after error comparison.
	
	-- Bit Shifter.
	SIGNAL 	bdr_clk_en, left0_right1:	std_logic;	-- Enable/Disable bit shifting.
	
	-- Extender.
	SIGNAL 	extender_state				: 	std_logic_vector(3 downto 0);		-- (Fully Retracted) 0000->1000->1100->1110->1111 (Fully Extended) [Can also go opposite way] (MOORE)
	SIGNAL 	extender_out, grap_enable	: 	std_logic; 
	
	
	
----------------------------------------------------------------------------------------------------
BEGIN

-- CLOCKING GENERATOR WHICH DIVIDES THE INPUT CLOCK DOWN TO A LOWER FREQUENCY

BinCLK: PROCESS(clkin_50, rst_n) is
   BEGIN
		IF (rising_edge(clkin_50)) THEN 					-- binary counter increments on rising clock edge
         bin_counter <= bin_counter + 1;
      END IF;
   END PROCESS;

Clock_Source:
				Main_CLK <= 
				clkin_50 when sim = TRUE else				-- for simulations only
				std_logic(bin_counter(23));				-- for real FPGA operation
					
---------------------------------------------------------------------------------------------------

-- REST OF CODE

-- Assign inputs to signals:
target_x_coord <= sw(7 downto 4);
target_y_coord <= sw(3 downto 0);

-- X and Y Counter Instantiation:
XCOUNTER: U_D_Bin_Counter4bit port map(Main_CLK, rst_n, xc_clk_en, x_u1_d0, real_x_coord);
YCOUNTER: U_D_Bin_Counter4bit port map(Main_CLK, rst_n, yc_clk_en, y_u1_d0, real_y_coord);

-- X and Y Target Coordinate Management (Use Compx4 to determine if counters should increment or decrement etc.)

-- X and Y Comparator:
XCOMP: Compx4 port map(target_x_coord, real_x_coord, result_x);
YCOMP: Compx4 port map(target_y_coord, real_y_coord, result_y);

-- MEALY_XY instantiation:
MEALYXY: Mealy_XY port map(Main_CLK, rst_n, NOT(pb(3)), NOT(pb(2)), result_x, result_y, extender_out, xc_clk_en, yc_clk_en, x_u1_d0, y_u1_d0, ERROR_ON);

-- Setup leds 2 and 1 to display whether x and y target coordinates reached.
leds(2) <= result_x(1);
leds(1) <= result_y(1);

-- Setup leds 0 to on if there's an error:
leds(0) <= ERROR_ON;

-- SevenSegment Display Setup:

MUXSELECT: mux_target_real port map(target_x_coord, target_y_coord, real_x_coord, real_y_coord, NOT(pb(3)), NOT(pb(2)), display_X, display_Y);

DIGIT_A: SevenSegment port map(display_X, Digit1_temp);
DIGIT_B: SevenSegment port map(display_Y, Digit2_temp);

-- Error handling:
MUXERROR: mux_error port map(Main_CLK, rst_n, ERROR_ON, Digit1_temp, Digit2_temp, Digit1, Digit2);

SEGMUX: segment7_mux port map(clkin_50, Digit2, Digit1, seg7_data, seg7_char2, seg7_char1);

----- BITSHIFTING extender state and MOORE_STATE function -----
BITSHIFT: Bidir_shift_reg port map(Main_CLK, rst_n, bdr_clk_en, left0_right1, extender_state);

MOORESM1: MOORE_SM1 port map(Main_CLK, rst_n, NOT(pb(1)), result_x(1) AND result_y(1), extender_state, left0_right1, bdr_clk_en, extender_out, grap_enable);

leds(7 downto 4) <= extender_state;	-- Assign output to LEDS

----- GRAPPLE ------
MOORESM2: MOORE_SM2 port map(Main_CLK, rst_n, NOT(pb(0)), grap_enable, leds(3));

END SimpleCircuit;


