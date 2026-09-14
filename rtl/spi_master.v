module spi_master (
    input        clk,
    input        reset,
    input        start,

    input  [15:0] tx_data,
    input         miso,

    input  [15:0] clk_div,
    input  [4:0]  transfer_width,
    input  [1:0]  spi_mode,

    output        busy,
    output        done,
    output        error,

    output [15:0] rx_data,

    output        cs_n,
    output        sclk,
    output        mosi,

    output        sclk_rise,
    output        sclk_fall
);

    wire load;
    wire sample;
    wire shift;
    wire clock_enable;


    wire [4:0] bit_count;

    wire cpol;
    wire cpha;

    assign cpol = spi_mode[1];
    assign cpha = spi_mode[0];

    spi_clock_gen clock_gen (
        .clk       (clk),
        .reset     (reset),
        .enable    (clock_enable),
        .cpol      (cpol),
        .clk_div   (clk_div),

        .sclk      (sclk),
        .sclk_rise (sclk_rise),
        .sclk_fall (sclk_fall)
    );

    spi_master_fsm fsm (
        .clk            (clk),
        .reset          (reset),
        .start          (start),

        .sclk_rise      (sclk_rise),
        .sclk_fall      (sclk_fall),

        .bit_count      (bit_count),
        .transfer_width (transfer_width),
        .spi_mode       (spi_mode),

        .load           (load),
        .sample         (sample),
        .shift          (shift),
        .clock_enable   (clock_enable),

        .busy           (busy),
        .done           (done),
        .error          (error),
        .cs_n           (cs_n)
    );

    spi_master_shift_reg #(
        .WIDTH(16)
    ) shift_reg (
        .clk            (clk),
        .reset          (reset),

        .load           (load),
        .sample         (sample),
        .shift          (shift),

        .cpha           (cpha),

        .tx_data        (tx_data),
        .miso           (miso),
        .transfer_width (transfer_width),

        .mosi           (mosi),
        .rx_data        (rx_data),
        .bit_count      (bit_count)
    );

endmodule