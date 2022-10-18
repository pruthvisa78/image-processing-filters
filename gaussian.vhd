library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;
entity mul_add is
  Port (clk,rst,start : in std_logic;
        dout: out std_logic_vector(7 downto 0);
        addr: in std_logic_vector(10 downto 0);
        done: out std_logic );
end mul_add;

architecture mdad of mul_add is
component blk_mem_gen_0 IS
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
  end component;
signal acc : std_logic_vector(11 downto 0);
signal memcounter,counter : std_logic_vector(3 downto 0);
signal weight : std_logic_vector(2 downto 0);
signal ps,ns:std_logic_vector(1 downto 0);
signal acc_comp_mem,acc_comp: std_logic;
signal memout : std_logic_vector(7 downto 0);
signal memin : std_logic_vector(7 downto 0):="00000000";
signal we : std_logic_vector(0 downto 0):="0";
signal starta,startb : std_logic;
signal mem_addr : std_logic_vector(10 downto 0);
signal memps,memns : std_logic_vector(1 downto 0);
begin
DUT : blk_mem_gen_0 port map(clka=>clk,addra=>mem_addr,douta=>memout,dina=>memin,wea =>we);
--mem state
memaddrp:process(clk)
begin
    if(rising_edge(clk)) then
        if(rst = '1') then
            memps <= "00";
        else
            memps<= memns;
        end if;
    end if;
end process;
--mem ns logic
memnsl:process(start,memps,acc_comp_mem)
begin
    case memps is
        when "00" =>
            if(start = '1') then
                memns <= "01";
            else
                memns <= "00";
            end if;
       when "01" =>
            if(acc_comp_mem = '1') then
                memns <= "10";
            else
                memns <= "01";
            end if;
       when "10" =>
            memns <= "00";
       when others =>
            memns <= "00";       
    end case;
end process;
p1:process(clk)
begin
    if(rising_edge(clk)) then
        if(rst = '1' or memps = "00") then
            memcounter <= (others => '0');
        elsif(memcounter = "1000") then
            memcounter <= (others => '0');
        elsif( memps = "01") then
            memcounter <= memcounter + 1;
        end if;
     end if;
end process;
acc_comp_mem <= memcounter(3) and (not memcounter(2)) and (not memcounter(1)) and (not memcounter(0));
-- addr selection
p3:process(memcounter,addr)
begin
    case memcounter is
        when "0000" =>
            mem_addr <= addr - 35;
        when "0001" =>
            mem_addr <= addr - 34;
        when "0010" =>
            mem_addr <= addr - 33;
        when "0011" =>
            mem_addr <= addr - 1;
        when "0100" =>
            mem_addr <= addr;
        when "0101" =>
            mem_addr <= addr + 1;
        when "0110" =>
            mem_addr <= addr + 33;
        when "0111" =>
            mem_addr <= addr + 34;
        when "1000" =>
            mem_addr <= addr + 35;                 
        when others =>
            mem_addr <= (others => '0');    
    end case;
end process;
--- start delay
startdel:process(clk)
begin
    if(rising_edge(clk)) then
        starta <= start;
        startb <= starta;
    end if;
end process;

p2:process(clk)
begin
    if(rising_edge(clk)) then
        if(ps <= "00") then
            acc <= x"008";
        elsif( ps = "01") then
            acc <= weight*memout + acc;
        end if;
     end if;
end process;
pr:process(clk)
begin
    if(rising_edge(clk)) then
        if(rst = '1' or ps = "00") then
            counter <= (others => '0');
        elsif(counter = "1000") then
            counter <= (others => '0');
        elsif( ps = "01") then
            counter <= counter + 1;
        end if;
     end if;
end process;
acc_comp <= counter(3) and (not counter(2)) and (not counter(1)) and (not counter(0));
-- weight selection
pr3:process(counter)
begin
    case counter is
        when "0000" =>
            weight <= "001";
        when "0001" =>
            weight <= "010";
        when "0010" =>
            weight <= "001";
        when "0011" =>
            weight <= "010";
        when "0100" =>
            weight <= "100";
        when "0101" =>
            weight <= "010";
        when "0110" =>
            weight <= "001";
        when "0111" =>
            weight <= "010";
        when "1000" =>
            weight <= "001";                 
        when others =>
            weight <= "000";    
    end case;
end process;
-- state machine
p4:process(clk)
begin
    if(rising_edge(clk)) then
        if(rst = '1') then
            ps <= "00";
        else
            ps<= ns;
        end if;
    end if;
end process;
-- next state and output logic
p5:process(startb,ps,acc_comp,addr)
begin
    case ps is
        when "00" =>
            done <= '0';
            if(startb = '1' and addr<1121) then
                ns <= "01";
            else
                ns <= "00";
            end if;
       when "01" =>
            done <= '0';
            if(acc_comp = '1') then
                ns <= "10";
            else
                ns <= "01";
            end if;
       when "10" =>
            done <= '1';
            ns <= "00";
       when others =>
            done <= '0';
            ns <= "00";        
    end case;
end process;
dout <= acc(11 downto 4);
end mdad;
