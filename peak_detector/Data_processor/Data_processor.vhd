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
  end dataConsume;
architecture dataConsume_state OF dataConsume IS 
  type state_type IS(init, first);
  SIGNAL curState,nextState:state_type;
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
counter_process:process()--to calculate the index and compare the peak value. 
BEGIN
  IF reset = '0' THEN -- active high reset
    COUNTER0 <= 0;
  ELSIF clk' EVENT and clk='1' THEN
    IF reset0 = '0' THEN
      IF enable0 = '1' THEN -- enable
        COUNTER0 <= COUNTER0 + 1 ;
      END IF;
    ELSE
      COUNTER0 <= 0;
    END IF;
  END IF;
END PROCESS;  
----------------------------------------------------
shifter_process:process()
begin
