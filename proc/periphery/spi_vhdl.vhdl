library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_vhdl_e is
  generic (
    cnt_limit_spi: integer := 1302
  );

  port (
      clk: in std_logic;
      fromRX: in std_logic;
      value : out std_logic_vector (7 downto  0);
      -- led: out std_logic;
      -- led2: out std_logic;
      reset: in std_logic

  );

  attribute chip_pin : string;
  
  attribute chip_pin of clk : signal is "E1"; 
  attribute chip_pin of fromRX : signal is "F14"; 
  -- attribute chip_pin of led : signal is "L14";
  -- attribute chip_pin of led2 : signal is "L13";
  attribute chip_pin of reset : signal is "J14";
  attribute chip_pin of value: signal is "C3,A2,B3,A3,B4,A4,B5,A5";



  -- attribute chip_pin of my_pin: signal is "4, , 6";
end;

-- entity clks is
--   generic (
--     clk_counter : integer  range 0 to 1302
--   );
--   port (
--     clk_in: in bit;
--     clk_out : out bit
--   );
--   variable clk_in_cnt : integer range 0 to clk_counter;
-- end;


architecture synth of spi_vhdl_e is 
signal clk_2x : std_logic;
signal spi_clk : std_logic;
signal sw_spi_clk : std_logic;
type statetype is (start,count,stop,stop_delay);
signal state, next_state : statetype;
signal clk_mux : std_logic;
signal bit_counter : std_logic_vector (7 downto  0);
signal bit_val : std_logic_vector (7 downto  0);

begin
  process (clk)
    variable cnt : integer range 0 to cnt_limit_spi := 0;
  begin
    if rising_edge(clk) then
      if cnt = cnt_limit_spi then
        clk_2x <= not clk_2x;
        cnt := 0;
      else
        cnt := cnt + 1;
      end if;
    end if;
  end process;

  process (clk_2x)
  begin
    if rising_edge(clk_2x) then
      if (sw_spi_clk = '1') then
        spi_clk <= not spi_clk;
      end if;
    end if;
  end process;



  -- process (clk_mux,reset) begin
  --   if (rising_edge(clk_mux)) then
  --     if (reset = '0') then
  --       bit_val <= (others => '0');
  --     elsif ((state = count) or (next_state = count)) then
  --       bit_val <=bit_val(6 downto 0) & fromRX;
  --     end if;
  --   end if;
  -- end process;

  value <= bit_val;
  
  process (clk_mux,reset) begin
    if (reset = '0') then 
      state <= start;
    elsif (rising_edge(clk_mux)) then 
      state <= next_state;
    end if;
  end process;

  process (clk_mux,reset) begin
    if (reset = '0') then 
      bit_counter <= (others => '0');
      bit_val <= (others => '0');
    elsif (rising_edge(clk_mux)) then
      if (state = count) then
        bit_counter <= std_logic_vector(unsigned(bit_counter) + 1);
        bit_val <=bit_val(6 downto 0) & fromRX;
      else
        bit_counter <= (others => '0');
      end if;
      end if;

  end process;

  process (all) begin
    if (sw_spi_clk = '1') then
      clk_mux <= spi_clk;
    else
      clk_mux <= clk_2x;
    end if;
  end process;

  process (all) begin
    if ((state = count) or (next_state = count)) then
      sw_spi_clk <= '1';
    else
      sw_spi_clk <= '0';
    end if;
  end process;

  process (all) begin
    case state is
      when start => if ( fromRX = '0' ) then next_state <= count; else next_state <= state; end if;
      when count => if (unsigned(bit_counter) = to_unsigned(7,8)) then next_state <= stop; else next_state <= count; end if;
      when stop => next_state <= stop_delay;
      when stop_delay => next_state <= start;
      when others => next_state <= state;
    end case;
  end process;  
  end;




