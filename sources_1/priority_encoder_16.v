module priority_encoder_16 (
    input  wire [15:0] x,
    output wire [3:0]  pos,
    output wire        valid
);

    wire       v3, v2, v1, v0;
    wire [1:0] p3, p2, p1, p0;

    pe4 u_pe3 (.x(x[15:12]), .valid(v3), .pos(p3));
    pe4 u_pe2 (.x(x[11:8]),  .valid(v2), .pos(p2));
    pe4 u_pe1 (.x(x[7:4]),   .valid(v1), .pos(p1));
    pe4 u_pe0 (.x(x[3:0]),   .valid(v0), .pos(p0));

    wire       v_lo8;
    wire [2:0] p_lo8;
    merge #(.W(2)) u_m01 (
        .v_hi(v1), .p_hi(p1),
        .v_lo(v0), .p_lo(p0),
        .v_out(v_lo8), .p_out(p_lo8)
    );

    wire       v_hi8;
    wire [2:0] p_hi8;
    merge #(.W(2)) u_m23 (
        .v_hi(v3), .p_hi(p3),
        .v_lo(v2), .p_lo(p2),
        .v_out(v_hi8), .p_out(p_hi8)
    );

    merge #(.W(3)) u_final (
        .v_hi(v_hi8), .p_hi(p_hi8),
        .v_lo(v_lo8), .p_lo(p_lo8),
        .v_out(valid), .p_out(pos)
    );

endmodule


module pe4 (
    input  wire [3:0] x,
    output wire       valid,
    output wire [1:0] pos
);
    assign valid   = |x;
    assign pos[1]  = x[3] | x[2];
    assign pos[0]  = x[3] | (~x[2] & x[1]);
endmodule


module merge #(
    parameter W = 2
)(
    input  wire         v_hi,
    input  wire [W-1:0] p_hi,
    input  wire         v_lo,
    input  wire [W-1:0] p_lo,
    output wire         v_out,
    output wire [W:0]   p_out
);
    assign v_out = v_hi | v_lo;
    assign p_out = v_hi ? {1'b1, p_hi} : {1'b0, p_lo};
endmodule
