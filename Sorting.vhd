-- Median filter block to perform median filtering
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;
entity Sorting is
    Port ( mem_addr: in STD_LOGIC_VECTOR ( 10 downto 0 );          --mem_addr is the address of the data on which median filtering has to be performed
           clk,start,reset : in STD_LOGIC;
           median_out : out STD_LOGIC_VECTOR (7 downto 0);
           done : out std_logic);
end Sorting;

architecture Behavioral of Sorting is
component blk_mem_gen_0 IS                                         -- BRAM which holds the test image 
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END component;
TYPE STATE_TYPE1 IS (s0, s1,s2,s3,s4,s5,s6,s7,s8,s9,s10);           -- states to load the 9 pixel data in a array memory
   SIGNAL load_state   : STATE_TYPE1;
TYPE STATE_TYPE2 IS (s0, s1,s2,s3);                                 -- states to sort the stored data
   SIGNAL state_sort   : STATE_TYPE2;
TYPE STATE_TYPE3 IS (s0, s1,s2,s3);                                 -- final control path state machine to control the operation
   SIGNAL state   : STATE_TYPE3;
signal memin:std_logic_vector(7 downto 0):="00000000";
signal addr:std_logic_vector(10 downto 0);
signal memout:std_logic_vector(7 downto 0);
signal count_freq_div: integer:=0;  
signal count,pivot: integer;  
signal sort_count: integer; 
signal start_int,sort_start,scan,load_done: std_logic;
signal we: std_logic_vector(0 to 0):="0";
signal enable_read,sort_done :std_logic:='0';
type data_array is array (0 to 8 ) of std_logic_vector (7 downto 0);
signal data: data_array :=(                                                    -- variable to store the 9 pixel data
    "00000000", "00000000", "00000000", "00000000", "00000000", "00000000","00000000","00000000","00000000");
begin
DUT : blk_mem_gen_0 port map(clka=>clk,addra=>addr,douta=>memout,dina=>memin,wea =>we);
process(clk)           
 begin                                                                     --enable_read siganl generated every 2 cycle to perform read operation as the BRAM itself has 2 cycle delay of accessing the data   
  if(clk'event and clk='1') then
     if(start_int='1') then
     count_freq_div <=count_freq_div+1;
     if (count_freq_div = 1) then
        count_freq_div <= 0;
     end if;
     end if;
  end if;
end process;
enable_read <= '1' when count_freq_div=1 else '0'; 
process (clk)                                                   -- process block to generate the adddress of required pixel elements for performing the opeartion
   begin
     if(clk'event and clk = '1') then
        if (start_int = '0') then
           load_state <= s0;
           load_done<='0';
           count<=0;
        else
         if(enable_read='1' and start_int='1') then
           case load_state is
            when s0=>
                  load_state <= s1;
                  addr<=mem_addr-35; 
            when s1=>
                  addr<=mem_addr-34; 
                  load_state <= s2;
            when s2=>
                  addr<=mem_addr-33; 
                  load_state <= s3;
                  count<=count+1;
            when s3=>
                  addr<=mem_addr-1; 
                  load_state <= s4;
                  count<=count+1;
            when s4=>
                  addr<=mem_addr; 
                  load_state <= s5;
                  count<=count+1;
            when s5=>
                  addr<=mem_addr+1; 
                  load_state <= s6;
                  count<=count+1;
            when s6=>
                  addr<=mem_addr+33; 
                  load_state <= s7; 
                  count<=count+1;  
            when s7=>
                  addr<=mem_addr+34; 
                  load_state <= s8; 
                  count<=count+1;
            when s8=>
                  addr<=mem_addr+35; 
                  load_state <= s9; 
                  count<=count+1;
            when s9=>
                   load_state <= s10;
                   count<=count+1;
            when s10=>
                  load_state <= s0;
                  load_done<='1';
          end case;
        end if;
      end if;
    end if;
 end process;
 process (clk)                                                   -- control state for implementing thesorting algorithm 
   begin
     if(clk'event and clk = '1') then
       if(sort_start='0') then
         state_sort<=s0;
         sort_done<='0';
       else
        if(sort_start='1') then
         case state_sort is
            when s0=>
                  state_sort <= s1;
            when s1=>
                  state_sort <= s2;
            when s2=>
                  if(scan='1') then
                     state_sort <= s2;
                  else
                    state_sort<= s3;
                  end if;
            when s3=>
                if(pivot=8) then
                   state_sort <= s0;
                   sort_done<='1';
                   median_out <= data(4);
                else 
                   state_sort <= s2;
                end if; 
          end case;
         end if;
       end if;
     end if;
 end process;
 process (clk)                                                     --data path for sorting process
   begin
     if(clk'event and clk = '1') then
      if(enable_read='1' and start_int='1') then
        data(count)<=memout;
      else
        if(sort_start='1') then
         case (state_sort) is
          when s0=>
          when s1=>
            pivot<=0;
            scan<='1';
            sort_count<=1;
          when s2=>
            if(sort_count<9) then
               if(data(sort_count)<data(pivot)) then
                  data(pivot)<=data(sort_count);
                  data(sort_count)<=data(pivot);
                  sort_count<=sort_count+1;
               else
                  sort_count<=sort_count+1;
               end if;
            else 
               scan<='0';
               end if;
          when s3=>
            scan<='1';
            pivot<=pivot+1;
            sort_count<=pivot+2;
       end case;
       end if;
     end if;
     end if;
 end process;              
 process (clk)                                        -- Control path state machine implementation for median filter block
   begin
     if(clk'event and clk = '1') then
       if(reset='1') then
            state<=s0;
       else
           case state is
            when s0=>
                  start_int<='0';
                  sort_start<='0';
                  done<='0';
                  if(start='1' and mem_addr<1121) then
                      state <= s1;
                  else
                      state <= s0;
                  end if;
            when s1=>
                  start_int<='1';
                  sort_start<='0';
                  state <= s2;
            when s2=>
                  if(load_done='1') then
                    state<=s3;
                    start_int<='0';
                    sort_start<='1';
                  else 
                    state<=s2;
                  end if;   
            when s3=>
                  if(sort_done='1') then
                    state<=s0;
                    sort_start<='0';
                    done<='1';
                  else 
                    state<=s3;
                  end if;   
            end case;
           end if;
         end if;
  end process;
end Behavioral;
