module MEF_posicionamento(
    input count_sig,
	 input posicionamento_en,
    input clk,
    input reset,
    output [1:0] tipo_navio,
    output reg complete
);
//--------------------------------------------------- 
    wire [2:0] casas_navio;           // contagem de 3 bits
    reg reset_contador, inc_contador; // manipular o contador
//-------------------------------------------------------
    // 1º - Definição dos estados
    reg [1:0] estado_atual;
    reg [1:0] proximo_estado;

    localparam INSERE_PORTA_AVIAO = 2'b00;
    localparam INSERE_FRAGATA     = 2'b01;
    localparam INSERE_CORVETA     = 2'b10;
    localparam INSERE_SUB         = 2'b11;
//-------------------------------------------------------
    // 2º - Bloco Sequencial
    always @(posedge clk or posedge reset) begin
        if (reset) 
            estado_atual <= INSERE_PORTA_AVIAO;
        else 
            estado_atual <= proximo_estado;
    end
//-------------------------------------------------------
    // 3º - Lógica Próximo estados
    always @(*) begin
        // Valores base:
        reset_contador = 1'b0;
        inc_contador   = 1'b0;
        complete       = 1'b0;
		if(posicionamento_en)begin
        case (estado_atual)
            INSERE_PORTA_AVIAO: begin
                if (count_sig) begin
                    if (casas_navio == 5) begin
                        proximo_estado = INSERE_FRAGATA;
                        reset_contador = 1'b1;
                    end else begin
                        proximo_estado = INSERE_PORTA_AVIAO;
                        inc_contador   = 1'b1;
                    end
                end else begin
                    proximo_estado = INSERE_PORTA_AVIAO;
                end
            end

            INSERE_FRAGATA: begin
                if (count_sig) begin
                    if (casas_navio == 4) begin
                        proximo_estado = INSERE_CORVETA;
                        reset_contador = 1'b1;
                    end else begin
                        proximo_estado = INSERE_FRAGATA;
                        inc_contador   = 1'b1;
                    end
                end else begin
                    proximo_estado = INSERE_FRAGATA;
                end
            end

            INSERE_CORVETA: begin
                if (count_sig) begin
                    if (casas_navio == 3) begin
                        proximo_estado = INSERE_SUB;
                        reset_contador = 1'b1;
                    end else begin
                        proximo_estado = INSERE_CORVETA;
                        inc_contador   = 1'b1;
                    end
                end else begin
                    proximo_estado = INSERE_CORVETA;
                end
            end

            INSERE_SUB: begin
                if (count_sig) begin
                    if (casas_navio == 2) begin
                        proximo_estado = INSERE_PORTA_AVIAO;
                        reset_contador = 1'b1;
                        complete       = 1'b1;
                    end else begin
                        proximo_estado = INSERE_SUB;
                        inc_contador   = 1'b1;
                    end
                end else begin
                    proximo_estado = INSERE_SUB;
                end
            end

            default: begin
                proximo_estado = INSERE_PORTA_AVIAO;
            end
        endcase
    end
	end
//-------------------------------------------------------
    // Lógica das saídas
    contador_navios CONTADOR_UNICO (
        .clk(clk),                       // clock do sistema
        .incremento(inc_contador),       // controlado pela FSM
        .reset(reset_contador || reset), // reset global ou local
        .contagem(casas_navio)           // saída alimenta 'casas_navio'
    );

    assign tipo_navio = estado_atual;
    
endmodule
