library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

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
	    dac_MCLK : OUT STD_LOGIC; -- these 4 used for speaker DAC
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
		title : in std_logic;
		displaying : in std_logic
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
        note : in std_logic_vector(3 downto 0);
		playing : in std_logic;
        wclk : IN STD_LOGIC;
        audio_clk : IN STD_LOGIC;
        audio_data : OUT SIGNED (15 DOWNTO 0)
    );
END COMPONENT;


-- speaker timing signals
SIGNAL tcount : unsigned (19 DOWNTO 0) := (OTHERS => '0'); -- timing counter
SIGNAL data_L, data_R : SIGNED (15 DOWNTO 0); -- 16-bit signed audio data
SIGNAL dac_load_L, dac_load_R : STD_LOGIC; -- timing pulses to load DAC shift reg.
SIGNAL slo_clk, sclk, audio_CLK : STD_LOGIC;
signal playing, nx_playing : std_logic := '0';

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

-- signals to change 7 seg display
signal title, nx_title : std_logic := '1';
signal disp, nx_disp : std_logic := '1';


type state is (SELECT_SONG, BEGIN_SONG, ENTER_NOTE, RELEASE_NOTE, 
               RELEASE_SONG, FINISH_SONG, RELEASE_FINISH);
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
    
    -- timing signals definition
    fsm_clk <= count(20);
    kp_clk <= count(15);
    mpx_clk <= count(19 downto 17);
    
    s1: songs
    port map(note =>s, index => index, songChoice => choice, length => songLength);

    l1: leddec
    port map(seg => seg, dig=>mpx_clk, data=>s, anode=>anode, song=>choice, title => title, displaying=>disp);
    
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
    PORT MAP(playing => playing,
        note => kp_value,
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
            disp <= nx_disp;
            playing <= nx_playing;
        end if;
    end process;
    
    -- fsm comb logic process
    fsm_comb_proc: process(BTNU, BTNC, BTND, kp_hit, kp_value)
    begin
        -- update the old nx signals
        nx_index <= index;
        nx_s <= s;
        nx_choice <= choice;
        nx_title <= title;
        nx_disp <= disp;
        nx_playing <= playing;
        
        case ps is
            when SELECT_SONG =>
                -- BTNC = 1 --> BEGIN_SONG
                -- BTNU or BTND = 1 --> RELEASE_SONG
                -- else --> SELECT_SONG
                if (BTNC = '1') then
                    nx_title <= '0';
                    ns <= BEGIN_SONG;
                elsif (BTND = '1') then
                    if (choice > 0) then
                        nx_choice <= choice - 1;
                    end if;
                    
                    ns <= RELEASE_SONG;
                elsif (BTNU = '1') then
                    if (choice < 3) then
                        nx_choice <= choice + 1;
                    end if;
                    
                    ns <= RELEASE_SONG;
                else
                    ns <= SELECT_SONG;
                end if;
            when RELEASE_SONG =>
                -- BTNU and BTND = 0 --> SELECT_SONG
                -- else --> RELEASE_SONG
                if (BTNC = '0' and BTND = '0' and BTNU = '0') then
                    ns <= SELECT_SONG;
                else
                    ns <= RELEASE_SONG;
                end if;
            
            when BEGIN_SONG =>
                -- BTNC = 0 --> ENTER_NOTE
                -- else --> BEGIN_SONG
                if (BTNC = '0') then
                    ns <= ENTER_NOTE;
                else   
                    ns <= BEGIN_SONG;
                end if;
            when ENTER_NOTE =>
                -- kp_hit = 1 --> RELEASE_SONG
                -- index = length --> FINISH_SONG
                -- else --> ENTER_NOTE
                if (index > songLength) then
                    nx_index <= 0;
                    nx_title <= '1';
                    nx_choice <= -1;
                    ns <= FINISH_SONG;
        
                elsif (kp_hit = '1') then
                    ns <= RELEASE_NOTE;
                    nx_disp <= '0';
                    nx_playing <= '1';
                    
                    if (s = kp_value) then
                        nx_index <= index + 1;
                    end if;
                else
                    ns <= ENTER_NOTE;
                end if;
                 
            when RELEASE_NOTE =>
                -- kp_hit = 0 --> ENTER_NOTE
                -- else --> RELEASE_NOTE
                if (kp_hit = '0') then
                    ns <= ENTER_NOTE;
                    nx_disp <= '1';
                    nx_playing <= '0';
                else
                    ns <= RELEASE_NOTE;
                end if;
            when FINISH_SONG =>
                -- kp_hit = 1 --> RELEASE_FINISH
                -- else --> FINISH_SONG
                if (kp_hit = '1') then
                    nx_choice <= 0;
                    ns <= RELEASE_FINISH;
                else
                    ns <= FINISH_SONG;
                end if;
            when RELEASE_FINISH =>
                -- kp_hit = 0 --> SELECT_SONG
                -- else --> RELEASE_FINISH
                if (kp_hit = '0') then
                    nx_choice <= 0;
                    nx_index <= 0;
                    nx_title <= '1';
                    ns <= SELECT_SONG;
                else
                    ns <= RELEASE_FINISH;
                end if;
        end case;
                        
                            
    end process;
    
end Behavioral;
