library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;


-- c : 0
-- d : 1
-- e : 2
-- f : 3
-- g : 4
-- a : 5
-- b : 6
-- c : 7

entity songs is
    port(
        note : out std_logic_vector(3 downto 0);
        index : in integer;
        songChoice : in integer;
        length : out integer
    );
end songs;

architecture Behavioral of songs is

constant HCBlen : integer := 16;
type HCBsong is array (0 to HCBlen) of std_logic_vector(3 downto 0);

constant HCB : HCBsong := (x"6", x"5", x"4", x"6", x"5", x"4",
                        x"4", x"4", x"4", x"4",
                        x"5", x"5", x"5", x"5",
                        x"6", x"5", x"4"); -- hot cross buns

constant MHLLlen : integer := 12;
type MHLLsong is array (0 to MHLLlen) of std_logic_vector(3 downto 0);

constant MHLL : MHLLsong := (x"2", x"1", x"0", x"1", 
                            x"2", x"2", x"2", 
                            x"1", x"1", x"1", 
                            x"2", x"4", x"4");

constant TTLSlen: integer := 13;

type TTLSsong is array (0 to TTLSlen) of std_logic_vector(3 downto 0);
constant TTLS : TTLSsong := (x"0", x"0", x"4", x"4",
                        x"5", x"5", x"4",
                        x"3", x"3", x"2", x"2",
                        x"1", x"1", x"0");
                   
constant RRRYBlen : integer := 26;

type RRRYBsong is array (0 to RRRYBlen) of std_logic_vector(3 downto 0);
constant RRRYB : RRRYBsong := (x"0", x"0", x"0", x"1", x"2",
                              x"2", x"1", x"2", x"3", x"4",
                              x"7", x"7", x"7", x"4", x"4", x"4",
                              x"2", x"2", x"2", x"0", x"0", x"0",
                              x"4", x"3", x"2", x"1", x"0");


begin

with songChoice select
    note <= HCB(index) when 0,
    MHLL(index) when 1,
    TTLS(index) when 2,
    RRRYB(index) when 3,
    "1111" when others;
with songChoice select
    length <= HCBlen when 0,
    MHLLlen when 1,
    TTLSlen when 2,
    RRRYBlen when 3,
    0 when others;

end Behavioral;
