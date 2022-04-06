library ieee;
use ieee.std_logic_1164.all;
use work.common_pack.all;
use ieee.numeric_std.all;

  ENTITY dataConsume is
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
  TYPE state_type IS(init, first);
  SIGNAL init,first:state_type;--状态
  SIGNAL counter_reset,compare_reset:std_logic;  --清空
  SIGNAL ctrlIn_delayed, ctrlIn_detected,ctrlOut_reg:std_logic;
  SIGNAL data:std_vector(7 downto 0);--传来的数据
  SIGNAL peak:std_logic;--最大数
  SIGNAL COUNTER : integer:=0;--计数器
  SIGNAL prefix:char_array_type(0 TO 3);--记peak前三位
  SIGNAL finnal_result:char_array_type(0 TO 7);--记全部
  SIGNAL index, index_peak:integer;--记位置
  SIGNAL DATAREADY : std_logic;
  SIGNAL Controlforindex, Controlforcomplete : std_logic
BEGIN 

combi_nextState:process(curState, X)
  BEGIN 
    CASE curState IS 
      WHEN init => -- Wait for start signal
        IF start = 1 THEN
          nextState => first;
        ELSE
          nextState => init;
        END IF
      WHEN first => --Wait for ctrl1 and ctrl2
        IF ctrlIn_detected = 1 THEN
          nextState => second;
        Else 
          nextState => first;
        END IF
      WHEN second => --Wait for dataready signal
        IF DATAREADY =1 THEN
          nextState => third;
        Else
          nextState => second;
        END IF
      WHEN third =>  --Wait for index signal, and convert hexadecimal to binomial
        IF Controlforindex =1 THEN
          nextState => fourth;
        Else 
          nextState => third;
        END IF
      WHEN fourth => --wait for complete signal
        IF Controlforcomplete =1 THEN
          nextState => fifth;
        Else
          nextState => fourth;
        END IF
      When fifth => --complete
          nextState => init;
END PROCESS;

HexaToBinomial_process:process(DATA)
BEGIN
END PROCESS;

----------------------------------------------------

COUNTER_process:process(data,reset)--TO calculate the index and compare the peak value. 
BEGIN
  IF counter_reset='1' THEN
      COUNTER<=0;
  ELSIF rising_edge(clk) THEN
      COUNTER = COUNTER + 1;
  END IF;
END PROCESS;  

----------------------------------------------------

SHIFTER_process:process(data) --存三位
BEGIN
IF rising_edge(clk) and ctrlIn_detected='1' THEN
    for i in 0 TO 2 loop
      prefix(i)<=prefix(i+1);
    end loop;
      prefix(3)<=data;
END PROCESS;

----------------------------------------------------

COMPARATOR_process:process(clk,counter)
BEGIN
IF compare_reset='1' or curstate= start THEN--清除
  index_peak<="0";---
END IF;

ELSIF rising_edge(clk) THEN

  IF peak(7)='1' and data(7)='1' THEN
    IF data > prefix(3) THEN
      finnal_result(0 TO 3)<=prefix;
      index_peak<=counter;
    END IF;

  ELSIF peak(7)='0' and data(7)='1' THEN
    peak<=peak;
  END IF;
  
  ELSIF peak(7)='0' and data(7)='0' THEN
    IF data > finnal_result(3) THEN
      finnal_result(0 TO 3)<=prefix;
      index_peak<=counter;
    END IF;

  ELSE 
  finnal_result(0 TO 3)<=prefix;
    index_peak<=counter;

  END IF;
END IF;
END PROCESS;