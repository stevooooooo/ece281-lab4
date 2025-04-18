library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;


-- Lab 4
entity top_basys3 is
    port(
        -- inputs
        clk     :   in std_logic; -- native 100MHz FPGA clock
        sw      :   in std_logic_vector(15 downto 0);
        btnU    :   in std_logic; -- master_reset
        btnL    :   in std_logic; -- clk_reset
        btnR    :   in std_logic; -- fsm_reset
        
        -- outputs
        led :   out std_logic_vector(15 downto 0);
        -- 7-segment display segments (active-low cathodes)
        seg :   out std_logic_vector(6 downto 0);
        -- 7-segment display active-low enables (anodes)
        an  :   out std_logic_vector(3 downto 0)
    );
end top_basys3;

architecture top_basys3_arch of top_basys3 is

    -- signal declarations
 	signal w_clk1 : std_logic; 
 	signal w_clk2 : std_logic; 
    signal w_floor : std_logic_vector(3 downto 0);
    signal w_reset1 : std_logic;
    signal w_reset2 : std_logic;
    signal w_floorTDM1 : std_logic_vector(3 downto 0);
    signal w_floorTDM2 : std_logic_vector(3 downto 0);
  
	-- component declarations
    component sevenseg_decoder is
        port (
            i_Hex : in STD_LOGIC_VECTOR (3 downto 0);
            o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
        );
    end component sevenseg_decoder;
    
    component elevator_controller_fsm is
		Port (
            i_clk        : in  STD_LOGIC;
            i_reset      : in  STD_LOGIC;
            is_stopped   : in  STD_LOGIC;
            go_up_down   : in  STD_LOGIC;
            o_floor : out STD_LOGIC_VECTOR (3 downto 0)		   
		 );
	end component elevator_controller_fsm;
	
	component TDM4 is
		generic ( constant k_WIDTH : natural  := 4); -- bits in input and output
        Port ( i_clk		: in  STD_LOGIC;
           i_reset		: in  STD_LOGIC; -- asynchronous
           i_D3 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
	   	   i_D2 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D1 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   i_D0 		: in  STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_data		: out STD_LOGIC_VECTOR (k_WIDTH - 1 downto 0);
		   o_sel		: out STD_LOGIC_VECTOR (3 downto 0)	-- selected data line (one-cold)
	   );
    end component TDM4;
     
	component clock_divider is
        generic ( constant k_DIV : natural := 2	); -- How many clk cycles until slow clock toggles
                                                   -- Effectively, you divide the clk double this 
                                                   -- number (e.g., k_DIV := 2 --> clock divider of 4)
        port ( 	i_clk    : in std_logic;
                i_reset  : in std_logic;		   -- asynchronous
                o_clk    : out std_logic		   -- divided (slow) clock
        );
    end component clock_divider;
	
begin
	-- PORT MAPS ----------------------------------------
    TDM4_inst: TDM4
    port map (
        i_reset => w_reset1,
        i_clk => w_clk2,
        i_D0 => w_floorTDM1,
        i_D1 => x"F",
        i_D2 => w_floorTDM2,
        i_D3 => x"F",
        o_data => w_floor,
        o_sel => an
    );
        

    
    elevator_controller_inst: elevator_controller_fsm
    port map (
        i_clk => w_clk1,
        i_Reset => w_reset2,
        go_up_down => sw(1),
        is_stopped => sw(0),
        o_floor => w_floorTDM1
    );   	
    
    elevator_controller_inst2: elevator_controller_fsm
    port map (
        i_clk => w_clk1,
        i_Reset => w_reset2,
        go_up_down => sw(3),
        is_stopped => sw(2),
        o_floor => w_floorTDM2
    );   	
    
    sevenseg_decoder_inst: sevenseg_decoder 
    port map (
        i_Hex => w_floor,
        o_seg_n => seg
    );
	
			clkdiv_inst1 : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 50000000 ) -- 0.5 Hz clock from 100 MHz
        port map (						  
            i_clk   => clk,
            i_reset =>  w_reset1,
            o_clk   => w_clk1
        );  
			clkdiv_inst2 : clock_divider 		--instantiation of clock_divider to take 
        generic map ( k_DIV => 416666) -- 240 Hz (60 Hz per panel) clock from 100 MHz
        port map (						  
            i_clk   => clk,
            i_reset =>  w_reset1,
            o_clk   => w_clk2
        );  
	-- CONCURRENT STATEMENTS ----------------------------
	
	-- LED 15 gets the FSM slow clock signal. The rest are grounded.
	led(15) <= w_clk1;

	
	-- leave unused switches UNCONNECTED. Ignore any warnings this causes.
	
	-- reset signals
process(btnU, btnR, btnL)
begin
    if (btnU = '1' or btnL = '1') then
        w_reset1 <= '1';
    else
        w_reset1 <= '0';
    end if;
    if (btnU = '1' or btnR = '1') then
        w_reset2 <= '1';
    else
        w_reset2 <= '0';
    end if;
end process;
	
end top_basys3_arch;
