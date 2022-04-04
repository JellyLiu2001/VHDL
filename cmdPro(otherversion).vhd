USE WORK.all;
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
use work.common_pack.all;
use IEEE.std_logic_unsigned.all;




entity cmdProcessor is
port (

      clk: in std_logic;
      reset: in std_logic;
      rxnow: in std_logic;
      rxData: in std_logic_vector (7 downto 0);
      txData: out std_logic_vector (7 downto 0);
      rxdone: out std_logic;
      ovErr: in std_logic;
      framErr: in std_logic;
      txnow: out std_logic;
      txdone: in std_logic;
      start: out std_logic;
      numWords_bcd: out BCD_ARRAY_TYPE(2 downto 0) ;
      dataReady: in std_logic;
      byte: in std_logic_vector(7 downto 0);
      maxIndex: in BCD_ARRAY_TYPE(2 downto 0);
      dataResults: in CHAR_ARRAY_TYPE(0 to 6);
      seqDone: in std_logic
    );
 
end;


architecture dataflow of cmdProcessor is
  type state_type is (S0_INIT , S1_RXDATA , S2_PEAK, S3_LIST, S4_NUM, S5, S6);  
  signal currentState, nextState: state_type;
  SIGNAL COUNT_PEAK,COUNT_LIST,COUNT_NUM: integer:=0;----three counters
  signal numWords_bcdtest: BCD_ARRAY_TYPE(2 downto 0) ;-----cannot read out put signal so we musr set a intermediate signal
  signal resetPeak,resetList: std_logic:='0';------reset signal 
  signal txnowis : std_logic:='0';----------cannot read output
begin

  numWords_bcdtest(0) <= "0000" ;-------set initial value to test
  numWords_bcdtest(1) <= "0000" ;
  numWords_bcdtest(2) <= "0000" ; 

  combi_nextState: process(currentState, rxData)
  begin
    case currentState is
      when S0_INIT =>
        
        if rxnow='1' THEN
          nextState <= S1_RXDATA;
        end if ;
       
      WHEN S1_RXDATA =>
        IF rxData="01000001" or "01100001"  THEN-------A/a
              nextState <= S4_NUM;
        
        elsif rxData= "01010000" or "01110000" THEN-----P/p
          if  numWords_bcdtest(0) = "0000" and numWords_bcdtest(1) = "0000" and numWords_bcdtest(2) = "0000" THEN
              nextState <= S0_INIT;
          else
              nextState <= S2_PEAK;
          end if;
         
        ELSIF rxData="01001100" or "01101100" THEN ------L/l
          if  numWords_bcdtest(0) = "0000" and numWords_bcdtest(1) = "0000" and numWords_bcdtest(2) = "0000" THEN
              nextState <= S0_INIT;
          else   
              nextState <=S3_LIST;
          end if; 
          
        ELSE
          nextState <= S0_INIT;
         
        END IF;
       
     
      WHEN  S2_PEAK =>
          resetPeak <= '0' ;
          nextState <= S0_INIT;
         
         
      WHEN  S3_LIST =>
       
          resetList<='0';
          nextState <= S0_INIT;
      WHEN  S4_NUM =>
        
          nextState <= S0_INIT;
         
    end case;     
  end process;        
         
     
         
     
   
   
   
   
   
   
  combi_output:process(currentState)
  begin
    case currentState is
      when S2_PEAK=>
        if COUNT_PEAK = 0 and txnowis='0' THEN
          txData <= dataResults(3);
          txnowis <='1';
          if txdone = '1' THEN
            txnowis <='0';            
          end if;
        
           
        elsif COUNT_PEAK = 1 and txnowis='0' THEN
          txData <= "00100000";
          txnowis <='1';
          if txdone = '1' THEN
            txnowis <='0';
          end if;    
          
                  
        elsif COUNT_PEAK = 2 and txnowis='0' THEN
          txData(7 downto 4) <= "0011";
          txData(3 downto 0) <= maxIndex(2);
          txnowis <='1';
          if txdone = '1' THEN
            txnowis <='0';
          end if;
        
          
        elsif COUNT_PEAK = 3 and txnowis='0' THEN
          txData(7 downto 4) <= "0011";
          txData(3 downto 0) <= maxIndex(1);
          txnowis <='1';
          if txdone = '1' THEN
            txnowis <='0';
          end if;
         
        
        elsif COUNT_PEAK = 4 and txnowis='0' THEN
          txData(7 downto 4) <= "0011";
          txData(3 downto 0) <= maxIndex(0);
          txnowis <='1';
          if txdone = '1' THEN
            txnowis <='0';
            resetPeak<='1';
          end if;
        end if;
        
      when S3_LIST=>
        if COUNT_LIST=0 and txnowis='0' THEN
          txData <= dataResults(COUNT_LIST);
          txnowis <='1';
          if txdone = '1' THEN
            txnowis <='0';            
          end if;
        END IF;
        
        elsif COUNT_LIST=1 and txnowis='0' THEN
          txData <= dataResults(COUNT_LIST);
          txnowis <='1';
          if txdone = '1' THEN
            txnowis <='0';            
          end if;
        
        
        elsif COUNT_LIST=2 and txnowis='0' THEN
          txData <= dataResults(COUNT_LIST);
          txnowis <='1';
          if txdone = '1' THEN
            txnowis <='0';            
          end if;
        
        
        elsif COUNT_LIST=3 and txnowis='0' THEN
          txData <= dataResults(COUNT_LIST);
          txnowis <='1';
          if txdone = '1' THEN
            txnowis <='0';            
          end if;
        END IF;
        
        elsif COUNT_LIST=4 and txnowis='0' THEN
          txData <= dataResults(COUNT_LIST);
          txnowis <='1';
          if txdone = '1' THEN
            txnowis <='0';            
          end if;
       
        
        elsif COUNT_LIST=5 and txnowis='0' THEN
          txData <= dataResults(COUNT_LIST);
          txnowis <='1';
          if txdone = '1' THEN
            txnowis <='0';            
          end if;
        
        
        elsif COUNT_LIST=6 and txnowis='0' THEN
          txData <= dataResults(COUNT_LIST);
          txnowis <='1';
          if txdone = '1' THEN
            txnowis <='0';  
            resetList<='1';      
          end if;
        END IF;
    end case;
  end process;        
 
COUNTER_PEAK:PROCESS(RESET,CLK)
		BEGIN
		  IF resetPeak='1' THEN
		    COUNT_PEAK <=0;
		  ELSIF CLK'EVENT and CLK='1' THEN
		    IF txnowis='1' THEN
		      COUNT_PEAK <= COUNT_PEAK +1;
		    END IF;
		  END IF;
		END PROCESS;
       
COUNTER_LIST :PROCESS(RESET,CLK)
		BEGIN
		  IF resetList<='1' THEN
		    COUNT_LIST <=0;
		  ELSIF CLK'EVENT and CLK='1' THEN
		    IF txnowis='1' THEN
		      COUNT_LIST <= COUNT_LIST +1;

		    END IF;
		  END IF;
		END PROCESS;



--------------------------
--COUNTER_NUM :PROCESS(RESET,CLK)
--		BEGIN
--		  IF S4_NUM THEN
--		    COUNT_NUM <=0;
--		  ELSIF CLK'EVENT and CLK='1' THEN
--		    IF txnowis='0' THEN
--		      COUNT_NUM <= COUNT_NUM +1;
--		    ELSIF curState= FIRST THEN
--		      COUNT_NUM <=0;
--		    END IF;
--		  END IF;
--		END PROCESS;
------------------ 
 
 
 
 
 
 
 
 
 
 
 
 
 
       
             
  eq_state: PROCESS (CLK, reset)
  BEGIN
    IF reset = '0' THEN
      currentState <= S0_INIT;
    ELSIF CLK'EVENT AND CLK='1' THEN
      currentState <= nextState;
    END IF;
  END PROCESS; -- seq  
  
END dataflow;
    

