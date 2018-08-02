------------------------------------------------------------------------------
--      _____
--     *     *
--    *____   *____
--   * *===*   *==*
--  *___*===*___**  AVNET
--       *======*
--        *====*
------------------------------------------------------------------------------
--
-- This design is the property of Avnet.  Publication of this
-- design is not authorized without written consent from Avnet.
--
-- Disclaimer:
--    Avnet, Inc. makes no warranty for the use of this code or design.
--    This code is provided  "As Is". Avnet, Inc assumes no responsibility for
--    any errors, which may appear in this code, nor does it make a commitment
--    to update the information contained herein. Avnet, Inc specifically
--    disclaims any implied warranties of fitness for a particular purpose.
--                     Copyright(c) 2018 Avnet, Inc.
--                             All rights reserved.
--
------------------------------------------------------------------------------
--
-- Create Date:         Feb 25, 2018
-- File Name:           axi_counter.vhd
--
-- Tool versions:       Vivado 2017.4
--
-- Description:         Programmable counter
--
-- Revision:            Feb 25, 2018: 1.00 Initial version
--
------------------------------------------------------------------------------ 

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity axi_counter is
  port (
    
    -- Clocks & Resets
    clk                   : in  std_logic;
    rst_n                 : in  std_logic;
    
    -- Register Interface
    reg_addr              : in  std_logic_vector(9 downto 0);
    reg_data_in           : in  std_logic_vector(31 downto 0);
    reg_wea               : in  std_logic;
    reg_data_out          : out std_logic_vector(31 downto 0);      
      
    -- Counter output
    counter               : out std_logic_vector(31 downto 0);
    counter_valid         : out std_logic 
    
  );
end axi_counter;
  
architecture rtl of axi_counter is
  
  -- CONSTANTS
  constant MAX_REG    : integer := 6; -- Number of valid registers
  constant REG_CLEAR  : integer := 0; -- Clear Register address
  constant REG_ENABLE : integer := 1; -- Enable Register address
  constant REG_UPDATE : integer := 2; -- Update Register address
  constant REG_INCR   : integer := 3; -- Increment Register address
  constant REG_RATE   : integer := 4; -- Rate Register address
  constant REG_INIT   : integer := 5; -- Initial Value Register address
  
  -- TYPES
  type reg_array is array (natural range <>) of std_logic_vector(31 downto 0);
  
  -- SIGNALS
  signal local_count : std_logic_vector(31 downto 0);
  signal rate_count  : std_logic_vector(9 downto 0);
  signal clear       : std_logic;
  signal enable      : std_logic;
  signal update      : std_logic;
  signal init        : std_logic_vector(31 downto 0);
  signal incr        : std_logic_vector(9 downto 0);
  signal incr_q      : std_logic_vector(9 downto 0);
  signal rate        : std_logic_vector(9 downto 0);
  signal rate_q      : std_logic_vector(9 downto 0);
  signal reg_file    : reg_array(MAX_REG-1 downto 0);  
  
begin
  
  p_main : process(clk, rst_n)
  begin
    if rising_edge(clk) then
      
      if (rst_n = '0') then
        counter               <= (others => '0');
        counter_valid         <= '0';
        local_count           <= (others => '0');
        rate_count            <= (others => '0');
        incr_q                <= "0000000001";
        rate_q                <= "0000000001"; 
        reg_file              <= (others => (others => '0'));
        reg_data_out          <= (others => '0');
      else        
        
        -- Default values              
        counter_valid <= '0'; 
        
        -- Store input parameters that fall in the valid address range.  
        if (reg_wea = '1') and (reg_addr < MAX_REG) then                    
          reg_file(conv_integer(reg_addr)) <= reg_data_in;  
        elsif (reg_wea = '0') then
          if (reg_addr < MAX_REG) then
            reg_data_out <= reg_file(conv_integer(reg_addr));                     
          else
            reg_data_out <= x"DEADBEEF";
          end if;
        end if;

        -- Allow the counter to increment when the enable register is set
        if reg_file(REG_ENABLE)(0) = '1' then
          
          -- Update the counter value by the increment register when the 
          -- rate (i.e. period) counter reaches the user programmed rate register
          if (rate_count = rate_q) then
            counter_valid <= '1';
            counter       <= local_count;
            local_count   <= local_count + incr_q;
            rate_count    <= (others => '0');
          else
            counter_valid <= '0';
            rate_count    <= rate_count + '1';
          end if; 
                     
        -- Clear the counter when the clear register is set
        elsif reg_file(REG_CLEAR)(0) = '1' then
          counter     <= (others => '0');
          local_count <= (others => '0');
          rate_count  <= (others => '0');
            
        -- Update the rate, increment, and intial value parameters when the 
        -- update register is set.  Subtract one from the rate parameter since
        -- our counter is zero based and rate is the number of clock cycles to 
        -- wait between counter ticks.  
        elsif reg_file(REG_UPDATE)(0) = '1' then
          rate_count  <= (others => '0');
          counter     <= reg_file(REG_INIT);
          local_count <= reg_file(REG_INIT);
          incr_q      <= reg_file(REG_INCR)(9 downto 0);
            
          if (reg_file(REG_RATE)(9 downto 0) = 0) then
            rate_q <= (others => '0');
          else            
            rate_q <= reg_file(REG_RATE)(9 downto 0) - '1';
          end if;

        end if;
        
      end if;
                                          
    end if; 
  end process p_main;
  
end rtl;