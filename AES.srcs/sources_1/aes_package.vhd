----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/20/2022 08:27:48 PM
-- Design Name: 
-- Module Name: aes_package 
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

package aes_package is
    -- parameters --

    -- valid key_size, Nr pairs:
    -- 128, 10
    -- 192, 12
    -- 256, 14    

    constant key_size : integer := 128; -- 128, 192, 256
    constant Nr       : integer := 10;  -- 10,  12,  14 
    constant Nk       : integer := key_size/32;

    -- constants --
    constant Nb : integer := 4; -- number of 32-bit words in the state

    type state_row_t is array(0 to Nb-1) of std_logic_vector(7 downto 0);
    type word_t is array(0 to Nb-1) of std_logic_vector(7 downto 0);
    type state_t is array(0 to Nb-1) of state_row_t;
    type byte_vec is array(natural range <>) of std_logic_vector(7 downto 0);
    type word_vec is array(natural range <>) of word_t;
    type key_schedule_wv is array(0 to Nk*(Nr+1)-1) of word_t;
    type key_schedule_t is array(natural range <>) of std_logic_vector(key_size-1 downto 0);
    constant sbox : byte_vec(0 to 255) := ( 
        x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5", x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76", 
        x"ca", x"82", x"c9", x"7d", x"fa", x"59", x"47", x"f0", x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0", 
        x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc", x"34", x"a5", x"e5", x"f1", x"71", x"d8", x"31", x"15", 
        x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a", x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", x"75", 
        x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0", x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84", 
        x"53", x"d1", x"00", x"ed", x"20", x"fc", x"b1", x"5b", x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf", 
        x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85", x"45", x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8", 
        x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5", x"bc", x"b6", x"da", x"21", x"10", x"ff", x"f3", x"d2", 
        x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17", x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73", 
        x"60", x"81", x"4f", x"dc", x"22", x"2a", x"90", x"88", x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db", 
        x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c", x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79", 
        x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9", x"6c", x"56", x"f4", x"ea", x"65", x"7a", x"ae", x"08", 
        x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6", x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a", 
        x"70", x"3e", x"b5", x"66", x"48", x"03", x"f6", x"0e", x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e", 
        x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", x"94", x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df", 
        x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68", x"41", x"99", x"2d", x"0f", x"b0", x"54", x"bb", x"16"
    ); 

    constant inv_sbox : byte_vec(0 to 255) := (
        x"52", x"09", x"6a", x"d5", x"30", x"36", x"a5", x"38", x"bf", x"40", x"a3", x"9e", x"81", x"f3", x"d7", x"fb", 
        x"7c", x"e3", x"39", x"82", x"9b", x"2f", x"ff", x"87", x"34", x"8e", x"43", x"44", x"c4", x"de", x"e9", x"cb", 
        x"54", x"7b", x"94", x"32", x"a6", x"c2", x"23", x"3d", x"ee", x"4c", x"95", x"0b", x"42", x"fa", x"c3", x"4e",
        x"08", x"2e", x"a1", x"66", x"28", x"d9", x"24", x"b2", x"76", x"5b", x"a2", x"49", x"6d", x"8b", x"d1", x"25",
        x"72", x"f8", x"f6", x"64", x"86", x"68", x"98", x"16", x"d4", x"a4", x"5c", x"cc", x"5d", x"65", x"b6", x"92",
        x"6c", x"70", x"48", x"50", x"fd", x"ed", x"b9", x"da", x"5e", x"15", x"46", x"57", x"a7", x"8d", x"9d", x"84",
        x"90", x"d8", x"ab", x"00", x"8c", x"bc", x"d3", x"0a", x"f7", x"e4", x"58", x"05", x"b8", x"b3", x"45", x"06",
        x"d0", x"2c", x"1e", x"8f", x"ca", x"3f", x"0f", x"02", x"c1", x"af", x"bd", x"03", x"01", x"13", x"8a", x"6b",
        x"3a", x"91", x"11", x"41", x"4f", x"67", x"dc", x"ea", x"97", x"f2", x"cf", x"ce", x"f0", x"b4", x"e6", x"73",
        x"96", x"ac", x"74", x"22", x"e7", x"ad", x"35", x"85", x"e2", x"f9", x"37", x"e8", x"1c", x"75", x"df", x"6e",
        x"47", x"f1", x"1a", x"71", x"1d", x"29", x"c5", x"89", x"6f", x"b7", x"62", x"0e", x"aa", x"18", x"be", x"1b",
        x"fc", x"56", x"3e", x"4b", x"c6", x"d2", x"79", x"20", x"9a", x"db", x"c0", x"fe", x"78", x"cd", x"5a", x"f4",
        x"1f", x"dd", x"a8", x"33", x"88", x"07", x"c7", x"31", x"b1", x"12", x"10", x"59", x"27", x"80", x"ec", x"5f",
        x"60", x"51", x"7f", x"a9", x"19", x"b5", x"4a", x"0d", x"2d", x"e5", x"7a", x"9f", x"93", x"c9", x"9c", x"ef",
        x"a0", x"e0", x"3b", x"4d", x"ae", x"2a", x"f5", x"b0", x"c8", x"eb", x"bb", x"3c", x"83", x"53", x"99", x"61",
        x"17", x"2b", x"04", x"7e", x"ba", x"77", x"d6", x"26", x"e1", x"69", x"14", x"63", x"55", x"21", x"0c", x"7d"
    );

    -- Rcon[i] = [x^(i-1) ,{00},{00},{00}] for i from 1 to 8
    -- x is denoted as {02}
    constant rcon : word_vec(0 to 9) := (
        (x"00",x"00",x"00",x"01"),
        (x"00",x"00",x"00",x"02"),
        (x"00",x"00",x"00",x"04"),
        (x"00",x"00",x"00",x"08"),
        (x"00",x"00",x"00",x"10"),
        (x"00",x"00",x"00",x"20"),
        (x"00",x"00",x"00",x"40"),
        (x"00",x"00",x"00",x"80"),
        (x"00",x"00",x"00",x"1b"),
        (x"00",x"00",x"00",x"36")
    );

    -- functions --
    function slv_to_state(slv : std_logic_vector(127 downto 0)) return state_t;
    function state_to_slv(state : state_t) return std_logic_vector;
    function slv_to_word(slv : std_logic_vector(31 downto 0)) return word_t;
    function word_to_slv(w : word_t) return std_logic_vector;
    function mult_by_2(x : std_logic_vector(7 downto 0)) return std_logic_vector;
    function mult_by_3(x : std_logic_vector(7 downto 0)) return std_logic_vector;

    -- Encrypt functions
    function sub_bytes(s : state_t) return state_t;
    function shift_rows(s : state_t) return state_t;
    function mix_cols(s : state_t) return state_t;
    function add_round_key(s : state_t; key : std_logic_vector(127 downto 0)) return state_t;

    -- Decrypt function
    function inv_sub_bytes(s : state_t) return state_t;
    function inv_shift_rows(s : state_t) return state_t;
    function inv_mix_cols(s : state_t) return state_t;

    -- Key Expansion functions
    function sub_word(w : word_t) return word_t;
    function rot_word(w : word_t) return word_t;
    function xor_word(w1, w2 : word_t) return word_t;
    function expand_key(key : std_logic_vector(key_size-1 downto 0)) return key_schedule_t;
    function print_word(w : word_t) return integer; 
    function print_state(s : state_t) return integer; 

end aes_package;

package body aes_package is

    function slv_to_state(slv : std_logic_vector(127 downto 0)) return state_t is
        variable state : state_t;
        variable i : integer;
    begin
        for row in 0 to 3 loop
            for col in 0 to 3 loop
                i := 4*col + row;
                state(row)(col) := slv(127-(i*8) downto 127-7-(i*8)); 
            end loop;
        end loop;
        return state;
    end function;

    function state_to_slv(state : state_t) return std_logic_vector is
        variable slv : std_logic_vector(127 downto 0);
        variable i : integer;
    begin
        for row in 0 to 3 loop
            for col in 0 to 3 loop
                i := 4*col + row;
                slv(127-(i*8) downto 127-7-(i*8)) := state(row)(col); 
            end loop;
        end loop;
        return slv;
    end function;

    function slv_to_word(slv : std_logic_vector(31 downto 0)) return word_t is
        variable w : word_t; 
    begin
        w(3) := slv(31 downto 24);
        w(2) := slv(23 downto 16);
        w(1) := slv(15 downto 8);
        w(0) := slv(7  downto 0);
        return w;
    end function;

    function word_to_slv(w : word_t) return std_logic_vector is
        variable slv : std_logic_vector(31 downto 0);
    begin
        slv(31 downto 24):= w(3);
        slv(23 downto 16):= w(2);
        slv(15 downto 8) := w(1);
        slv(7  downto 0) := w(0);
        return slv;
    end function;

    function mult_by_2(x : std_logic_vector(7 downto 0)) return std_logic_vector is 
        variable y : std_logic_vector(7 downto 0);
    begin
        y := x(6 downto 0) & '0';
        if x(7) = '1' then
            y := y xor x"1B";
        end if;
        return y;
    end function;

    function mult_by_3(x : std_logic_vector(7 downto 0)) return std_logic_vector is 
        variable y : std_logic_vector(7 downto 0);
    begin 
        return mult_by_2(x) xor x;
        if x(7) = '1' then
            y := y xor x"1B";
        end if;
    end function; 

    function sub_bytes(s : state_t) return state_t is 
        variable s_prime : state_t;
    begin
        for row in 0 to Nb-1 loop
            for col in 0 to Nb-1 loop
                s_prime(row)(col) := sbox(conv_integer(s(row)(col)));
            end loop;
        end loop;
        return s_prime;
    end function;

    function shift_rows(s : state_t) return state_t is
        variable s_prime : state_t;
    begin
        s_prime := ((s(0)(0), s(0)(1), s(0)(2), s(0)(3)),
                    (s(1)(1), s(1)(2), s(1)(3), s(1)(0)),
                    (s(2)(2), s(2)(3), s(2)(0), s(2)(1)),
                    (s(3)(3), s(3)(0), s(3)(1), s(3)(2))); 
        return s_prime;
    end function;

    function mix_cols(s :state_t) return state_t is
        variable s_prime : state_t;
    begin
        for c in 0 to Nb-1 loop
            s_prime(0)(c) := mult_by_2(s(0)(c)) xor mult_by_3(s(1)(c)) xor           s(2)(c)  xor           s(3)(c); 
            s_prime(1)(c) :=           s(0)(c)  xor mult_by_2(s(1)(c)) xor mult_by_3(s(2)(c)) xor           s(3)(c);
            s_prime(2)(c) :=           s(0)(c)  xor           s(1)(c)  xor mult_by_2(s(2)(c)) xor mult_by_3(s(3)(c));
            s_prime(3)(c) := mult_by_3(s(0)(c)) xor           s(1)(c)  xor           s(2)(c)  xor mult_by_2(s(3)(c));
        end loop;
        return s_prime;
    end function;

    function add_round_key(s : state_t; key : std_logic_vector(127 downto 0)) return state_t is
        variable k : state_t;
        variable s_prime : state_t;
    begin
        k := slv_to_state(key);
        for row in 0 to Nb-1 loop
            for col in 0 to Nb-1 loop
                s_prime(row)(col) := s(row)(col) xor k(row)(col);
            end loop;
        end loop;
        return s_prime;
    end function;

    function sub_word(w : word_t) return word_t is 
        variable w_prime : word_t;
    begin
        for byte in 0 to 3 loop
            w_prime(byte) := sbox(conv_integer(w(byte)));
        end loop;
        return w_prime;
    end function;

    function rot_word(w : word_t) return word_t is 
        variable w_prime : word_t;
    begin
        for byte in 0 to 3 loop
            w_prime(byte) := w((byte-1) mod 4);
        end loop;
        return w_prime;
    end function;

    function inv_sub_bytes(s : state_t) return state_t is 
        variable s_prime : state_t;
    begin
        for row in 0 to Nb-1 loop
            for col in 0 to Nb-1 loop
                s_prime(row)(col) := inv_sbox(conv_integer(s(row)(col)));
            end loop;
        end loop;
        return s_prime;
    end function;

    function inv_shift_rows(s : state_t) return state_t is
        variable s_prime : state_t;
    begin
        s_prime := ((s(0)(0), s(0)(1), s(0)(2), s(0)(3)),
                    (s(1)(3), s(1)(0), s(1)(1), s(1)(2)),
                    (s(2)(2), s(2)(3), s(2)(0), s(2)(1)),
                    (s(3)(1), s(3)(2), s(3)(3), s(3)(0))); 
        return s_prime;
    end function;

    function inv_mix_cols(s :state_t) return state_t is
        variable s_prime : state_t;
    begin
        for c in 0 to Nb loop
            s_prime(0)(c) := x"0e" * s(0)(c) xor x"0b" * s(1)(c) xor x"0d" * s(2)(c) xor x"09" * s(3)(c); 
            s_prime(1)(c) := x"09" * s(0)(c) xor x"0e" * s(1)(c) xor x"0b" * s(2)(c) xor x"0d" * s(3)(c);
            s_prime(2)(c) := x"0d" * s(0)(c) xor x"09" * s(1)(c) xor x"0e" * s(2)(c) xor x"0b" * s(3)(c);
            s_prime(3)(c) := x"0b" * s(0)(c) xor x"0d" * s(1)(c) xor x"09" * s(2)(c) xor x"09" * s(3)(c);
        end loop;
        return s_prime;
    end function;

    function xor_word(w1, w2 : word_t) return word_t is 
        variable w3 : word_t;
    begin
        for b in 0 to 3 loop
            w3(b) := w1(b) xor w2(b);
        end loop;
        return w3;
    end function;

    function print_word(w : word_t) return integer is 
    begin
        report to_hstring(to_bitvector(w(3))) &
               to_hstring(to_bitvector(w(2))) &
               to_hstring(to_bitvector(w(1))) &
               to_hstring(to_bitvector(w(0))) ;
        return 0;
    end function;

    function print_state(s : state_t) return integer is 
    begin
        report to_hstring(to_bitvector(s(0)(0))) & to_hstring(to_bitvector(s(1)(0))) & to_hstring(to_bitvector(s(2)(0))) & to_hstring(to_bitvector(s(3)(0))) &
               to_hstring(to_bitvector(s(0)(1))) & to_hstring(to_bitvector(s(1)(1))) & to_hstring(to_bitvector(s(2)(1))) & to_hstring(to_bitvector(s(3)(1))) &
               to_hstring(to_bitvector(s(0)(2))) & to_hstring(to_bitvector(s(1)(2))) & to_hstring(to_bitvector(s(2)(2))) & to_hstring(to_bitvector(s(3)(2))) &
               to_hstring(to_bitvector(s(0)(3))) & to_hstring(to_bitvector(s(1)(3))) & to_hstring(to_bitvector(s(2)(3))) & to_hstring(to_bitvector(s(3)(3)));
        return 0;
    end function;

    function expand_key(key : std_logic_vector(key_size-1 downto 0)) return key_schedule_t is
        variable temp : word_t;
        variable key_sched_wv : key_schedule_wv;
        variable key_schedule : key_schedule_t(0 to Nr);
        variable x : integer;
    begin
        for w in 0 to Nk-1 loop
            key_sched_wv(w) := slv_to_word(key(key_size-w*32-1 downto key_size-(w+1)*32));
        end loop;
        for w in Nk to Nk*(Nr+1)-1 loop
            temp := key_sched_wv(w-1);
            if w mod Nk = 0 then
                temp := rot_word(temp);
                temp := sub_word(temp);
                temp := xor_word(temp, rcon(w/Nk-1));
                report "";
            end if;
            key_sched_wv(w) := xor_word(key_sched_wv(w-Nk), temp);
        end loop;
        for round in 0 to Nr loop
            for word in 0 to Nk-1 loop
                key_schedule(round)(127-32*word downto 128-32*(word+1)) := word_to_slv(key_sched_wv(4*round+word)); 
            end loop;
        end loop; 
        return key_schedule;
    end function;   

end package body;