// Autores originais e modificadores do arquivo.
//made by Marcelo Tavares @ 2026

module VGA_interface
(
	input clk_25mhz, reset, write_enable, // Clocks de 25MHz, reset do sistema e habilitação de escrita.
	input [1:0] data, 	// Entrada de 4 bits (embora o registrador use apenas 2) para cor/tipo da embarcação.
	input [5:0] address, // Endereço de 6 bits (0 a 63) para selecionar qual bloco da grade alterar.
	output v_sync, h_sync, // Saídas físicas de sincronismo vertical e horizontal para o monitor.
	output [3:0] R, G, B // Saídas digitais de 4 bits para as cores Vermelho, Verde e Azul.
);

	wire [9:0] x_count, y_count; // Fios que recebem a posição atual do pixel (X e Y) gerada pelo driver.
	reg in_scope, is_edge;       // Registradores combinacionais: indicam se está dentro da grade e se é borda.
	reg [1:0] curr_reg;          // Armazena o valor de 2 bits lido do registrador correspondente ao bloco atual.
	reg [1:0] register [63:0];   // Memória interna (Array) de 64 posições de 2 bits cada (Grade 8x8).
	reg [2:0] x_axis, y_axis;    // Índices de 3 bits para indicar a coluna (0-7) e linha (0-7) do bloco na grade.
	reg [10:0] x_offset;         // Coordenada X corrigida com o deslocamento (offset).
	reg [11:0] color;            // Cor final do pixel atual no formato RGB de 12 bits (4 bits para cada cor).
	
	integer i; // Variável inteira usada como índice do laço 'for'.
	
	// Bloco sequencial para escrita na memória e inicialização (Reset)
	always @(posedge clk_25mhz or posedge reset) begin
		if (reset) begin
			// Se o reset for ativado, limpa todas as 64 posições da memória colocando zero.
			for (i = 0; i < 64; i = i + 1) begin
				register[i] <= 0;
			end
		end
		else begin
			// Se a escrita estiver habilitada, guarda os bits de 'data' no endereço selecionado.
			if (write_enable)
				register[address] <= data[1:0]; // Nota: Guarda apenas os 2 bits menos significativos.
		end
	end
	
	// Bloco combinacional que decide a cor de cada pixel em tempo real com base na varredura da tela
	always @(*) begin	
		// Subtrai 80 de x_count para empurrar a grade 80 pixels para a direita. O {1'b0, ...} evita problemas de sinal.
		x_offset = {1'b0, x_count} - 11'sd80;

		// Verifica se o pixel atual está na borda de um bloco de 60x60 (resto 0 ou 59 na divisão por 60).
		is_edge = (y_count%60 == 0) | (x_offset%60 == 0) | (y_count%60 == 59) | (x_offset%60 == 59);
		
		// Define o limite horizontal da grade: ela só existe enquanto x_offset for menor que 480 (8 blocos * 60 pixels).
		in_scope = (x_offset < 480); 

		// Divide a posição do pixel por 60 para descobrir em qual quadrado (0 a 7) da grade a varredura está passando.
		x_axis = x_offset/60;
		y_axis = y_count/60;
		
		// Concatena y_axis (linha) e x_axis (coluna) para formar o endereço de 6 bits e lê o dado da memória.
		curr_reg = register[{y_axis, x_axis}];

		// Lógica de pintura do pixel:
		if (is_edge & in_scope)
			color = 12'h888; // Se for borda e estiver dentro do limite da grade, pinta de cinza (R=8, G=8, B=8).
		else if (in_scope)
			// Se estiver dentro da grade mas não for borda, olha o valor registrado para aquele bloco:
			case (curr_reg)
				2'b00: color = 12'hF00; // Se for 00, pinta o interior do bloco de Vermelho.
				2'b01: color = 12'h00F; // Se for 01, pinta o interior do bloco de Azul.
				2'b10: color = 12'hFF0; // Se for 10, pinta o interior do bloco de Amarelo.
				2'b11: color = 12'hFFF; // Se for 11, pinta o interior do bloco de Branco.
			endcase
		else
			color = 12'h000; // Se o pixel atual estiver fora da grade (ex: margens), pinta de preto.
	end
		
	// Instanciação do driver VGA padrão. Ele recebe a cor calculada e gera os sinais de vídeo.
	VGA_driver driver(
		clk_25mhz, // Clock de entrada do driver.
		reset,     // Reset do driver.
		color,     // Cor de 12 bits determinada pela nossa lógica acima.
		x_count,   // Saída do driver informando a coluna atual do pixel na tela.
		y_count,   // Saída do driver informando a linha atual do pixel na tela.
		h_sync,    // Saída física de sincronismo horizontal.
		v_sync,    // Saída física de sincronismo vertical.
		R, G, B    // Saídas físicas das cores separadas em canais de 4 bits.
	);
	
endmodule // Fim do módulo VGA_interface