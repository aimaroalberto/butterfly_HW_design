LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY CONTROL_UNIT IS
PORT (	CLOCK,RESET_N : IN STD_LOGIC;
	    START, START_R: IN STD_LOGIC;
		INSTRUCTION : OUT STD_LOGIC_VECTOR(20 DOWNTO 0));
END CONTROL_UNIT;

ARCHITECTURE BEHAVIOR OF CONTROL_UNIT IS

COMPONENT MICRO_ROM IS
	GENERIC(N:INTEGER := 23; --NUMERO DI BIT PER OGNI RIGA DELLA ROM
			M:INTEGER := 4); -- 2^M NUMERO DI RIGHE DELLA ROM (M BIT DI INDIRIZZO)
	PORT (ADDRESS : IN STD_LOGIC_VECTOR(M-1 DOWNTO 0);
		  DATA_OUT : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT;

COMPONENT REGN_EN_FP IS
	GENERIC ( N : INTEGER:=23); 
	PORT (R: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
		  ENABLE, CLOCK, RESETN : IN STD_LOGIC;
	      Q:OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT;

COMPONENT MUX_3TO1 IS
	GENERIC(N:INTEGER:=4);
	PORT(	I1: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			I2: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			I3: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			S: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			F: OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT;

COMPONENT INCREASER IS
	GENERIC(N:INTEGER:=4);
	PORT(	X : IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
			Y : OUT STD_LOGIC_VECTOR(N-1 DOWNTO 0));
END COMPONENT;

SIGNAL I1,I2,I3,MUX_OUT,ADDRESS: STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL S: STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL DATA_OUT, INSTRUCTION_r: STD_LOGIC_VECTOR(22 DOWNTO 0);
SIGNAL CC0,CC1,CLOCK_N: STD_LOGIC;


BEGIN

CLOCK_N<=NOT CLOCK; -- LO STATUS REGISTER COMMUTA SUL FRONTE DI SALITA

I2<="1010";--INDIRIZZO SALTO IN STATO 10
I3<="0000";--INDIRIZZO SALTO IN IDLE

MUX: MUX_3TO1 PORT MAP(I1,I2,I3,S,MUX_OUT); -- MUX DI SELEZIONE INDIRIZZO

STATUS_REG: REGN_EN_FP GENERIC MAP(4)									-- STATUS REGISTER
					   PORT MAP(MUX_OUT,'1', CLOCK_N,RESET_N,ADDRESS);	-- SUL FRONTE DI DISCESA
			  
ADDER: INCREASER PORT MAP (ADDRESS,I1); 	-- INCREMENTO INDIRIZZO PER STATO SUCCESSIVO

ROM: MICRO_ROM PORT MAP(ADDRESS,DATA_OUT); 	-- MICRO ROM
-- INSTRUCTION REGISTER
INSTRUCTION_REGISTER: REGN_EN_FP PORT MAP(DATA_OUT,'1',CLOCK,RESET_N,INSTRUCTION_r); 

CC0<=INSTRUCTION_r(22);  -- BIT DI SALTO IN IDLE
CC1<=INSTRUCTION_r(21);  -- BIT DI SALTO ALLO STATO 10

INSTRUCTION <= INSTRUCTION_r(20 DOWNTO 0);
S(0)<=(not(CC0) AND CC1 AND START_R);
S(1)<=(CC0 AND (NOT CC1) AND (NOT START)) OR (not CC0 AND CC1 AND (NOT START_R));


END BEHAVIOR;