USE WORK.all;
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
USE IEEE.numeric_std.all;
use work.common_pack.all;
use IEEE.std_logic_unsigned.all;




entity cmdProc is
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
 
end ;

architecture dataflow of cmdProc is
  type state_type is (S0_INIT , S1_RXDATA ,count_N,counter_RESET,counter_receive,transmition,check,GIVE_Num,Give_data,recieve_byte,Print_byte_one,recieve_byte_2,Print_byte_two,recieve_space,print_space,print_last,undefined);  
    signal currentState, nextState: state_type;
    SIGNAL COUNT_NUM: integer:=0;


  
    signal encount2, counterRST2:std_logic;-----counternum signal
    signal  R,register2:std_logic_vector(11 downto 0);----signal used in register to save input
begin
  combi_nextState: process(currentState, rxNow, txdone, seqDone, dataReady)
  begin
    case currentState is
      when S0_INIT =>
      
        if rxnow='1' THEN
          nextState <= S1_RXDATA;
        else
          nextState <= S0_INIT;------xiugai   111111
        end if ;
       
      WHEN S1_RXDATA =>
            if rxData="01000001" or rxData="01100001"  THEN-------A/a
                nextState <= count_N;
           
            else
                nextState <= S0_INIT;------------------222222222
            
            end if;
      
      When count_N =>
      
      if rxNow = '1' then
       if rxData >="00110000" and rxData<="00111001" then------check 0-9
            if COUNT_NUM = 0 then
             R(11 downto 8) <= rxData(3 downto 0);
            elsif COUNT_NUM =  1 then
             R(7 downto 4) <= rxData(3 downto 0);
            elsif COUNT_NUM = 2 then
             R (3 downto 0) <= rxData(3 downto 0);
            end if;
         nextState <= counter_receive;
        else  
          nextState <=  counter_RESET;
            
        end if;
      else 
        nextState <= count_N;
      end if;
        
      WHEN counter_RESET =>
         
          nextState <= transmition;
      
      WHEN counter_receive =>
          nextState <= transmition;
      
      WHEN transmition =>
          nextState <= Check;
          
      WHEN check =>
      IF  rxData >="00110000" and rxData<="00111001" then
          if COUNT_NUM < 3 then
            nextState <= count_N;
          else ---------have contain aNNN
            nextState <= GIVE_Num;
          end if;
      ELSE 
          nextState <= S0_INIT;
      end if;
 
      WHEN GIVE_Num =>
            numWords_bcd(2) <= register2(11 downto 8);  
   
            numWords_bcd(1) <= Register2(7 downto 4);
            
            numWords_bcd(0) <= Register2(3 downto 0);
            
            nextState  <= Give_data;
      When Give_data =>
            nextState <= recieve_byte;
      
      When  recieve_byte =>
          if dataReady ='1' then
            if byte(7 downto 4) < "1010" then    ---------first 4 bits represents from 0-9
                R(7 downto 4)<="0011";
                R(3 downto 0) <= byte(7 downto 4);
            else 
                 
                R(7 downto 4) <="0100";
                if byte(7 downto 4)= "1010" then ------10 hexA 
                  R(3 downto 0) <= "0001";
                Elsif byte(7 downto 4)= "1011" then ---11B
                  R(3 downto 0) <= "0010";
                Elsif byte(7 downto 4)= "1100" then ----12C
                  R(3 downto 0) <= "0011";
                Elsif byte(7 downto 4)= "1101" then ----13D
                  R(3 downto 0) <= "0100";
                Elsif byte(7 downto 4)= "1110" then ----14E
                  R(3 downto 0) <= "0101";  
                Elsif byte(7 downto 4)= "1111" then ----15F
                  R(3 downto 0) <= "0110";
                end if;
            end if;
            nextState <= Print_byte_one;
          else
            nextState <= recieve_byte;
          end if;
      
      
      When Print_byte_one =>
        
        nextState <= recieve_byte_2;
      
      
      When recieve_byte_2 =>
        if txdone='1' then
            if byte(3 downto 0) < "1010" then    ---------last 4 bits represents from 0-9
                R(7 downto 4)<="0011";
                R(3 downto 0) <= byte(3 downto 0);
            else 
                 
                R(7 downto 4) <="0100";
                if byte(3 downto 0)= "1010" then ------10 hexA 
                  R(3 downto 0) <= "0001";
                Elsif byte(3 downto 0)= "1011" then ---11B
                  R(3 downto 0) <= "0010";
                Elsif byte(3 downto 0)= "1100" then ----12C
                  R(3 downto 0) <= "0011";
                Elsif byte(3 downto 0)= "1101" then ----13D
                  R(3 downto 0) <= "0100";
                Elsif byte(3 downto 0)= "1110" then ----14E
                  R(3 downto 0) <= "0101";  
                Elsif byte(3 downto 0)= "1111" then ----15F
                  R(3 downto 0) <= "0110";
                end if;
            end if;
            nextState <= Print_byte_two;
          else
            nextState <= recieve_byte_2;
          end if;
      
          
        
      When Print_byte_two =>
        
        nextState <= print_space;
      
      when recieve_space =>
          if txdone ='1' then
            R(7 downto 0)<= "00100000";
            nextState <= print_space;
          end if;
      when print_space =>
         nextState <= Give_data;
        
          
           
     
      
      
          
           
     
      
      When print_last =>
        if encount2 <='1' then
          
           nextState <= S0_INIT;
        else 
            
            nextState <= Give_data;
        end if;
      When undefined =>
        nextState <=  S0_INIT;
      end case;     
  end process;       
  
  combi_output:process(currentState)
  begin
  txnow<='0';
  start <='0';
  rxDone<='0';
  encount2<='0';
  counterRST2<='0';
  
    
    case currentState is
      when S0_INIT =>
        txNow<='0';
        start <='0';
        rxDone<='0';
        encount2<='0';
        counterRST2<='0';
      when S1_RXDATA=>
        
        
         if rxData="01000001" or rxData="01100001"  THEN-------A/a
              RxDone <='1' ;
         else 
              RxDone <='1';
         end if;
           
      When count_N =>
        if rxNow = '1' then
          if rxData >="00110000" and rxData<="00111001" then------check 0-9  
              encount2<='1';
              RxDone <='1';
          
          
          end if;
        end if;
          
          
         
      
      WHEN counter_RESET =>
            counterRST2 <='1';
            RxDone <= '1';
         
            
      
      WHEN counter_receive =>
            encount2 <='1';
            RxDone <='1';
      
         
      
      
      WHEN transmition =>
         TxData <= RxData;
         TxNow<='1';
          
      WHEN check =>
          TxNow <='0';
          RxDone <='0';
         
          
      WHEN GIVE_Num =>  
           counterRST2 <='1';-----succussfully have NNN reset the clk  
           
           
      When Give_data =>
            start <='1';
      
      
      When  recieve_byte =>
          start <='0';
          txNow <='0';
      When Print_byte_one =>
        txData<= register2 (7 downto 0);
        txNow<='1';       
      When recieve_byte_2 =>
          txNow <= '0' ;   
      When Print_byte_two => 
        
        txData <= register2(7 downto 0);
        txNow <='1';
      
      When recieve_space =>
        if txDone='1' then
          txNow <='0';
        end if;
      
      when print_space => 
          
            txNow <='1';
            txData<= "00100000";
            
        
        
      When print_last =>
        if encount2 <='1' then
          txData <= register2(7 downto 0);
          txNow <='1';
          counterRST2<='0'; 
        else 
          txNow <='1';
          txdata<="00100000";
        end if;
      When undefined =>
        txnow<='0';
        start <='0';
        rxDone<='0';
        encount2<='0';
        counterRST2<='0';
     end case;
  end process;    
  COUNTER_NUM: PROCESS(reset, clk) 

  BEGIN 

    IF counterRST2 = '1' THEN  -- active high reset 

        COUNT_NUM <= 0; 

    ELSIF clk'EVENT and clk='1' THEN 

        IF encount2= '1' THEN              

           COUNT_NUM <= COUNT_NUM + 1; 

        END IF; 

    END IF; 

  END PROCESS; 
  
     
 
 
 
 
 
 
 
  register1: PROCESS (clk, R, register2)
     BEGIN
       IF clk'EVENT AND clk='1' THEN
         register2 <= R;
       END IF;
     END PROCESS;
 
 
 
 
       
             
  seq_state: PROCESS (CLK, reset)
  BEGIN
    IF reset = '1' THEN
      currentState <= S0_INIT;
    ELSIF CLK'EVENT AND CLK='1' THEN
      currentState <= nextState;
    END IF;
  END PROCESS; -- seq  
  
END dataflow;