`timescale 1ns/1ps

module tb_spi_master_fsm;

    reg        clk;
    reg        reset;
    reg        start;
    reg        sclk_rise;
    reg        sclk_fall;
    reg  [4:0] bit_count;
    reg [4:0] transfer_width;

    wire load;
    wire sample;
    wire shift;
    wire clock_enable;
    wire busy;
    wire done;
    wire cs_n;

    spi_master_fsm dut (
        .clk          (clk),
        .reset        (reset),
        .start        (start),
        .sclk_rise    (sclk_rise),
        .sclk_fall    (sclk_fall),
        .bit_count    (bit_count),

        .load         (load),
        .sample       (sample),
        .shift        (shift),
        .clock_enable (clock_enable),
        .busy         (busy),
        .done         (done),
        .cs_n         (cs_n),
        .transfer_width (transfer_width)
    );

    always #5 clk = ~clk;

    initial begin

        clk        = 0;
        reset      = 1;
        start      = 0;
        sclk_rise  = 0;
        sclk_fall  = 0;
        bit_count  = 0;
        transfer_width = 16;

        #20;
        reset = 0;

        // Start transaction
        #10;
        start = 1;

        #10;
        start = 0;

        // Simulate 8 SPI bits
        repeat (16) begin

            // Rising edge -> sample
            #20;
            sclk_rise = 1;
            #10;
            sclk_rise = 0;

            // Falling edge -> shift
            #20;
            sclk_fall = 1;
            #10;
            sclk_fall = 0;

            bit_count = bit_count + 1;

        end

        #30;

        $finish;
    end


always @(posedge clk) begin
    if (start || sclk_rise || sclk_fall || load || sample || shift || done)
        $display("TIME=%0t | COUNT=%0d | RISE=%b FALL=%b | LOAD=%b SAMPLE=%b SHIFT=%b | BUSY=%b DONE=%b CS_N=%b",
                 $time,
                 bit_count,
                 sclk_rise,
                 sclk_fall,
                 load,
                 sample,
                 shift,
                 busy,
                 done,
                 cs_n);
end
endmodule