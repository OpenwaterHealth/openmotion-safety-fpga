// SPDX-License-Identifier: AGPL-3.0-or-later

module limit_check( 
    input        rstn,
    input        clk,

    input        clear_fail,
    input        laser_pulse,
    input        laser_ready,

    input [31:0] pulse_width_lower_limit,
    input [31:0] pulse_width_upper_limit,
    input [31:0] rate_lower_limit,	

    output       pulse_lower_limit_fail,
    output       pulse_upper_limit_fail,
    output       rate_lower_limit_fail,

    output       width_limit_window,
	output       edge_detect_1st,
    output       edge_detect_2nd,

	output       pulse_check,
    output       period_check,
    output       pulse_limit_check



);

logic_check logic_check( 
    .rstn                     (rstn),
    .clk                      (clk),
    .clear_fail               (clear_fail),

    .laser_pulse_in           (laser_pulse),
    .laser_ready              (laser_ready),

    .pulse_width_lower_limit  (pulse_width_lower_limit),
    .pulse_width_upper_limit  (pulse_width_upper_limit),
    .rate_lower_limit         (rate_lower_limit),

    .pulse_lower_limit_fail   (pulse_lower_limit_fail),
    .pulse_upper_limit_fail   (pulse_upper_limit_fail),
    .rate_lower_limit_fail    (rate_lower_limit_fail),

    .width_limit_window       (width_limit_window),
    .edge_detect_1st          (edge_detect_1st),
    .edge_detect_2nd          (edge_detect_2nd),

    .pulse_check              (pulse_check),
    .period_check             (period_check),
    .pulse_limit_check        (pulse_limit_check)


);

endmodule
