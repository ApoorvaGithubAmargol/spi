`timescale 1ns/1ps

module tb_spi_master;

    reg clk;
    reg reset;
    reg start;

    reg [15:0] tx_data;
    reg miso;

    reg [15:0] clk_div;
    reg [4:0] transfer_width;
    reg [1:0] spi_mode;

    wire busy;
    wire done;
    wire error;

    wire [15:0] rx_data;
    wire cs_n;
    wire sclk;
    wire mosi;

    integer errors;

    spi_master dut (
        .clk            (clk),
        .reset          (reset),
        .start          (start),
        .tx_data        (tx_data),
        .miso           (miso),
        .clk_div        (clk_div),
        .transfer_width (transfer_width),
        .spi_mode       (spi_mode),
        .busy            (busy),
        .done            (done),
        .error           (error),
        .rx_data         (rx_data),
        .cs_n            (cs_n),
        .sclk            (sclk),
        .mosi            (mosi)
    );

    always #5 clk = ~clk;

    task run_test;
        input [1:0] mode;
        input [4:0] width;

        integer j;
        reg [15:0] tx;
        reg [15:0] rx;

        begin
            spi_mode       = mode;
            transfer_width = width;

            if (width == 8) begin
                tx = 16'h00B2;
                rx = 16'h006D;
            end
            else begin
                tx = 16'hB2D6;
                rx = 16'h6DAD;
            end

            tx_data = tx;
            miso    = 1'b0;

            @(posedge clk);
            start = 1'b1;

            @(posedge clk);
            start = 1'b0;

            wait (cs_n == 1'b0);

            if (mode[0] == 1'b0) begin
                miso = (width == 8) ? rx[7] : rx[15];

                for (j = width-1; j > 0; j = j - 1) begin
                    if (mode[1] == 0)
                        @(negedge sclk);
                    else
                        @(posedge sclk);

                    miso = (width == 8) ? rx[j-1] : rx[j-1];
                end
            end
            else begin
                for (j = width-1; j >= 0; j = j - 1) begin

                    if (mode[1] == 0)
                        @(posedge sclk);
                    else
                        @(negedge sclk);

                    miso = (width == 8) ? rx[j] : rx[j];
                end
            end

            wait (done);
            #1;

            if (width == 8) begin
                if (rx_data[7:0] !== rx[7:0]) begin
                    $display("FAIL MODE=%0d WIDTH=%0d RX=%h EXP=%h",
                             mode, width, rx_data[7:0], rx[7:0]);
                    errors = errors + 1;
                end
            end
            else begin
                if (rx_data !== rx) begin
                    $display("FAIL MODE=%0d WIDTH=%0d RX=%h EXP=%h",
                             mode, width, rx_data, rx);
                    errors = errors + 1;
                end
            end

            if (cs_n !== 1'b1) begin
                $display("FAIL CS MODE=%0d WIDTH=%0d", mode, width);
                errors = errors + 1;
            end

            $display("PASS MODE=%0d WIDTH=%0d RX=%h",
                     mode, width, rx_data);

            @(posedge clk);
        end
    endtask

    initial begin
        clk = 0;
        reset = 1;
        start = 0;

        tx_data = 0;
        miso = 0;

        clk_div = 16'd4;
        transfer_width = 16;
        spi_mode = 0;

        errors = 0;

        #20;
        reset = 0;

        #20;

        run_test(2'b00, 8);
        run_test(2'b00, 16);

        run_test(2'b01, 8);
        run_test(2'b01, 16);

        run_test(2'b10, 8);
        run_test(2'b10, 16);

        run_test(2'b11, 8);
        run_test(2'b11, 16);

        if (errors == 0)
            $display("\nALL MASTER TESTS PASSED");
        else
            $display("\nMASTER TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule