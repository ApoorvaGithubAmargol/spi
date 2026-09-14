`timescale 1ns/1ps

module tb_spi_slave_fsm;

    reg clk;
    reg reset;
    reg cs_n;

    reg sclk_rise;
    reg sclk_fall;

    reg [4:0] bit_count;
    reg [4:0] transfer_width;

    wire sample;
    wire shift;
    wire busy;
    wire done;

    integer i;

    spi_slave_fsm dut (
        .clk            (clk),
        .reset          (reset),
        .cs_n           (cs_n),

        .sclk_rise      (sclk_rise),
        .sclk_fall      (sclk_fall),

        .bit_count      (bit_count),
        .transfer_width (transfer_width),

        .sample         (sample),
        .shift          (shift),
        .busy           (busy),
        .done            (done)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        cs_n = 1;

        sclk_rise = 0;
        sclk_fall = 0;

        bit_count = 0;
        transfer_width = 16;

        #20;
        reset = 0;

        #10;
        cs_n = 0;

        #10;

        for (i = 0; i < 16; i = i + 1) begin

            sclk_rise = 1;
            #10;
            sclk_rise = 0;

            sclk_fall = 1;
            #10;
            sclk_fall = 0;

            bit_count = bit_count + 1'b1;
        end

        #20;

        $display("BIT COUNT = %d", bit_count);
        $display("BUSY      = %b", busy);
        $display("DONE      = %b", done);

        if (bit_count == 16)
            $display("PASS: 16-BIT TRANSFER");
        else
            $display("FAIL: BIT COUNT");

        cs_n = 1;

        #20;

        $display("BUSY AFTER CS = %b", busy);

        $finish;
    end

endmodule