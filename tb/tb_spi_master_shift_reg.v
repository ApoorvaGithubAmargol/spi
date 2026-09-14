`timescale 1ns/1ps

module tb_spi_master_shift_reg;

    parameter WIDTH = 16;

    reg                  clk;
    reg                  reset;

    reg                  load;
    reg                  sample;
    reg                  shift;

    reg  [WIDTH-1:0]     tx_data;
    reg                  miso;

    wire                 mosi;
    wire [WIDTH-1:0]     rx_data;
    wire [4:0]           bit_count;

    reg  [WIDTH-1:0]     rx_pattern;

    integer i;


    // DUT

    spi_master_shift_reg #(
        .WIDTH(WIDTH)
    ) dut (
        .clk       (clk),
        .reset     (reset),
        .load      (load),
        .sample    (sample),
        .shift     (shift),
        .tx_data   (tx_data),
        .miso      (miso),
        .mosi      (mosi),
        .rx_data   (rx_data),
        .bit_count (bit_count)
    );


    // CLOCK

    always #5 clk = ~clk;


    // TEST
 
    initial begin

        clk   = 1'b0;
        reset = 1'b1;

        load   = 1'b0;
        sample = 1'b0;
        shift  = 1'b0;

        tx_data    = 16'b1011001011010110;
        rx_pattern = 16'b0110110110101101;
        miso       = 1'b0;


        // Reset

        #20;
        reset = 1'b0;


        // Load TX data

        load = 1'b1;
        #10;
        load = 1'b0;

       // Sample MISO bits
        // RX = 0110110110101101
 
        for (i = WIDTH-1; i >= 0; i = i - 1) begin

            miso = rx_pattern[i];

            sample = 1'b1;
            #10;
            sample = 1'b0;

        end

      // Shift TX data

        for (i = 0; i < WIDTH; i = i + 1) begin

            shift = 1'b1;
            #10;
            shift = 1'b0;

        end


        // Final result

        #20;

        $display("WIDTH    = %0d", WIDTH);
        $display("TX DATA  = %b", tx_data);
        $display("RX DATA  = %b", rx_data);
        $display("COUNT    = %0d", bit_count);

        $finish;

    end


    // MONITOR


    always @(posedge clk) begin

        if (sample) begin

            $display(
                "TIME=%0t | SAMPLE | MISO=%b | RX=%b | COUNT=%0d",
                $time,
                miso,
                rx_data,
                bit_count
            );

        end

        if (shift) begin

            $display(
                "TIME=%0t | SHIFT  | MOSI=%b | TX=%b",
                $time,
                mosi,
                dut.tx_shift_reg
            );

        end

    end

endmodule