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

module adc_pulse_rate_check( 
    input           rstn,
    input           clk,
    input           clear_fail,

    input           adc_bypass,
    input           adc_data_valid,
    input [15:0]    adc_data,

    input [31:0]    pulse_width_lower_limit,
    input [31:0]    pulse_width_upper_limit,
    input [31:0]    rate_lower_limit,

    output reg      adc_pulse_width_lower_limit_fail,
    output reg      adc_pulse_width_upper_limit_fail,
    output reg      adc_rate_lower_limit_fail

);

parameter   IDLE        = 0,
            PULSE_CHECK = 1,
            RATE_CHECK  = 2,
            DONE        = 3;

parameter pulse_high = 16'h0100;

reg [3:0]  state;
reg        adc_data_d1,adc_data_d2;
reg [31:0] count;

always @(posedge clk,negedge rstn)
begin
    if (!rstn) begin
        adc_data_d1 <= 0;     
        adc_data_d2 <= 0;     
        count <= 0;     
  
        adc_pulse_width_lower_limit_fail <= 0;
        adc_pulse_width_upper_limit_fail <= 0;
        adc_rate_lower_limit_fail <= 0;
        state <= IDLE;
    end else begin
                adc_data_d1 <= adc_data;
                adc_data_d2 <= adc_data_d1;
                case(state)
                     IDLE : begin
                                if (!adc_bypass) begin
                                        if (adc_data_valid) begin
                                            if (adc_data_d2 > pulse_high) begin
                                                count <= count + 1;
                                                state <= PULSE_CHECK;
                                            end else count <= 0;
                                        end
                                end
                            end
              PULSE_CHECK : begin

                                if (adc_data_valid) begin
                                    if (adc_data_d2 < pulse_high) begin
                                        if (count < pulse_width_lower_limit) begin
                                            adc_pulse_width_lower_limit_fail <= 1;
                                            state <= DONE;
                                        end else state <= RATE_CHECK;
                                    end
                                end
                            end
               RATE_CHECK : begin
                                if (adc_data_valid) begin
                                     if (adc_data_d2 < pulse_high) begin
                                          if (count < pulse_width_lower_limit) begin
                                               adc_pulse_width_lower_limit_fail <= 1;
                                               state <= DONE;
                                          end
                                     end
                                end
                            end
                      DONE: begin
                                if (adc_pulse_width_lower_limit_fail | adc_pulse_width_upper_limit_fail) begin
                                    if (clear_fail) begin
                                        count <= 0;
                                        adc_pulse_width_lower_limit_fail <= 0;
                                        adc_pulse_width_upper_limit_fail <= 0;
                                        count <= 0;
                                        state <= IDLE;
                                    end
                                end 
                            end
                endcase
            end
end

endmodule

