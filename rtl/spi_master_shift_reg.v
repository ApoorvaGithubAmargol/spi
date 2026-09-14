module spi_master_shift_reg #(
    parameter WIDTH = 16
)(
    input              clk,
    input              reset,

    input              load,
    input              sample,
    input              shift,

    input              cpha,

    input  [WIDTH-1:0] tx_data,
    input              miso,
    input  [4:0]       transfer_width,

    output             mosi,
    output [WIDTH-1:0] rx_data,
    output [4:0]       bit_count
);

        reg [WIDTH-1:0] tx_shift_reg;
        reg [WIDTH-1:0] rx_shift_reg;
        reg [4:0] bit_count_reg;

        reg mosi_cpha1;

        assign mosi = cpha ?
                    mosi_cpha1 :
                    ((transfer_width == 5'd8) ?
                    tx_shift_reg[7] :
                    tx_shift_reg[15]);


    assign rx_data   = rx_shift_reg;
    assign bit_count = bit_count_reg;


    always @(posedge clk or posedge reset) begin

        if (reset) begin

            tx_shift_reg  <= 16'd0;
            rx_shift_reg  <= 16'd0;
            bit_count_reg <= 5'd0;

            mosi_cpha1    <= 1'b0;

        end

        else begin

//load
            if (load) begin

                if (transfer_width == 5'd8)
                    tx_shift_reg <= {8'h00, tx_data[7:0]};
                else
                    tx_shift_reg <= tx_data;

                rx_shift_reg  <= 16'd0;
                bit_count_reg <= 5'd0;

                mosi_cpha1    <= 1'b0;

            end

            else begin

//sample
                if (sample) begin

                    if (transfer_width == 5'd8) begin

                        rx_shift_reg[7:0] <=
                            {rx_shift_reg[6:0], miso};

                    end

                    else begin

                        rx_shift_reg <=
                            {rx_shift_reg[WIDTH-2:0], miso};

                    end

                    bit_count_reg <= bit_count_reg + 1'b1;

                end

//shift
                if (shift) begin

                    if (cpha) begin

                        if (transfer_width == 5'd8) begin
                            mosi_cpha1 <= tx_shift_reg[7];

                            tx_shift_reg[7:0] <=
                                {tx_shift_reg[6:0], 1'b0};
                        end

                        else begin
                            mosi_cpha1 <= tx_shift_reg[15];

                            tx_shift_reg <=
                                {tx_shift_reg[WIDTH-2:0], 1'b0};
                        end

                    end

                    else begin

                        if (transfer_width == 5'd8)
                            tx_shift_reg[7:0] <=
                                {tx_shift_reg[6:0], 1'b0};
                        else
                            tx_shift_reg <=
                                {tx_shift_reg[WIDTH-2:0], 1'b0};

                    end

                end

            end

        end

    end

endmodule