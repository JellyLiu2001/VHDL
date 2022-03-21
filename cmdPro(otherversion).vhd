
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
      byte: in std_logic_vector(7 downto 0);
      maxIndex: in BCD_ARRAY_TYPE(2 downto 0);
      dataResults: in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
      seqDone: in std_logic
    );
 
end;


architecture dataflow of cmdProcessor is
  type state_type is (S0_INIT , S1_RXDATA , S2_PEAK, S3_LIST, S4_NUM, S5, S6);  
  signal currentState, nextState: state_type;
 
begin
 

  combi_nextState: process(currentState, rxData)
  begin
    case currentState is
      when S0_INIT =>
        if rxnow='1' THEN
          nextState <= S1_RXDATA;
        end if ;
       
       
      when S1_RXDATA =>
        if rxData= '01010000' or '01110000' THEN-----P/p
          nextState <= S2_PEAK;
         
        ELSIF rxData='01001100' or '01101100' THEN ------L/l
          nextState <=S3_LIST;
         
        ELSIF rxData= '01000001' or '01100001' THEN-------A/a
          nextState <=S4_NUM;
       
        ELSE
          nextState <= S0_INIT;
         
        END IF;
       
     
      WHEN  S2_PEAK;
         
          nextState <= S0_INIT;
         
     
   
   
   
   
   
   
  combi_output:process(currentState);
  begin
        when currentState = S2_PEAK;
          txData <= dataResults[3];
          txnow <='1';
          if txdone <= '1' THEN
            txnow <='0';
          end if;
           
          txData <= '00100000';
          txnow <='1';
          if txdone <= '1' THEN
            txnow <='0';
          end if;'0';
          end if;
         
  end process;              
             
  eq_state: PROCESS (CLK, reset)
  BEGIN
    IF reset = '0' THEN
      curState <= INIT;
    ELSIF CLK'EVENT AND CLK='1' THEN
      curState <= nextState;
    END IF;
  END PROCESS; -- seq
 
         
          txData(7 downto 4) <= '0011';
          txData(3 downto 0) <= maxIndex[2]
          txnow <='1';
          if txdone <= '1' THEN
            txnow <='0';
          end if;
         
          txData(7 downto 4) <= '0011';
          txData(3 downto 0) <= maxIndex[1]
          txnow <='1';
          if txdone <= '1' THEN
            txnow <='0';
          end if;
         
          txData(7 downto 4) <= '0011';
          txData(3 downto 0) <= maxIndex[0]
          txnow <='1';
          if txdone <= '1' THEN
            txnow <='0';
          end if;
         
  end process;              
             
  eq_state: PROCESS (CLK, reset)
  BEGIN
    IF reset = '0' THEN
      curState <= INIT;
    ELSIF CLK'EVENT AND CLK='1' THEN
      curState <= nextState;
    END IF;
  END PROCESS; -- seq