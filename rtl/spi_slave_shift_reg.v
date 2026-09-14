module spi_slave_shift_reg #(
    parameter WIDTH = 16
)(
    input              clk,
    input              reset,

    input              load,
    input              sample,
    input              shift,

    input              response_load,
    input  [WIDTH-1:0] response_data,

    input              cpha,

    input  [WIDTH-1:0] tx_data,
    input              mosi,

    output             miso,
    output [WIDTH-1:0] rx_data,
    output [4:0]       bit_count
);

    reg [WIDTH-1:0] tx_shift_reg;
    reg [WIDTH-1:0] rx_shift_reg;
    reg [WIDTH-1:0] response_reg;
    reg [4:0]       bit_count_reg;
    reg             response_active;

    assign rx_data   = rx_shift_reg;
    assign bit_count = bit_count_reg;

    assign miso = response_active && (bit_count_reg >= 5'd8) ?
                  response_reg[15 - bit_count_reg] :
                  (cpha ? tx_shift_reg[15] : tx_shift_reg[14]);

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            tx_shift_reg  <= 16'h0000;
            rx_shift_reg  <= 16'h0000;
            response_reg  <= 16'h0000;
            bit_count_reg <= 5'd0;
            response_active <= 1'b0;
        end

        else begin

            if (load) begin
                tx_shift_reg    <= tx_data;
                rx_shift_reg    <= 16'h0000;
                response_reg    <= 16'h0000;
                bit_count_reg   <= 5'd0;
                response_active <= 1'b0;
            end

            else begin

                if (response_load) begin
                    response_reg    <= response_data;
                    response_active <= 1'b1;
                end

                if (sample) begin
                    rx_shift_reg <= {
                        rx_shift_reg[WIDTH-2:0],
                        mosi
                    };

                    bit_count_reg <= bit_count_reg + 1'b1;
                end

                if (shift) begin
                    tx_shift_reg <= {
                        tx_shift_reg[WIDTH-2:0],
                        1'b0
                    };
                end

            end

        end
    end

endmodule