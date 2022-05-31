//==============================================================================
// Copyright (c) 2022 agithubber777
//------------------------------------------------------------------------------
// Module      : wm8731_def
// Description : WM8731 definitions
// Author      : agithubber777
// Created     : 2022/05/31
//------------------------------------------------------------------------------
// Version Control Log:
//
// File$
// Revision$
// Author$
// Date$
//==============================================================================
// Configuration Interface parameters
`define   WM8731_I2C_ADDR 7'b0011010  // WM8731 I2C Slave Address

// WM8731 Operating parameters (Initial Configuration)

//  Left Line IN (7'h00)
`define   LRINBOTH  1'b0        // Disable simultaneous load
`define   LINMUTE   1'b0        // Disable mute
`define   LINVOL    5'b01110    // Volume = -21 dB
//  Right Line IN (7'h01)
`define   RLINBOTH  1'b0        // Disable simultaneous load
`define   RINMUTE   1'b0        // Disable mute
`define   RINVOL    5'b01110    // Volume = -21 dB
//  Left Headphone Out (7'h02)
`define   LRHPBOTH  1'b0        // Disable simultaneous load
`define   LZCEN     1'b0        // Disable zero cross detect
`define   LHPVOL    7'b1111111  // Volume = +6 dB
//  Right Headphone Out (7'h03)
`define   RLHPBOTH  1'b0        // Disable simultaneous load
`define   RZCEN     1'b0        // Disable zero cross detect
`define   RHPVOL    7'b1111111  // Volume = +6 dB
//  Analog Audio Path Control (7'h04)
`define   SIDEATT   2'b11       // Side Tone Attenuation = -15 dB
`define   SIDETONE  1'b0        // Disable Side Tone
`define   DACSEL    1'b1        // Select DAC
`define   BYPASS    1'b0        // Disable Bypass
`define   INSEL     1'b0        // Line Input Select to ADC
`define   MUTEMIC   1'b1        // Enable Microphone Input Mute to ADC
`define   MICBOOST  1'b0        // Disable Microphone Input Level Boost
//  Digital Audio Path Control (7'h05)
`define   HPOR      1'b0        // Clear DC offset
`define   DACMU     1'b0        // Disable DAC soft mute
`define   DEEMPH    2'b00       // Disable De-emphasis control
`define   ADCHPD    1'b0        // Enable ADC High Pass filter
//  Power Down Control (7'h06)
`define   PWROFF    1'b0        // Disable POWEROFF mode
`define   CLKOUTPD  1'b0        // Disable CLKOUT power down
`define   OSCPD     1'b0        // Disable Oscillator power down
`define   OUTPD     1'b0        // Disable Outputs power down
`define   DACPD     1'b0        // Disable DAC power down
`define   ADCPD     1'b0        // Disable ADC power down
`define   MICPD     1'b1        // Enable Microphone Input power down
`define   LINEINPD  1'b0        // Disable Line Input Power Down
//  Digital Audio Interface Format (7'h07)
`define   BCLKINV   1'b0        // Don't invert Bit Clock BCLK
`define   MS        1'b1        // Enable Master mode
`define   LRSWAP    1'b0        // Right channel DAC data right
`define   LRP       1'b0        // DACLRC Phase Control
`define   IWL       2'b00       // Input audio data length = 16 bits
`define   FORMAT    2'b10       // Audio data format : 10 - I2S, 11 - PCM
//  Sampling Control (7'h08)
`define   CLKODIV2  1'b0        // CLOCKOUT is core clock
`define   CLKIDIV2  1'b0        // Core clock is MCLK
`define   SR        4'b0011     // ADC and DAC sampling rate = 8 kHz
`define   BOSR      1'b1        // Base oversampling rate = 384 fs
`define   USBNORM   1'b0        // Normal Mode 256/384 fs
//  Active Control (7'h09)
`define   ACTIVE    1'b1        // Activate interface