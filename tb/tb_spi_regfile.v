`timescale 1ns/1ps

module tb_spi_regfile;

    reg clk;
    reg reset;

    reg        write_en;
    reg [7:0]  addr;
    reg [7:0]  write_data;

    wire [7:0] read_data;

    spi_regfile dut (
        .clk       (clk),
        .reset     (reset),
        .write_en  (write_en),
        .addr      (addr),
        .write_data(write_data),
        .read_data (read_data)
    );

    always #5 clk = ~clk;

    initial begin
        clk       = 0;
        reset     = 1;
        write_en  = 0;
        addr      = 8'h00;
        write_data = 8'h00;

        #10;
        reset = 0;

        // Test 1: Device ID
        addr = 8'h00;
        #1;

        if (read_data == 8'hA5)
            $display("PASS: Device ID = %h", read_data);
        else
            $display("FAIL: Device ID = %h", read_data);

        // Test 2: Write and read Control
        addr       = 8'h01;
        write_data = 8'h55;
        write_en   = 1;

        @(posedge clk);
        #1;

        write_en = 0;
        #1;

        if (read_data == 8'h55)
            $display("PASS: Control write/read");
        else
            $display("FAIL: Control = %h", read_data);

        // Test 3: Write and read Data
        addr       = 8'h03;
        write_data = 8'hAB;
        write_en   = 1;

        @(posedge clk);
        #1;

        write_en = 0;
        #1;

        if (read_data == 8'hAB)
            $display("PASS: Data write/read");
        else
            $display("FAIL: Data = %h", read_data);

        // Test 4: Attempt to write Device ID
        addr       = 8'h00;
        write_data = 8'hFF;
        write_en   = 1;

        @(posedge clk);
        #1;

        write_en = 0;
        #1;

        if (read_data == 8'hA5)
            $display("PASS: Device ID is read-only");
        else
            $display("FAIL: Device ID changed to %h", read_data);

        // Test 5: Attempt to write Status
        addr       = 8'h02;
        write_data = 8'hFF;
        write_en   = 1;

        @(posedge clk);
        #1;

        write_en = 0;
        #1;

        if (read_data == 8'h00)
            $display("PASS: Status is read-only");
        else
            $display("FAIL: Status changed to %h", read_data);

        // Test 6: Invalid address
        addr = 8'hFF;
        #1;

        if (read_data == 8'h00)
            $display("PASS: Invalid address returns 00");
        else
            $display("FAIL: Invalid address returned %h", read_data);

        $display("Register file test complete.");

        $finish;
    end

endmodule