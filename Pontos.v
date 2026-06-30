module Pontos(
	input clk, rst,
	input enable,
	input [1:0] tipo_navio,
	input erro_ou_acerto,
	output reg [5:0]count_total,
	output reg game_over
);

	// Contadores de navios
	reg [2:0] count_porta_avioes;
	reg [2:0] count_fragata;
	reg [2:0] count_corverta;
	reg [2:0] count_sub;

	wire win_condition;
	assign win_condition = (count_porta_avioes == 5 &&
	                        count_fragata == 4 &&
	                        count_corverta == 3 &&
	                        count_sub == 2);

	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			count_total <= 6'd10;
			count_porta_avioes <= 0;
			count_fragata <= 0;
			count_corverta <= 0;
			count_sub <= 0;
			game_over <= 0;
		end 
		else if (!game_over && enable) begin

			// ERRO -> perde ponto
			if (erro_ou_acerto == 0) begin
				if (count_total > 0)
					count_total <= count_total - 1;
			end

			// ACERTO -> soma ponto e atualiza navio
			else begin
				count_total <= count_total + 1;

				case (tipo_navio)
					2'b00: count_porta_avioes <= count_porta_avioes + 1;
					2'b01: count_fragata     <= count_fragata + 1;
					2'b10: count_corverta    <= count_corverta + 1;
					2'b11: count_sub         <= count_sub + 1;
				endcase

				// bônus por tipo de navio (baseado no valor ATUAL)
				if (count_porta_avioes == 4) count_total <= count_total + 8;
				else if (count_fragata == 3) count_total <= count_total + 6;
				else if (count_corverta == 2) count_total <= count_total + 4;
				else if (count_sub == 1) count_total <= count_total + 10;
			end

			// vitória tem prioridade lógica
			if (win_condition)
				game_over <= 1'b1;

			// derrota
			if (count_total == 0 && erro_ou_acerto == 0)
				game_over <= 1'b1;

		end
	end

endmodule