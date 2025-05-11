LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Generates a "wailing siren" sound by instancing a "tone" module and modulating
-- the pitch of the tone. The pitch is increased until it reaches hi_pitch and then
-- decreased until it reaches lo_pitch and then increased again, etc.
ENTITY wail IS
	PORT (
		note : in std_logic_vector(3 downto 0);
		playing : in std_logic;
		wclk : IN STD_LOGIC; -- wailing clock (47.6 Hz)
		audio_clk : IN STD_LOGIC; -- audio sampling clock (48.8 kHz)
	audio_data : OUT SIGNED (15 DOWNTO 0)); -- output audio sequence (wailing tone)
END wail;

ARCHITECTURE Behavioral OF wail IS
	COMPONENT tone IS
		PORT (
			clk : IN STD_LOGIC;
			pitch : IN UNSIGNED (13 DOWNTO 0);
			data : OUT SIGNED (15 DOWNTO 0);
			playing : in std_logic
		);
	END COMPONENT;
	
	-- speaker constants
    constant Clow : UNSIGNED (13 DOWNTO 0) := to_unsigned (351, 14);
    constant D : UNSIGNED (13 DOWNTO 0) := to_unsigned (394, 14);
    constant E : UNSIGNED (13 DOWNTO 0) := to_unsigned (443, 14);
    constant F : UNSIGNED (13 DOWNTO 0) := to_unsigned (469, 14);
    constant G : UNSIGNED (13 DOWNTO 0) := to_unsigned (526, 14);
    constant A : UNSIGNED (13 DOWNTO 0) := to_unsigned (591, 14);
    constant B : UNSIGNED (13 DOWNTO 0) := to_unsigned (663, 14);
    constant Chigh : UNSIGNED (13 DOWNTO 0) := to_unsigned (702, 14);
                                                            
	
	SIGNAL curr_pitch : UNSIGNED (13 DOWNTO 0); -- current wailing pitch
BEGIN
	-- this process modulates the current pitch. It keep a variable updn to indicate
	-- whether tone is currently rising or falling. Each wclk period it increments
	-- (or decrements) the current pitch by wspeed. When it reaches hi_pitch, it
	-- starts counting down. When it reaches lo_pitch, it starts counting up
	
	with note select
	   curr_pitch <= 
	   Clow when x"0",
	   D when x"1",
	   E when x"2",
	   F when x"3",
	   G when x"4",
	   A when x"5",
	   B when x"6",
	   Chigh when x"7",
	   to_unsigned(0,14) when others;
	
	tgen : tone
	PORT MAP(
		clk => audio_clk, -- instance a tone module
		pitch => curr_pitch, -- use curr-pitch to modulate tone
		data => audio_data,
		playing => playing
		);
END Behavioral;
