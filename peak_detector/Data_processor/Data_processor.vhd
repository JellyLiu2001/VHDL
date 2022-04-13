library ieee;--import basic library
use ieee.std_logic_1164.all;
use work.common_pack.all;
use ieee.numeric_std.all;

  ENTITY dataConsume is --Define the input and output port.
    port (
      clk: in std_logic;
      reset: in std_logic; -- synchronous reset
      start: in bit; --check rising edge, when 1, start--下面的state重名了
      numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);--3*4 BCD ANNN--下面重名了
      ctrlIn: in std_logic;--握手
      ctrlOut: out std_logic;--握手
      data: in std_logic_vector(7 downto 0); --从data gen的数据
      dataReady: out std_logic; --data可用传输
      byte: out std_logic_vector(7 downto 0); --给到cmd的数据
      seqDone: out std_logic; --完成状态
      maxIndex: out BCD_ARRAY_TYPE(2 downto 0); --3*4 BCD
      dataResults: out CHAR_ARRAY_TYPE(0 TO 6)  -- 7*8 (-3:peak:3)
    ); 
  END dataConsume;

architecture dataConsume_state OF dataConsume IS 
  TYPE state_type IS(init, first, second, third, fourth, fifth);--define state 
 -- SIGNAL init,first,second,third,fourth,fifth:state_type;--SIGNAL of the state
  SIGNAL COUNTER_reset,compare_reset,COUNTER_done,SHIFTER_prefix_done,COMPARATOR_done:std_logic;  --erase the COUNTER and comparetor during each cycle.
  SIGNAL ctrlIn_detected, ctrlIn_delayed,ctrlOut_reg:std_logic;
  SIGNAL ctrlIn_delayed, ctrlIn_detected,ctrlOut_reg:std_logic;
  SIGNAL MAXindex_BCD:BCD_ARRAY_TYPE(2 downto 0);--store the maximum number's index.
  SIGNAL COUNTER : integer:=0;--counting the number and store as index. 
  SIGNAL prefix:char_array_type(0 TO 2);--记peak前三位
  SIGNAL suffix:char_array_type(0 to 3);--记peak和三位
  SIGNAL finnal_result:char_array_type(0 TO 6);--记全部
  SIGNAL index, index_peak:integer;--记位置
  SIGNAL DATAREADY : std_logic;
  SIGNAL Controlforindex, Controlforcomplete : std_logic;
  SIGNAL valueofnumwords : integer 0 to 999; --integer value of numWords_BCD
BEGIN 
valueofnumwords = TO_INTEGER(unsigned(numWords_bcd(0))) + TO_INTEGER(unsigned(numWords_bcd(1))) *10 + TO_INTEGER(unsigned(numWords_bcd(2))) * 100--transfer BCD to integer
ctrlOut <= ctrlOut_reg
ctrlIn_detected = ctrl_In xor ctrlIn_delayed
combi_nextState:process(curState, start, reset, COUNTER, CtrlIn_detected, Comparator_done)
  BEGIN 
    CASE curState IS 
      WHEN init => -- Wait for start SIGNAL
        ctrlOut_reg ='0'
        IF start = '1' THEN
          nextState => first;
        ELSE
          nextState => init;
        END IF
      WHEN first => --Send ctrl1 and wait for ctrl2
        IF reset= '0' and ctrlIn_detected='1' THEN
          nextState => second;
        ElSIF reset = '0' and ctrlIn_detected='0' THEN
          nextState => first;
        ELSE
          nextState => init;
        END IF
      WHEN second => --Set dataready SIGNAL high and give byte
        nextState => third
      WHEN third =>  --stage to see if counter 
        IF COUNTER = valueofnumwords THEN --All bytes has been counted.
          nextState => fourth;
        Else 
          nextState => first;--Not all bytes counted, go back to first stage and step to next byte
        END IF
      WHEN fourth => --All bytes counter, transfer all SIGNAL to cmd, then step to seqdone.
        IF Comparator_done ='1' THEN --wait for shifter and comparator
          nextState => fifth;
        Else
          nextState => fourth;
        END IF
      When fifth => --complete, give seqDone high SIGNAL
        nextState => init; 
      When others =>
        nextState => init;   
    END CASE;
          
  END process;

Handshakeprotocol: process(clk)     
  begin
    IF rising_edge(clk) THEN
      ctrlIn_delayed <= ctrlIn
      IF curState = first THEN
        ctrlOut_reg <= NOT ctrlOut_reg
      ELSE
        ctrlOut_reg <= ctrlOut_reg 
    END if;
  END process;


Control_SIGNAL :process (curstate)
  begin
    DATAREADY ='0'
    COUNTER_reset='0'
    compare_reset='0'
    COUNTER_done='0'
    

    CASE curstate is
      WHEN init =>
        COUNTER_reset ='1'
        compare_reset ='1'
      When first =>
        ctrlOut ='1'
      when second =>
        DATAREADY ='1'
        byte <= data
      when third =>
        DATAREADY ='0'
      when fourth =>
        COUNTER_done ='1'
      When fifth =>
        Seqdone ='1'
        reset='1'
        COUNTER_reset='1'
        Compare_reset='1'
        dataResults <= finnal_result
        maxIndex <= MAXindex_BCD
    END CASE;
  END process;

STAGE_RESET:process (curState)
  begin
    IF reset ='1' THEN
      curState <= INIT
    ELSIF rising_edge (clk) and reset='0' THEN
      curState <= nextState  
    END IF;
  END process;
----------------------------------------------------

COUNTER_process:process(data,reset)--TO calculate the index and compare the peak value. 
BEGIN
  IF COUNTER_reset='1' THEN
      COUNTER<=0;
  ELSIF rising_edge(clk) THEN
      COUNTER = COUNTER + 1;
      COUNTER_done='1';--!总结写
  END IF;
END process;  

----------------------------------------------------

SHIFTER_prefix:process(data) --存三位
BEGIN
IF rising_edge(clk) and ctrlIn_detected='1' THEN
    for i in 0 TO 2 loop--3位循环
      prefix(i)<=prefix(i+1);
    END loop;
      prefix(3)<=data;
      SHIFTER_prefix_done='1';--!
END process;

----------------------------------------------------

COMPARATOR_process:process(clk,COUNTER)--比较
BEGIN
IF compare_reset='1' or curstate= start THEN--清零(curstate 应该是init)
  index_peak<="0";
END IF;

ELSIF rising_edge(clk) THEN
    IF data > prefix(3) THEN--选择最大的值
      index_peak<=COUNTER;
      COMPARATOR_done='1';--!
    END IF;
END IF;
END process;

----------------------------------------------------

SHIFTER_suffix:process(COUNTER,index_peak) --存后四位
BEGIN
if COUNTER-index_peak=0 then
  suffix(0)<=data;
elsif COUNTER-index_peak=1 then
  suffix(1)<=data;
elsif COUNTER-index_peak=2 then
  suffix(2)<=data;
elsif COUNTER-index_peak=3 then
  suffix(3)<=data;
  finnal_result(0 to 2)<=prefix;--全部的7位
  finnal_result(3 to 6)<=suffix;
END if;
END process;

----------------------------------------------------

maxindex:process(index_peak) --integer输出bcd
BEGIN
MAXindex_BCD(2)<=std_logic_vector(to_unsigned(index_peak/100 mod 10,numWords_bcd(0)'length));
MAXindex_BCD(1)<=std_logic_vector(to_unsigned(index_peak/10 mod 10,numWords_bcd(0)'length));
MAXindex_BCD(0)<=std_logic_vector(to_unsigned(index_peak/1 mod 10,numWords_bcd(0)'length));
END process;
----------------------------------------------------
