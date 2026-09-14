module spi_master_fsm (
    input        clk,
    input        reset,
    input        start,

    input        sclk_rise,
    input        sclk_fall,

    input  [4:0] bit_count,
    input  [4:0] transfer_width,
    input  [1:0] spi_mode,

    output reg   load,
    output reg   sample,
    output reg   shift,
    output reg   clock_enable,

    output reg   busy,
    output reg   done,
    output reg   error,
    output reg   cs_n
);

    reg [2:0] state;

    localparam IDLE     = 3'd0;
    localparam LOAD     = 3'd1;
    localparam TRANSFER = 3'd2;
    localparam DONE     = 3'd3;

    wire cpol = spi_mode[1];
    wire cpha = spi_mode[0];

    wire leading_edge;
    wire trailing_edge;

    assign leading_edge = cpol ? sclk_fall : sclk_rise;
    assign trailing_edge = cpol ? sclk_rise : sclk_fall;

    wire sample_edge = cpha ? trailing_edge : leading_edge;
    wire shift_edge  = cpha ? leading_edge  : trailing_edge;

    wire [4:0] width;
    assign width = (transfer_width == 5'd8) ? 5'd8 : 5'd16;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end
        else begin
            case (state)

                IDLE: begin
                    if (start)
                        state <= LOAD;
                end

                LOAD: begin
                    state <= TRANSFER;
                end

                TRANSFER: begin
                    if (sample_edge &&
                        bit_count == width - 1'b1)
                        state <= DONE;
                end

                DONE: begin
                    state <= IDLE;
                end

                default: state <= IDLE;

            endcase
        end
    end

    always @(*) begin
        load         = 1'b0;
        sample       = 1'b0;
        shift        = 1'b0;
        clock_enable = 1'b0;
        busy         = 1'b0;
        done         = 1'b0;
        error        = 1'b0;
        cs_n         = 1'b1;

        case (state)

            IDLE: begin
                if (start)
                    error = busy;
            end

            LOAD: begin
                load         = 1'b1;
                clock_enable = 1'b1;
                busy         = 1'b1;
                cs_n         = 1'b0;
            end

            TRANSFER: begin
                clock_enable = 1'b1;
                busy         = 1'b1;
                cs_n         = 1'b0;

                if (sample_edge)
                    sample = 1'b1;

                if (shift_edge)
                    shift = 1'b1;

                if (start)
                    error = 1'b1;
            end

            DONE: begin
                done = 1'b1;
            end

            default: begin
                cs_n = 1'b1;
            end

        endcase
    end

endmodule