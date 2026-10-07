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

module logic_check( 
    input           rstn,
    input           clk,
    input           clear_fail,
    input           laser_pulse_in,
    input           laser_ready,

    input [31:0]    pulse_width_lower_limit,
    input [31:0]    pulse_width_upper_limit,
    input [31:0]    rate_lower_limit,

    output reg      pulse_lower_limit_fail,
    output reg      pulse_upper_limit_fail,
    output reg      rate_lower_limit_fail,

    output reg      edge_detect_1st,
    output reg      edge_detect_2nd,
	
    output          width_limit_window,
    output reg      pulse_check,
    output reg      period_check,
    output reg      pulse_limit_check

);

parameter   IDLE         = 0,
            WIDTH_CHECK  = 1,
            RATE_CHECK   = 2, 
      CHECK_LOWER_WINDOW = 3, 
      CHECK_UPPER_WINDOW = 4, 
            DONE         = 5;

reg [3:0]  state,window_state,edge_detect_state;
reg        laser_pulse_d1,laser_pulse_d2,laser_pulse_d3,laser_pulse_d4,laser_pulse_d5;
reg [31:0] count,window_count;
reg pulse_width_limit_window;
reg [3:0] edge_count;
reg [31:0] pulse_width_lower_limit_d,pulse_width_upper_limit_d;
reg [15:0] clk_count;
wire pulse_clk;
reg laser_pulse;
reg clear_fail_d1,clear_fail_d2,clear_fail_d3,clear_fail_d4,clear_fail_all;

assign width_limit_window = pulse_width_limit_window;

assign pulse_clk = clk_count[2];

always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
           clk_count <= 0;
      end else begin
                  clk_count <= clk_count + 1;
               end
end

always @(posedge clk or negedge rstn) begin
      if (!rstn) begin
           clear_fail_d1 <= 0;
           clear_fail_d2 <= 0;
           clear_fail_d3 <= 0;
           clear_fail_d4 <= 0;
      end else begin
                  clear_fail_d1 <= clear_fail;
                  clear_fail_d2 <= clear_fail_d1;
                  clear_fail_d3 <= clear_fail_d2;
				  clear_fail_d4 <= clear_fail_d3 | clear_fail_d2 | clear_fail_d1 | clear_fail;
               end
end


always @(posedge pulse_clk,negedge rstn)
begin
    if (!rstn) begin
        laser_pulse <= 0;     
    end else begin
                laser_pulse <= laser_pulse_in & laser_ready;
              end
end

always @(posedge pulse_clk,negedge rstn)
begin
    if (!rstn) begin
        laser_pulse_d1 <= 0;     
        edge_detect_1st <= 0;    
        edge_detect_2nd <= 0;   
        edge_count <= 0;   
        edge_detect_state <= IDLE;
    end else begin
                laser_pulse_d1 <= laser_pulse;
				
                case(edge_detect_state)
                     IDLE : begin
						         edge_detect_2nd <= 0;
								 if (!laser_pulse_d1 & laser_pulse) begin
									 edge_detect_1st <= 1; 
									 edge_detect_state <= DONE;
								 end
                            end
                     DONE : begin
						         edge_detect_1st <= 0; 
                                 if (laser_pulse_d1 & !laser_pulse) begin
									 edge_detect_2nd <= 1;
									 edge_detect_state <= IDLE;
								 end
                            end

                endcase
            end
end

///////////////////////////////////////////////////////////////////////////////////////////////////
always @(posedge pulse_clk,negedge rstn)
begin
    if (!rstn) begin
        count <= 0;  
        pulse_lower_limit_fail <= 0;
        pulse_upper_limit_fail <= 0;
        rate_lower_limit_fail <= 0;
        pulse_check <= 0;
        period_check <= 0;
		pulse_limit_check <= 0;
		clear_fail_all <= 0;
        state <= IDLE;
    end else begin			
                clear_fail_all <= clear_fail_d4;		
                case(state)
                     IDLE : begin
                                if (edge_detect_1st) begin
                                     count <= count + 2;
                                     state <= WIDTH_CHECK;
							    end else count <= 0;
                            end
               WIDTH_CHECK: begin
				   				pulse_check <= 1;
				                period_check <= 0;
				                count <= count + 1;
                                if (count > 32'h2f5) pulse_limit_check <= 1;    // offset = 13, 0x2f5, 6% windows
                                if (!laser_pulse_d1) begin
									pulse_limit_check <= 0; 
                                    if (count > pulse_width_upper_limit) begin    // 0x314
                                        pulse_upper_limit_fail <= 1;
                                        state <= DONE;
                                    end else begin
												if (count < pulse_width_lower_limit) begin    // 0x307
													pulse_lower_limit_fail <= 1;
													state <= DONE;
												end else state <= RATE_CHECK;
											 end
                                end  

                            end
               RATE_CHECK: begin
				                pulse_check <= 0;
				                period_check <= 1;
								pulse_limit_check <= 0;
								if (count == 32'h013123) pulse_limit_check <= 1;    // offset = 10, 1% windows
                                if (laser_pulse_d1) begin
									pulse_limit_check <= 0; 
                                    if (count < rate_lower_limit) begin             // 32'h01312d=25ms
                                        rate_lower_limit_fail <= 1;
                                        state <= DONE;
                                    end else begin
									             count <= 1;
									             state <= WIDTH_CHECK;
										     end
                                end else begin
											if (count > rate_lower_limit) begin
												count <= 0;
												state <= IDLE;
											end else count <= count + 1;
										 end
                            end
                     DONE : begin
                                if (pulse_lower_limit_fail | pulse_upper_limit_fail | rate_lower_limit_fail) begin
                                    if (clear_fail_all) begin
                                        count <= 0;
                                        pulse_lower_limit_fail <= 0;
                                        pulse_upper_limit_fail <= 0;
                                        rate_lower_limit_fail <= 0;
                                        state <= IDLE;
                                    end
                                end 
                            end

                endcase
            end
end

always @(posedge pulse_clk,negedge rstn)
begin
    if (!rstn) begin
        window_count <= 0;
        pulse_width_lower_limit_d <= 0;
        pulse_width_upper_limit_d <= 0;
        pulse_width_limit_window <= 0;
        window_state <= IDLE;
    end else begin
		        pulse_width_lower_limit_d <= pulse_width_lower_limit;
		        pulse_width_upper_limit_d <= pulse_width_upper_limit;
				
                case(window_state)
                     IDLE : begin
                                if (edge_detect_1st) begin
                                    window_count <= window_count + 1;
                                    window_state <= CHECK_LOWER_WINDOW;
                                end
                            end
        CHECK_LOWER_WINDOW: begin
                                window_count <= window_count + 1;
                                if (window_count == pulse_width_lower_limit_d) begin
									pulse_width_limit_window <= 1;
                                    window_state <= CHECK_UPPER_WINDOW;
                                end 
                            end
        CHECK_UPPER_WINDOW: begin
                                if (window_count == pulse_width_upper_limit_d) begin
                                    window_count <= 0;
                                    pulse_width_limit_window <= 0;
                                    window_state <= IDLE;
                                end else begin
                                              window_count <= window_count + 1;
                                         end
                            end
                endcase
            end
end


endmodule

