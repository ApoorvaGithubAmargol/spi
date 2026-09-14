module spi_slave_reg_controller (
    input        clk,
    input        reset,

    input        sample,
    input  [4:0] bit_count,
    input        mosi,

    input  [7:0] control_reg,
    input  [7:0] status_reg,
    input  [7:0] data_reg,

    output reg        response_load,
    output reg [15:0] response_data,

    output reg        write_en,
    output reg [7:0]  write_addr,
    output reg [7:0]  write_data
);

    reg [7:0] header_reg;
    reg [7:0] data_reg_rx;

    wire [7:0] header_next;
    wire [7:0] data_next;

    assign header_next = {header_reg[6:0], mosi};
    assign data_next   = {data_reg_rx[6:0], mosi};

    function [7:0] get_register;
        input [7:0] addr;

        begin
            case (addr)

                8'h00: get_register = 8'hA5;
                8'h01: get_register = control_reg;
                8'h02: get_register = status_reg;
                8'h03: get_register = data_reg;

                default:
                    get_register = 8'h00;

            endcase
        end
    endfunction

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            header_reg  <= 8'h00;
            data_reg_rx <= 8'h00;
        end

        else if (sample) begin

            if (bit_count < 5'd8)
                header_reg <= header_next;
            else
                data_reg_rx <= data_next;

        end

    end

    always @(*) begin

        response_load = 1'b0;
        response_data = 16'h0000;

        write_en   = 1'b0;
        write_addr = 8'h00;
        write_data = 8'h00;

        if (sample && bit_count == 5'd7) begin

            if (header_next[7]) begin
                response_load = 1'b1;
                response_data = {
                    8'h00,
                    get_register({1'b0, header_next[6:0]})
                };
            end

        end

        if (sample && bit_count == 5'd15) begin

            if (!header_reg[7]) begin
                write_en   = 1'b1;
                write_addr = {1'b0, header_reg[6:0]};
                write_data = data_next;
            end

        end

    end

endmodule