library ieee;--import basic library
use ieee.std_logic_1164.all;
use work.common_pack.all;
use ieee.numeric_std.all;

  ENTITY dataConsume is --Define the input and output port.
    port (
      clk: in std_logic;
      reset: in std_logic; -- synchronous reset
      start: in bit; --check rising edge, when 1, start
      numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);--3*4 BCD ANNN
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
  SIGNAL init,first,second,third,fourth,fifth:state_type;--Signal of the state
  SIGNAL COUNTER_reset,compare_reset,COUNTER_done,SHIFTER_prefix_done,COMPARATOR_done:std_logic;  --erase the COUNTER and comparetor during each cycle.
  SIGNAL ctrlOut_detected, ctrlIn_detected,ctrlOut_reg:std_logic;
  SIGNAL data:std_vector(7 downto 0);--data from data generator.
  SIGNAL ctrlIn_delayed, ctrlIn_detected,ctrlOut_reg:std_logic;
  SIGNAL MAXindex_BCD:BCD_ARRAY_TYPE(2 downto 0);--store the maximum number's index.
  SIGNAL COUNTER : integer:=0;--counting the number and store as index. 
  SIGNAL prefix:char_array_type(0 TO 2);--记peak前三位
  signal suffix:char_array_type(0 to 3);--记peak和三位
  SIGNAL finnal_result:char_array_type(0 TO 7);--记全部
  SIGNAL index, index_peak:integer;--记位置
  SIGNAL DATAREADY : std_logic;
  SIGNAL Controlforindex, Controlforcomplete : std_logic;
BEGIN 

ctrlIn_detected = ctrl_In xor ctrlIn_delayed
combi_nextState:process(curState, start, reset, ctrlOut_detected,DATAREADY, Controlforindex, Controlforcomplete)
  BEGIN 
    CASE curState IS 
      WHEN init => -- Wait for start signal
        IF start = '1' THEN
          nextState => first;
        ELSE
          nextState => init;
        END IF
      WHEN first => --Wait for ctrl1 and ctrl2
        ctrlOut_detected = ctrl_Out xor ctrlOut_reg
        IF reset= '0' and ctrlOut_detected='1' THEN
          ctrlIn_delayed = not ctrlIn_delayed
          nextState => second;
        ElSIF reset = '0' and ctrlOut_detected='0' THEN
          nextState => first;
        ELSE
          nextState => init;
        END IF
      WHEN second => --Wait for dataready signal
        IF DATAREADY = '1' THEN
          nextState => third;
        Else
          nextState => second;
        END IF
      WHEN third =>  --Wait for index signal, and convert hexadecimal to decimal
        IF Controlforindex ='1' THEN
          nextState => fourth;
        Else 
          nextState => third;
        END IF
      WHEN fourth => --wait for complete signal
        IF Controlforcomplete ='1' THEN
          nextState => fifth;
        Else
          nextState => fourth;
        END IF
      When fifth => --complete
        nextState => init; 

      When others =>
        nextState => init;
    END CASE;
          
  END process;

delay_CtrlOut: process(clk)     
  begin
    if rising_edge(clk) then
      ctrlOut_reg <= ctrlOut;
    END if;
  END process;

Control_signal :process (curstate)
  begin
    DATAREADY ='0'
    COUNTER_reset='0'
    compare_reset='0'
    COUNTER_done='0'
    SHIFTER_prefix_done='0'
    COMPARATOR_done='0'
    Controlforindex='0'
    controlforcomplete ='0'

    CASE curstate is
      WHEN init =>
        COUNTER_reset ='1'
        compare_reset ='1'
      When first =>
        ctrlOut ='1'
      When fifth =>
        reset='1'
    END CASE;
  END process;

STAGE_RESET ：process (curState)
  begin
    IF reset ='1' THEN
      curState <= INIT
    ELSIF rising_edge (clk) THEN
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
      COUNTER_done='1';--!
  END IF;
END process;  

----------------------------------------------------

SHIFTER_prefix:process(data) --存三位
BEGIN
IF rising_edge(clk) and ctrlIn_detected='1' THEN
    for i in 0 TO 2 loop
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
    IF data > prefix(3) THEN
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
