module Matriz_registradores(
    input [3:0] dado_in,
    input clk,
    input rst,
    input escrita,

    input [2:0] linha_jogo,
    input [2:0] coluna_jogo,

    output [3:0] dado_jogo
);

    // Memória do jogo (64 posições de 4 bits)
    reg [3:0] matriz [0:63];

    wire [5:0] endereco_jogo;

    integer i;

    assign endereco_jogo = {linha_jogo, coluna_jogo};

    // Escrita síncrona
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            for(i = 0; i < 64; i = i + 1)
                matriz[i] <= 4'b0000;
        end
        else if (escrita) begin
            matriz[endereco_jogo] <= dado_in;
        end
    end

    // Leitura assíncrona
    assign dado_jogo = matriz[endereco_jogo];

endmodule