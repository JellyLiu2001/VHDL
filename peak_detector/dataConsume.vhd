library ieee;--import basic library
use ieee.std_logic_1164.all;
use work.common_pack.all;
use ieee.numeric_std.all;

  ENTITY dataConsume is --Define the input and output port.
    port (
      clk: in std_logic;
      reset: in std_logic; -- synchronous reset
      start: in std_logic; --check rising edge, when 1, start--ä¸é¢çstateéåäº
      numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);--3*4 BCD ANNN--ä¸é¢éåäº
      ctrlIn: in std_logic;--æ¡æ
      ctrlOut: out std_logic;--æ¡æ
      data: in std_logic_vector(7 downto 0); --ä»data gençæ°æ®á
      dataReady: out std_logic; --dataå¯ç¨ä¼ è¾
      byte: out std_logic_vector(7 downto 0); --ç»å°cmdçæ°æ®
      seqDone: out std_logic; --å®æç¶æ
      maxIndex: out BCD_ARRAY_TYPE(2 downto 0); --3*4 BCD
      dataResults: out CHAR_ARRAY_TYPE(0 TO 6)  -- 7*8 (-3:peak:3)
    ); 
  END dataConsume;

architecture dataConsume_state OF dataConsume IS 
  TYPE state_type IS(init, first,haha, second, third, fourth, fifth);--define state 
 --SIGNAL init,first,second,third,fourth,fifth:state_type;--SIGNAL of the state
  SIGNAL COUNTER_reset,compare_reset,COUNTER_done,SHIFTER_prefix_done,COMPARATOR_done,k:std_logic;  --erase the COUNTER and comparetor during each cycle.
  SIGNAL ctrlIn_detected, ctrlIn_delayed,ctrlOut_reg:std_logic :='0';
  SIGNAL MAXindex_BCD:BCD_ARRAY_TYPE(2 downto 0);--store the maximum number's index.
  SIGNAL COUNTER : integer:=0;--counting the number and store as index. 
  SIGNAL prefix:char_array_type(0 TO 3);--è®°peakåä¸ä½
  SIGNAL suffix:char_array_type(0 to 3);--è®°peakåä¸ä½
  SIGNAL finnal_result:char_array_type(0 TO 6);--è®°å¨é¨
  SIGNAL index, index_peak:integer;--è®°ä½ç½®
  SIGNAL DATA_READY : std_logic;
  SIGNAL curstate, nextstate:state_type; 
  SIGNAL valueofnumwords: integer range 0 to 999; --integer value of numWords_BCD
BEGIN 
valueofnumwords <= TO_INTEGER(unsigned(numWords_bcd(0))) + TO_INTEGER(unsigned(numWords_bcd(1))) *10 + TO_INTEGER(unsigned(numWords_bcd(2))) * 100;--transfer BCD to integer
ctrlIn_detected <= ctrlIn xor ctrlIn_delayed;
combi_nextState:process(curState, start, reset, COUNTER, CtrlIn_detected, Comparator_done)
  BEGIN           
    CASE curState IS 
      WHEN init => -- Wait for start SIGNAL
        COUNTER_reset<='1';
        compare_reset<='1';
        COUNTER_done <='0';
        CtrlOut_reg <='0';
        IF start = '1' THEN
          nextState <= first;
        ELSE
          nextState <= init;
        END IF;
        
      WHEN first => 
      COUNTER_reset<='0';
      compare_reset<='0';
      
      IF ctrlIn_detected ='1' THEN
        CtrlOut_reg <='0';

        nextState <= second;
      Else

        CtrlOut_reg <='1';
      END IF;

     -- When haha=>
   -- IF ctrlIn_detected='1' THEN
     -- nextState <= first;
--    ElSIF ctrlIn_detected='0' THEN
     -- nextState <= haha;
       -- ELSE
        --  nextState <= init;
      --  END IF;

      WHEN second => --Set dataready SIGNAL high and give byte
        CtrlOut_reg <='0';
 
        nextState <= third;

      WHEN third =>  --stage to see if counter 
        CtrlOut_reg <='0';
        IF COUNTER = valueofnumwords THEN --All bytes has been counted.
          nextState <= fourth;
        Else 
          nextState <= init;--Not all bytes counted, go back to first stage and step to next byte
        END IF;
      WHEN fourth => --All bytes counter, transfer all SIGNAL to cmd, then step to seqdone
 
        COUNTER_done <='1';
        IF Comparator_done ='1' THEN --wait for shifter and comparator
          nextState <= fifth;
        Else
          nextState <= fourth;
        END IF;
      When fifth => --complete, give seqDone high SIGNAL
        Seqdone <='1';
        COUNTER_reset<='1';
        Compare_reset<='1';
        dataResults <= finnal_result;
        maxIndex <= MAXindex_BCD;
        nextState <= init; 
      When others =>
        seqDone<='0';
    END CASE;
          
  END process;

Handshakeprotocol :process (clk) --initialize
  begin
    IF rising_edge(clk) THEN
      ctrlIn_delayed <= ctrlIn;
      ctrlOut <= CtrlOut_reg;
      byte <= data;
      DATA_ready <= CtrlIn_detected;
      dataready<=DATA_READY;
--      IF reset = '1' THEN
--        ctrlOut_reg<='0';
--      ELSE
--        IF curState = first THEN
--          ctrlOut_reg <= not ctrlOut_reg;
--        else
--          ctrlOut_reg <= ctrlOut_reg;
--        END IF;
--      END IF;
    END IF;
  END PROCESS;
      
--Control_SIGNAL :process (curstate)
--  begin
--    DATA_READY <='0';
--    COUNTER_reset<='0';
--    compare_reset<='0';
--    COUNTER_done<='0';
-- --   ctrlOut_reg <='0';
--    
--
--    CASE curstate is
--      WHEN init =>
--        COUNTER_reset<='1';
--        compare_reset<='1';
--
--      when second =>
--        byte <= data;
--
--      when third =>
--        DATA_READY<='1';
--        dataready<=DATA_READY;
--
--      when fourth =>
--        COUNTER_done <='1';
--
--      When fifth =>
--        Seqdone <='1';
--        COUNTER_reset<='1';
--        Compare_reset<='1';
--        dataResults <= finnal_result;
--        maxIndex <= MAXindex_BCD;
--        
--      when others=>
--        seqDone<='0';
--        data_ready<='0';
--    END CASE;
--  END process;




STAGE_RESET:process (clk)
  begin
    IF reset ='1' THEN
      curState <= INIT;
    ELSIF rising_edge (clk) and reset='0' THEN
      curState <= nextState  ;
    END IF;
  END process;
----------------------------------------------------

COUNTER_process:process(DATA_READY)--TO calculate the index and compare the peak value. 
BEGIN
  IF COUNTER_reset='1' THEN
      COUNTER<=0;
  ELSIF data_ready='1'THEN
      COUNTER <= COUNTER + 1;
      COUNTER_done<='1';
  END IF;
END process;  

----------------------------------------------------

SHIFTER_prefix:process(data,clk) 
BEGIN
IF reset='1' THEN
prefix<=("00000000","00000000","00000000","00000000");
elsIF rising_edge(clk) and ctrlIn_detected='1' THEN
	k<='0';
	if k='0' then
   	 	for i in 0 TO 2 loop
      			prefix(i)<=prefix(i+1);
    		END loop;
      		prefix(2)<=data;--peak
	elsif k='1' then
		prefix(3)<=data;
	End if;
SHIFTER_prefix_done<='1';
END IF;
END process;

--------------------------------------------------
COMPARATOR_process:process(clk,data)
BEGIN

IF compare_reset='1' or curstate= init THEN
  index_peak<=0;

ELSIF rising_edge(clk) THEN
    IF data > prefix(3) THEN
	k<='1';
      index_peak<=COUNTER;
      COMPARATOR_done<='1';
     	ELSE
	k<='0';
      COMPARATOR_done<='0';
    END IF;
END IF;
END process;

--------------------------------------------------

--SHIFTER_suffix:process(COUNTER,index_peak) 
--BEGIN
--if COUNTER-index_peak=0 then
--  suffix(0)<=data;
--elsif COUNTER-index_peak=1 then
--  suffix(1)<=data;
--elsif COUNTER-index_peak=2 then
--  suffix(2)<=data;
--elsif COUNTER-index_peak=3 then
--  suffix(3)<=data;
--  finnal_result(0 to 2)<=prefix;
--  finnal_result(3 to 6)<=suffix;
--END if;
--END process;

----------------------------------------------------

maxindex_conversion:process(index_peak) 
BEGIN
MAXindex_BCD(2)<=std_logic_vector(to_unsigned(index_peak/100 mod 10,numWords_bcd(0)'length));
MAXindex_BCD(1)<=std_logic_vector(to_unsigned(index_peak/10 mod 10,numWords_bcd(0)'length));
MAXindex_BCD(0)<=std_logic_vector(to_unsigned(index_peak/1 mod 10,numWords_bcd(0)'length));
END process;


END dataConsume_state;
