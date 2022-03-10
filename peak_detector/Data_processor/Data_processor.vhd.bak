library ieee;
use ieee.std_logic_1164.all;

entity data_processor is
	port (
		clk: in std_logic; --clock
		reset: in std_logic; --reset
		ctrlOut: in std_logic; --ctrl_2
		ctrlIn: out std_logic; --ctrl_1
		data: in std_logic_vector(7 downto 0); --data(8bit) 16 to binary. 
		start: in std_logic; --start
		numWords: in std_logic_vector(12 downto 0); --numWords(12bit)(3*4)
		dataReady: out; --dataReady
		byte: out std_logic_vector(7 downto 0); --byte(8bit)
		maxIndax: out std_logic_vector(11 downto 0); --maxIndex(12bit)(3*4)
		dataResults: out std_logic_vector(55 downto 0); --dataResults(56bit)(7*8)
		seqDone: out std_logic --seqDone
	);
end dataGen;