// SPDX-License-Identifier: AGPL-3.0-or-later

module power_peak_check( 
    input         rstn,
    input         clk,
    input         laser_pulse,

    input         clear_power_fail,

    input          adc_data_valid,
    input [15:0]  adc_data_value,
    input [15:0]  adc_data_old_value,
    input [15:0]  peak_power_value,
    input [15:0]  cw_power_value,

    input [15:0]  cw_current_limit,
    input [15:0]  drive_current_limit,
    output reg [15:0]  peak_power_value_capture,
    output reg [15:0]  drive_current_limit_capture,

    output reg    cw_current_limit_fail,
    output reg    power_peak_current_limit_fail

);

parameter   IDLE  = 0,
            CHECK = 1, 
            DONE  = 2;

reg [3:0] state;
reg [15:0] adc_data_d1;
reg [15:0] peak_power_value_d1,peak_power_value_d2;
reg [15:0] cw_power_value_d1,cw_power_value_d2;
reg [15:0] cw_current_limit_d1,cw_current_limit_d2;
reg [15:0] drive_current_limit_d1,drive_current_limit_d2;
reg adc_data_valid_d1;
reg laser_pulse_d1;

always @(posedge clk,negedge rstn)
begin
    if (!rstn) begin
        drive_current_limit_d1 <= 0;     
        drive_current_limit_d2 <= 0;
        peak_power_value_capture <= 0;
        drive_current_limit_capture <= 0;		
        cw_current_limit_d1 <= 0;     
        cw_current_limit_d2 <= 0;     
        cw_power_value_d1 <= 0;     
        cw_power_value_d2 <= 0;     
        peak_power_value_d1 <= 0;     
        peak_power_value_d2 <= 0;     
        adc_data_valid_d1 <= 0;     
        adc_data_d1 <= 0;     
        laser_pulse_d1 <= 0;     
        cw_current_limit_fail <= 0;     
        power_peak_current_limit_fail <= 0;     
	    state <= IDLE;
    end else begin
                laser_pulse_d1 <= laser_pulse;
                drive_current_limit_d1 <= drive_current_limit;
                drive_current_limit_d2 <= drive_current_limit_d1;
                cw_current_limit_d1 <= cw_current_limit;
                cw_current_limit_d2 <= cw_current_limit_d1;
                peak_power_value_d1 <= peak_power_value;
                peak_power_value_d2 <= peak_power_value_d1;
                cw_power_value_d1 <= cw_power_value;
                cw_power_value_d2 <= cw_power_value_d1;
                adc_data_valid_d1 <= adc_data_valid;
                adc_data_d1 <= adc_data_old_value;
				case (state)
						IDLE : begin
									if (!laser_pulse_d1 & laser_pulse) state <= CHECK;
							   end
				   	   CHECK : begin
									if (peak_power_value > drive_current_limit_d1) begin
										state <= DONE;
										peak_power_value_capture <= peak_power_value;
										drive_current_limit_capture <= drive_current_limit_d1;
										power_peak_current_limit_fail <= 1;
									end
							   end
						DONE : begin
									if (clear_power_fail) begin
										state <= IDLE;
										peak_power_value_capture <= 0;
										drive_current_limit_capture <= 0;
										cw_current_limit_fail <= 0;
										power_peak_current_limit_fail <= 0;
									end
							   end
				endcase
            end
end



endmodule

