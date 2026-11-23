module gcd_pipeline #(
    parameter W      = 16,
    parameter STAGES = 32,
    parameter CW     = $clog2(W)
)(
    input  wire         clk,
    input  wire         reset,
    input  wire [W-1:0] a_in,
    input  wire [W-1:0] b_in,
    output wire [W-1:0] gcd_out
);

    reg [W-1:0] a_reg [0:STAGES-1];
    reg [W-1:0] b_reg [0:STAGES-1];
    reg [CW-1:0] c_reg [0:STAGES-1];

    integer i;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            a_reg[0] <= {W{1'b0}};
            b_reg[0] <= {W{1'b0}};
            c_reg[0] <= {CW{1'b0}};
        end else begin
            a_reg[0] <= a_in;
            b_reg[0] <= b_in;
            c_reg[0] <= {CW{1'b0}};
        end
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 1; i < STAGES; i = i + 1) begin
                a_reg[i] <= {W{1'b0}};
                b_reg[i] <= {W{1'b0}};
                c_reg[i] <= {CW{1'b0}};
            end
        end else begin
            for (i = 1; i < STAGES; i = i + 1) begin
                if (a_reg[i-1] != 0 && b_reg[i-1] != 0) begin
                    if (!a_reg[i-1][0] && !b_reg[i-1][0]) begin
                        a_reg[i] <= a_reg[i-1] >> 1;
                        b_reg[i] <= b_reg[i-1] >> 1;
                        c_reg[i] <= c_reg[i-1] + 1'b1;
                    end else if (!a_reg[i-1][0]) begin
                        a_reg[i] <= a_reg[i-1] >> 1;
                        b_reg[i] <= b_reg[i-1];
                        c_reg[i] <= c_reg[i-1];
                    end else if (!b_reg[i-1][0]) begin
                        a_reg[i] <= a_reg[i-1];
                        b_reg[i] <= b_reg[i-1] >> 1;
                        c_reg[i] <= c_reg[i-1];
                    end else if (a_reg[i-1] > b_reg[i-1]) begin
                        a_reg[i] <= (a_reg[i-1] - b_reg[i-1]) >> 1;
                        b_reg[i] <= b_reg[i-1];
                        c_reg[i] <= c_reg[i-1];
                    end else begin
                        a_reg[i] <= a_reg[i-1];
                        b_reg[i] <= (b_reg[i-1] - a_reg[i-1]) >> 1;
                        c_reg[i] <= c_reg[i-1];
                    end
                end else begin
                    a_reg[i] <= a_reg[i-1];
                    b_reg[i] <= b_reg[i-1];
                    c_reg[i] <= c_reg[i-1];
                end
            end
        end
    end

    assign gcd_out = (a_reg[STAGES-1] | b_reg[STAGES-1]) << c_reg[STAGES-1];

endmodule
