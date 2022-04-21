library ieee;--import basic library
use ieee.std_logic_1164.all;
use work.common_pack.all;
use ieee.numeric_std.all;

  ENTITY dataConsume is --Define the input and output port.
    port (
      clk: in std_logic;
      reset: in std_logic; -- synchronous reset
      start: in std_logic; --check rising edge, when 1, start
      numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);--3*4 BCD ANNN
      ctrlIn: in std_logic;
      ctrlOut: out std_logic;
      data: in std_logic_vector(7 downto 0); 
      dataReady: out std_logic; 
      byte: out std_logic_vector(7 downto 0); 
      seqDone: out std_logic; 
      maxIndex: out BCD_ARRAY_TYPE(2 downto 0); --3*4 BCD
      dataResults: out CHAR_ARRAY_TYPE(0 TO 6)  -- 7*8 (-3:peak:3)
    ); 
  END dataConsume;

architecture dataConsume_state OF dataConsume IS 
  TYPE state_type IS(reset_stage, init, first,haha, second, third, fourth, fIFth);--define state 
 --SIGNAL init,first,second,third,fourth,fIFth:state_type;--SIGNAL of the state
  SIGNAL COUNTER_reset,COMPARATOR_done,shifter_reset,peaknumer_status,data_real_prefix_status,Counter_stop:std_logic;  --shows the status and reset
  SIGNAL ctrlIn_detected, ctrlIn_delayed,ctrlOut_reg:std_logic :='0';--for handshake
  SIGNAL MAXindex_BCD:BCD_ARRAY_TYPE(2 downto 0);--store the maximum number's index.
  SIGNAL COUNTER : integer:=0;--counting the number and store as index. 
  SIGNAL prefix:char_array_type(0 TO 3);--store the three number before the peak number continuously
  SIGNAL real_prefix:char_array_type(0 TO 2);--store the three number from prefix after the peak number
  SIGNAL suffix:char_array_type(0 to 2);--store the last three number after peak numebr. 
  SIGNAL finnal_result:char_array_type(0 TO 6);--combine all seven datas including prefix, peak numebr and suffix.
  SIGNAL index_peak:integer;--the index of the peak value
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
        dataResults <= finnal_result;
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
--????????CODE BY JELLY JINZHE LIU????????--
----------------------------------------------------   
COUNTER_process:process(DATA_READY,COUNTER_reset)--TO calculate the index.
BEGIN
  IF COUNTER_reset='1' THEN--reset to zero
      COUNTER <=0;
  ELSIF data_ready='1' THEN--IF dataready which means the new data has came.
      COUNTER <= COUNTER + 1;--the counter plus one.
  END IF;
END process;  

----------------------------------------------------

SHIFTER_prefix:process(data,clk) --the store the first three number. 
BEGIN
IF reset='1' or shifter_reset='1' THEN
prefix<=("00000000","00000000","00000000","00000000");--init the prefix and reset to zero

ELSIF rising_edge(clk) and ctrlIn_detected='1' THEN--rising clock's senstive list
	IF peaknumer_status='0' then--IF new data is smaller than old peak
   	 	FOR i in 0 TO 2 loop--a loop for record the data, i will be 0 to 2 , and store each data in different i+1 index.
      		prefix(i)<=prefix(i+1);
    		END loop;--finish the loop
      		prefix(2)<=data;--peak
	ELSE
		prefix(3)<=data;--IF new data is higher than old peak number, it will store into prefix (3) which is peak value. 
	END IF;
END IF;
END process;

--------------------------------------------------
COMPARATOR_process:process(clk)--to store the counter into index peak value when it's dectect the peak number. 
BEGIN
IF rising_edge(clk)  THEN--IF it's peak number
    IF peaknumer_status='1' THEN
 	    index_peak<=COUNTER+1;--index_peak is counter+ 1 because there is a clock delay.
      COMPARATOR_done<='1';--show the status that indexpeak is working. 
    ELSE
      COMPARATOR_done<='0';--it's not peak number, the process will wait until the peak number. 
	  END IF;

ELSIF counter_reset='1' THEN--IF counter reset to zero.
    index_peak<=0;--index peak will reset too. 

END IF;
END process;

--------------------------------------------------
peak:process(clk,data)--this process is to judge IF peak number is bigger or smaller than prefix(3)
BEGIN
	IF data>prefix(3) then
		peaknumer_status<='1';--IF it's bigger, that's peak number. the signal will turn to high to be detected by another process. 

	ELSE
		peaknumer_status<='0';--otherwise, it's always be zero.

	END IF;
END process;
----------------------------------------------------
data_real_prefix:process(clk)--to store the real prefix after the peak number. 
BEGIN
IF shifter_reset='1' then--to reset the shifter 
real_prefix<=("00000000","00000000","00000000");--idle the shifter and reset. 
ELSE
    IF peaknumer_status='1' then--IF it's peak number
      real_prefix(0)<=prefix(0);--store the first prefix into first real_prefix one by one. 
      real_prefix(1)<=prefix(1);
      real_prefix(2)<=prefix(2);
	    data_real_prefix_status<='1';
    ELSE
	    data_real_prefix_status<='0';
    END IF;
END IF;
END process;


----------------------------------------------------
SHIFTER_suffix:process(COUNTER,index_peak) --to store the suffix after peak number.
BEGIN
IF shifter_reset='1' then--to reset the shifter 
suffix<=("00000000","00000000","00000000");--idle the shifter and reset.
ELSE
  IF COUNTER-index_peak=1 then--IF counter-index_peak=1 which is the space next to the indexpeak, so it's suffix(0)
    suffix(0)<=data;
  ELSIF COUNTER-index_peak=2 then
    suffix(1)<=data;
  ELSIF COUNTER-index_peak=3 then
    suffix(2)<=data;
  ELSE
    finnal_result(0 to 2)<=real_prefix;--prefix to final result
    finnal_result(3)<=prefix(3);--peak number(prefix(3)) to final result
    finnal_result(4 to 6)<=suffix(0 to 2);--suffix to final result
  END IF;
END IF;
END process;

----------------------------------------------------

maxindex_conversion:process(index_peak) --change the numebr into BCD
BEGIN
MAXindex_BCD(2)<=std_logic_vector(to_unsigned(index_peak/100 mod 10,numWords_bcd(0)'length));--A mod B = A - ( A / B ) * B mod
MAXindex_BCD(1)<=std_logic_vector(to_unsigned(index_peak/10 mod 10,numWords_bcd(0)'length));
MAXindex_BCD(0)<=std_logic_vector(to_unsigned(index_peak/1 mod 10,numWords_bcd(0)'length));
END process;

----------------------------------------------------
counter_done:process(counter,clk) --check IF it's stop
BEGIN 
IF counter=valueofnumwords then--IF numebr ==annn
    Counter_stop<='1';--stop all process into fifth stage.
ELSE
    Counter_stop<='0';--go on. 
END IF;
END process;
END dataConsume_state;
