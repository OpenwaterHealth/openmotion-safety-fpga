// SPDX-License-Identifier: AGPL-3.0-or-later

module power_peak_check_top( 
    input            rstn,
    input            clk,
    input            laser_pulse,
    input            clear_power_fail,
    input            clear_peak_power,
    input            peak_power_read,

    input            adc_sdo,

    output           adc_sck,
    output           adc_convert,

    input [15:0]    cw_current_limit,
    input [15:0]    drive_current_limit,
    output           adc_data_valid,
    output [15:0]   adc_data_value,
	output [15:0]   adc_data_old_value,
    output [15:0]   peak_power_value,
    output [15:0]   peak_power_min,
    output [15:0]   peak_power_max,

    output [15:0]   cw_power_value,
    output [15:0]   peak_power_value_capture,
    output [15:0]   drive_current_limit_capture,

    output           cw_current_limit_fail,
    output           power_peak_current_limit_fail,
    output           start_timer,
	output           laser_pulse_delay

);


adc_control adc_control( 
    .rstn      			(rstn),
    .clk       			(clk),
    .laser_pulse 		(laser_pulse),
    .clear_peak_power 	(clear_peak_power),
    .peak_power_read 	(peak_power_read),

    .adc_sdo 			(adc_sdo),
    .adc_sck 			(adc_sck),
    .adc_convert 		(adc_convert),
    .adc_data_valid 	(adc_data_valid),
    .adc_data_value 	(adc_data_value),
    .adc_data_old_value (adc_data_old_value),
    .peak_power_value   (peak_power_value), 
    .peak_power_min     (peak_power_min), 
    .peak_power_max     (peak_power_max), 
    .cw_power_value     (cw_power_value),
    .start_timer        (start_timer),
    .laser_pulse_delay  (laser_pulse_delay)

);

power_peak_check power_peak_check( 
    .rstn      						(rstn),
    .clk       						(clk),
    .laser_pulse 		            (laser_pulse),
    .clear_power_fail 	            (clear_power_fail),
    .adc_data_valid 				(adc_data_valid),
    .adc_data_value 				(adc_data_value),
    .adc_data_old_value 			(adc_data_old_value),
    .peak_power_value              (peak_power_value), 
    .cw_power_value                (cw_power_value), 

    .cw_current_limit 		        (cw_current_limit),
    .drive_current_limit 		    (drive_current_limit),
    .peak_power_value_capture 		(peak_power_value_capture),
    .drive_current_limit_capture   (drive_current_limit_capture),
	
    .cw_current_limit_fail     	    (cw_current_limit_fail),
    .power_peak_current_limit_fail 	(power_peak_current_limit_fail)
);



endmodule

