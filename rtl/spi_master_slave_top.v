module spi_master_slave_top (
    input         clk,
    input         reset,
    input         start,

    input  [15:0] tx_data,
    input  [15:0] clk_div,
    input  [4:0]  transfer_width,
    input  [1:0]  spi_mode,

    output [15:0] master_rx_data,

    output        busy,
    output        done,
    output        error,

    output        cs_n,
    output        sclk,
    output        mosi,
    output        miso,

    output [15:0] slave_rx_data,
    output        slave_busy,
    output        slave_done,

    output [7:0]  slave_control_reg,
    output [7:0]  slave_status_reg,
    output [7:0]  slave_data_reg
);

    wire sclk_rise;
    wire sclk_fall;

    spi_master master (
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

        .rx_data         (master_rx_data),

        .cs_n            (cs_n),
        .sclk            (sclk),
        .mosi            (mosi),

        .sclk_rise       (sclk_rise),
        .sclk_fall       (sclk_fall)
    );

    spi_slave slave (
        .clk            (clk),
        .reset          (reset),

        .cs_n            (cs_n),
        .sclk            (sclk),

        .sclk_rise       (sclk_rise),
        .sclk_fall       (sclk_fall),

        .mosi            (mosi),
        .miso            (miso),

        .spi_mode        (spi_mode),

        .tx_data         (16'h0000),
        .rx_data         (slave_rx_data),

        .busy            (slave_busy),
        .done            (slave_done),

        .control_reg     (slave_control_reg),
        .status_reg      (slave_status_reg),
        .data_reg        (slave_data_reg)
    );

endmodule