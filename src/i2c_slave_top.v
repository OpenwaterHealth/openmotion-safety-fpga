// SPDX-License-Identifier: AGPL-3.0-or-later
///////////////////////////////////////////////////////////////////////////////////////////////////
// Company: <Name>
//
// File: top.v
// File history:
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//      <Revision number>: <Date>: <Comments>
//
// Description: 
//
// <Description here>
//
// Targeted device: <Family::ProASIC3> <Die::A3PN010> <Package::48 QFN>
// Author: <Name>
//
/////////////////////////////////////////////////////////////////////////////////////////////////// 
`timescale 1ns / 1ps

module i2c_slave_top( 
    input     	   rstn,                 	 
    input    	   clk,              	     
	
    inout     	   scl,             		 
    inout     	   sda,             		 
			
    input [15:0]  temperature_sensor,
    input [7:0]   revision,
    input [7:0]   minor,
    input [7:0]   major,
    input [7:0]   ID,

    input [15:0]  adc_data,
    input [15:0]  adc_data_old_value,
    input [15:0]  peak_power_value,
    input [15:0]  peak_power_min,
    input [15:0]  peak_power_max,
    input [15:0]  cw_power_value,
    input [15:0]  peak_power_value_capture,
    input [15:0]  drive_current_limit_capture,

    input [7:0]   monitor_status,
    input [7:0]   status,

    output [31:0] pulse_width_lower_limit,
    output [31:0] pulse_width_upper_limit,
    output [31:0] rate_lower_limit,
    output [15:0] drive_current_limit,
    output [15:0] cw_current_limit,
    output [15:0] dynamic_control,
    output [15:0] static_control,            
    output         peak_power_read

);

wire start;
wire stop;
wire data_vld;
wire r_w;
wire [7:0] data_in;
wire [7:0] data_out;
wire stretch_on;
		
i2cslave_controller_top i2cslave_controller_top (
	.scl 		(scl),
	.sda 		(sda),
	.clk 		(clk),
	.reset 		(!rstn),
	.stretch_on (stretch_on),
	.data_in 	(data_in),

	.start 		(start),
	.stop 		(stop),
	.data_vld 	(data_vld),
	.r_w 		(r_w),
	.data_out 	(data_out)
);

registers registers(
	.clk 					(clk),
	.rst 					(!rstn),
	.SCL 					(scl),
	.data_to_i2c 			(data_in),
	.start 					(start),
	.stop 					(stop),
	.data_vld 				(data_vld),
	.r_w 					(r_w),
	.i2c_to_data			(data_out),
	.stretch_on             (stretch_on),

	.temperature_sensor     (temperature_sensor),
	.revision     			(revision),
	.minor     				(minor),
	.major     				(major),
	.ID     				(ID),

	.adc_data 		        (adc_data),
	.adc_data_old_value     (adc_data_old_value),
	.peak_power_value       (peak_power_value),
	.peak_power_min         (peak_power_min),
	.peak_power_max         (peak_power_max),
	.cw_power_value         (cw_power_value),
    .peak_power_value_capture    (peak_power_value_capture),
    .drive_current_limit_capture (drive_current_limit_capture),

	.monitor_status 		(monitor_status),
	.status 				(status),
	
    .pulse_width_lower_limit (pulse_width_lower_limit),
    .pulse_width_upper_limit (pulse_width_upper_limit),
    .rate_lower_limit     	  (rate_lower_limit),
    .drive_current_limit     (drive_current_limit),
    .cw_current_limit        (cw_current_limit),
    .dynamic_control 	     (dynamic_control),
    .static_control 	     (static_control),
    .peak_power_read 	     (peak_power_read)

);
 

endmodule

