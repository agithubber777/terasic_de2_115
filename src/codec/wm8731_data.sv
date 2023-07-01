//==============================================================================
// Copyright (C) 2023 agithubber777
//------------------------------------------------------------------------------
// File        : wm8731_data.sv
// Description : WM8731 Data Interface
// Author      : agithubber777 (agit.hubber@gmail.com)
// Created     : 2022/05/31
//==============================================================================
`define I2S   1'b1
`define PCM   1'b0

module wm8731_rtx
(
// Input Ports
    input                           i_clk,
    input                           i_rstn,
    input                           i_bclk,
    input                           i_lrck,
    input                           i_din,
    input        signed   [15:00]   i_data_left,
    input        signed   [15:00]   i_data_right,
    input                           i_mode,     // 1 - I2S Mode (default)
                                                // 0 - DSP/PCM Mode
// Output Ports
    output logic                    o_dout,
    output logic                    o_strobe,
    output logic signed   [15:00]   o_data_left,
    output logic signed   [15:00]   o_data_right
);

// ---------- Input Syncronizers ---------- //
logic       bclk_async, bclk_sync;
logic       lrck_async, lrck_sync;
logic       din_async, din_sync;

always_ff @(posedge i_clk) bclk_async <= i_bclk;
always_ff @(posedge i_clk) bclk_sync <= bclk_async;

always_ff @(posedge i_clk) lrck_async <= i_lrck;
always_ff @(posedge i_clk) lrck_sync <= lrck_async;

always_ff @(posedge i_clk) din_async  <= i_din;
always_ff @(posedge i_clk) din_sync  <= din_async;
// --------------------------------------- //

// ---------- Edge Detectors ---------- //
logic   [02:00]     lrck_ed, bclk_ed;

logic lrck_re = ~lrck_ed[1] &  lrck_ed[0];
logic lrck_fe =  lrck_ed[1] & ~lrck_ed[0];

logic bclk_re = ~bclk_ed[1] &  bclk_ed[0];
logic bclk_fe =  bclk_ed[1] & ~bclk_ed[0];

always_ff @(posedge i_clk) begin : edge_detect
    if (!i_rstn) begin
        lrck_ed <= 3'b0;
        bclk_ed <= 3'b0;
    end
    else begin
        lrck_ed <= {lrck_ed[01:00], lrck_sync};
        bclk_ed <= {bclk_ed[01:00], bclk_sync};
    end
end
// ----------------------------------- //

// ---------- Bit Pointers ---------- //
logic [04:00] bitptr_i2s;
logic [05:00] bitptr_pcm;

// I2S Mode Bit Pointer
always_ff @(posedge i_clk) begin : i2s_bit_ptr_mngmnt
    if (!i_rstn)
        bitptr_i2s <= 5'd31;
    else begin
        if (lrck_fe)
            bitptr_i2s <= 5'd16;
        else if (lrck_re)
            bitptr_i2s <= 5'd16;
        else if (bitptr_i2s == 5'd31)
            bitptr_i2s <= 5'd17;
        else if (bitptr_i2s == 5'd17)
            bitptr_i2s <= 5'd17;
        else if (bclk_re)
            bitptr_i2s <= bitptr_i2s - 1'b1;
    end
end

// PCM Mode Bit Pointer
always_ff @(posedge i_clk) begin : pcm_bit_ptr_mngmnt
    if (!i_rstn)
        bitptr_pcm <= 6'd63;
    else begin
        if (lrck_re)
            bitptr_pcm <= 6'd32;
        else if (bitptr_pcm == 6'd63)
            bitptr_pcm <= 6'd33;
        else if (bitptr_pcm == 6'd33)
            bitptr_pcm <= 6'd33;
        else if (bclk_re)
            bitptr_pcm <= bitptr_pcm - 1'b1;
    end
end
// ----------------------------------- //

// ---------- Data Strobe Generator ---------- //
always_ff @(posedge i_clk) begin : strobe_gen
    if (!i_rstn)
        o_strobe <= 1'b0;
    else begin
        if (i_mode == `I2S)
            o_strobe <= lrck_fe & ~lrck_sync;
        else
            o_strobe <= (bitptr_pcm == 6'd32);
    end
end
// ------------------------------------------ //

// ---------- Serial Data Receiver ---------- //
logic   [17:00] i2s_rx_buf_l, i2s_rx_buf_r;
logic   [33:00] pcm_rx_buf;

always_ff @(posedge i_clk) begin : serial_rcvr
    if (!i_rstn) begin
        i2s_rx_buf_l <= 18'h0;
        i2s_rx_buf_r <= 18'h0;
        pcm_rx_buf   <= 34'h0;
    end
    else begin
        if (bclk_re) begin
            if (i_mode == `I2S) begin
                if (!lrck_sync)
                    i2s_rx_buf_l[bitptr_i2s] <= din_sync;
                else
                    i2s_rx_buf_r[bitptr_i2s] <= din_sync;
            end
            else
                pcm_rx_buf[bitptr_pcm] <= din_sync;
        end
    end
end

always_ff @(posedge i_clk) begin : set_rcvr_out
    if (!i_rstn) begin
        o_data_left <= 16'h0;
        o_data_right <= 16'h0;
    end
    else begin
        if (o_strobe) begin
            if (i_mode == `I2S) begin
                o_data_left <= i2s_rx_buf_l[15:00];
                o_data_right <= i2s_rx_buf_r[15:00];
            end
            else begin
                o_data_left <= pcm_rx_buf[31:16];
                o_data_right <= pcm_rx_buf[15:00];
            end
        end
    end
end
// ------------------------------------------ //

// ---------- Serial Data Transmitter ---------- //
logic   [17:00]  i2s_tx_buf_l, i2s_tx_buf_r;
logic   [33:00]  pcm_tx_buf;

always_ff @(posedge i_clk) begin : set_tmit_in
    if (!i_rstn) begin
        i2s_tx_buf_l <= 18'h0;
        i2s_tx_buf_r <= 18'h0;
        pcm_tx_buf   <= 34'h0;
    end
    else begin
        if (o_strobe) begin
            if (i_mode == `I2S) begin
                i2s_tx_buf_l <= {2'b00, i_data_left};
                i2s_tx_buf_r <= {2'b00, i_data_right};
            end
            else
                pcm_tx_buf <= {2'b00, i_data_left, i_data_right};
        end
    end
end

always_ff @(posedge i_clk) begin : serial_tmtr
    if (!i_rstn)
        o_dout <= 1'b0;
    else begin
        if (bclk_fe) begin
            if (i_mode == `I2S) begin
                if (!lrck_sync)
                    o_dout <= i2s_tx_buf_l[bitptr_i2s];
                else
                    o_dout <= i2s_tx_buf_r[bitptr_i2s];
            end
            else
                o_dout <= pcm_tx_buf[bitptr_pcm];
        end
    end
end
// --------------------------------------------- //

endmodule