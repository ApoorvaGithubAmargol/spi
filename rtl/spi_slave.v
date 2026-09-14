module spi_slave (
    input         clk,
    input         reset,

    input         cs_n,
    input         sclk,

    input         sclk_rise,
    input         sclk_fall,

    input         mosi,
    output        miso,

    input  [1:0]  spi_mode,

    input  [15:0] tx_data,
    output [15:0] rx_data,

    output        busy,
    output        done,

    output [7:0]  control_reg,
    output [7:0]  status_reg,
    output [7:0]  data_reg
);

    wire load;
    wire sample;
    wire shift;

    wire [4:0] bit_count;

    wire        response_load;
    wire [15:0] response_data;

    wire        write_en;
    wire [7:0]  write_addr;
    wire [7:0]  write_data;

    wire [7:0] status_value;

    wire [7:0] regfile_status_reg;



    assign status_value = {6'b0, done, busy};

    assign status_reg = status_value;


//slave fsm

    spi_slave_fsm fsm (
        .clk        (clk),
        .reset      (reset),

        .cs_n       (cs_n),
        .sclk_rise  (sclk_rise),
        .sclk_fall  (sclk_fall),

        .bit_count  (bit_count),
        .spi_mode   (spi_mode),

        .load       (load),
        .sample     (sample),
        .shift      (shift),

        .busy       (busy),
        .done       (done)
    );


//reg controller

    spi_slave_reg_controller reg_controller (
        .clk            (clk),
        .reset          (reset),

        .sample         (sample),
        .bit_count      (bit_count),
        .mosi           (mosi),

        .control_reg    (control_reg),
        .status_reg     (status_reg),
        .data_reg       (data_reg),

        .response_load  (response_load),
        .response_data  (response_data),

        .write_en       (write_en),
        .write_addr     (write_addr),
        .write_data     (write_data)
    );


//reg file

    spi_regfile regfile (
        .clk         (clk),
        .reset       (reset),

        .write_en    (write_en),
        .addr        (write_addr),
        .write_data  (write_data),

        .read_data   (),

        .control_reg (control_reg),

        /*
         * FIX:
         *
         * Previously:
         *
         *     .status_reg(status_reg)
         *
         * which created a multiple-driver condition because
         * status_reg is also assigned from status_value.
         */
        .status_reg  (regfile_status_reg),

        .data_reg    (data_reg)
    );


//slave shift reg

    spi_slave_shift_reg #(
        .WIDTH(16)
    ) shift_reg (
        .clk            (clk),
        .reset          (reset),

        .load           (load),
        .sample         (sample),
        .shift          (shift),

        .response_load  (response_load),
        .response_data  (response_data),

        .cpha           (spi_mode[0]),

        .tx_data        (tx_data),
        .mosi           (mosi),

        .miso           (miso),
        .rx_data        (rx_data),
        .bit_count      (bit_count)
    );

endmodule