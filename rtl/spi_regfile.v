module spi_regfile (
    input        clk,
    input        reset,

    input        write_en,
    input  [7:0] addr,
    input  [7:0] write_data,

    output reg [7:0] read_data,

    output reg [7:0] control_reg,
    output reg [7:0] status_reg,
    output reg [7:0] data_reg
);

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            control_reg <= 8'h00;
            status_reg  <= 8'h00;
            data_reg    <= 8'h00;

        end

        else if (write_en) begin

            case (addr)

                8'h01:
                    control_reg <= write_data;

                8'h03:
                    data_reg <= write_data;

            //Device ID and status are read-only.

                default: begin
                end

            endcase

        end

    end


    always @(*) begin

        case (addr)

            8'h00:
                read_data = 8'hA5;

            8'h01:
                read_data = control_reg;

            8'h02:
                read_data = status_reg;

            8'h03:
                read_data = data_reg;

            default:
                read_data = 8'h00;

        endcase

    end

endmodule