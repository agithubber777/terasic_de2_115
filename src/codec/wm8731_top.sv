//==============================================================================
// Copyright (C) 2023 agithubber777
//------------------------------------------------------------------------------
// File        : wm8731_top.sv
// Description : WM8731 Control Top
// Author      : agithubber777 (agit.hubber@gmail.com)
// Created     : 2022/05/31
//==============================================================================
module wm8731_top #(
    parameter
        MCLK_FREQ = 50000000,                           // Main Clock Frequency (Hz)
        I2C_SCL_FREQ = 100000,                          // I2C SCL Frequency (Hz)
        I2C_CLK_COUNT = 500
) (
// Control Signals
    input                           i_clk,              // Global Clock
    input                           i_rstn,             // Global Reset
    input                           i_drv_if_mode,      // Interface Mode (1 - I2S Mode (default)
                                                        //                 0 - DSP/PCM Mode)
    output logic                    o_wm8731_clk,       // WM8731 Clock (18.4 MHz)
    output logic                    o_data_ready,       // Parallel Data Ready Strobe
// WM8731 Digital Audio Interface
    input                           i_bclk,             // Bit Clock
    input                           i_adc_lrck,         // ADC Left/Right Clock
    input                           i_dac_lrck,         // DAC Left/Right Clock
    input                           i_adc_data,         // Serial ADC Data
    output logic                    o_dac_data,         // Serial DAC Data
// WM8731 I2C Interface
    output logic                    o_i2c_done,         // I2C Configuration Done Flag
    output logic                    o_i2c_scl,          // I2C Serial Clock
    inout                           io_i2c_sda,         // I2C Serial Data
// WM8731 Config Interface
    input                   [06:00] i_cfg_reg_addr,     // WM8731 Internal Register Address
    input                   [08:00] i_cfg_reg_data,     // WM8731 Internal Register Data
    input                           i_cfg_start,        // Start WM8731 Re-config
// Parallel Data Interface
    input         signed    [15:00] i_tx_pdata_left,    // Left Channel Parallel Data for Transmitting
    input         signed    [15:00] i_tx_pdata_right,   // Right Channel Parallel Data for Transmitting
    output logic  signed    [15:00] o_rx_pdata_left,    // Left Channel Received Parallel Data
    output logic  signed    [15:00] o_rx_pdata_right    // Right Channel Received Parallel Data
);

localparam EVENT_COUNT_MAX = MCLK_FREQ / I2C_SCL_FREQ;

endmodule