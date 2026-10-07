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

//`timescale <time_units> / <precision>

module adc_control( 
    input              rstn,
    input              clk,

    input              laser_pulse,
    input              clear_peak_power,
    input              adc_sdo,
    input              peak_power_read,
    input [7:0]       adc_sample,

    output             adc_sck,
    output reg         adc_convert,
	output reg         adc_data_valid,
    output reg [15:0] adc_data_value,
    output reg [15:0] adc_data_old_value,
    output reg [15:0] peak_power_value,
    output reg [15:0] peak_power_min,
    output reg [15:0] peak_power_max,
    output reg [15:0] cw_power_value,
    output reg         start_timer,
	output             laser_pulse_delay


)/* synthesis syn_preserve=1 */;

parameter   CONVERT_DELAY = 16'd3000;
parameter   SAMPLE = 16'd5;

parameter   INIT        = 4'd0,
            IDLE        = 4'd1,
            CONVERT     = 4'd2, 
            SCK_HIGH    = 4'd3, 
            SCK_LOW     = 4'd4, 
            CAPTURE     = 4'd5,
            SHIFT       = 4'd6,
            WAIT        = 4'd7,
            REPEAT      = 4'd8,
            DONE        = 4'd9,
            PWRUP       = 4'd10;

reg [3:0] state=0,capture_state=0;
reg [7:0] convert_count;
reg [7:0] count;
reg [13:0] voltage_data,voltage_data_temp;
reg [13:0] current_data;
reg [15:0] final_voltage_data_d2,final_voltage_data_d1,final_voltage_data,final_voltage_data_old;
reg [3:0] sck_count;
reg [3:0] index;
reg [7:0] cycle_count,adc_sample_d;
reg [15:0] wait_timer,sample_count;
reg [15:0] voltage_data_value_old;
reg [15:0] power_up_count;
reg [15:0] peak_power_value_d1,peak_power_value_average;
reg [3:0]  data_valid_check,peak_power_valid_d1,peak_power_valid_d2,peak_power_valid_d3;

reg adc_sdo_d1,adc_sdo_d2;
reg data_ready,laser_pulse_d;
reg adc_sck_temp;
reg voltage_data_valid_d3,voltage_data_valid_d2,voltage_data_valid_d1,voltage_data_valid;
reg laser_pulse_d1,laser_pulse_d2,laser_pulse_d3,laser_pulse_d4,laser_pulse_d5;

assign adc_sck = adc_sck_temp & data_ready;
assign laser_pulse_delay = laser_pulse_d2;

always @(posedge clk,negedge rstn)
begin
    if (!rstn) begin
        adc_sdo_d1 <= 0;     
        adc_sdo_d2 <= 0;     
    end else begin
		         adc_sdo_d1 <= adc_sdo;
		         adc_sdo_d2 <= adc_sdo_d1;
		     end
end

always @(posedge clk,negedge rstn)
begin
    if (!rstn) begin
		adc_sample_d <= 0;
		power_up_count <= 0;
        adc_convert <= 0;     
        convert_count <= 0; 
        sample_count <= 0;		
        data_ready <= 0;     
        adc_sck_temp <= 0;     
        sck_count <= 0;     
        cycle_count <= 0;     
        wait_timer <= 0;     
        start_timer <= 0;     
        laser_pulse_d1 <= 0;     
        laser_pulse_d2 <= 0;     
        laser_pulse_d3 <= 0;     
        laser_pulse_d4 <= 0;     
        laser_pulse_d5 <= 0;     
        state <= PWRUP;     
    end else begin
		      laser_pulse_d1 <= laser_pulse;
		      laser_pulse_d2 <= laser_pulse_d1;
		      laser_pulse_d3 <= laser_pulse_d2;
		      laser_pulse_d4 <= laser_pulse_d3;
		      laser_pulse_d5 <= laser_pulse_d4;
			  adc_sample_d <= adc_sample;
			  
                    case (state)
                          PWRUP : begin
									if (power_up_count > 16'hfff0) begin
										power_up_count <= 0;
									    state <= INIT;
								    end else power_up_count <= power_up_count + 1;
                                 end
                          INIT : begin
                                    data_ready <= 0;
									if (!laser_pulse_d1 && laser_pulse) begin
										wait_timer <= 0;
										start_timer <= 1;
									    state <= IDLE;
								    end
                                 end
                          IDLE : begin
									if (wait_timer > CONVERT_DELAY) begin
											wait_timer <= 0;
											start_timer <= 0; 
											adc_convert <= 0;
											state <= CONVERT;
									end else begin
											        wait_timer <= wait_timer + 1;
												    adc_convert <= 1;
											 end
                                 end
                       CONVERT : begin
                                    if (convert_count > 20) begin
                                        adc_convert <= 0;
                                        convert_count <= 0;
                                        data_ready <= 1;
                                        state <= SCK_HIGH;
                                    end else convert_count <= convert_count + 1;                                       
                                 end
                      SCK_HIGH : begin
                                    adc_sck_temp <= 1;
                                    state <= SCK_LOW;
                                 end
                       SCK_LOW : begin
                                    adc_sck_temp <= 0;
                                    if (sck_count > 12) data_ready <= 0;
                                    if (sck_count > 13) adc_convert <= 1;
                                    if (sck_count > 14) begin
                                        sck_count <= 0;
									    state <= REPEAT;
                                    end else begin
                                                sck_count <= sck_count + 1;
                                                state <= SCK_HIGH;
                                             end
                                 end
                        REPEAT : begin
									if (sample_count > adc_sample_d) begin
										sample_count <= 0;
										state <= DONE;
									end else begin
										        sample_count <= sample_count + 1;
											    state <= CONVERT;
										 end
                                 end
                          DONE : begin
									if (laser_pulse_d && !laser_pulse) state <= INIT;
                                 end
                    endcase
        end
end

always @(posedge adc_sck_temp,negedge rstn)
begin
    if (!rstn) begin
        index <= 12;     
        count <= 0;     
        voltage_data_valid <= 0; 
        voltage_data_temp <= 0;     
        voltage_data <= 0;     
        capture_state <= IDLE;
    end else begin
                case(capture_state)
                        IDLE : begin
                                    voltage_data_valid <= 0;
                                    voltage_data_temp <= 0;
                                    if (data_ready) capture_state <= CAPTURE;
                               end
                     CAPTURE : begin //4
                                    voltage_data_temp[index] <= adc_sdo;
                                    if (count > 11) begin
                                        index <= 12;
                                        count <= 0;
                                        capture_state <= DONE;
                                    end else begin
                                                index <= index - 1;
                                                count <= count + 1;
                                             end
                              end
                       DONE : begin //8
						   		    voltage_data <= {4'h0,voltage_data_temp[12:1]};
                                    voltage_data_valid <= 1;
                                    capture_state <= IDLE;
                              end
                endcase
            end
end

always @(posedge clk,negedge rstn)
begin
    if (!rstn) begin
        laser_pulse_d <= 0;
        peak_power_value <= 0;
		cw_power_value <= 0;
        peak_power_value_average <= 0;     
        peak_power_value_d1 <= 0;     
        final_voltage_data_d1 <= 0;     
        final_voltage_data_d2 <= 0;     
        voltage_data_valid_d1 <= 0;     
        voltage_data_valid_d2 <= 0;     
        voltage_data_valid_d3 <= 0;     
        final_voltage_data <= 16'h0;     
        adc_data_old_value <= 16'h0;     
        adc_data_value <= 16'h0;     
        adc_data_valid <= 0; 
        data_valid_check <= 0;
		
    end else begin
				 laser_pulse_d <= laser_pulse;
				 voltage_data_valid_d1 <= voltage_data_valid;
				 voltage_data_valid_d2 <= voltage_data_valid_d1;
				 voltage_data_valid_d3 <= voltage_data_valid_d2;
				 
				 final_voltage_data_d1 <= final_voltage_data;
				 final_voltage_data_d2 <= final_voltage_data_d1;
				 			
				 if (clear_peak_power) begin
					 data_valid_check <= 0;
					 peak_power_value <= 0;
				 end
				 if (data_valid_check > 1) peak_power_value_average <= final_voltage_data;
				 else peak_power_value_average <= final_voltage_data;
				
				 if (!peak_power_read) peak_power_value <= peak_power_value_average;
				 peak_power_value_d1 <= peak_power_value;
                 
				 if (!voltage_data_valid_d3 & voltage_data_valid_d2) begin
				     adc_data_valid <= 1;
					 adc_data_value <= voltage_data;
					 final_voltage_data_old <= final_voltage_data;
					 if (data_valid_check < 2) data_valid_check <= data_valid_check + 1;
					 if (data_valid_check < 1) begin
						 final_voltage_data <= voltage_data;
					 end else final_voltage_data <= (voltage_data + final_voltage_data) >> 1;
				 end else begin
								adc_data_valid <= 0;
						  end
             end
end

always @(posedge clk,negedge rstn)
begin
    if (!rstn) begin
        peak_power_min <= 16'hffff;     
        peak_power_max <= 0;     
        peak_power_valid_d1 <= 0;     
        peak_power_valid_d2 <= 0;     
        peak_power_valid_d3 <= 0;     
    end else begin
				    peak_power_valid_d1 <= data_valid_check;
				    peak_power_valid_d2 <= peak_power_valid_d1;
				    peak_power_valid_d3 <= peak_power_valid_d2;
				    if (peak_power_valid_d3 > 0) begin
						if (peak_power_min > peak_power_value_d1) peak_power_min <= peak_power_value;
			            if (peak_power_max < peak_power_value_d1) peak_power_max <= peak_power_value;
					end
             end
end


endmodule

