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

module reset_generator( 
    input  rstn,
    input  clk,

    output reset_n
);

//always @(posedge clk,negedge rstn)
//begin
//    if (!rstn) begin
 //       reset_n <= 0;     
 //   end else begin
 //                if (count > 10) reset_n <= 1;
 //                else count <= count + 1;
 //           end
//end

  // internal signals
   reg  in_d1;
   reg  in_d2;
   reg  in_d3;
   reg  out_n;

   reg clk_d2,clk_d4,clk_d8,clk_d16,clk_d32,clk_d64;
   reg reset_delay;
   reg [31:0] count;
   
 //  assign reset_n = out_n & sys_reset_out_n;
   assign reset_n = out_n & reset_delay;


   always @(posedge clk or negedge rstn) begin
      if(!rstn) begin
         clk_d2 <= 1'b0;
      end else begin
         clk_d2 <= !clk_d2;       
      end
   end
   
   always @(posedge clk_d2 or negedge rstn) begin
      if(!rstn) begin
         clk_d4 <= 1'b0;
      end else begin
         clk_d4 <= !clk_d4;       
      end
   end

   always @(posedge clk_d4 or negedge rstn) begin
      if(!rstn) begin
         clk_d8 <= 1'b0;
      end else begin
         clk_d8 <= !clk_d8;       
      end
   end

   always @(posedge clk_d8 or negedge rstn) begin
      if(!rstn) begin
         clk_d16 <= 1'b0;
      end else begin
         clk_d16 <= !clk_d16;       
      end
   end
   
   always @(posedge clk_d16 or negedge rstn) begin
      if(!rstn) begin
         clk_d32 <= 1'b0;
      end else begin
         clk_d32 <= !clk_d32;       
      end
   end
   
   always @(posedge clk_d32 or negedge rstn) begin
      if(!rstn) begin
         clk_d64 <= 1'b0;
      end else begin
         clk_d64 <= !clk_d64;       
      end
   end
   //---------------------------------------------------------
   always @(posedge clk_d2 or negedge rstn) begin
      if(!rstn) begin
         in_d1 <= 1'b0;
         in_d2 <= 1'b0;
         in_d3 <= 1'b0;
      end else begin
         in_d1 <= rstn;       // Synchronizer #1
         in_d2 <= in_d1;       // Synchronizer #2
         in_d3 <= in_d2;       // Filter
      end
   end

   // Filter - two consecutive samples must match
   //        - all glitches shorter than clock period are suppressed
   always @(posedge clk_d2 or negedge rstn) begin
      if(!rstn) begin
         out_n <= 1'b0;
      end else if (in_d2 == in_d3) begin
         out_n <= in_d3;
      end
   end
   
      always @(posedge clk_d64 or negedge rstn) begin
      if(!rstn) begin
         count <= 0;
         reset_delay <= 0;
      end else begin
		         if (!reset_delay) begin
					 if (count > 32'h0004fff0) begin
						 count <= 0;
						 reset_delay <= 1;   
					 end else count <= count + 1;					 
				 end
      end
   end


endmodule

