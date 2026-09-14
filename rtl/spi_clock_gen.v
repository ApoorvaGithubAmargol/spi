module spi_clock_gen (
    input        clk,
    input        reset,
    input        enable,
    input        cpol,
    input [15:0] clk_div,

    output reg   sclk,
    output reg   sclk_rise,
    output reg   sclk_fall
);

    reg [15:0] count;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count     <= 16'd0;
            sclk      <= cpol;
            sclk_rise <= 1'b0;
            sclk_fall <= 1'b0;
        end
        else begin
            sclk_rise <= 1'b0;
            sclk_fall <= 1'b0;

            if (!enable) begin
                count <= 16'd0;
                sclk  <= cpol;
            end
            else if (clk_div <= 16'd1 || count == clk_div - 1'b1) begin
                count <= 16'd0;

                if (!sclk) begin
                    sclk      <= 1'b1;
                    sclk_rise <= 1'b1;
                end
                else begin
                    sclk      <= 1'b0;
                    sclk_fall <= 1'b1;
                end
            end
            else begin
                count <= count + 1'b1;
            end
        end
    end

endmodule