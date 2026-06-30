module contador_navios(
    input clk,
    input incremento,
    input reset,
    output reg [2:0] contagem
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            contagem <= 3'b000;
        else if (incremento)
            contagem <= contagem + 1'b1;
    end

endmodule
