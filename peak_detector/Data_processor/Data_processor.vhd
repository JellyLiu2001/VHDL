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
  TYPE state_type IS(init, first, second, third, fourth, fifth);
  SIGNAL init,first,second,third,fourth,fifth:state_type;--状态
  SIGNAL counter_reset,compare_reset:std_logic;  --清空
<<<<<<< HEAD
  SIGNAL ctrlOut_detected, ctrlIn_detected,ctrlOut_reg:std_logic;
  SIGNAL data:std_vector(7 downto 0);--传来的数据
=======
  SIGNAL ctrlIn_delayed, ctrlIn_detected,ctrlOut_reg:std_logic;
>>>>>>> 528ca583c1f52c2315f52c672cd55227f3b3920f
  SIGNAL peak:std_logic;--最大数
  SIGNAL MAXindex_BCD:BCD_ARRAY_TYPE(2 downto 0);
  SIGNAL COUNTER : integer:=0;--计数器
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
          
          
END PROCESS;

delay_CtrlOut: process(clk)     
  begin
    if rising_edge(clk) then
      ctrlOut_reg <= ctrlOut;
    end if;
  end process;

Control_signal :process (curstate)
  begin
    reset = '0'
    start = '0'
    DATAREADY ='0'
    index ='0'
    index_peak='0'
    peak ='0'
    ctrlOut ='0'
    counter_reset='0'
    compare_reset='0'
    Controlforindex='0'
    controlforcomplete ='0'

    CASE curstate is
      WHEN init =>
        counter_reset ='1'
        compare_reset ='1'
      When first =>
        ctrlOut ='1'
      When fifth =>
        reset='1'
      
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

SHIFTER_prefix:process(data) --存三位
BEGIN
IF rising_edge(clk) and ctrlIn_detected='1' THEN
    for i in 0 TO 2 loop
      prefix(i)<=prefix(i+1);
    end loop;
      prefix(3)<=data;
END PROCESS;

----------------------------------------------------

COMPARATOR_process:process(clk,counter)--比较
BEGIN
IF compare_reset='1' or curstate= start THEN--清除(curstate 应该是init)
  index_peak<="0";---
END IF;

ELSIF rising_edge(clk) THEN
    IF data > prefix(3) THEN
      index_peak<=counter;
    END IF;

END IF;
END PROCESS;

----------------------------------------------------

SHIFTER_suffix:process(counter,index_peak) --存后四位
BEGIN
if counter-index_peak=0 then
  suffix(0)<=data;
elsif counter-index_peak=1 then
  suffix(1)<=data;
elsif counter-index_peak=2 then
  suffix(2)<=data;
elsif counter-index_peak=3 then
  suffix(3)<=data;
  finnal_result(0 to 2)<=prefix;--全部的7位
  finnal_result(3 to 6)<=suffix;
end if;
END PROCESS;

----------------------------------------------------

maxindex:process(index_peak) --integer输出bcd
BEGIN
MAXindex_BCD(2)<=std_logic_vector(to_unsigned(index_peak/100 mod 10,numWords_bcd(0)'length));
MAXindex_BCD(1)<=std_logic_vector(to_unsigned(index_peak/10 mod 10,numWords_bcd(0)'length));
MAXindex_BCD(0)<=std_logic_vector(to_unsigned(index_peak/1 mod 10,numWords_bcd(0)'length));
END PROCESS;

----------------------------------------------------