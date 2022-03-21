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
  signal counterN: integer:=0;
  singal Asc: std_logic_vector(11 downto 0);
  SIGNAL EN, RST: bit;





begin   
    combi_nextState:process(curState,rxNow,rxData,txdone,dataready,seqDone)
    begin
       case curState is
        When init => 
              if  rxNow ='1' then
                  nextState <= Rxdata_ready;
              else 
                  nextState   <= IDLE;           ----------------waiting the Rx have a byte from the computer
              end if;
   
    
    
    
        ----Part 1  input Numwords to data processor.
        when Check =>----- check A/a
              if countN = 0 then              -------count is 0 check the first input from list
                if rxData = '01100001' or rxData ='01100101' then------check the first charactor is A/a
                      EN= '1'                   -------at this time counter ready to count the number of 0-9 charactors
                      nextState <= check2;     
                else 
                      
                      nextState <= init;            --------- not A/a ,back to the init to find the A and a occurs
                end if;
              else                              ----counter not 0, means it is not the first bit, check if it is a number
                   if rxData >= '00110000' and rxData <='00111001' then -----0-9  
                      if counter = 1 then
                        R(11 downto 8) =  RxData(3 downto 0);
                      elsif counter = 2 then
                        R( 7 downto 4) = RxData(3 downto 0);
                      elsif counter = 3 then
                        R(3 downto 0) = RxData (3 downto 0);
                      
                      end if; 
                      nextState <= transmit_receive;
              else                                        ----------not a number or a/A then counter should be reset.
                
                    RST = 1;
                    RxDone <= '1';
                    nextState <= transmit_receive;
              end if;
                
      
    
        when transmit_receive =>
              TxData <= RxData;
              TxNow <='1';
              nextState <= Check_Transmit;
        
        
        when check_Transmit=>
              TxNow <='0';
              RxDone <='0';
              
              
             
        
        when send =>
          TxNow <='0'
          TxDone<= '0'
          if counter = 3 then
            RST ='1'
            numWords_bcd(0) <= Q(3 downto 0)
            numWords_bcd(1) <= Q(7 downto 4)
            numWords_bcd(2) <= Q(11 downto 8) 
            nextState <= RECIEVE;
          else
            nextState <=IDLE;
          end if;
          
            
        
     
          
          
          
              
    
    
    
    
    combi_output:process(curState);
    begin
    -----set the default values to represent all initial condtions
    
    rxdone <= '0';
    start <= '0'
    txData <=
    
    ELSIF curState = CORRECT_INPUT then
    EN1 <= '1'
    
    
    
        end case;
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
  
     
         
         
  registerNum: PROCESS(clk,R1,R2)-----save users input get the 12bit BCD 
  Begin
    if clk'EVENT AND clk='1' THEN
      R2<=R1;
    end if ;
  end process;
         
      
      
            
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         