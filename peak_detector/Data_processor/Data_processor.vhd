library ieee;
use ieee.std_logic_1164.all;
use work.common_pack.all;

  ENTITY dataConsume is
    port (
      clk: in std_logic;
      reset: in std_logic; -- synchronous reset
      start: in bit; --check rising edge, when 1, start
      numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);-- 3bit annn
      ctrlIn: in std_logic;--握手
      ctrlOut: out std_logic;--握手
      data: in std_logic_vector(7 downto 0); 
      dataReady: out std_logic;
      byte: out std_logic_vector(7 downto 0);
      seqDone: out std_logic;
      maxIndex: out BCD_ARRAY_TYPE(2 downto 0);--最多三位数
      dataResults: out CHAR_ARRAY_TYPE(0 to 6) 
    );
  end dataConsume;
architecture dataConsume_state OF dataConsume IS 
  type state_type IS(init, first);
  SIGNAL curState,nextState:state_type;
  SIGNAL count:integer:=0;
  SIGNAL ctrlIn_delayed, ctrlIn_detected:std_logic;
  SIGNAL Maxnum:std_logic;
  SIGNAL 
BEGIN 

  combi_nextState:process(curState, X)
  BEGIN case curState IS 
  when start =>1
    when INIT=>


----------------------------------------------------
counter_process:process()--to calculate the index and compare the peak value. 
begin
----------------------------------------------------
shifter_process:process()
begin
  