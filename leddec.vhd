LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;


ENTITY leddec IS
	PORT (
		dig : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
		data : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
		song : IN integer;
		title : in std_logic;
		displaying : in std_logic
	);
END leddec;

ARCHITECTURE Behavioral OF leddec IS

    signal titleData : std_logic_vector(20 downto 0);
    signal titleSeg, noteSeg : std_logic_vector(6 downto 0);

BEGIN
    
    -- generates the right segments for the song title
    with song select
    titleData <= 
    "100100001100011100000" when 0, -- H C b  - hot cross buns
    "100100011100011110001" when 1, -- H L L  - mary had a little lamb
    "111100011100010100100" when 2, -- t L S - twinkle twinkle little star
    "111101010001001100000" when 3, -- r Y b -- row row row your boat
    "100010000010001000100" when -1, -- Y A Y  - YAY
    (others => '0') when others;

    -- isolates the correct digit of the tempData
    with dig select
    titleSeg <=
    titleData(6 downto 0) when "000",
    titleData(13 downto 7) when "001",
    titleData(20 downto 14) when "010",
    "1111111" when others;

	-- Turn on segments corresponding to 4-bit data word
	noteSeg <= "1110010" WHEN data = "0000" ELSE -- C = 0
	       "1000010" WHEN data = "0001" ELSE -- D = 1
	       "0110000" WHEN data = "0010" ELSE -- E = 2 
	       "0111000" WHEN data = "0011" ELSE -- F = 3
	       "0000100" WHEN data = "0100" ELSE -- G = 4
	       "0001000" WHEN data = "0101" ELSE -- A = 5
	       "1100000" WHEN data = "0110" ELSE -- B = 6
	       "0110001" WHEN data = "0111" ELSE -- C = 7      
	       "1111111";
	
	with title select
	seg <= noteSeg when '0',
	titleSeg when others;
	
	-- Turn on anode of 7-segment display addressed by 3-bit digit selector dig
	-- Only need first 3 digits
	anode <= "11111110" WHEN displaying = '1' and dig = "000" ELSE -- 0
	         "11111101" WHEN displaying = '1' and dig = "001" and title = '1' ELSE -- 1
	         "11111011" WHEN displaying = '1' and dig = "010" and title = '1' ELSE -- 2
	         "11111111";
END Behavioral;
