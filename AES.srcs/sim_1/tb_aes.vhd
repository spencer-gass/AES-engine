----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/28/2022 08:13:44 PM
-- Design Name: 
-- Module Name: tb_aes - tb
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_misc.all;

library work;
use work.aes_package.all;

entity tb_aes is
end tb_aes;

architecture tb of tb_aes is
    
    component aes is
        port (
            clk         : in  std_logic;
            arst_n      : in  std_logic;

            din_vld     : in  std_logic;
            din         : in  std_logic_vector(127 downto 0);
            key         : in  std_logic_vector(key_size-1 downto 0);

            dout_vld    : out std_logic;
            dout        : out std_logic_vector(127 downto 0)

         );
    end component;

    constant c_din : std_logic_vector(127 downto 0) := x"3243f6a8885a308d313198a2e0370734";
    constant c_key : std_logic_vector(127 downto 0) := x"2b7e151628aed2a6abf7158809cf4f3c";

    signal clk         : std_logic;
    signal arst_n      : std_logic;
    signal din_vld     : std_logic;
    signal din         : std_logic_vector(127 downto 0);
    signal key         : std_logic_vector(key_size-1 downto 0);
    signal dout_vld    : std_logic;
    signal dout        : std_logic_vector(127 downto 0);

begin

clk_p : process
begin
    clk <= '1' , '0' after 50 ns;
    wait for 100 ns;
end process;

main_p : process
begin
    arst_n <= '0';
    din_vld <= '0';
    wait for 1 us;
    arst_n <= '1';
    wait for 1 us;
    wait until clk'event and clk='1';
    din_vld <= '1';
    din <= c_din;
    key <= c_key;
    wait until clk'event and clk='1';
    din_vld <= '0';
    wait;
end process;


uaes : aes
port map (
    clk        => clk, 
    arst_n     => arst_n, 
                 
    din_vld    => din_vld, 
    din        => din, 
    key        => key, 
                 
    dout_vld   => dout_vld, 
    dout       => dout     

);

end tb;
