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

module reset_laser( 
    input  rstn,
    input  clk,

    output reg laser_ready
);


   reg [31:0] count;

   
   always @(posedge clk or negedge rstn) begin
      if(!rstn) begin
         count <= 0;
         laser_ready <= 0;
      end else begin
		         if (!laser_ready) begin
					 if (count > 32'h00fffff0) begin
						 count <= 0;
						 laser_ready <= 1;   
					 end else count <= count + 1;					 
				 end
      end
   end


endmodule

