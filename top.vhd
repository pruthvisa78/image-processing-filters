--Top module for image filtering block
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
entity top_module is
   port(clk,rst,start,g_m:in std_logic;     -- g_m enable signal for gaussian or median filter block
        done: out std_logic; 
        done_data : out std_logic ;
        fil_data: out std_logic_vector(7 downto 0)
        );
end top_module;

architecture top of top_module is
component mul_add is                                    -- mul_add is the gaussian filter block
  Port (clk,rst,start : in std_logic;
        dout: out std_logic_vector(7 downto 0);
        addr: in std_logic_vector(10 downto 0);
        done: out std_logic );
end component;
component blk_mem_gen_filterd IS                         -- BRAM for storing the filtered image pixel values
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
  end component;
component Sorting is                                       -- median filter block component
    Port ( mem_addr: in STD_LOGIC_VECTOR ( 10 downto 0 );
           clk,start,reset : in STD_LOGIC;
           median_out : out STD_LOGIC_VECTOR (7 downto 0);
           done : out std_logic);
end component;

signal data_g,data_m,dataout : std_logic_vector(7 downto 0);
signal datain : std_logic_vector(7 downto 0);
signal start_med,done_m,start_g,done_g : std_logic;          -- internal start_g,done_g,start_med,done_m are control signal for starting and completeion of the gaussian and median filter block
signal wea : std_logic_vector(0 downto 0);                   -- write enable for writing the data toBRAM 
signal done_int : std_logic_vector(1 downto 0);              -- done_int signals the completion of processing of one pixel 

signal count: integer; 
signal addr_count : std_logic_vector(10 downto 0):="00000000000";    -- addr_count holds the address of the data to be processed
TYPE STATE_TYPE IS (s0, s1,s2);       
   SIGNAL state   : STATE_TYPE;
begin
DUT1:blk_mem_gen_filterd port map(clka=>clk,wea=>wea,addra=>addr_count,dina=>datain,douta=>dataout);
DUT2:Sorting port map(clk=>clk,start=>start_med,reset=>rst,median_out=>data_m,mem_addr=>addr_count,done=>done_m);
DUT3: mul_add port map(clk=>clk,start=>start_g,rst=>rst,dout=>data_g,addr=>addr_count,done=>done_g);
 done_int<=(done_m & done_g);                        -- wea is configuerd to write the data after done_int goes high signalling the operation has been completed 
 with done_int select
 wea<= "1" when "10",
       "1" when "01",
       "0" when others;  
 with g_m select                                      --g_m switch for enabling gaussian or median filter block
 datain<= data_m when '1',
          data_g when '0',
          "00000000" when others;  
with ena select 
    fil_data <= data_m when '1',
                data_g when '0',
                x"00" when others;
done_data <= done_g or done_m;
process(clk)
begin
    if(clk'event and clk = '1') then
        if(rst ='1') then
           state<=s0;
           addr_count<="00000100011";
           count<=1;
           start_med<='0';
           done<='0';
        else
        case state is
         when s0=>  if(start='1' and addr_count<1121) then
                       state<=s1;
                    else
                       start_g<='0';
                       start_med<='0';
                       state<=s0;
                    end if;
         when s1=> state<=s2; 
                  case g_m is
                     when '1'=> 
                         start_med<='1';
                         start_g<='0';
                     when '0'=>
                         start_med<='0';
                         start_g<='1'; 
                     when others=> 
                          start_med<='0';
                          start_g<='0'; 
                   end case; 
         when s2=> case g_m is
              when '1'=>      
                 if(addr_count<=1120) then
                    if(done_m='1') then
                      start_med<='1';
                      if(count=32) then
                         addr_count<=addr_count+3;
                         count<=1;
                      else
                         addr_count<=addr_count+1;
                         count<=count+1;
                      end if;
                    else
                      start_med<='0';
                    end if;
                  else
                    state<=s0;
                    done<='1';
                  end if;
              when '0'=> 
                  if(addr_count<=1120) then
                    if(done_g='1') then
                      start_g<='1';
                      if(count=32) then
                         addr_count<=addr_count+3;
                         count<=1;
                      else
                         addr_count<=addr_count+1;
                         count<=count+1;
                      end if;
                    else
                      start_g<='0';
                    end if;
                  else
                    state<=s0;
                    done<='1';
                  end if;
               when others=> state<=s0;
                end case;      
         end case;
    end if;
  end if;
end process;
end top;
