library ieee;
use ieee.std_logic_1164.all;
use work.common_pack.all;

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
      dataResults: out CHAR_ARRAY_TYPE(0 to 6)  -- 7*8 (-3:peak:3)
    ); 
  END dataConsume;
architecture dataConsume_state OF dataConsume IS 
  TYPE state_type IS(init, first);
  SIGNAL curState, nextState:state_type;
  SIGNAL count:integer:=0;
  SIGNAL ctrlIn_delayed, ctrlIn_detected:std_logic;
  SIGNAL Maxnum:std_logic;
  SIGNAL COUNTER : integer:=0;
BEGIN 

  combi_nextState:process(curState, X)
  BEGIN case curState IS 
  when start =>1
    when INIT=>


----------------------------------------------------
COUNTER_process:process(DATA)--To calculate the index and compare the peak value. 
BEGIN
  if COUNTER_RESET='1' THEN
      COUNTER<=0;
  else 
      COUNTER = COUNTER + 1;
  end if;
END PROCESS;  
----------------------------------------------------
shifter_process:process(DATA) -- To store the number(bcd). 
BEGIN

END PROCESS;