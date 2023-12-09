----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/20/2022 08:27:48 PM
-- Design Name: 
-- Module Name: aes - rtl
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

library unisim;
use unisim.vcomponents.all;

library work;
use work.aes_package.all;

entity aes is
    port (
        clk         : in  std_logic;
        arst_n      : in  std_logic;

        din_vld     : in  std_logic;
        din         : in  std_logic_vector(127 downto 0);
        key         : in  std_logic_vector(key_size-1 downto 0);

        dout_vld    : out std_logic;
        dout        : out std_logic_vector(127 downto 0)

     );
end aes;

architecture rtl of aes is

    signal state : state_t;
    signal key_schedule : key_schedule_t(0 to Nr);
    signal round_cnt : integer;
    signal round_cnt_d : integer;

begin

    aes_p : process(clk, arst_n)
        procedure reset_signals is
        begin
            dout_vld <= '0';
            dout     <= (others=>'0');
            round_cnt <= Nr;
        end procedure;
        variable state_v : state_t;
        variable x : integer;
    begin
        if arst_n='0' then
            reset_signals;
        elsif clk'event and clk='1' then

            dout_vld <= '0';
            dout <= (others=>'0');
            round_cnt_d <= round_cnt;

            if din_vld = '1' then
                state <= slv_to_state(din);
                key_schedule <= expand_key(key);
                round_cnt <= 0;
            end if;

            if round_cnt < Nr then
                report integer'image(round_cnt);
                round_cnt <= round_cnt + 1;
                state_v := state;
                x := print_state(state_v);
                state_v := sub_bytes(state_v);
                x := print_state(state_v);
                state_v := shift_rows(state_v);
                x := print_state(state_v);
                if round_cnt /= Nr then
                    state_v := mix_cols(state_v);
                end if;
                state_v := add_round_key(state_v, key_schedule(round_cnt));
                state <= state_v;
            end if;

            if round_cnt = Nr and round_cnt_d = Nr-1 then
                dout <= state_to_slv(state);
                dout_vld <= '1';
            end if;

        end if;
    end process aes_p;

end rtl;
