module spi_slave_fsm (
    input        clk,
    input        reset,

    input        cs_n,
    input        sclk_rise,
    input        sclk_fall,

    input  [4:0] bit_count,
    input  [1:0] spi_mode,

    output reg   load,
    output reg   sample,
    output reg   shift,

    output reg   busy,
    output reg   done
);

    reg [1:0] state;

    localparam IDLE     = 2'd0;
    localparam LOAD     = 2'd1;
    localparam TRANSFER = 2'd2;
    localparam DONE     = 2'd3;

    wire cpol = spi_mode[1];
    wire cpha = spi_mode[0];

    wire leading_edge;
    wire trailing_edge;

    assign leading_edge  = cpol ? sclk_fall : sclk_rise;
    assign trailing_edge = cpol ? sclk_rise : sclk_fall;

    wire sample_edge = cpha ? trailing_edge : leading_edge;
    wire shift_edge  = cpha ? leading_edge  : trailing_edge;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end
        else begin

            case (state)

                IDLE: begin
                    if (!cs_n)
                        state <= LOAD;
                end

                LOAD: begin
                    state <= TRANSFER;
                end

                TRANSFER: begin
                    if (sample_edge && bit_count == 5'd15)
                        state <= DONE;
                end

                DONE: begin
                    if (cs_n)
                        state <= IDLE;
                end

                default:
                    state <= IDLE;

            endcase

        end
    end

    always @(*) begin
        load   = 1'b0;
        sample = 1'b0;
        shift  = 1'b0;
        busy   = 1'b0;
        done   = 1'b0;

        case (state)

            IDLE: begin
            end

            LOAD: begin
                load = 1'b1;
                busy = 1'b1;
            end

            TRANSFER: begin
                busy = 1'b1;

                if (sample_edge)
                    sample = 1'b1;

                if (shift_edge)
                    shift = 1'b1;
            end

            DONE: begin
                done = 1'b1;
            end

        endcase
    end

endmodule