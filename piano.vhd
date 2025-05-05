library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity piano is
    port(
        clk_100MHz : in std_logic;
        BTNU : in std_logic;
        BTND : in std_logic;
        BTNC : in std_logic;
        anode : out std_logic_vector(7 downto 0);
        seg : out std_logic_vector(6 downto 0);
        KB_col : OUT STD_LOGIC_VECTOR (4 DOWNTO 1); -- keypad column pins
	    KB_row : IN STD_LOGIC_VECTOR (4 DOWNTO 1); -- keypad row pins
	    dac_MCLK : OUT STD_LOGIC; -- outputs to PMODI2L DAC
		dac_LRCK : OUT STD_LOGIC;
		dac_SCLK : OUT STD_LOGIC;
		dac_SDIN : OUT STD_LOGIC
    );
end piano;

architecture Behavioral of piano is

component leddec is
    PORT (
		dig : IN STD_LOGIC_VECTOR (2 DOWNTO 0);
		data : IN STD_LOGIC_VECTOR (3 DOWNTO 0);
		anode : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		seg : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);
		song : IN integer;
		title : in std_logic
	);
end component;
	
component songs is
    port(
        note : out std_logic_vector(3 downto 0);
        index : in integer;
        songChoice : in integer;
        length : out integer
    );
end component;
	
component keypad IS
	PORT (
		samp_ck : IN STD_LOGIC; -- clock to strobe columns
		col : OUT STD_LOGIC_VECTOR (4 DOWNTO 1); -- output column lines
		row : IN STD_LOGIC_VECTOR (4 DOWNTO 1); -- input row lines
		value : OUT STD_LOGIC_VECTOR (3 DOWNTO 0); -- hex value of key depressed
	hit : OUT STD_LOGIC); -- indicates when a key has been pressed
END component;

COMPONENT dac_if IS
    PORT (
        SCLK : IN STD_LOGIC;
        L_start : IN STD_LOGIC;
        R_start : IN STD_LOGIC;
        L_data : IN signed (15 DOWNTO 0);
        R_data : IN signed (15 DOWNTO 0);
        SDATA : OUT STD_LOGIC
    );
END COMPONENT;
COMPONENT wail IS
    PORT (
        lo_pitch : IN UNSIGNED (13 DOWNTO 0);
        hi_pitch : IN UNSIGNED (13 DOWNTO 0);
        wspeed : IN UNSIGNED (7 DOWNTO 0);
        wclk : IN STD_LOGIC;
        audio_clk : IN STD_LOGIC;
        audio_data : OUT SIGNED (15 DOWNTO 0)
    );
END COMPONENT;

-- speaker constant
constant Clow : UNSIGNED (13 DOWNTO 0) := to_unsigned (351, 14);
constant D : UNSIGNED (13 DOWNTO 0) := to_unsigned (394, 14);
constant E : UNSIGNED (13 DOWNTO 0) := to_unsigned (443, 14);
constant F : UNSIGNED (13 DOWNTO 0) := to_unsigned (469, 14);
constant G : UNSIGNED (13 DOWNTO 0) := to_unsigned (526, 14);
constant A : UNSIGNED (13 DOWNTO 0) := to_unsigned (591, 14);
constant B : UNSIGNED (13 DOWNTO 0) := to_unsigned (663, 14);
constant Chigh : UNSIGNED (13 DOWNTO 0) := to_unsigned (702, 14);

signal currFreq : unsigned(13 downto 0) := to_unsigned(0, 14);
signal currFreqHigh : unsigned(13 downto 0) := to_unsigned(0, 14);
signal nxFreq : unsigned(13 downto 0) := to_unsigned(0, 14);

CONSTANT wail_speed : UNSIGNED (7 DOWNTO 0) := to_unsigned (8, 8); -- sets wailing speed

-- speaker timing signals
SIGNAL tcount : unsigned (19 DOWNTO 0) := (OTHERS => '0'); -- timing counter
SIGNAL data_L, data_R : SIGNED (15 DOWNTO 0); -- 16-bit signed audio data
SIGNAL dac_load_L, dac_load_R : STD_LOGIC; -- timing pulses to load DAC shift reg.
SIGNAL slo_clk, sclk, audio_CLK : STD_LOGIC;

-- fsm, keypad, and leddec timing signlas
signal count: std_logic_vector(20 downto 0);
signal fsm_clk, kp_clk : std_logic;
signal kp_hit : std_logic;
signal kp_value : std_logic_vector(3 downto 0);
signal mpx_clk : std_logic_vector(2 downto 0);

-- current song signals
signal curNote: std_logic_vector(3 downto 0);
signal songLength: integer;

-- select songs variables
signal choice: integer := 0;
signal nx_choice: integer := 0;

-- song position and note value signals
signal index: integer := 0;
signal nx_index: integer := 0;
signal s, nx_s: std_logic_vector(3 downto 0) := x"F";

signal title, nx_title : std_logic := '1';

type state is (SELECT_SONG, BEGIN_SONG, ENTER_NOTE, RELEASE_NOTE, RELEASE_SONG);
signal PS, NS: state := SELECT_SONG;

begin
    
    -- speaker timing process
    tim_pr : PROCESS
	BEGIN
		WAIT UNTIL rising_edge(clk_100MHz);
		IF (tcount(9 DOWNTO 0) >= X"00F") AND (tcount(9 DOWNTO 0) < X"02E") THEN
			dac_load_L <= '1';
		ELSE
			dac_load_L <= '0';
		END IF;
		IF (tcount(9 DOWNTO 0) >= X"20F") AND (tcount(9 DOWNTO 0) < X"22E") THEN
			dac_load_R <= '1';
		ELSE dac_load_R <= '0';
		END IF;
		tcount <= tcount + 1;
	end process;
    dac_MCLK <= NOT tcount(1); -- DAC master clock (12.5 MHz)
	audio_CLK <= tcount(9); -- audio sampling rate (48.8 kHz)
	dac_LRCK <= audio_CLK; -- also sent to DAC as left/right clock
	sclk <= tcount(4); -- serial data clock (1.56 MHz)
	dac_SCLK <= sclk; -- also sent to DAC as SCLK
	slo_clk <= tcount(19); -- clock to control wailing of tone (47.6 Hz)
    
    -- clock update process
    clk_proc: process(clk_100MHz)
    begin
        if (rising_edge(clk_100MHz)) then
            count <= count + 1;
        end if;
    end process;
    
    fsm_clk <= count(20);
    kp_clk <= count(15);
    mpx_clk <= count(19 downto 17);
    
    s1: songs
    port map(note =>s, index => index, songChoice => choice, length => songLength);

    l1: leddec
    port map(seg => seg, dig=>mpx_clk, data=>s, anode=>anode, song=>choice, title => title);
    
    k1: keypad
    port map(samp_ck => kp_clk, col => KB_col, row => KB_row, value => kp_value, hit => kp_hit);
    
    dac : dac_if
	PORT MAP(
		SCLK => sclk, -- instantiate parallel to serial DAC interface
		L_start => dac_load_L, 
		R_start => dac_load_R, 
		L_data => data_L, 
		R_data => data_R, 
		SDATA => dac_SDIN 
		);
    w1 : wail
    PORT MAP(lo_pitch => currFreq, -- instantiate wailing siren
        hi_pitch => currFreqHigh,
        wspeed => to_unsigned(0,8), 
        wclk => slo_clk, 
        audio_clk => audio_clk, 
        audio_data => data_L
    );
    data_R <= data_L; -- duplicate data on right channel
    
    -- fsm state change process
    fsm_clk_proc: process(fsm_clk)
    begin
        if rising_edge(clk_100Mhz) then
            PS <= NS;
            index <= nx_index;
            s <= nx_s;
            choice <= nx_choice;
            title <= nx_title;
            if (nxFreq = to_unsigned(0,14)) then
                currFreqHigh <= nxFreq;
            else
                currFreqHigh <= nxFreq + 1;
            end if;
            
        end if;
    end process;
    
    -- fsm comb logic process
    fsm_comb_proc: process(BTNU, BTNC, BTND, kp_hit, kp_value)
    begin
        nx_index <= index;
        nx_s <= s;
        nx_choice <= choice;
        nx_title <= title;
        case ps is
            when SELECT_SONG =>
                if (BTNC = '1') then
                    nx_title <= '0';
                    ns <= BEGIN_SONG;
                elsif (BTND = '1') then
                    if (choice > 0) then
                        nx_choice <= choice - 1;
                    end if;
                    
                    ns <= RELEASE_SONG;
                elsif (BTNU = '1') then
                    if (choice < 1) then
                        nx_choice <= choice + 1;
                    end if;
                end if;
            when RELEASE_SONG =>
                if (BTNC = '0' and BTND = '0' and BTNU = '0') then
                    ns <= SELECT_SONG;
                else
                    ns <= RELEASE_SONG;
                end if;
            
            when BEGIN_SONG =>
                if (BTNC = '0') then
                    ns <= ENTER_NOTE;
                else   
                    ns <= BEGIN_SONG;
                end if;
            when ENTER_NOTE =>
                if (s = kp_value and kp_hit = '1') then
                    nx_index <= index + 1;
                end if;
                
                if (nx_index > songLength) then
                    nx_index <= 0;
                end if;
                
                if (kp_hit = '1') then
                    ns <= RELEASE_NOTE;
                else
                    ns <= ENTER_NOTE;
                end if;
                 
            when RELEASE_NOTE =>
                case kp_value is
                    when x"0" => nxFreq <= Clow;
                    when x"1" => nxFreq <= D;
                    when x"2" => nxFreq <= E;
                    when x"3" => nxFreq <= F;
                    when x"4" => nxFreq <= G;
                    when x"5" => nxFreq <= A;
                    when x"6" => nxFreq <= B;
                    when x"7" => nxFreq <= Chigh;
                    when others => nxFreq <= to_unsigned(0,14);
                end case;
                    
            
                if (kp_hit = '0') then
                    nxFreq <= to_unsigned(0,14);
                    ns <= ENTER_NOTE;
                else
                    ns <= RELEASE_NOTE;
                end if;
                
                
        end case;
                        
                            
    end process;
    
end Behavioral;
