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
  signal ifANNN : integer:=0;
  signal resetPeak,resetList: std_logic:='0';------reset signal 
  --signal txnowis : std_logic:='0';----------cannot read output

  
  function BtoH1 (binaryNum:std_logic_vector (7 downto 0):="00000000") 
       return std_logic_vector is 
    variable hexNum1 : std_logic_vector(7 downto 0):="00000000"; 
    variable midNum1 :  std_logic_vector(3 downto 0):="0000";
    
  begin
     midNum1:= binaryNum(7 downto 4);
     if midNum1="0000"   then--0
       hexNum1:="00110000";     
     elsif midNum1="0001"   then--1
       hexNum1:="00110001";       
     elsif midNum1= "0010"  then--2
       hexNum1:="00110010";      
     elsif midNum1= "0011" then--3
       hexNum1:="00110011";       
     elsif midNum1= "0100"  then--4
       hexNum1:="00110100";       
     elsif midNum1= "0101"  then--5
       hexNum1:="00110101";      
     elsif midNum1= "0110"  then--6
       hexNum1:="00110110";        
     elsif midNum1= "0111"  then--7
       hexNum1:="00110111";       
     elsif midNum1= "1000"  then--8
       hexNum1:="00110110";       
     elsif midNum1= "1001"  then--9
       hexNum1:="00111001";      
     elsif midNum1= "1010"  then--A
       hexNum1:="01000001";     
     elsif midNum1= "1011"  then--B
       hexNum1:="01000010";  
     elsif midNum1= "1100"  then--C
       hexNum1:="01000011";  
     elsif midNum1= "1101"  then--D
       hexNum1:="01000100"; 
     elsif midNum1= "1110"  then--E
       hexNum1:="01000101";        
     elsif midNum1= "1111"  then--F
       hexNum1:="01000110";             
     end if; 
     return hexNum1;
  end BtoH1;
  
  function BtoH2 (binaryNum:std_logic_vector (7 downto 0):="00000000") 
       return std_logic_vector is 
    variable hexNum1 : std_logic_vector(7 downto 0):="00000000"; 
    variable midNum1 :  std_logic_vector(3 downto 0):="0000";
    
  begin
     midNum1:= binaryNum(3 downto 0);
     if midNum1="0000"   then--0
       hexNum1:="00110000";       
     elsif midNum1="0001"   then--1
       hexNum1:="00110001";      
     elsif midNum1= "0010"  then--2
       hexNum1:="00110010";     
     elsif midNum1= "0011" then--3
       hexNum1:="00110011";      
     elsif midNum1= "0100"  then--4
       hexNum1:="00110100";       
     elsif midNum1= "0101"  then--5
       hexNum1:="00110101";      
     elsif midNum1= "0110"  then--6
       hexNum1:="00110110";       
     elsif midNum1= "0111"  then--7
       hexNum1:="00110111";      
     elsif midNum1= "1000"  then--8
       hexNum1:="00110110";      
     elsif midNum1= "1001"  then--9
       hexNum1:="00111001";     
     elsif midNum1= "1010"  then--A
       hexNum1:="01000001";   
     elsif midNum1= "1011"  then--B
       hexNum1:="01000010"; 
     elsif midNum1= "1100"  then--C
       hexNum1:="01000011";  
     elsif midNum1= "1101"  then--D
       hexNum1:="01000100";
     elsif midNum1= "1110"  then--E
       hexNum1:="01000101";        
     elsif midNum1= "1111"  then--F
       hexNum1:="01000110";      
       
     end if; 
     return hexNum1;
  end BtoH2;
  
 begin


  
  combi_nextState: process(currentState, rxData)
  begin
    case currentState is
      when S0_INIT =>
        resetPeak <= '1' ;------------reset counters
        resetList<='1';
        if rxnow='1' THEN
          nextState <= S1_RXDATA;
        end if ;
       
      WHEN S1_RXDATA =>
        IF rxData="01000001" or rxdata="01100001"  THEN-------A/a
              nextState <= S4_NUM;
        
        elsif rxData= "01010000" or rxdata="01110000" THEN-----P/p
          if  ifANNN = 0  THEN
              nextState <= S0_INIT;---if ifANNN=0 means that we enter P/p before we run aNNN,so the command should be rejected.
          else                          
              nextState <= S2_PEAK;
          end if;
         
        ELSIF rxData="01001100" or rxdata="01101100" THEN ------L/l
          if  ifANNN =0  THEN
              nextState <= S0_INIT;---same as P/p
          else   
              nextState <=S3_LIST;
          end if; 
          
        ELSE
          nextState <= S0_INIT;-------any other wrong command should be rejected and return to initial state
         
        END IF;
       
     
      WHEN  S2_PEAK =>
          resetPeak <= '0' ;
          if COUNT_PEAK=6 THEN
            nextState <= S0_INIT;
          end if;
         
         
      WHEN  S3_LIST =>
       
          resetList<='0';
          if COUNT_LIST=14 THEN---------when output 7 byte then return to inital state 
            nextState <= S0_INIT;
          end if;  
          
      WHEN  S4_NUM =>
        
          nextState <= S0_INIT;
         
    end case;     
  end process;        
         
     
         
     
   
   
   
   
   
   
  combi_output:process(currentState)
  begin
    case currentState is
      when S2_PEAK=>
        if COUNT_PEAK = 0 and txdone='1' THEN----output peak value
          txData <= BtoH1(dataResults(3));
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0'; 
            txData <= BtoH2(dataResults(3));
            txnow <='1';
            if txdone = '1' THEN
              txnow <='0';            
            end if;           
          end if;
         
        
           
        elsif COUNT_PEAK = 2 and txdone='1' THEN-----output a space
          txData <= "00100000";
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';
          end if;    
          
                  
        elsif COUNT_PEAK = 3 and txdone='1' THEN----first bit of maxindex
          txData(7 downto 4) <= "0011";
          txData(3 downto 0) <= maxIndex(2);
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';
          end if;
        
          
        elsif COUNT_PEAK = 4 and txdone='1' THEN----second bit of maxindex
          txData(7 downto 4) <= "0011";
          txData(3 downto 0) <= maxIndex(1);
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';
          end if;
         
        
        elsif COUNT_PEAK = 5 and txdone='1' THEN----third bit of maxindex
          txData(7 downto 4) <= "0011";
          txData(3 downto 0) <= maxIndex(0);
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0';
            resetPeak<='1';
          end if;
        end if;
        
      when S3_LIST=>
        
          txData <= BtoH1(dataResults(COUNT_LIST/2));
          txnow <='1';
          if txdone = '1' THEN
            txnow <='0'; 
            txData <= BtoH2(dataResults((COUNT_LIST-1)/2));
            txnow <='1';
            if txdone = '1' THEN
              txnow <='0';            
            end if;           
          end if;
          
        
        
       
    end case;
  end process;        
 
COUNTER_PEAK:PROCESS(RESET,CLK)
		BEGIN
		  IF resetPeak='1' THEN
		    COUNT_PEAK <=0;
		  ELSIF CLK'EVENT and CLK='1' THEN
		    IF txdone='1' THEN
		      COUNT_PEAK <= COUNT_PEAK +1;
		    END IF;
		  END IF;
		END PROCESS;
       
COUNTER_LIST :PROCESS(RESET,CLK)
		BEGIN
		  IF resetList<='1' THEN
		    COUNT_LIST <=0;
		  ELSIF CLK'EVENT and CLK='1' THEN
		    IF txdone='1' THEN
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
    
    

