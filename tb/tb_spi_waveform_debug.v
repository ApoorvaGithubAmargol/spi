`timescale 1ns/1ps

module tb_spi_waveform_debug;

    // ============================================================
    // DUT INTERFACE
    // ============================================================

    reg         clk;
    reg         reset;
    reg         start;

    reg [15:0]  tx_data;
    reg [15:0]  clk_div;
    reg [4:0]   transfer_width;
    reg [1:0]   spi_mode;

    wire        busy;
    wire        done;
    wire        error;


    wire        cs_n;
    wire        sclk;
    wire        mosi;
    wire        miso;

    wire [15:0] master_rx_data;
    wire [15:0] slave_rx_data;

    wire [7:0]  slave_control_reg;
    wire [7:0]  slave_status_reg;
    wire [7:0]  slave_data_reg;


//dut
spi_master_slave_top dut (
    .clk              (clk),
    .reset            (reset),
    .start            (start),

    .tx_data          (tx_data),
    .clk_div         (clk_div),
    .transfer_width  (transfer_width),
    .spi_mode        (spi_mode),

    .master_rx_data   (master_rx_data),

    .busy             (busy),
    .done             (done),
    .error            (error),

    .cs_n             (cs_n),
    .sclk             (sclk),
    .mosi             (mosi),
    .miso             (miso),

    .slave_rx_data    (slave_rx_data),
    .slave_busy       (slave_busy),
    .slave_done       (slave_done),

    .slave_control_reg(slave_control_reg),
    .slave_status_reg (slave_status_reg),
    .slave_data_reg   (slave_data_reg)
);


//system clock 100MHz

    always #5 clk = ~clk;

//reset

    task do_reset;
        begin
            reset = 1'b1;
            start = 1'b0;

            #40;

            reset = 1'b0;

            #40;
        end
    endtask

//start of spi transaction

    task spi_transfer;
        input [15:0] command;

        begin

            tx_data = command;

            @(posedge clk);
            start = 1'b1;

            @(posedge clk);
            start = 1'b0;

            wait(done == 1'b1);

            #20;

        end
    endtask


//write register

    task write_register;
        input [1:0] mode;
        input [7:0] address;
        input [7:0] data;

        reg [15:0] command;

        begin

            spi_mode = mode;

            command = {1'b0, address[6:0], data};

            $display(
                "WRITE  MODE=%0d  CMD=%04h  ADDR=%02h  DATA=%02h",
                mode, command, address, data
            );

            spi_transfer(command);

            if (address == 8'h01 && slave_control_reg == data) begin

                $display(
                    "       PASS: slave_control_reg = %02h",
                    slave_control_reg
                );

            end
            else begin

                $display(
                    "       FAIL: slave_control_reg = %02h, EXPECTED=%02h",
                    slave_control_reg, data
                );

            end

            #50;

        end
    endtask


  //read reg

    task read_register;
        input [1:0] mode;
        input [7:0] address;
        input [7:0] expected;

        reg [15:0] command;
        reg [15:0] expected_response;

        begin

            spi_mode = mode;

            command = {1'b1, address[6:0], 8'h00};

            expected_response = {8'h00, expected};

            $display(
                "READ   MODE=%0d  CMD=%04h  EXPECTED RX=%04h",
                mode, command, expected_response
            );

            spi_transfer(command);

            if (master_rx_data == expected_response) begin

                $display(
                    "       PASS: rx_data = %04h",
                    master_rx_data
                );

            end
            else begin

                $display(
                    "       FAIL: rx_data = %04h, EXPECTED=%04h",
                    master_rx_data, expected_response
                );

            end

            #50;

        end
    endtask

//initialize

    initial begin

        clk            = 1'b0;
        reset          = 1'b0;
        start          = 1'b0;

        tx_data        = 16'h0000;
        clk_div        = 16'd4;
        transfer_width = 5'd16;
        spi_mode       = 2'b00;


        // waveform

        $dumpfile("sim/spi_waveform_all_modes.vcd");
        $dumpvars(0, tb_spi_waveform_debug);


        // reset

        do_reset;


        // mode 0

        $display("");
        $display("======================================");
        $display("           SPI MODE 0");
        $display("======================================");

        write_register(2'b00, 8'h01, 8'h5A);
        read_register (2'b00, 8'h01, 8'h5A);


        // mode 1

        $display("");
        $display("======================================");
        $display("           SPI MODE 1");
        $display("======================================");

        write_register(2'b01, 8'h01, 8'h5A);
        read_register (2'b01, 8'h01, 8'h5A);


        // mode 2

        $display("");
        $display("======================================");
        $display("           SPI MODE 2");
        $display("======================================");

        write_register(2'b10, 8'h01, 8'h5A);
        read_register (2'b10, 8'h01, 8'h5A);


        // mode 3

        $display("");
        $display("======================================");
        $display("           SPI MODE 3");
        $display("======================================");

        write_register(2'b11, 8'h01, 8'h5A);
        read_register (2'b11, 8'h01, 8'h5A);




        #100;

        $display("");
        $display("======================================");
        $display("   ALL 4 SPI MODES WAVEFORM TESTED");
        $display("======================================");

        $finish;

    end

endmodule