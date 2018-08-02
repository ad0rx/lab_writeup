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
-- File Name:           axi_counter_ip.vhd
--
-- Tool versions:       Vivado 2017.4
--
-- Description:         Programmable counter top-level with AXI-Lite Interface
--
-- Revision:            Feb 25, 2018: 1.00 Initial version
--
------------------------------------------------------------------------------ 

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity axi_counter_ip is
  port (
    
    -- Clocks & Resets
    clk           : in  std_logic;
    rst_n         : in  std_logic;
    
    -- AXI-Lite Interface
    s_axi_aclk    : in  std_logic;
    s_axi_aresetn : in  std_logic;
    s_axi_awaddr  : in  std_logic_vector(11 downto 0);
    s_axi_awlen   : in  std_logic_vector(7 downto 0);
    s_axi_awsize  : in  std_logic_vector(2 downto 0);
    s_axi_awburst : in  std_logic_vector(1 downto 0);
    s_axi_awlock  : in  std_logic;
    s_axi_awcache : in  std_logic_vector(3 downto 0);
    s_axi_awprot  : in  std_logic_vector(2 downto 0);
    s_axi_awvalid : in  std_logic;
    s_axi_awready : out std_logic;
    s_axi_wdata   : in  std_logic_vector(31 downto 0);
    s_axi_wstrb   : in  std_logic_vector(3 downto 0);
    s_axi_wlast   : in  std_logic;
    s_axi_wvalid  : in  std_logic;
    s_axi_wready  : out std_logic;
    s_axi_bresp   : out std_logic_vector(1 downto 0);
    s_axi_bvalid  : out std_logic;
    s_axi_bready  : in  std_logic;
    s_axi_araddr  : in  std_logic_vector(11 downto 0);
    s_axi_arlen   : in  std_logic_vector(7 downto 0);
    s_axi_arsize  : in  std_logic_vector(2 downto 0);
    s_axi_arburst : in  std_logic_vector(1 downto 0);
    s_axi_arlock  : in  std_logic;
    s_axi_arcache : in  std_logic_vector(3 downto 0);
    s_axi_arprot  : in  std_logic_vector(2 downto 0);
    s_axi_arvalid : in  std_logic;
    s_axi_arready : out std_logic;
    s_axi_rdata   : out std_logic_vector(31 downto 0);
    s_axi_rresp   : out std_logic_vector(1 downto 0);
    s_axi_rlast   : out std_logic;
    s_axi_rvalid  : out std_logic;
    s_axi_rready  : in  std_logic;
    
    -- Counter Outputs
    counter       : out std_logic_vector(31 downto 0);
    counter_valid : out std_logic
    
  );
end axi_counter_ip;

architecture rtl of axi_counter_ip is
  
  -- SIGNALS
  signal reg_addr     : std_logic_vector(11 downto 0);
  signal reg_data_in  : std_logic_vector(31 downto 0);
  signal reg_wea      : std_logic_vector(3 downto 0);
  signal reg_data_out : std_logic_vector(31 downto 0);  

begin

  -- AXI-Lite to BRAM interface adaptor
  u_axi_bram_ctrl_0 : entity work.axi_bram_ctrl_0
  port map (
    s_axi_aclk    => s_axi_aclk,
    s_axi_aresetn => s_axi_aresetn,
    s_axi_awaddr  => s_axi_awaddr,
    s_axi_awlen   => s_axi_awlen,
    s_axi_awsize  => s_axi_awsize,
    s_axi_awburst => s_axi_awburst,
    s_axi_awlock  => s_axi_awlock,
    s_axi_awcache => s_axi_awcache,
    s_axi_awprot  => s_axi_awprot,
    s_axi_awvalid => s_axi_awvalid,
    s_axi_awready => s_axi_awready,
    s_axi_wdata   => s_axi_wdata,
    s_axi_wstrb   => s_axi_wstrb,
    s_axi_wlast   => s_axi_wlast,
    s_axi_wvalid  => s_axi_wvalid,
    s_axi_wready  => s_axi_wready,
    s_axi_bresp   => s_axi_bresp,
    s_axi_bvalid  => s_axi_bvalid,
    s_axi_bready  => s_axi_bready,
    s_axi_araddr  => s_axi_araddr,
    s_axi_arlen   => s_axi_arlen,
    s_axi_arsize  => s_axi_arsize,
    s_axi_arburst => s_axi_arburst,
    s_axi_arlock  => s_axi_arlock,
    s_axi_arcache => s_axi_arcache,
    s_axi_arprot  => s_axi_arprot,
    s_axi_arvalid => s_axi_arvalid,
    s_axi_arready => s_axi_arready,
    s_axi_rdata   => s_axi_rdata,
    s_axi_rresp   => s_axi_rresp,
    s_axi_rlast   => s_axi_rlast,
    s_axi_rvalid  => s_axi_rvalid,
    s_axi_rready  => s_axi_rready,
    bram_rst_a    => open,
    bram_clk_a    => open,
    bram_en_a     => open,
    bram_we_a     => reg_wea,
    bram_addr_a   => reg_addr,
    bram_wrdata_a => reg_data_in,
    bram_rddata_a => reg_data_out
  );

  -- Programmable counter with BRAM control interface
  u_axi_counter : entity work.axi_counter
  port map (
    clk            => clk,
    rst_n          => rst_n,
    reg_addr       => reg_addr(11 downto 2),
    reg_data_in    => reg_data_in,
    reg_wea        => reg_wea(0),
    reg_data_out   => reg_data_out,
    counter        => counter,
    counter_valid  => counter_valid
  );

end rtl;