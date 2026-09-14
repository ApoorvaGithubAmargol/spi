`timescale 1ns/1ps

module tb_spi_master_slave;

    reg clk;
    reg reset;
    reg start;

    reg [15:0] tx_data;
    reg [15:0] clk_div;
    reg [4:0]  transfer_width;
    reg [1:0]  spi_mode;

    wire [15:0] master_rx_data;

    wire busy;
    wire done;
    wire error;

    wire cs_n;
    wire sclk;
    wire mosi;
    wire miso;

    wire [15:0] slave_rx_data;
    wire slave_busy;
    wire slave_done;

    wire [7:0] slave_control_reg;
    wire [7:0] slave_status_reg;
    wire [7:0] slave_data_reg;

    integer errors;
    integer edge_count;

    spi_master_slave_top dut (
        .clk                (clk),
        .reset              (reset),
        .start              (start),

        .tx_data            (tx_data),
        .clk_div            (clk_div),
        .transfer_width     (transfer_width),
        .spi_mode           (spi_mode),

        .master_rx_data     (master_rx_data),

        .busy               (busy),
        .done               (done),
        .error              (error),

        .cs_n               (cs_n),
        .sclk               (sclk),
        .mosi               (mosi),
        .miso               (miso),

        .slave_rx_data      (slave_rx_data),
        .slave_busy         (slave_busy),
        .slave_done         (slave_done),

        .slave_control_reg  (slave_control_reg),
        .slave_status_reg   (slave_status_reg),
        .slave_data_reg     (slave_data_reg)
    );

    always #5 clk = ~clk;

    always @(posedge sclk or negedge sclk) begin
            edge_count = edge_count + 1;
    end

    task transfer;
        input [1:0] mode;
        input [15:0] tx;
        begin

            spi_mode = mode;
            tx_data  = tx;

            edge_count = 0;

            @(posedge clk);
            start = 1'b1;

            @(posedge clk);
            start = 1'b0;

            wait (busy);

            #1;

            if (cs_n !== 1'b0) begin
                $display("FAIL CS did not go low");
                errors = errors + 1;
            end

            wait (done);

            #1;

            if (cs_n !== 1'b1) begin
                $display("FAIL CS did not return high");
                errors = errors + 1;
            end

            /* if (edge_count != 32) begin
                $display("FAIL MODE=%0d clock edges=%0d",
                         mode, edge_count);
                errors = errors + 1;
            end
            */

            @(posedge clk);

        end
    endtask

    task check_read;
        input [1:0] mode;
        input [15:0] command;
        input [15:0] expected;
        begin

            transfer(mode, command);

            if (master_rx_data !== expected) begin
                $display("FAIL READ MODE=%0d CMD=%h RX=%h EXPECTED=%h",
                         mode, command,
                         master_rx_data, expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS READ  MODE=%0d CMD=%h RX=%h",
                         mode, command, master_rx_data);
            end

        end
    endtask

    task check_write;
        input [1:0] mode;
        input [15:0] command;
        input [7:0] expected;
        begin

            transfer(mode, command);

            if (slave_control_reg !== expected &&
                command[14:8] == 7'h01) begin

                $display("FAIL WRITE CONTROL MODE=%0d VALUE=%h",
                         mode, slave_control_reg);
                errors = errors + 1;

            end
            else if (slave_data_reg !== expected &&
                     command[14:8] == 7'h03) begin

                $display("FAIL WRITE DATA MODE=%0d VALUE=%h",
                         mode, slave_data_reg);
                errors = errors + 1;

            end
            else begin
                $display("PASS WRITE MODE=%0d CMD=%h",
                         mode, command);
            end

        end
    endtask

    integer mode;




    initial begin

        clk            = 1'b0;
        reset          = 1'b1;
        start          = 1'b0;
        tx_data        = 16'h0000;
        clk_div        = 16'd4;
        transfer_width = 5'd16;
        spi_mode       = 2'd0;

        errors = 0;
        edge_count = 0;

        #30;
        reset = 1'b0;

        for (mode = 0; mode < 4; mode = mode + 1) begin
            check_write(
                mode[1:0],
                16'h015A,
                8'h5A
            );

            check_read(
                mode[1:0],
                16'h8100,
                16'h005A
            );

            transfer(
                mode[1:0],
                16'h03C3
            );

            if (slave_data_reg !== 8'hC3) begin
                $display("FAIL DATA WRITE MODE=%0d VALUE=%h",
                         mode, slave_data_reg);
                errors = errors + 1;
            end
            else begin
                $display("PASS DATA WRITE MODE=%0d VALUE=%h",
                         mode, slave_data_reg);
            end

            check_read(
                mode[1:0],
                16'h8300,
                16'h00C3
            );

            check_read(
                mode[1:0],
                16'h8000,
                16'h00A5
            );

        end

        spi_mode = 2'd0;
        tx_data  = 16'h0155;

        @(posedge clk);
        start = 1'b1;

        @(posedge clk);
        start = 1'b0;

        wait (busy);

        @(negedge clk);
        start = 1'b1;

        #1;

        if (error !== 1'b1) begin
            $display("FAIL BUSY START ERROR");
            errors = errors + 1;
        end
        else begin
            $display("PASS BUSY START ERROR");
        end

        @(posedge clk);
        start = 1'b0;

        wait (done);

        #1;

        if (slave_control_reg !== 8'h55) begin
            $display("FAIL FINAL WRITE");
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("");
            $display(" ALL SPI INTEGRATION TESTS PASSED");
        end
        else begin
            $display("");
            $display(" SPI INTEGRATION TESTS FAILED: %0d",
                     errors);
        end



        #20;
        $finish;

    end

endmodule