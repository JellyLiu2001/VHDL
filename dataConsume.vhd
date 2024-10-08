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
  TYPE state_type IS(reset_stage, init, first,haha, second, third, fourth, fIFth);--define state 
 --SIGNAL init,first,second,third,fourth,fIFth:state_type;--SIGNAL of the state
  SIGNAL COUNTER_reset,COMPARATOR_done,shifter_reset,peaknumer_status,data_real_prefix_status,Counter_stop:std_logic;  --erase the COUNTER and comparetor during each cycle.
  SIGNAL ctrlIn_detected, ctrlIn_delayed,ctrlOut_reg:std_logic :='0';
  SIGNAL MAXindex_BCD:BCD_ARRAY_TYPE(2 downto 0);--store the maximum number's index.
  SIGNAL COUNTER : integer:=0;--counting the number and store as index. 
  SIGNAL prefix:char_array_type(0 TO 3);
  SIGNAL real_prefix:char_array_type(0 TO 2);--è®°peakåä¸ä½
  SIGNAL suffix:char_array_type(0 to 2);--è®°peakåä¸ä½
  SIGNAL final_result:char_array_type(0 TO 6);--è®°å¨é¨
  SIGNAL index_peak:integer;--è®°ä½ç½®
  SIGNAL DATA_READY : std_logic;
  SIGNAL curstate, nextstate:state_type; 
  SIGNAL valueofnumwords: integer range 0 to 999; --integer value of numWords_BCD
BEGIN 
valueofnumwords <= TO_INTEGER(unsigned(numWords_bcd(0))) + TO_INTEGER(unsigned(numWords_bcd(1))) *10 + TO_INTEGER(unsigned(numWords_bcd(2))) * 100;--transfer BCD to integer
ctrlIn_detected <= ctrlIn xor ctrlIn_delayed;

combi_nextState:process(curState, start, reset, COUNTER, CtrlIn_detected, Comparator_done)
  BEGIN           
    CASE curState IS 
      when reset_stage =>
        COUNTER_reset <='1';
        SeqDone <='0';
        nextState <= init;
        shifter_reset<='1';

        
      WHEN init => -- Wait for start SIGNAL
        COUNTER_reset<='0';
        shifter_reset<='0';
        IF start = '1' THEN
          nextState <= first;
        ELSE
          nextState <= init;
        END IF;
        
      WHEN first => 

      IF ctrlIn_detected ='1' THEN
        CtrlOut_reg <=CtrlOut_reg;
        nextState <= second;
      ELSE
        CtrlOut_reg <=not CtrlOut_reg;
      END IF;


      WHEN second => --Set dataready SIGNAL high and give byte

        nextState <= third;

      WHEN third =>  --stage to see IF counter 

        IF COUNTER = valueofnumwords THEN --All bytes has been counted.
          nextState <= fourth;
        ELSE 
          nextState <= init;--Not all bytes counted, go back to first stage and step to next byte
        END IF;
      WHEN fourth => --All bytes counter, transfer all SIGNAL to cmd, then step to seqdone
        IF Counter_stop ='1' THEN --wait for shIFter and comparator
          nextState <= fIFth;
        ELSE
          nextState <= fourth;
        END IF;
      When Fifth => --complete, give seqDone high SIGNAL
        Seqdone <='1';
        dataResults <= final_result;
        maxIndex <= MAXindex_BCD;
        nextState <= reset_stage; 
      When others =>
        seqDone<='0';
    END CASE;
          
  END process;
Handshakeprotocol :process (clk) --initialize
  BEGIN
    IF rising_edge(clk) THEN
      ctrlIn_delayed <= ctrlIn;
      ctrlOut <= CtrlOut_reg;
      byte <= data;
      DATA_ready <= CtrlIn_detected;
      dataready<=DATA_READY;
    END IF;
  END PROCESS;
      

STAGE_RESET:process (clk)
  BEGIN
    IF reset ='1' THEN
      curState <= INIT;
    ELSIF rising_edge (clk) and reset='0' THEN
      curState <= nextState  ;
    END IF;
  END process;
----------------------------------------------------   


COUNTER_process:process(DATA_READY,COUNTER_reset)--TO calculate the index and compare the peak value. 
BEGIN
  IF COUNTER_reset='1' THEN
      COUNTER <=0;
  ELSIF data_ready='1' THEN
      COUNTER <= COUNTER + 1;
  END IF;
END process;  

----------------------------------------------------

SHIFTER_prefix:process(data,clk) 
BEGIN
IF reset='1' or shifter_reset='1' THEN
prefix<=("00000000","00000000","00000000","00000000");

ELSIF rising_edge(clk) and ctrlIn_detected='1' THEN
	IF peaknumer_status='0' then
   	 	for i in 0 TO 2 loop
      			prefix(i)<=prefix(i+1);
    		END loop;
      		prefix(2)<=data;--peak
	ELSE
		prefix(3)<=data;
	END IF;
END IF;
END process;

--------------------------------------------------
COMPARATOR_process:process(clk)
BEGIN
IF rising_edge(clk)  THEN
    IF peaknumer_status='1' THEN
 	    index_peak<=COUNTER+1;
      COMPARATOR_done<='1';
    ELSE
      COMPARATOR_done<='0';
	  END IF;
ELSIF counter_reset='1' THEN
    index_peak<=0;
END IF;
END process;

--------------------------------------------------
peak:process(clk,data)
BEGIN
	IF data>prefix(3) then
		peaknumer_status<='1';
	ELSE
		peaknumer_status<='0';
	END IF;
END process;
----------------------------------------------------
data_real_prefix:process(clk)
BEGIN
if shifter_reset='1' then
real_prefix<=("00000000","00000000","00000000");
else
    IF peaknumer_status='1' then
      real_prefix(0)<=prefix(0);
      real_prefix(1)<=prefix(1);
      real_prefix(2)<=prefix(2);
	    data_real_prefix_status<='1';
    else
	    data_real_prefix_status<='0';
    END IF;
end if;
END process;


----------------------------------------------------
SHIFTER_suffix:process(COUNTER,index_peak) 
BEGIN
if shifter_reset='1' then
suffix<=("00000000","00000000","00000000");
else
  IF COUNTER-index_peak=1 then
    suffix(0)<=data;
  ELSIF COUNTER-index_peak=2 then
    suffix(1)<=data;
  ELSIF COUNTER-index_peak=3 then
    suffix(2)<=data;
  ELSE
    final_result(0 to 2)<=real_prefix;
    final_result(3)<=prefix(3);
    final_result(4 to 6)<=suffix(0 to 2);
    end if;
END IF;
END process;

----------------------------------------------------

maxindex_conversion:process(index_peak) 
BEGIN
MAXindex_BCD(2)<=std_logic_vector(to_unsigned(index_peak/100 mod 10,numWords_bcd(0)'length));
MAXindex_BCD(1)<=std_logic_vector(to_unsigned(index_peak/10 mod 10,numWords_bcd(0)'length));
MAXindex_BCD(0)<=std_logic_vector(to_unsigned(index_peak/1 mod 10,numWords_bcd(0)'length));
END process;

----------------------------------------------------
counter_done:process(counter,clk) 
BEGIN 
  if counter=valueofnumwords then
  Counter_stop<='1';
else
  Counter_stop<='0';
  end if;
END process;
END dataConsume_state;
