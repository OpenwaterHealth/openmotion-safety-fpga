// SPDX-License-Identifier: AGPL-3.0-or-later
`timescale 1ns / 1ps



//Seed DDS: 0 mA (Limit 80mA)
//Seed CW: 140 mA (Limit 140mA)

//Pulse width limit, upper: 0µs
//Pulse width limit, upper: 225µs
//Period limit: 22500µs

//CW Current: 160mA
//PWM Current: 80mA


module top( 
    input     rstn,                    // Pin 21
//    input     system_reset_n,          // Pin 13
	
	input 	  scl_cfg,
	inout	  sda_cfg,

    input     clk_50mhz,               // Pin 1
	input     laser_pulse,             // Pin 7
	input     select,                  // Pin 78    0=EE, 1=OPT
	
	output    laser_pwr_en1_n,      	// Pin 18
	output    watchdog_timeout_led_n,  // Pin 25
	output    calibrated_led_n,        // Pin 31
	output    peak_error_led_n,        // Pin 32
	output    pulse_error_led_n,       // Pin 34
	output    rate_error_led_n,        // Pin 35
	
	output    test_pass_led_n,        // Pin 36
	output    test_fail_led_n,        // Pin 37
	output    TA_shutdown,            // Pin 58
	
	input     adc_sdo,        	       // Pin 98
	output    adc_sck,         	   // Pin 99
	output    adc_convert,     	   // Pin 97
	
    inout     scl,             	   // Pin 88
    inout     sda,             	   // Pin 87	

    output    heartbeat_n,            // Pin 45
    output    heartbeat2_n,           // Pin 43
		
	inout     spare1,          	  // Pin 69
	inout     spare2,          	  // Pin 71
	inout     spare3,          	  // Pin 74
	inout     spare4,          	  // Pin 70
	
	inout     gpio1,           	  // Pin 30
	inout     gpio2,           	  // Pin 27
	inout     gpio3,           	  // Pin 28
	inout     gpio4           	      // Pin 30
	
);

wire        buf_rstn;
wire        buf_clk;
wire        buf_laser_active;
wire        adc_data_valid;
wire [15:0] adc_data_value;
wire [7:0]  status;

wire [31:0] pulse_width_lower_limit;
wire [31:0] pulse_width_upper_limit;
wire [31:0] rate_lower_limit;
wire [15:0] power_peak_current_limit;
wire [31:0] adc_pulse_current_limit;
wire [31:0] adc_cw_current_limit;
wire pulse_lower_limit_fail,adc_pulse_width_lower_limit_fail;
wire pulse_upper_limit_fail,adc_pulse_width_upper_limit_fail;
wire rate_lower_limit_fail,adc_rate_lower_limit_fail;
wire width_limit_window;
wire peak_power_update;
wire [15:0] peak_power_value_capture;
wire [15:0] drive_current_limit_capture;

wire [15:0] temperature_sensor;
wire [15:0] drive_current;
wire [15:0] drive_current_limit;
wire [15:0] cw_current_limit;
wire [15:0] static_control;
wire [15:0] dynamic_control;
wire        over_current_limit;
wire        laser_ready;
wire        enable_error_check;
wire        clear_power_fail,clear_peak_power;
wire [15:0] peak_power_min;
wire [15:0] peak_power_max;
wire         peak_power_read;

wire [15:0] adc_data_old_value;
wire [15:0] peak_power_value;
wire [15:0] cw_power_value;
wire         start_timer;
wire         laser_pulse_delay;

wire        power_peak_current_limit_fail;
wire        cw_current_limit_fail;

wire        edge_detect_1st;
wire        edge_detect_2nd;
wire        pulse_check;
wire        period_check;
wire        offset_count;
wire        pulse_limit_check;
wire        ID;

assign ID = select ? 3 : 4;
assign heartbeat2_n = heartbeat_n;

///////////////// reg 18 //////////////////////
assign pulse_cw_select      = static_control[0];
assign adc_bypass           = static_control[1];
assign laser_pwr_en1_n      = !static_control[2];
assign enable_error_check   = static_control[3];

assign calibrated_led_n     = !power_peak_current_limit_fail;
assign peak_error_led_n     = !cw_current_limit_fail;
//assign calibrated_led_n     = !pulse_lower_limit_fail;
//assign peak_error_led_n     = !current_limit_fail;
assign pulse_error_led_n    = !pulse_upper_limit_fail;
assign rate_error_led_n     = !rate_lower_limit_fail;
assign watchdog_timeout_led_n = !static_control[7];
assign test_pass_led_n      = !static_control[8];
assign test_fail_led_n      = !static_control[9];

assign clear_fail           = dynamic_control[0];
assign clear_power_fail     = dynamic_control[1] | dynamic_control[0];
assign clear_peak_power     = dynamic_control[2];

assign TA_shutdown = (pulse_lower_limit_fail | pulse_upper_limit_fail | rate_lower_limit_fail | power_peak_current_limit_fail);
//assign TA_shutdown = (pulse_lower_limit_fail | pulse_upper_limit_fail | rate_lower_limit_fail);

assign pulse_rate_status = {4'h0,pulse_lower_limit_fail,pulse_upper_limit_fail,rate_lower_limit_fail,0};
assign current_status = {6'h0,cw_current_limit,power_peak_current_limit_fail};

//assign spare1              = laser_pulse;
//assign spare1              = current_limit_fail;
//assign spare2              = clear_fail;
//assign spare2              = pulse_limit_check;
//assign spare3              = pulse_lower_limit_fail;

//assign spare1              = laser_pulse_delay;
assign spare2              = laser_pulse;
//assign spare1              = reset_n;
assign spare1              = start_timer;
//assign spare2              = adc_convert;
//assign spare4              = adc_data_valid;
assign spare4              = power_peak_current_limit_fail;
//assign spare3              = adc_sdo;
assign spare3              = adc_sck;
//assign spare4              = pulse_upper_limit_fail;
//assign spare4              = edge_detect_2nd;
//assign spare2              = edge_detect_1st;
//assign spare4              = adc_sck;
//assign spare2              = pulse_check;
//assign spare4              = period_check;
//assign spare4              = adc_data_valid;
//assign spare4              = rate_lower_limit_fail;
//assign spare4              = offset_count;
//assign spare4              = laser_ready;

assign gpio1               = 0;
assign gpio2               = 0;
assign gpio3               = 0;
assign gpio4               = 0;

assign status = {5'h0,rate_lower_limit_fail,(pulse_upper_limit_fail | pulse_lower_limit_fail),power_peak_current_limit_fail};

assign buf_clk              = clk_50mhz;

wire clk_div2,clk_div4;
wire buf_laser_pulse;

//assign buf_rstn = rstn  & system_reset_n;

reset_generator reset_generator( 
    .rstn      (rstn),
    .clk       (clk_div4),
    .reset_n   (reset_n)
);

reset_laser reset_laser( 
    .rstn          (rstn),
    .clk           (clk_div4),
    .laser_ready   (laser_ready)
);
	
PLL PLL( 
    .RST      	(!rstn),
    .CLKI      (buf_clk),
    .CLKOP     (clk_div2),
    .CLKOS     (clk_div4),
    .LOCK      ( )
);
	
efb_i2c efb_inst (
	// Wishbone clock (MANDATORY)
	.wb_clk_i(buf_clk),
	.wb_rst_i(1'b0),

	// Wishbone interface (unused, but must exist)
	.wb_stb_i(1'b0),
	.wb_cyc_i(1'b0),
	.wb_we_i(1'b0),
	.wb_adr_i(8'b0),
	.wb_dat_i(8'b0),

	// Outputs (unused)
	.wb_ack_o(),
	.wb_dat_o(),
	.i2c1_irqo(),

	// I2C pins
	.i2c1_scl(scl_cfg),
	.i2c1_sda(sda_cfg)

	// SPI / Timer / UART ports can be left unconnected
);

synchronizer synchronizer( 
    .rstn      	(reset_n),
    .clk      	(clk_div2),
    .din       (laser_pulse),
    .dount     (buf_laser_pulse)
);

heart_beat heart_beat( 
    .rstn      (rstn),
    .clk       (clk_div2),
    .heartbeat (heartbeat_n)
);

i2c_slave_top i2c_slave_top (
	.rstn 					(rstn),
	.clk 					(clk_div2),
	
	.scl 					(scl),
	.sda 					(sda),
	
    .temperature_sensor     (16'h1122),
    .revision               (8'h4),
    .minor                  (8'h1),
    .major                  (8'h0),
    .ID                     (ID),

    .adc_data 		        (adc_data_value),
    .adc_data_old_value     (adc_data_old_value),
    .peak_power_value       (peak_power_value),
	.peak_power_min         (peak_power_min),
    .peak_power_max         (peak_power_max),

    .cw_power_value              (cw_power_value),
    .peak_power_value_capture    (peak_power_value_capture),
    .drive_current_limit_capture (drive_current_limit_capture),

    .monitor_status 		(monitor_status),
    .status 				(status),
	
    .pulse_width_lower_limit 	(pulse_width_lower_limit),
    .pulse_width_upper_limit 	(pulse_width_upper_limit),
    .rate_lower_limit     	 	(rate_lower_limit),
    .drive_current_limit    	(drive_current_limit),
    .cw_current_limit      		(cw_current_limit),
    .dynamic_control 	   		(dynamic_control),
    .static_control 	   		(static_control),
    .peak_power_read 	   		(peak_power_read)
);
    
limit_check limit_check( 
    .rstn                               (rstn),
    .clk                                (clk_div2),
    .clear_fail                         (clear_fail),

    .laser_pulse                        (buf_laser_pulse),
    .laser_ready                        (laser_ready),

    .pulse_width_lower_limit            (pulse_width_lower_limit),
    .pulse_width_upper_limit            (pulse_width_upper_limit),
    .rate_lower_limit                   (rate_lower_limit),

    .pulse_lower_limit_fail             (pulse_lower_limit_fail),
    .pulse_upper_limit_fail             (pulse_upper_limit_fail),
    .rate_lower_limit_fail              (rate_lower_limit_fail),

    .width_limit_window                 (width_limit_window),

    .edge_detect_1st                    (edge_detect_1st),
    .edge_detect_2nd                    (edge_detect_2nd),
    .pulse_check                        (pulse_check),
    .period_check                       (period_check),
    .pulse_limit_check                  (pulse_limit_check)
);

power_peak_check_top power_peak_check_top( 
    .rstn                   		(reset_n),
    .clk                    		(clk_div2),
    .laser_pulse            		(buf_laser_pulse),
    .clear_power_fail       	    (clear_power_fail),
    .clear_peak_power       	    (clear_peak_power),
    .peak_power_read 	   		    (peak_power_read),

    .adc_sdo       					(adc_sdo),
    .adc_sck       					(adc_sck),
    .adc_convert       				(adc_convert),
    .adc_data_valid       		    (adc_data_valid),
    .adc_data_value       		    (adc_data_value),
    .adc_data_old_value       		(adc_data_old_value),
    .peak_power_value       		(peak_power_value),
    .peak_power_min       		    (peak_power_min),
    .peak_power_max       		    (peak_power_max),
    .cw_power_value       		    (cw_power_value),

    .cw_current_limit               (cw_current_limit),
    .cw_current_limit_fail          (cw_current_limit_fail), 
    .drive_current_limit            (drive_current_limit),
	.peak_power_value_capture       (peak_power_value_capture),
    .drive_current_limit_capture    (drive_current_limit_capture),

    .power_peak_current_limit_fail  (power_peak_current_limit_fail),
    .start_timer                    (start_timer),
    .laser_pulse_delay              (laser_pulse_delay)


);


endmodule


