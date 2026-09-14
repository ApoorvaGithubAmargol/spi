`timescale 1ns/1ps

module tb_spi_slave;

    reg clk;
    reg reset;

    reg cs_n;
    reg sclk;
    reg sclk_rise;
    reg sclk_fall;

    reg mosi;
    wire miso;

    reg [1:0] spi_mode;
    reg [15:0] tx_data;

    wire [15:0] rx_data;
    wire busy;
    wire done;

    integer errors;
    integer i;

    reg [15:0] rx_pattern;
    reg [15:0] tx_pattern;

    spi_slave dut (
        .clk       (clk),
        .reset     (reset),

        .cs_n      (cs_n),
        .sclk      (sclk),

        .sclk_rise (sclk_rise),
        .sclk_fall (sclk_fall),

        .mosi      (mosi),
        .miso      (miso),

        .spi_mode  (spi_mode),

        .tx_data   (tx_data),
        .rx_data   (rx_data),

        .busy      (busy),
        .done      (done)
    );

    always #5 clk = ~clk;

    task spi_edge;
        input reg edge_type;
        begin
            if (edge_type == 1'b1) begin
                sclk = 1'b1;
                sclk_rise = 1'b1;
            end
            else begin
                sclk = 1'b0;
                sclk_fall = 1'b1;
            end

            #1;
            @(posedge clk);

            sclk_rise = 1'b0;
            sclk_fall = 1'b0;

            #1;
        end
    endtask

    task run_test;
        input [1:0] mode;

        integer j;

        begin
            spi_mode = mode;

            rx_pattern = 16'h6DAD;
            tx_pattern = 16'hB2D6;
            tx_data = tx_pattern;

            cs_n = 1'b1;
            sclk = mode[1];
            sclk_rise = 1'b0;
            sclk_fall = 1'b0;
            mosi = 1'b0;

            #20;

            cs_n = 1'b0;

            @(posedge clk);
            @(posedge clk);

            for (j = 15; j >= 0; j = j - 1) begin

                if (mode[0] == 1'b0) begin
                    mosi = tx_pattern[j];

                    if (mode[1] == 1'b0)
                        spi_edge(1'b1);
                    else
                        spi_edge(1'b0);

                    if (j > 0) begin
                        if (mode[1] == 1'b0)
                            spi_edge(1'b0);
                        else
                            spi_edge(1'b1);

                        mosi = tx_pattern[j-1];
                    end
                end

                else begin

                    if (mode[1] == 1'b0)
                        spi_edge(1'b1);
                    else
                        spi_edge(1'b0);

                    mosi = tx_pattern[j];

                    if (mode[1] == 1'b0)
                        spi_edge(1'b0);
                    else
                        spi_edge(1'b1);
                end

            end

            cs_n = 1'b1;

            #20;

            if (rx_data !== tx_pattern) begin
                $display("FAIL MODE=%0d RX=%h EXP=%h",
                         mode, rx_data, tx_pattern);
                errors = errors + 1;
            end
            else begin
                $display("PASS MODE=%0d RX=%h", mode, rx_data);
            end
        end
    endtask

    initial begin

        clk = 0;
        reset = 1;

        cs_n = 1;
        sclk = 0;
        sclk_rise = 0;
        sclk_fall = 0;

        mosi = 0;
        spi_mode = 0;
        tx_data = 0;

        errors = 0;

        #20;
        reset = 0;

        run_test(2'b00);
        run_test(2'b01);
        run_test(2'b10);
        run_test(2'b11);

        if (errors == 0)
            $display("\nALL SLAVE TESTS PASSED");
        else
            $display("\nSLAVE TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule