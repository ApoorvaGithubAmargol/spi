`timescale 1ns/1ps

module tb_spi_clock_gen;

    reg        clk;
    reg        reset;
    reg        enable;
    reg [15:0] clk_div;

    wire       sclk;
    wire       sclk_rise;
    wire       sclk_fall;

spi_clock_gen dut (
    .clk       (clk),
    .reset     (reset),
    .enable    (enable),
    .clk_div   (clk_div),
    .sclk      (sclk),
    .sclk_rise (sclk_rise),
    .sclk_fall (sclk_fall)
);

    always #5 clk = ~clk;

    initial begin

        clk     = 1'b0;
        reset   = 1'b1;
        enable  = 1'b0;
        clk_div = 16'd4;

        #20;
        reset = 1'b0;

        #20;
        enable = 1'b1;

        #160;

        enable = 1'b0;

        #20;

        $finish;
    end

always @(posedge clk) begin

    if (sclk_rise)
        $display("TIME=%0t | SCLK RISE | SCLK=%b", $time, sclk);

    if (sclk_fall)
        $display("TIME=%0t | SCLK FALL | SCLK=%b", $time, sclk);

end

endmodule