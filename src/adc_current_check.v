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

module adc_current_check( 
    input           rstn,
    input           clk,
    input           clear_fail,

    input [15:0]   drive_current_limit,
	
    input           adc_data_valid,
    input [15:0]   adc_data,

    output reg      current_limit_fail

);

parameter   IDLE    = 0,
            START   = 1,
            DONE    = 2;

reg [3:0]  state;
reg        adc_data_d1,adc_data_d2;
reg [31:0] count;


always @(posedge clk,negedge rstn)
begin
    if (!rstn) begin
        count <= 0;
        adc_data_d1 <= 0;     
        adc_data_d2 <= 0;     
        state <= IDLE;
    end else begin
                adc_data_d1 <= adc_data;
                adc_data_d2 <= adc_data_d1;
                case(state)
                    IDLE : begin
                                if (adc_data_valid) begin
                                    if (adc_data_d2 > (drive_current_limit)) begin
                                        current_limit_fail <= 1;
                                        state <= DONE;
                                    end else current_limit_fail <= 0;   
                                end
                            end
                    DONE : begin
                                if (current_limit_fail) begin
                                    if (clear_fail) begin
                                        count <= 0;
                                        current_limit_fail <= 0;
                                        state <= IDLE;
                                    end
                                end 
                            end
                endcase
            end
end


endmodule

