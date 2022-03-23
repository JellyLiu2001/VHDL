library ieee;
use ieee.std_logic_1164.all;
use work.common_pack.all;

  ENTITY dataConsume is
    port (
      clk: in std_logic;
      reset: in std_logic; -- synchronous reset
      start: in std_logic; --check rising edge, when 1, start
      numWords_bcd: in BCD_ARRAY_TYPE(2 downto 0);
      ctrlIn: in std_logic;
      ctrlOut: out std_logic;
      data: in std_logic_vector(7 downto 0);
      dataReady: out std_logic;
      byte: out std_logic_vector(7 downto 0);
      seqDone: out std_logic;
      maxIndex: out BCD_ARRAY_TYPE(2 downto 0);
      dataResults: out CHAR_ARRAY_TYPE(0 to 6) 
    );
  end dataConsume;
  architecture dataConsume_state OF dataConsume IS 
    type state_type IS(init, first);
    SIGNAL curstate,nextState:state_type;
    SIGNAL count:integer:=0;