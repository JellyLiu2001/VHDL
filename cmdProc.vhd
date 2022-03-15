library ieee;
use ieee.std_logic_1164.all;
use work.common_pack.all;
-- library UNISIM;
-- use UNISIM.VCOMPONENTS.ALL;
-- use UNISIM.VPKG.ALL;

entity tb_dataGenConsume is 
end;



ENTITY cmdProc is
    port (
      clk:		in std_logic;
      reset:		in std_logic;
      rxnow:		in std_logic;---va;id
      rxData:			in std_logic_vector (7 downto 0);
      txData:			out std_logic_vector (7 downto 0);
      rxdone:		out std_logic;
      ovErr:		in std_logic;
      framErr:	in std_logic;
      txnow:		out std_logic;
      txdone:		in std_logic;
      start: out std_logic;
      numWords_bcd: out BCD_ARRAY_TYPE(2 downto 0);
      dataReady: in std_logic;
      byte: in std_logic_vector(7 downto 0);
      maxIndex: in BCD_ARRAY_TYPE(2 downto 0);
      dataResults: in CHAR_ARRAY_TYPE(0 to RESULT_BYTE_NUM-1);
      seqDone: in std_logic
    );
end component;


ARCHITECTURE cmdProc_interim OF cmdProc is
  type cmd_state is (INIT

 
 
 
 -------set signals
  signal curState, nextState: cmd_state;
  signal counterN: integer=0;
  singal Asc: std_logic_vector(11 downto 0);
  SIGNAL EN, RST: bit;





begin   
    combi_nextState:process(curState,rxNow,rxData,txdone,dataready,seqDone)
    begin
       case curState is
          When init =>                 ----------------waiting the Rx have a byte from the computer
          next
       end case;
    end process;
    
    
    
    
  when S4_NUM =>
    if rxData >= '00110000' and rxData <='00111001' then -----0-9
      nextState <= CORRECT_INPUT;
    else 
      nextState <= INIT;
    end if;
    
  
  
  
  
  
  
  
  
  when CORRECT_INPUT =>    
    if counterN <= 1 then
        Asc(11 downto 8) <= rxData (3 downto 0);------users input 8 bit ASCII get the last four bit and store it to the register
    elsif  counterN<=2 then
        Asc ( 7 downto 4) <= rxData (3 downto 0);
    elsif counterN <=3 then
        Asc (3 downto 0) <= rxData (3 downto 0);
    end if;
    
        
    else
    nextState < CORRECT_INPUT;
    end if;
    
    
    
    combi_output:process(curState);
    begin
    -----set the default values to represent all initial condtions
    
    rxdone <= '0';
    start <= '0'
    txData 
    
    ELSIF curState = CORRECT_INPUT then
    EN1 <= '1'
    
    
    
    
    
    
    end process;
    
    
    
 -------sequential proecess to define state machine
    seq_state : PROCESS(clk, reset)
    BEGIN
      if reset ='1' then
        curState <= INIT;
      elsif clk'EVENT AND clk = '1' then
        curState <= nextState;
      end if;
    end process;
 
 








------other functions

   
          
  counter_N: PROCESS(reset, clk) 

  BEGIN 

    IF RST_C1 = '1' THEN  -- active high reset 

        counterN <= 0; 

    ELSIF clk'EVENT and clk='1' THEN 

        IF EN_1 = '1' THEN              

           counterN <= onecounter + 1; 

        END IF; 

    END IF; 

  END PROCESS; 
  
     
         
         
  registerNum: PROCESS(clk,)-----save users input get the 12bit BCD 
  Begin
    if clk'EVENT AND clk='1' THEN
      
            
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         