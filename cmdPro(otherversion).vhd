USE WORK.all;
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
use work.common_pack.all;


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
      numWords_bcd: out BCD_ARRAY_TYPE(2 downto 0);
      dataReady: in std_logic;
      byte: in std_logic_vector(7 downto 0);USE WORK.all;
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
use work.common_pack.all;


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
      numWords_bcd: out BCD_ARRAY_TYPE(2 downto 0);
      dataReady: in std_logic;
      byte: in std_logic_vector(7 downto 0);
      maxIndex: in BCD_ARRAY_TYPE(2 downto 0);
      dataResults: in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
      seqDone: in std_logic
    );
 
end;


architecture dataflow of cmdProcessor is
  type state_type is (IDLE,input_num,S0_INIT , S1_RXDATA , S2_PEAK, S3_LIST, S4_NUM, S5, S6);  
  signal currentState, nextState: state_type;
  SIGNAL COUNT_PEAK,COUNT_LIST,COUNT_NUM: integer:=0;
 
begin
 

  combi_nextState: process(currentState, rxData)
  begin
    case currentState is
      when S0_INIT =>
        if rxnow='1' THEN
          nextState <= S1_RXDATA;
        end if ;
       
      WHEN S1_RXDATA =>
        IF rxData='01000001' or '01100001' THEN-------A/a
          nextState <= input_num;
        
        if rxData= '01010000' or '01110000' THEN-----P/p
          nextState <= S2_PEAK;
         
        ELSIF rxData='01001100' or '01101100' THEN ------L/l
          nextState <=S3_LIST;
       
        ELSE
          nextState <= S0_INIT;
         
        END IF;
       
     
      WHEN  S2_PEAK =>
          resetPeak <= '0' ;
          nextState <= S0_INIT;
         
         
      WHEN  S3_LIST =>
       
          resetList<='0'
          nextState <= S0_INIT;
      WHEN  S4_NUM;
        
          nextState <= S0_INIT;
         
         
  end process;        
         
     
         
     
   
   
   
   
   
   
  combi_output:process(currentState);
  begin
    case currentState is
      when currentState = S2_PEAK;
        if COUNT_PEAK = 0 and txnow='0' THEN
          txData <= dataResults[3];
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';            
          end if;
        END IF;
           
        if COUNT_PEAK = 1 and txnow='0' THEN
          txData <= '00100000';
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';
          end if;    
        END IF;  
                  
        if COUNT_PEAK = 2 and txnow='0' THEN
          txData(7 downto 4) <= '0011';
          txData(3 downto 0) <= maxIndex[2]
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';
          end if;
          
        if COUNT_PEAK = 3 and txnow='0' THEN
          txData(7 downto 4) <= '0011';
          txData(3 downto 0) <= maxIndex[1]
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';
          end if;
        END IF; 
        
        if COUNT_PEAK = 4 and txnow='0' THEN
          txData(7 downto 4) <= '0011';
          txData(3 downto 0) <= maxIndex[0]
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';
            resetPeak<='1';
          end if;
        end if;
        
      when currentState = S3_LIST;
        if COUNT_LIST=0 and txnow='0' THEN
          txData <= dataResults[COUNT_LIST];
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';            
          end if;
        END IF;
        
        if COUNT_LIST=1 and txnow='0' THEN
          txData <= dataResults[COUNT_LIST];
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';            
          end if;
        END IF;
        
        if COUNT_LIST=2 and txnow='0' THEN
          txData <= dataResults[COUNT_LIST];
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';            
          end if;
        END IF;
        
        if COUNT_LIST=3 and txnow='0' THEN
          txData <= dataResults[COUNT_LIST];
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';            
          end if;
        END IF;
        
        if COUNT_LIST=4 and txnow='0' THEN
          txData <= dataResults[COUNT_LIST];
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';            
          end if;
        END IF;
        
        if COUNT_LIST=5 and txnow='0' THEN
          txData <= dataResults[COUNT_LIST];
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';            
          end if;
        END IF;
        
        if COUNT_LIST=6 and txnow='0' THEN
          txData <= dataResults[COUNT_LIST];
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';  
            resetList<='1';      
          end if;
        END IF;
    
  end process;        
 
COUNTER_PEAK:PROCESS(RESET,CLK,X)
		BEGIN
		  IF resetPeak='1' THEN
		    COUNT_PEAK <=0;
		  ELSIF CLK'EVENT and CLK='1' THEN
		    IF txnow='1' THEN
		      COUNT_PEAK <= COUNT_PEAK +1;
		    END IF;
		  END IF;
		END PROCESS;
       
COUNTER_LIST :PROCESS(RESET,CLK,X)
		BEGIN
		  IF resetList<='1' THEN
		    COUNT_LIST <=0;
		  ELSIF CLK'EVENT and CLK='1' THEN
		    IF txnow='1' THEN
		      COUNT_LIST <= COUNT_LIST +1;

		    END IF;
		  END IF;
		END PROCESS;

COUNTER_NUM :PROCESS(RESET,CLK,X)
		BEGIN
		  IF curState=S4_NUM THEN
		    COUNT_NUM <=0;
		  ELSIF CLK'EVENT and CLK='1' THEN
		    IF ='0' THEN
		      COUNT_NUM <= COUNT_NUM +1;
		      ELSIF curState= FIRST THEN
		        COUNT_NUM <=0;
		    END IF;
		  END IF;
		END PROCESS;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
       
             
  eq_state: PROCESS (CLK, reset)
  BEGIN
    IF reset = '0' THEN
      curState <= INIT;
    ELSIF CLK'EVENT AND CLK='1' THEN
      curState <= nextState;
    END IF;
  END PROCESS; -- seq  
      maxIndex: in BCD_ARRAY_TYPE(2 downto 0);
      dataResults: in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
      seqDone: in std_logic
    );
 
end;


