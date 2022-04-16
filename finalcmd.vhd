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
    type state_type is (S0_INIT , S1_RXDATA ,L_HOLD,Print_P,Print_L,count_N,counter_RESET,counter_receive,transmition,check,GIVE_Num,Give_data,recieve_byte,Print_byte_one,recieve_byte_2,
  Print_byte_two,recieve_space,print_space,undefined,stop_print,n_print,r_print,transmition_fail,waiting_tx,wait_txnow,print_lastbyte,receive_lastbyte,
  S2_PEAK,S2_HOLD,PEAK1,PEAK1_HOLD,PEAK2,PEAK2_HOLD,SPACE,SPACE_HOLD,INDEX1,INDEX1_HOLD,INDEX2,INDEX2_HOLD,INDEX3,SPACEL_wait, List1_wait,List2_wait,S3_LIST,S3_HOLD,L_wait,List1,List1_HOLD,
  SPACE_wait,PEAK1_wait,PEAK2_wait,P_wait,INDEX1_wait,INDEX2_wait,INDEX3_wait,List2,List2_HOLD,SPACEL,SPACEL_HOLD,Print_LF,LF_wait,LF_HOLD,Print_CR,CR_wait,CR_hold);
    signal currentState, nextState: state_type;
    SIGNAL COUNT_NUM: integer:=0;
    SIGNAL COUNT_LIST: integer:=0;
    signal ifANNN : integer:=0;
    signal resetList: std_logic:='0';------reset signal 
    signal dataResultsR:  CHAR_ARRAY_TYPE(0 to 6);
    signal  maxIndexR:  BCD_ARRAY_TYPE(2 downto 0);
    signal encounterList : std_logic:='0';
  
    signal encount2, counterRST2:std_logic;-----counternum signal
    signal  R,register2:std_logic_vector(11 downto 0);----signal used in register to save input
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
       hexNum1:="00111000";       
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
       hexNum1:="00111000";      
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
  combi_nextState: process(currentState, rxNow, txdone, seqDone, dataReady)-----------------this part only shows the transfer logic of each state, The output and the state of signals in Output part
  begin
    
    
    case currentState is
      when S0_INIT =>--------signal all back to the inital 
        resetList<='0';
      
        if rxnow='1' THEN -------waiting rxnow go high to receive data 
          nextState <= S1_RXDATA;
        else
          nextState <= S0_INIT;
        end if ;
       
      WHEN S1_RXDATA =>
            if rxData="01000001" or rxData="01100001"  THEN-------check if the first input is "A" or "a"
              if txdone='1' then
                nextState <= transmition;               -----------send it to the Txdata to make it echo on the terminal
              else
                nextState <=S1_RXDATA;
              end if;
              
            elsif rxData= "01010000" or rxdata="01110000" THEN-----P/p
              if ifANNN > 0 then                    
                nextState <= S2_PEAK;
                
              elsif ifANNN=0 then
                nextState <= S0_INIT;
                
              end if;
         


         
            ELSIF rxData="01001100" or rxdata="01101100" THEN ------L/l
              if ifANNN > 0 then
                nextState <=S3_LIST;
                
              elsif ifANNN=0 then
                nextState <= S0_INIT;
                
              end if;   
           
            else                                        ----- other inputs  
              if txdone ='1' then  
                nextState <= transmition_fail;------------------ go to  
              else 
                nextState <= S1_RXDATA;
              end if;
            end if;
      
      When count_N =>     
      
      if rxNow = '1' then
       if rxData >="00110000" and rxData<="00111001" then------check if the next input after "A" or "a" is 0-9
            if COUNT_NUM = 0 then                         ----------this time register signal "R" form "AN"  assign the 4-bits binary into the MSB 
             R(11 downto 8) <= rxData(3 downto 0);
            elsif COUNT_NUM =  1 then
             R(7 downto 4) <= rxData(3 downto 0);        -----------this time "R" form "ANN" assign to the next four bits of register 
            elsif COUNT_NUM = 2 then
             R (3 downto 0) <= rxData(3 downto 0);      ------------"R" form "ANNN"
            end if;
         nextState <= counter_receive;                  -------------jump to a state to increase the counter number
        else  
          nextState <=  counter_RESET;                     ------------- the second Rxdata input is not a (0-9)number, so command is not valid jump to a state reset the counter
            
        end if;
      else 
        nextState <= count_N;
      end if;
        
      WHEN counter_RESET =>                              --------------set the reset of the counter to high to make COUNT_NUM back to 0.
         
          nextState <= transmition;
      
      WHEN counter_receive =>                           -------------set enable of the COUNT_NUM to high to make the counter add 1.
          nextState <= transmition;
      
      WHEN transmition =>                                 -------transimit 
     
        if rxData="01000001" or rxData="01100001" then    ---------  After transmit it from TX 
          nextState <= count_N;                         ----------jump to receive number (0-9) state.
        else
          nextState <= Check;                     
        end if;
    
      
      WHEN transmition_fail =>
       
       nextState <= S0_INIT;                              ------------- not a valid command , after output it to terminal then back to the INIT
       
          
      WHEN check =>                                        -----------check the number of "N"
      IF  rxData >="00110000" and rxData<="00111001" then
          if COUNT_NUM < 3 then                               ----------the counter number smaller than 3, still need (0-9) input, back to count_N state to receive next byte.
            nextState <= count_N;
          else 
            if txdone ='1' then                             ---------------equal to 3 means has formed ANNN 
                nextState <= GIVE_Num;                            --------------waiting the last Txdata complete output then go to assign register value to numworcs
            else
                nextState <= check;
                
            end if;
          end if;
      ELSE 
          nextState <= S0_INIT;
      end if;
 
      WHEN GIVE_Num =>                                                    ---------------use the the data stored in the register  to assign numWords 
        
            numWords_bcd(2) <= register2(11 downto 8);  
   
            numWords_bcd(1) <= Register2(7 downto 4);
            
            numWords_bcd(0) <= Register2(3 downto 0);
            
            nextState  <= n_print;
            
-------------------------------------------------------------------------------------------------
      When Give_data => --------------------
        
        
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
        if seqDone='1' then
          nextState <= stop_print;
        else
        
        nextState <= recieve_byte_2;
      
        end if;
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
        if txdone ='1' then
        
          nextState <= recieve_space;
        else
           nextState <= Print_byte_two;
        end if;
      
      when recieve_space =>
        if txdone ='1' then
            R(7 downto 0)<= "00100000";
            nextState <= print_space;
        else
          nextState <= recieve_space;
        end if; 
      when print_space =>
         nextState <= waiting_tx;
      WHEN waiting_tx =>
        if txdone='1' then
          
         nextState <= Give_data;
       else 
         nextState <= waiting_tx;
       end if;
      When undefined =>
        nextState <=  S0_INIT;
      WHEN stop_print =>
        nextState <= print_lastbyte;
        
      WHEN print_lastbyte =>
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
            nextState <= receive_lastbyte;
          else
            nextState <= print_lastbyte;
          end if;
        WHEN receive_lastbyte =>
          if txdone='1' then

          nextState <= S0_INIT;
        end if;
     WHEN n_print =>
      if txdone ='1' then
        
        nextState <= wait_txnow;
      else 
        nextState <= n_print;
      end if;
     WHEN wait_txnow =>
       if txdone='1' then
       nextState <=r_print;
      else
        nextState <=wait_txnow;
      end if;
     WHEN r_print =>
       if txdone='1' then
        
          nextState <= waiting_tx;
       else
          nextState <= r_print;
       end if;
------------------------------------------------------------------------------------------------------------      
      WHEN  S2_PEAK => 
          nextState <= Print_P;
          
      
          
      when Print_P =>
       
          nextState <= P_wait;
          
      when P_wait =>
          nextState <=S2_HOLD;
        
      when S2_HOLD =>  
      
        if txdone='1' then 
           nextState <= Print_LF;
        end if; 
      when Print_LF =>
       
          nextState <= LF_wait;
          
      when LF_wait =>
          nextState <=LF_HOLD;
        
      when LF_HOLD => 
        if txdone='1' then 
          nextState <=Print_CR;
        end if;
      when Print_CR =>
       
          nextState <= CR_wait;
          
      when CR_wait =>
          nextState <=CR_HOLD;
        
      when CR_HOLD =>  
      
        if txdone='1' then 
          if rxData= "01010000" or rxdata="01110000" then
             nextState <= PEAK1;
          elsif rxData="01001100" or rxdata="01101100" then
             nextState <= S3_HOLD;
          end if;
        end if;   
          
      WHEN PEAK1=>
          
            nextState <= PEAK1_wait;
          
      when PEAK1_wait=>
         nextState <= PEAK1_HOLD;
      
      when PEAK1_HOLD=>
        if txdone='1' then
          nextState<= PEAK2;
        end if;  
      when PEAK2=>
          
            nextState <=PEAK2_wait;
      when PEAK2_wait=>
         nextState <= PEAK2_HOLD;    
      
      when PEAK2_HOLD=>
        if txdone='1' then
          nextState<= SPACE;
        end if;
      when SPACE=>
          
            nextState <= SPACE_wait;
      when SPACE_wait=>
         nextState <= SPACE_HOLD;      
          
      when SPACE_HOLD=>
        if txdone='1' then
          nextState<= INDEX1;   
        end if;   
      when INDEX1=>
          
            nextState <= INDEX1_wait;
      when INDEX1_wait=>
      
            nextState <=   INDEX1_HOLD; 
          
      when INDEX1_HOLD=>
        if txdone='1' then
          nextState<= INDEX2;
        end if;  
      when INDEX2=>
          
            nextState <= INDEX2_wait;
      when INDEX2_wait=>
      
            nextState <=   INDEX2_HOLD; 
          
      when INDEX2_HOLD=>
        if txdone='1' then
          nextState<= INDEX3;
        end if; 
          
      when INDEX3=>
          
            nextState <=INDEX3_wait ;
          
          
       when INDEX3_wait=>
          if txdone='1' then
            nextState <=S0_INIT ;
        end if;
---------------------------------------------------------------------------------------         
      WHEN  S3_LIST =>
         nextState <= Print_L;
         
      
         
      when Print_L =>
          
             nextState <=L_wait;
                      
      when  L_wait =>
             nextState <=L_HOLD;
          
      when L_HOLD=>
        if txdone='1' then
         nextState <= Print_LF;
        end if;
      when S3_HOLD =>      
        nextState <= List1;
        encounterList<='0';
        
      
      when List1=>  
         
            nextState <= List1_wait;
      when List1_wait=>
           nextState <= List1_HOLD;
       
      when List1_HOLD=>
        if txdone='1' then
          nextState <= List2;  
        end if; 
      when List2=>  
         
            nextState <= List2_wait;
      when List2_wait=>
         nextState <=List2_HOLD;
          
      when List2_HOLD=>
        if txdone='1' then
          nextState <= SPACEL;
        end if;  
      when SPACEL=>

          
          
           nextState <=SPACEL_wait;
           
      when SPACEL_wait=>   
           nextState <= SPACEL_HOLD;
          
      when SPACEL_HOLD=>
        if txdone='1' then
            encounterList<='1';
           if COUNT_LIST < 6 then
            nextState <=S3_HOLD;
            
          elsif COUNT_LIST = 6 then
            nextState <= S0_INIT;
            resetList<='1';
            encounterList<='0';
          end if;     
        end if;
          
     
---------------------------------------------------------------------------------------------- 
  
   
      end case;     
  end process;       
  -----------------------------------------------------------------------------------
  -----------------------------------------------------------------------------
  -------------------------------------------------------------------
  ---------------------------------------------------------------
  --------------------------------------------------------
  ---------------------------------------------------
  ----------------------------------------------
  
  combi_output:process(currentState)
  begin                                     ---------------set the default value of my signals
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
         
            
      
      WHEN counter_receive =>                             ----------set ENable to high
            encount2 <='1';
            RxDone <='1';
      
         
      
      
      WHEN transmition =>                               ---------set txnow to high tell Tx model txdata has been ready to be transmited
         txData <= rxData;
         txNow<='1';
          
      WHEN check =>
          TxNow <='0';
          RxDone <='0';
         
          
      WHEN GIVE_Num =>  
           counterRST2 <='1';-----succussfully have NNN reset the counter
           
  -------------------------------------------------------------------------------------         
      When Give_data =>
            txNow <= '0';
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
            
        
      When undefined =>
        txnow<='0';
        start <='0';
        rxDone<='0';
        encount2<='0';
        counterRST2<='0';
      WHEN stop_print =>
        txNow <= '0'; 
      WHEN print_lastbyte =>
        txNow <='0';
      WHEN receive_lastbyte =>
        txdata <= register2(7 downto 0);
        txNow <='1';
      WHEN n_print =>
       if txdone ='1' then
          txData <= "00001010"; -- /n character in ascii to change into a new line
           txNow <= '1';
       end if;
      WHEN wait_txnow =>
        txNow<='0';
      WHEN r_print =>
        txData <= "00001101"; -- /r character in ascii for entering data
        txNow <= '1';
      WHEN transmition_fail =>
        txnow<='1';
        txData <= rxData;
      WHEN waiting_tx=>
        
        txnow<='0';
        
      -------------------------------------------------------------------------------------------         
      when S2_PEAK=>
          null;
          
     
          
      when Print_P=>
          txData <= rxData;
          txnow <='1'; 
          
      when P_wait=>
          txnow<='0';  
      
      
      when S2_HOLD=>
          null;
          
      when Print_LF=>
          txData <= "00001010";
          txnow <='1'; 
          
      when LF_wait=>
          txnow<='0';  
      
      
      when LF_HOLD=>
          null;
      when Print_CR=>
          txData <= "00001101";
          txnow <='1'; 
          
      when CR_wait=>
          txnow<='0';  
      
      
      when CR_HOLD=>
          null;  
      when PEAK1=>
          txData <= BtoH1(dataResultsR(3));
          txnow <='1';
      
      when PEAK1_wait=>
          txnow<='0'; 
          
      when PEAK1_HOLD=>
          null;
              
          
      when PEAK2=>  
          txData <= BtoH2(dataResultsR(3));
          txnow <='1';
      when PEAK2_wait=>
          txnow<='0';     
      
      when PEAK2_HOLD=>
          null;
          
      when SPACE=>   -----output a space    

          txData <= "00100000";
          txnow <='1';
      when SPACE_wait=>
          txnow<='0';     
      
      when SPACE_HOLD=>
          null;
                  
      when INDEX1=>----first bit of maxindex
          txData(7 downto 4) <= "0011";
          txData(3 downto 0) <= maxIndexR(2);
          txnow <='1';
      when INDEX1_wait=>
          txnow<='0';     
      
      WHEN INDEX1_HOLD=>
          null;
          
      when INDEX2=>----second bit of maxindex
          txData(7 downto 4) <= "0011";
          txData(3 downto 0) <= maxIndexR(1);
          txnow <='1';
      when INDEX2_wait=>
          txnow<='0';     
          
      WHEN INDEX2_HOLD=>
          null;
              
      when INDEX3=>----third bit of maxindex
          txData(7 downto 4) <= "0011";
          txData(3 downto 0) <= maxIndexR(0);
          txnow <='1';
      when INDEX3_wait=>
          txnow<='0';     
 ----------------------------------------------------------------------------------------         
          
      when S3_LIST=>
          null;
          
      when L_HOLD=> 
         null;
          
      when Print_L=>
          txData <= rxData;
          txnow <='1'; 
      
      when L_wait=>
          txnow<='0';
          
      when S3_HOLD=>
          null;
          
      when List1=>
          txData <= BtoH1(dataResultsR(COUNT_LIST));
          txnow <='1';
      when List1_wait=>    
          txnow<='0';
      when List1_HOLD=>
          null;
          
      when List2=>
          txData <= BtoH2(dataResultsR(COUNT_LIST));
          txnow <='1';
       when List2_wait=>    
          txnow<='0';    
          
      when List2_HOLD=>
          null;
          
      when SPACEL=>
          txData <= "00100000";
          txnow <='1';
      when SPACEL_wait=>   
          txnow<='0';
      when SPACEL_HOLD=>
            null;
      
     end case;
  end process;    
  -------------------------------------------------------------------
  -------------------------------------------------------------
  -----------------------------------------------
  -------------------
  COUNTER_NUM: PROCESS(reset, clk)  ---------------------------this counter one of the function is to keep track of the number of the (0-9) inputs

  BEGIN 

    IF counterRST2 = '1' THEN  -- active high reset 

        COUNT_NUM <= 0; 

    ELSIF clk'EVENT and clk='1' THEN 

        IF encount2= '1' THEN              

           COUNT_NUM <= COUNT_NUM + 1; 

        END IF; 

    END IF; 

  END PROCESS; 
  
     
 
   COUNTER_LIST: PROCESS(reset, clk)

  BEGIN

    IF resetList = '1' THEN  -- active high reset

        COUNT_LIST <= 0;

    ELSIF clk'EVENT and clk='1' THEN

        IF encounterList= '1' THEN              

           COUNT_LIST <= COUNT_LIST + 1;

        END IF;

    END IF;

  END PROCESS;

  dataResultR_maxIndexR: process ( reset,seqDone)
      BEGIN
        if reset='1' then
          dataResultsR(0) <= "00000000";
          dataResultsR(1) <= "00000000";
          dataResultsR(2) <= "00000000";
          dataResultsR(3) <= "00000000";
          dataResultsR(4) <= "00000000";
          dataResultsR(5) <= "00000000";
          dataResultsR(6) <= "00000000";
      
          maxIndexR(0) <= "0000";
          maxIndexR(1) <= "0000";
          maxIndexR(2) <= "0000";
      
        elsif seqDone = '1' then
          dataResultsR <= dataResults;
          maxIndexR <= maxIndex;
          
        end if;
      end process;
 
 
 
 
 
 
 
 
 
         
  IF_A: PROCESS(reset, clk,seqDone)

  BEGIN

    IF reset = '1' THEN  -- active high reset

        ifANNN <= 0;

    ELSIF clk'EVENT and clk='1' THEN

        IF seqDone= '1' THEN              

           ifANNN <= ifANNN + 1;

        END IF;

    END IF;

  END PROCESS; 
 
 
 
 
 
  register1: PROCESS (clk, R, register2)------------------this register one of the function is store 12-bit wide of binary of "NNN" data
     BEGIN
       IF clk'EVENT AND clk='1' THEN
         register2 <= R;
       END IF;
     END PROCESS;
 
 
 
--- 
       
             
  seq_state: PROCESS (CLK, reset) ---------------------nextState logic
  BEGIN
    IF reset = '1' THEN
      currentState <= S0_INIT;
    ELSIF CLK'EVENT AND CLK='1' THEN
      currentState <= nextState;
    END IF;
  END PROCESS; -- seq  
  
END dataflow;



