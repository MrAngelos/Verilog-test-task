`timescale 1ns/1ps

module tb_gcd_pipeline;

    localparam W      = 16;
    localparam STAGES = 32;
    localparam CW     = $clog2(W);
    localparam NE     = 24;
    localparam NEX    = 65536;
    localparam NRND   = 20000;
    localparam VEC    = NE + NEX + NRND;

    reg         clk   = 0;
    reg         reset = 1;
    reg  [W-1:0] a_in = 0;
    reg  [W-1:0] b_in = 0;
    wire [W-1:0] gcd_out;

    gcd_pipeline #(.W(W), .STAGES(STAGES)) dut (
        .clk(clk), .reset(reset),
        .a_in(a_in), .b_in(b_in),
        .gcd_out(gcd_out)
    );

    function [W-1:0] gcd_ref(input [W-1:0] a, b);
        reg [W-1:0]  x, y;
        reg [CW-1:0] cnt;
        integer j;
        begin
            x = a; y = b; cnt = {CW{1'b0}};
            for (j = 0; j < 2*W; j = j + 1) begin
                if (x != 0 && y != 0) begin
                    if (!x[0] && !y[0]) begin
                        x = x >> 1; y = y >> 1; cnt = cnt + 1'b1;
                    end else if (!x[0]) begin
                        x = x >> 1;
                    end else if (!y[0]) begin
                        y = y >> 1;
                    end else if (x > y) begin
                        x = (x - y) >> 1;
                    end else begin
                        y = (y - x) >> 1;
                    end
                end
            end
            gcd_ref = (x | y) << cnt;
        end
    endfunction

    reg [W-1:0] a_vec [0:VEC-1];
    reg [W-1:0] b_vec [0:VEC-1];

    reg [W-1:0] ref_q [0:STAGES-1];
    integer k;
    always @(posedge clk) begin
        if (reset) begin
            for (k = 0; k < STAGES; k = k + 1) ref_q[k] <= {W{1'b0}};
        end else begin
            for (k = STAGES-1; k >= 1; k = k - 1) ref_q[k] <= ref_q[k-1];
            ref_q[0] <= gcd_ref(a_in, b_in);
        end
    end

    reg [31:0] cyc = 0;
    always @(posedge clk) cyc <= reset ? 0 : cyc + 1'b1;

    integer fail = 0;
    integer idx;
    always @(negedge clk) begin
        if (!reset && cyc >= STAGES && cyc <= STAGES + VEC - 1) begin
            idx = cyc - STAGES;
            if (gcd_out !== ref_q[STAGES-1]) begin
                if (fail < 20)
                    $display("FAIL vec=%0d (a=%0d b=%0d): got=%0d expected=%0d",
                             idx, a_vec[idx], b_vec[idx], gcd_out, ref_q[STAGES-1]);
                fail = fail + 1;
            end
        end
    end

    integer i;
    reg  [W-1:0] ea [0:NE-1];
    reg  [W-1:0] eb [0:NE-1];

    initial begin
        ea[0]=16'd0;      eb[0]=16'd0;
        ea[1]=16'd0;      eb[1]=16'd1;
        ea[2]=16'd1;      eb[2]=16'd0;
        ea[3]=16'd1;      eb[3]=16'd1;
        ea[4]=16'd1;      eb[4]=16'd65535;
        ea[5]=16'd65535;  eb[5]=16'd1;
        ea[6]=16'd65535;  eb[6]=16'd65535;
        ea[7]=16'd65535;  eb[7]=16'd65534;
        ea[8]=16'd65534;  eb[8]=16'd65535;
        ea[9]=16'd32768;  eb[9]=16'd32768;
        ea[10]=16'd32768; eb[10]=16'd32769;
        ea[11]=16'd32769; eb[11]=16'd32768;
        ea[12]=16'd6;     eb[12]=16'd4;
        ea[13]=16'd12;    eb[13]=16'd8;
        ea[14]=16'd270;   eb[14]=16'd192;
        ea[15]=16'd1071;  eb[15]=16'd462;
        ea[16]=16'd46368; eb[16]=16'd28657;
        ea[17]=16'd65535; eb[17]=16'd32767;
        ea[18]=16'd32767; eb[18]=16'd65535;
        ea[19]=16'd43690; eb[19]=16'd17476;
        ea[20]=16'd43690; eb[20]=16'd21845;
        ea[21]=16'd12345; eb[21]=16'd6789;
        ea[22]=16'd32768; eb[22]=16'd0;
        ea[23]=16'd0;     eb[23]=16'd32768;

        for (i = 0; i < NE; i = i + 1) begin
            a_vec[i] = ea[i];
            b_vec[i] = eb[i];
        end
        for (i = 0; i < NEX; i = i + 1) begin
            a_vec[NE + i] = (i >> 8) & 16'hFF;
            b_vec[NE + i] = i & 16'hFF;
        end
        for (i = 0; i < NRND; i = i + 1) begin
            a_vec[NE + NEX + i] = $random & 16'hFFFF;
            b_vec[NE + NEX + i] = $random & 16'hFFFF;
        end

        clk = 0;
        reset = 1;
        a_in = 0; b_in = 0;
        repeat (5) @(posedge clk);
        @(negedge clk);
        reset = 0;

        for (i = 0; i < VEC; i = i + 1) begin
            a_in = a_vec[i];
            b_in = b_vec[i];
            @(negedge clk);
        end
        a_in = 0; b_in = 0;

        repeat (STAGES + 4) @(negedge clk);

        if (fail == 0)
            $display("=== GCD TESTBENCH: PASS  (%0d vectors, STAGES=%0d) ===", VEC, STAGES);
        else
            $display("=== GCD TESTBENCH: FAIL  (%0d mismatches) ===", fail);
        $finish;
    end

    always #5 clk = ~clk;

    initial begin
        #( (VEC + STAGES + 20) * 10 + 1000 );
        $display("=== GCD TESTBENCH: TIMEOUT ===");
        $finish;
    end

endmodule
