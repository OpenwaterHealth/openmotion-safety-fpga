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

module synchronizer( 
    input  rstn,
    input  clk,
	
    input  din,

    output reg dount
);

reg din_d;

always @(posedge clk or negedge rstn) begin
      if(!rstn) begin
         din_d <= 0;
         dount <= 0;
      end else begin
		           din_d <= din;
		           dount <= din_d;
			   end
   end


endmodule

