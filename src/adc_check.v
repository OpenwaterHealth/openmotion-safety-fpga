// SPDX-License-Identifier: AGPL-3.0-or-later

module adc_check( 
    input        rstn,
    input        clk,
    input        clear_fail,

    input        adc_data_valid,
    input [15:0] adc_data,

    input [31:0] drive_current_limit,
    input [31:0] power_peak_current_limit,

    output       current_limit_fail

);

adc_current_check adc_current_check( 
    .rstn                    (rstn),
    .clk                     (clk),
    .clear_fail              (clear_fail),

    .drive_current_limit     (drive_current_limit),
	
    .adc_data_valid          (adc_data_valid),
    .adc_data                (adc_data),

    .current_limit_fail      (current_limit_fail)

);

endmodule
