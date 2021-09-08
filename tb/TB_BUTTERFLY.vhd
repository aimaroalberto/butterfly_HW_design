LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE STD.TEXTIO.ALL;
USE IEEE.STD_LOGIC_TEXTIO.ALL;

ENTITY TB_BUTTERFLY IS
END ENTITY;

ARCHITECTURE BEHAVIORAL OF TB_BUTTERFLY IS
	COMPONENT BUTTERFLY IS
		GENERIC (N: INTEGER:=24);
		PORT (A, B, Wr, Wi  		: IN STD_LOGIC_VECTOR(N-1 DOWNTO 0);
				START, CLOCK, RST_n	: IN STD_LOGIC;
				A_O, B_O      		: OUT STD_LOGIC_VECTOR (N-1 DOWNTO 0);
				DONE			  		: OUT STD_LOGIC);
	END COMPONENT;
	SIGNAL A, B, Wr, Wi  		: STD_LOGIC_VECTOR(23 DOWNTO 0);
	SIGNAL START,START_2, CLOCK, RST_n	: STD_LOGIC;
	SIGNAL A_O, B_O      		: STD_LOGIC_VECTOR (23 DOWNTO 0);
	SIGNAL DONE	,done_1,done_2	,error_ar,error_br,error_ai,error_bi	  		   : STD_LOGIC;
BEGIN
	DUT: BUTTERFLY PORT MAP (A, B, Wr, Wi, START, CLOCK, RST_n, A_O, B_O, DONE);

--GENERAZIONE CLOCK--------------------------------------------------------------	
	CLK: PROCESS
	BEGIN
		CLOCK<='0';
		WAIT FOR 50 PS;
		CLOCK<='1';
		WAIT FOR 50 PS;
	END PROCESS;
--GENERAZIONE RESET -------------------------------------------------------------
	RST: PROCESS
	BEGIN
		RST_n<='0';
		WAIT FOR 130 PS;
		RST_n<='1';
		WAIT;
	END PROCESS;
	
-- GENERAZIONE SEGNALE START ----------------------------------------------------
	START_PROCESS:PROCESS
	BEGIN
	START<='0';
	WAIT FOR 210 PS;
	START<='1';
	WAIT FOR 100 PS;
	START<='0';
		FOR I IN 0 TO 998 LOOP
			WAIT FOR 300 PS;
			START<='1';
			WAIT FOR 100 PS;
			START<='0';
		END LOOP;
		WAIT;
	END PROCESS;
-- GENERAZIONE DI UN SECONDO SEGNALE SUBITO DOPO START USATO PER INVIARE I SECONDI DATI-
	START2_PROCESS:PROCESS
	BEGIN
	START_2<='0';
	WAIT FOR 210 PS;
	START_2<='0';
	WAIT FOR 100 PS;
	START_2<='1';
	WAIT FOR 100 PS;
	START_2<='0';
	
		FOR I IN 0 TO 998 LOOP
			WAIT FOR 300 PS;
			START_2<='1';
			WAIT FOR 100 PS;
			START_2<='0';
		END LOOP;
		WAIT;
	END PROCESS;
	
-- INVIO DEI DATI: LA PARTE REALE SUBITO DOPO IL FRONTE DI DISCESA DI START E
-- LA PARTE IMMAGINARIA SUBITO DOPO IL FRONTE DI DISCESA DEL SEGNALE START_2, 
-- IN MODO CHE SIANO RITARDATI DI UN COLPO DI CLOCK
	DATA: PROCESS(START,START_2)
	file fp_Ar: text is in "Ar_ingresso_bin.txt";
	file fp_Br: text is in "Br_ingresso_bin.txt";
	file fp_Wr: text is in "Wr_ingresso_bin.txt";
		variable ln: line;
		variable AR,BR,WR_IN: STD_LOGIC_VECTOR (23 downto 0);
	file fp_Bi: text is in "Bi_ingresso_bin.txt";
	file fp_Ai: text is in "Ai_ingresso_bin.txt";
	file fp_Wi: text is in "Wi_ingresso_bin.txt";
		variable AI,BI,WI_IN: STD_LOGIC_VECTOR (23 downto 0);
		
	BEGIN
	if RST_n='0' then
		A<=(others=>'0');
		B<=(others=>'0');
		WR<=(others=>'0');
		Wi<=(others=>'0');
	else
		IF START'EVENT AND START='0' THEN
			readline( fp_Ar, ln ); read( ln, AR );
			readline( fp_Br, ln ); read( ln, BR );
			readline( fp_Wr, ln ); read( ln, WR_IN );

			A<=AR;
			B<=BR;
			WR<=WR_IN;
		END IF;
	
		IF START_2'EVENT AND START_2='0' THEN
			readline( fp_Ai, ln ); read( ln, AI);
			readline( fp_Bi, ln ); read( ln, BI );
			readline( fp_Wi, ln ); read( ln, WI_IN );
			A<=AI;
			B<=BI;
			WI<=WI_IN;
		END IF;
	end if;
	END PROCESS;
	
-- GENERAZIONE DI UN SECONDO SEGNALE DOPO IL DONE, CHE TORNA A ZERO AL FRONTE DI DISCESA DEL CLOCK SUCCESSIVO, 
-- IN MODO CHE SU QUESTO FRONTE SI RIESCA A SALVARE I DATI IN USCITA, VISTO CHE ESCONO DOPO IL DONE
	PROCESS(RST_n,CLOCK,DONE)
	BEGIN
	IF RST_n='0'THEN
				DONE_1<='0';
	ELSE
		IF DONE'EVENT AND DONE='0' THEN
				DONE_1<='1';
		
		
		elsIF CLOCK'EVENT AND CLOCK='0' THEN
				DONE_1<='0';
		END IF;

	END IF;
	END PROCESS;
-- GENERAZIONE DI UN SEGNALE DOPO IL DONE_1, CHE TORNA A ZERO AL FRONTE DI DISCESA DEL CLOCK SUCCESSIVO, 
-- IN MODO CHE SU QUESTO FRONTE SI RIESCA A SALVARE I SECONDI DATI IN USCITA
	PROCESS(RST_n,CLOCK,DONE_1)
	BEGIN
	IF RST_n='0'THEN
	DONE_2<='0';
	ELSE
		IF DONE_1'EVENT AND DONE_1='0' THEN
				DONE_2<='1';
		elsif CLOCK'EVENT AND CLOCK='0' THEN
		DONE_2<='0';
		END IF;

	END IF;
	END PROCESS;
	
-- PROCESS DI ACQUISIZIONE DATI, SINCRONIZZATO SUL PRIMO E SUL SECONDO FRONTE DI DISCESA DEL CLOCK, SUCCESSIVAMENTE ALL'ARRIVO DEL DONE
-- RISPETTANDO IL TIMING E ANDANDOLI A SALVARE NEL PONTO CENTRALE DELL'INTERVALLO DELLA LORO VALIDITà
	DATA_out: PROCESS(RST_n,DONE_1,DONE_2)
	file fp_Ar_out: text  open WRITE_MODE is  "Ar_uscita_MODELSIM.txt";
	file fp_Br_out: text  open WRITE_MODE is  "Br_uscita_MODELSIM.txt";
	
		variable ln_out: line;
		variable ln_in: line;
		variable AR_out,BR_out: STD_LOGIC_VECTOR (23 downto 0);
		
		
	file fp_Bi_out: text  open WRITE_MODE is  "Bi_uscita_MODELSIM.txt";
	file fp_Ai_out: text  open WRITE_MODE is  "Ai_uscita_MODELSIM.txt";
	
	
		variable AI_out,BI_out: STD_LOGIC_VECTOR (23 downto 0);
		
	file fp_Bi_out_matlab: text is in "Bi_out_bin.txt";
	file fp_Ai_out_matlab: text is in "Ai_out_bin.txt";
	file fp_Br_out_matlab: text is in "Br_out_bin.txt";
	file fp_Ar_out_matlab: text is in "Ar_out_bin.txt";
		variable Ai_out_matlab,Bi_out_matlab,Ar_out_matlab,Br_out_matlab: STD_LOGIC_VECTOR (23 downto 0);
		
	BEGIN
	IF RST_N='1' THEN
		IF DONE_1'EVENT AND DONE_1='0' THEN
		                readline( fp_Br_out_matlab, ln_in); read( ln_in, Br_out_matlab);
						readline( fp_Ar_out_matlab, ln_in ); read( ln_in, Ar_out_matlab );
						
						if A_O=Ar_out_matlab then
							error_ar<='1';
						else
							error_ar<='0';
						end if;
						if B_O=Br_out_matlab then
							error_br<='1';
						else
							error_br<='0';
						end if;
						
						WRITE( ln_out, A_O,left,24);  WRITEline( fp_Ar_out, ln_out ); 
						WRITE( ln_out, B_O,left,24);WRITEline( fp_Br_out, ln_out );
			
		END IF;
			
		IF DONE_2'EVENT AND DONE_2='0' THEN
						readline( fp_Bi_out_matlab, ln_in); read( ln_in, Bi_out_matlab);
						readline( fp_Ai_out_matlab, ln_in ); read( ln_in, Ai_out_matlab );
						
						if A_O=Ai_out_matlab then
							error_ai<='1';
						else
							error_ai<='0';
						end if;
						if B_O=Bi_out_matlab then
							error_bi<='1';
						else
							error_bi<='0';
						end if;
						WRITE( ln_out, A_O,left,24); 
						WRITEline( fp_Ai_out, ln_out ); 
						WRITE( ln_out, B_O,left,24);
						WRITEline( fp_Bi_out, ln_out );
		
		END IF;
	END IF;
	 END PROCESS;
END BEHAVIORAL;