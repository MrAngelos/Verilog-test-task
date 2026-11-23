`timescale 1ns/1ps

module tb_priority_encoder_16;

    reg  [15:0] x = 0;
    wire [3:0]  pos;
    wire        valid;

    priority_encoder_16 dut (.x(x), .pos(pos), .valid(valid));

    integer i, j;
    integer fail = 0;
    reg        exp_valid;
    reg  [3:0] exp_pos;

    initial begin
        for (i = 0; i < 65536; i = i + 1) begin
            x = i[15:0];
            #1;

            exp_valid = 1'b0;
            exp_pos   = 4'd0;
            for (j = 0; j < 16; j = j + 1) begin
                if (x[j]) begin
                    exp_valid = 1'b1;
                    exp_pos   = j[3:0];
                end
            end

            if (valid !== exp_valid || pos !== exp_pos) begin
                if (fail < 20)
                    $display("FAIL x=%04h: got valid=%b pos=%0d, expected valid=%b pos=%0d",
                             x, valid, pos, exp_valid, exp_pos);
                fail = fail + 1;
            end
        end

        if (fail == 0)
            $display("=== PRIORITY ENCODER TESTBENCH: PASS  (65536/65536) ===");
        else
            $display("=== PRIORITY ENCODER TESTBENCH: FAIL  (%0d mismatches) ===", fail);
        $finish;
    end

endmodule
