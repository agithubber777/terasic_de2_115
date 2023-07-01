//==============================================================================
// Copyright (C) 2023 agithubber777
//------------------------------------------------------------------------------
// File        : wm8731_reg.sv
// Description : WM8731 Config Register Control
// Author      : agithubber777 (agit.hubber@gmail.com)
// Created     : 2022/05/31
//==============================================================================
`include "wm8731_def.svh"

module wm8731_reg #(
    parameter p_CLK_COUNT = 500
) (
    input               i_clk,
    input               i_rstn,
    input       [06:00] i_reg_addr,
    input       [08:00] i_reg_data,
    input               i_start,
    inout               io_i2c_sda,
    output logic        o_i2c_scl,
    output logic        o_done
);

// I2C States
typedef enum logic [2:0] { s_INIT,
                           s_START,
                           s_SEND_BYTE,
                           s_GET_ACK,
                           s_STOP,
                           s_IDLE } state_t;
// ***

state_t             state,
                    nextstate;

logic   [04:00]     i2c_event_cnt;
logic               sda;

logic   [15:00]     init_cfg_mem [00:10];
logic   [03:00]     init_cfg_addr;
logic               init_cfg_done;
logic               runtime_cfg_done;
logic   [23:00]     i2c_tx_buffer;
logic               error;

logic   [02:00]     i2c_bit_cnt = i2c_event_cnt[02:00];

int                 clk_counter;

logic               clk_cnt_strobe = (clk_counter == p_CLK_COUNT);

// *** Assignments
assign io_i2c_sda = sda ? 1'bz : 1'b0;
assign o_done = !i_rstn ? 1'b0 : init_cfg_done && runtime_cfg_done;
// *** End of Assignments

// *** Counters handling
always_ff @(posedge i_clk) begin
    case (state)
        s_INIT : clk_counter <= 0;

        s_START : begin
            i2c_event_cnt <= 5'd23;
            if (clk_cnt_strobe)
                clk_counter <= 'd0;
            else
                clk_counter <= clk_counter + 1'b1;
        end

        s_SEND_BYTE : begin
            if (clk_cnt_strobe) begin
                i2c_event_cnt <= i2c_event_cnt - 1'b1;
                clk_counter <= 'd0;
            end
            else
                clk_counter <= clk_counter + 1'b1;
        end

        s_GET_ACK : begin
            if (clk_cnt_strobe)
                clk_counter <= 'd0;
            else
                clk_counter <= clk_counter + 1'b1;
        end

        s_STOP : begin
            if (clk_cnt_strobe)
                clk_counter <= 0;
            else
                clk_counter <= clk_counter + 1'b1;
        end

        s_IDLE : clk_counter <= 'd0;
        default : clk_counter <= 'd0;
    endcase
end
// *** End of Counters handling

// *** I2C Control FSM
always_ff @(posedge i_clk) begin : I2C_FSM_SEQ
    if (!i_rstn)
        state <= s_INIT;
    else
        state <= nextstate;
end

always_comb begin : I2C_FSM_COMB
    case (state)
        s_INIT : begin
            nextstate = s_START;
        end

        s_START : begin
            if (clk_cnt_strobe)
                nextstate = s_SEND_BYTE;
            else
                nextstate = s_START;
        end

        s_SEND_BYTE : begin
            if (clk_cnt_strobe) begin
                if (i2c_bit_cnt == 3'd0)
                    nextstate = s_GET_ACK;
                else
                    nextstate = s_SEND_BYTE;
                end
            else
                nextstate = s_SEND_BYTE;
        end

        s_GET_ACK : begin
            if (clk_cnt_strobe) begin
                if ((i2c_event_cnt == 5'd31) || error)
                    nextstate = s_STOP;
                else
                    nextstate = s_SEND_BYTE;
            end
            else
                nextstate = s_GET_ACK;
        end

        s_STOP : begin
            if (clk_cnt_strobe) begin
                if ((init_cfg_addr == 4'd10) || runtime_cfg_done)
                    nextstate = s_IDLE;
                else
                    nextstate = s_START;
            end
            else
                nextstate = s_STOP;
        end

        s_IDLE : begin
            if (i_start)
                nextstate = s_START;
            else
                nextstate = s_IDLE;
        end
        default : nextstate = s_IDLE;
    endcase
end

always_ff @(posedge i_clk) begin : I2C_FSM_COND
    case (state)
        s_INIT : begin
            init_cfg_addr <= 4'd0;
            init_cfg_mem[00] <= {7'b0001111, 9'b000000000};
            init_cfg_mem[01] <= {7'b0000000, `LRINBOTH, `LINMUTE, 2'b00, `LINVOL};
            init_cfg_mem[02] <= {7'b0000001, `RLINBOTH, `RINMUTE, 2'b00, `RINVOL};
            init_cfg_mem[03] <= {7'b0000010, `LRHPBOTH, `LZCEN, `LHPVOL};
            init_cfg_mem[04] <= {7'b0000011, `RLHPBOTH, `RZCEN, `RHPVOL};
            init_cfg_mem[05] <= {7'b0000100, 1'b0, `SIDEATT, `SIDETONE, `DACSEL, `BYPASS, `INSEL, `MUTEMIC, `MICBOOST};
            init_cfg_mem[06] <= {7'b0000101, 4'b0, `HPOR, `DACMU, `DEEMPH, `ADCHPD};
            init_cfg_mem[07] <= {7'b0000110, 1'b0, `PWROFF, `CLKOUTPD, `OSCPD, `OUTPD, `DACPD, `ADCPD, `MICPD, `LINEINPD};
            init_cfg_mem[08] <= {7'b0000111, 1'b0, `BCLKINV, `MS, `LRSWAP, `LRP, `IWL, `FORMAT};
            init_cfg_mem[09] <= {7'b0001000, 1'b0, `CLKODIV2, `CLKIDIV2, `SR, `BOSR, `USBNORM};
            init_cfg_mem[10] <= {7'b0001001, 8'b00000000, `ACTIVE};
            sda <= 1'b1;
            o_i2c_scl <= 1'b1;
            init_cfg_done <= 1'b0;
        end

        s_START : begin
            error <= 1'b0;
            runtime_cfg_done <= 1'b0;
            o_i2c_scl <= 1'b1;

            if (init_cfg_done)
            i2c_tx_buffer <= {`WM8731_I2C_ADDR, 1'b0, i_reg_addr, i_reg_data};
            else
            i2c_tx_buffer <= {`WM8731_I2C_ADDR, 1'b0, init_cfg_mem[init_cfg_addr]};

            if (clk_counter >= p_CLK_COUNT >> 1)
                sda <= 1'b0;
        end

        s_SEND_BYTE : begin
            sda <= i2c_tx_buffer[i2c_event_cnt];
            if (clk_counter >= p_CLK_COUNT >> 1)
                o_i2c_scl <= 1'b1;
            else
                o_i2c_scl <= 1'b0;
        end

        s_GET_ACK : begin
            error <= io_i2c_sda;
            sda <= 1'b0;
            if (clk_counter >= p_CLK_COUNT >> 1)
                o_i2c_scl <= 1'b1;
            else
                o_i2c_scl <= 1'b0;
        end

        s_STOP : begin
            if (init_cfg_done)
                runtime_cfg_done <= 1'b1;

            if (clk_counter >= p_CLK_COUNT >> 1)
                o_i2c_scl <= 1'b1;
            else
                o_i2c_scl <= 1'b0;

            if (clk_cnt_strobe) begin
                sda <= 1'b1;
                if (!error && !init_cfg_done)
                    init_cfg_addr <= init_cfg_addr + 1'b1;
            end
        end

        s_IDLE : begin
            init_cfg_done <= 1'b1;
            runtime_cfg_done <= 1'b1;
        end

        default : begin
            sda <= 1'b1;
            o_i2c_scl <= 1'b1;
            init_cfg_done <= 1'b1;
            runtime_cfg_done <= 1'b1;
        end
    endcase
end
// *** End of I2C Control FSM

endmodule