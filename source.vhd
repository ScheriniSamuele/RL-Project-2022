---------------------------------------------------------------------------------------
-- Engineers: Francesco Palumbo 
--            Samuele Scherini
-- 
-- Module Name: 10711027_10674683 - Behavioral
-- Project Name: project_reti_logiche
-- Description:  Si definiscano una sequenza continua di W parole in ingresso, 
-- ognuna lunga 8 bit, forniteci da una memoria, lo scopo del progetto è implementare 
-- un modulo hardware, descritto in VHDL, che restituisce una sequenza continua di Z parole, 
-- sempre di 8 bit, a valle di un processo di convoluzione.
-- 
-- Revision:
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
port (
    i_clk : in std_logic;
    i_rst : in std_logic;
    i_start : in std_logic;
    i_data : in std_logic_vector(7 downto 0);
    o_address : out std_logic_vector(15 downto 0);
    o_done : out std_logic;
    o_en : out std_logic;
    o_we : out std_logic;
    o_data : out std_logic_vector (7 downto 0)
);
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

    type state_type is (RESET, REQUEST_LENGTH, WAIT_RAM, GET_LENGTH, 
                        CHECK_LENGTH, GET_WORD, CONV0, CONV1, CONV2, CONV3, MEM_WRITE,
                        WRITE_W1, WRITE_W2, DONE);
                        
    signal state_reg, state_next, state_conv, state_conv_next: state_type;

    signal o_done_next, o_en_next, o_we_next : std_logic := '0';
  signal o_data_next : std_logic_vector(7 downto 0) := "00000000";
  signal o_address_next : std_logic_vector(15 downto 0) := "0000000000000000";
  
  signal word, word_next : std_logic_vector(7 downto 0) := "00000000";
  signal got_length, got_length_next : boolean := false;
  signal address_reg, address_next, w_add, w_add_next : std_logic_vector(15 downto 0) := "0000000000000000";
  signal length, length_next : integer range 0 to 255 := 0;
  signal i, i_next : integer range -1 to 8 := 7;
  signal Z, Z_next : std_logic_vector(15 downto 0) := "0000000000000000";

begin

process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            got_length <= false;
            address_reg <= "0000000000000000";
            word <= "00000000";
            length <= 0;
            i <= 7;
            Z <= "0000000000000000";
            state_conv <= CONV0;
            w_add <= "0000001111101000";
            
            state_reg <= RESET;
            
        elsif(i_clk'event and i_clk='1') then
            o_done <= o_done_next;
            o_en <= o_en_next;
            o_we <= o_we_next;
            o_data <= o_data_next;
            o_address <= o_address_next;
            w_add <= w_add_next;
            address_reg <= address_next;
            length <= length_next;
            got_length <= got_length_next;
            i <= i_next;
            word <= word_next;
            Z <= Z_next;
            state_conv <= state_conv_next;
            
            state_reg <= state_next;
            
        end if;                  
        end process;
        
        process(state_reg, i_data, i_start, word, length, i, got_length, Z, address_reg, w_add)
        begin
        
            o_done_next <= '0';
            o_en_next <= '0';
            o_we_next <= '0';
            o_data_next <= "00000000";
            o_address_next <= "0000000000000000";
            state_conv_next <= CONV0;
            w_add_next <= "0000001111101000";
            length_next <= length;
            address_next <= address_reg;
            got_length_next <= got_length;
            i_next <= i;
            word_next <= word;
            Z_next <= Z;
            w_add_next <= w_add;
            state_next <= state_reg;
            state_conv_next <= state_conv; 
            
            case state_reg is 
                when RESET =>
                    if(i_start = '1') then
                        state_next <= REQUEST_LENGTH;
                        state_conv_next <= CONV0;
                    end if;
                
                when REQUEST_LENGTH =>
                    o_en_next <= '1';
                    o_we_next <= '0';
                    o_address_next <= "0000000000000000";  
                    address_next <= "0000000000000000";
                    w_add_next <= "0000001111101000";
                    state_next <= WAIT_RAM;
                    
                when WAIT_RAM =>
                    --address_next <= o_address_next;
                    if(not got_length) then
                        state_next <= GET_LENGTH;
                    else
                        state_next <= GET_WORD;
                    end if;
                
                when GET_LENGTH =>
                    length_next <= conv_integer(i_data);
                    got_length_next <= true;
                    state_next <= CHECK_LENGTH;
                    
                when CHECK_LENGTH =>
                    if(length = 0) then 
                        o_done_next <= '1';
                        state_next <= DONE;
                    else
                        o_address_next <= address_reg + "0000000000000001";
                        address_next <= address_reg + "0000000000000001";
                        o_en_next <= '1';
                        o_we_next <= '0';
                        Z_next <= "0000000000000000";
                        state_next <= WAIT_RAM;
                    end if;
                  
                when GET_WORD =>
                    word_next <= i_data; 
                    i_next <= 7;
                    state_next <= state_conv_next;

                when CONV0 =>
                    if(i<0) then
                        state_conv_next <= CONV0;
                        state_next <= MEM_WRITE;
                    elsif (word(i)= '0') then
                        Z_next(2*i+1) <= '0';
                        Z_next(2*i) <= '0';
                        i_next <= i - 1;
                        state_next <= CONV0;
                    elsif(word(i)= '1') then
                        Z_next(2*i+1) <= '1';
                        Z_next(2*i) <= '1';
                        i_next <= i - 1;
                        state_next <= CONV2;
                    end if;
                    
                when CONV1=>
                    if(i<0) then
                        state_conv_next <= CONV1;
                        state_next <= MEM_WRITE;
                    elsif(word(i)= '0') then
                        Z_next(2*i+1) <= '1';
                        Z_next(2*i) <= '1';
                        i_next <= i - 1;
                        state_next <= CONV0;
                    elsif(word(i)= '1') then
                        Z_next(2*i+1) <= '0';
                        Z_next(2*i) <= '0';
                        i_next <= i - 1;
                        state_next <= CONV2;
                    end if;
                    
                when CONV2=>
                    if(i<0) then
		                state_conv_next <= CONV2;
                        state_next <= MEM_WRITE;
                    elsif(word(i)= '0') then
                        Z_next(2*i+1) <= '0';
                        Z_next(2*i) <= '1';
                        i_next <= i - 1;
                        state_next <= CONV1;
                    elsif(word(i)= '1') then
                        Z_next(2*i+1) <= '1';
                        Z_next(2*i) <= '0';
                        i_next <= i - 1;
                        state_next <= CONV3;
                    end if;
                       
                when CONV3=>
                    if(i<0) then
                        state_conv_next <= CONV3;
                        state_next <= MEM_WRITE;
                    elsif(word(i)= '0') then
                        Z_next(2*i+1) <= '1';
                        Z_next(2*i) <= '0';
                        i_next <= i - 1;
                        state_next <= CONV1;
                    elsif(word(i)= '1') then
                        Z_next(2*i+1) <= '0';
                        Z_next(2*i) <= '1';
                        i_next <= i - 1;
                        state_next <= CONV3;
                    end if;
                        
                when MEM_WRITE =>
                    o_en_next <= '1';
                    o_we_next <= '1';
                    o_data_next <= Z(15 downto 8);
                    o_address_next <= w_add;
                    state_next <= WRITE_W1;
                    
                when WRITE_W1 =>
                    o_en_next <= '1';
                    o_we_next <= '1';
                    o_address_next <= w_add + "0000000000000001";
                    w_add_next <= w_add + "0000000000000001";
                    o_data_next <= Z(7 downto 0);
                    state_next <= WRITE_W2;
                    
                when WRITE_W2 =>
                    w_add_next <= w_add + "0000000000000001";
                    length_next <= length - 1;
                    state_next <= CHECK_LENGTH;
                    
                when DONE =>
                    if(i_start='0') then 
                        o_address_next <= "0000000000000000";
                        address_next <= "0000000000000000";
                        w_add_next <= "0000001111101000";
                        got_length_next <= false;
                        length_next <= 0;
                        i_next <= 7;
                        Z_next <= "0000000000000000";
                        state_conv_next <= CONV0;
                        state_next <= RESET;
                     end if;
            
             end case;   
        

        end process;
end behavioral;