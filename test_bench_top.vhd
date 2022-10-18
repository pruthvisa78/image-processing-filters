library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
use STD.textio.all;
use ieee.std_logic_textio.all;
entity test_bench_top is
end test_bench_top;

architecture tb of test_bench_top is
component top_module is
   port(clk,rst,start,g_m:in std_logic;
        done:out std_logic;
        done_data : out std_logic; 
        fil_data : out std_logic_vector(7 downto 0)
        );
end component;
constant period: time:= 10 ns;
signal clk,rst,start,ena,done,done_data: std_logic;
signal fil_data:std_logic_vector(7 downto 0);
signal addr_count : integer range 0 to 1023;
signal addr_count : std_logic_vector(9 downto 0);
type data_array is array (0 to 1023 ) of std_logic_vector (7 downto 0);
signal str_mem: data_array;
-----------------------------------------------------------------
file filtered_img : text;
------------------------------------------------------------------
begin
uut: top_module port map(clk => clk, rst=> rst, start => start, g_m => ena, done => done,fil_data => fil_data,done_data => done_data);
process
 begin
  wait for 100 ns;
 cloop:loop
 clk<='0';
 wait for (period/2);
 clk<='1';
 wait for (period/2);
 
 end loop;
 
end process;

process
begin

wait for 100 ns;
rst <= '1'; start <= '0'; ena <= '0'; 
wait for 2*period;
rst <= '0'; start <= '1'; ena <= '0'; 
wait for 140 us;
rst <= '1'; start <= '0'; ena <= '1'; 
wait for 2*period;
rst <= '0'; start <= '1'; ena <= '1'; 
wait for 1ms;
wait;
end process;
process(clk)
begin
    if(rising_edge(clk))then
        if(rst = '1') then
            addr_count <= "0000000000";
        elsif(done_data = '1')then
            str_mem(conv_integer(addr_count)) <= fil_data;
            addr_count <= addr_count+1;
       end if;
     end if;
end process;
process   
   variable fstatus       :file_open_status;
   variable file_line     :line;
begin
    wait until done = '1';
        file_open(fstatus, filtered_img, "filtered_image.txt", write_mode);
        for i in 0 to 1023 loop
            write(file_line, conv_integer(str_mem(i)), left, 3);
            writeline(filtered_img, file_line);
        end loop;      
        file_close(filtered_img);   
    wait;
end process;
end tb;
