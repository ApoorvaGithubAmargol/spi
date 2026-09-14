`timescale 1ns/1ps

module tb_spi_slave_shift_reg;

    parameter WIDTH = 16;

    reg clk;
    reg reset;
    reg load;
    reg sample;
    reg shift;

    reg [WIDTH-1:0] tx_data;
    reg mosi;

    wire miso;
    wire [WIDTH-1:0] rx_data;
    wire [4:0] bit_count;

    integer i;

    spi_slave_shift_reg #(
        .WIDTH(WIDTH)
    ) dut (
        .clk       (clk),
        .reset     (reset),
        .load      (load),
        .sample    (sample),
        .shift     (shift),

        .tx_data   (tx_data),
        .mosi      (mosi),

        .miso      (miso),
        .rx_data   (rx_data),
        .bit_count (bit_count)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        load = 0;
        sample = 0;
        shift = 0;

        tx_data = 16'b1011001011010110;
        mosi    = 0;

        #20;
        reset = 0;

        load = 1;
        #10;
        load = 0;

        for (i = WIDTH-1; i >= 0; i = i - 1) begin
            mosi = 16'b0110110110101101 >> i;
            sample = 1;
            #10;
            sample = 0;
        end

        for (i = 0; i < WIDTH; i = i + 1) begin
            shift = 1;
            #10;
            shift = 0;
        end

        #10;

        $display("TX DATA = %b", tx_data);
        $display("RX DATA = %b", rx_data);
        $display("COUNT   = %d", bit_count);

        if (rx_data == 16'b0110110110101101)
            $display("PASS: RX DATA MATCH");
        else
            $display("FAIL: RX DATA MISMATCH");

        $finish;
    end

endmodule