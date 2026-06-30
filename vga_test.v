module vga_test(
    input [5:0] addr,       // Entrada de 6 bits para endereço de memória manual.
    input [1:0] color, mode,// Duas entradas de 2 bits: uma para cor manual e outra para o modo de operação.
    output [3:0] r, g, b,   // Saídas de 4 bits para os canais de cor Vermelho (R), Verde (G) e Azul (B).
    output hs, vs,          // Saídas de 1 bit para sincronismo horizontal (HSync) e vertical (VSync) do VGA.
    input rst, en, clk      // Entradas de 1 bit: Reset (rst), Enable/Habilitação (en) e Clock principal (clk).
);

	reg clk_vga;            // Registrador para armazenar o sinal de clock interno do VGA (frequência dividida).
	reg [5:0] count;        // Registrador de 6 bits usado como contador interno da máquina de estados.
	reg [1:0] state;        // Registrador de 2 bits para armazenar o estado atual da MEF (Máquina de Estados Finitos).
	reg fsm_en;             // Registrador de 1 bit que serve como sinal de habilitação gerado pela MEF.
	
	wire [1:0] t_color;     // Fio (wire) de 2 bits que transportará a cor selecionada (manual ou da MEF).
	wire [3:0] debug_counter;// Fio de 4 bits que armazenará o padrão de cores gerado para o teste.
	wire [5:0] t_addr;      // Fio de 6 bits que transportará o endereço selecionado (manual ou da MEF).
	
	// Bloco sequencial que dispara a cada borda de subida (posedge) do clock principal.
	always @(posedge clk) begin
		clk_vga <= !clk_vga; // Inverte o valor de clk_vga. Isso divide a frequência do clock original por 2.
	end
	
	// Atribuição contínua (combinacional) para gerar o padrão visual de debug.
	// Se mode[1] for 1, subtrai os bits mais significativos dos menos significativos de count.
	// Se mode[1] for 0, apenas extrai os bits [4:3] do count.
	assign debug_counter = mode[1] ? count[1:0] - count[5:3] : count[4:3];
	
	// Bloco sequencial da Máquina de Estados (MEF), ativado na subida do clk_vga ou na descida do rst (Reset ativo em baixo).
	always @(posedge clk_vga or negedge rst) begin
		// fsm
		if (!rst) begin          // Se o botão de reset for pressionado (for igual a 0)...
			state <= 0;          // Força o estado a voltar para zero (2'b00).
			count <= 0;          // Zera o contador interno.
			fsm_en <= 0;         // Desativa o sinal de habilitação da FSM.
		end else 
			begin 
			// Condição de transição do Estado 00 (Espera/IDLE) para o Estado 01.
			// Se o bit de modo 0 estiver ativo, o botão enable externo for zero, e estiver no estado 00...
			if(mode[0] & !en & state == 2'b00) begin
				state <= 2'b01;  // Avança para o estado 01 (Inicialização).
			end
			// Se estiver no Estado 01...
			else if (state == 2'b01) begin
				fsm_en <= 1'b1;  // Ativa o sinal de habilitação interno.
				count <= 6'b0;   // Garante que o contador comece em zero.
				state <= 2'b10;  // Avança para o estado 10 (Contagem/Desenho).
			end
			// Se estiver no Estado 10 e o contador ainda NÃO chegou no valor máximo (63 em decimal)...
			else if (state == 2'b10 & count != 6'b111111) begin
				count <= count + 1; // Incrementa o contador em 1. Ele continua no estado 10.
			end
			// Se estiver no Estado 10 e o contador atingiu o valor máximo (63)...
			else if (state == 2'b10 & count == 6'b111111) begin
				state <= 2'b11;  // Avança para o estado 11 (Fim do ciclo).
				fsm_en <= 1'b0;  // Desativa o sinal de habilitação interno.
				count <= 6'b0;   // Reseta o contador para zero.
			end
			// Se estiver no Estado 11 e o sinal de habilitação externo (en) voltar a ser 1...
			else if (state == 2'b11 & en) begin
				state <= 2'b00;  // Retorna para o estado inicial 00 (IDLE).
			end
		end
	end
	
	// Lógica combinacional (Multiplexadores) para decidir quais dados enviar para a tela:
	
	// Se mode[0] for 1, o enable do VGA vem da FSM (fsm_en). Se for 0, vem do botão externo invertido (!en).
	assign enable = mode[0] ? fsm_en : !en;
	
	// Se a FSM não estiver no estado inicial 00, envia o padrão de debug_counter. Se estiver em 00, envia a cor externa.
	assign t_color = (state != 2'b00) ? debug_counter : color;
	
	// Se a FSM não estiver no estado inicial 00, envia o contador interno como endereço. Se estiver em 00, envia o endereço externo.
	assign t_addr = (state != 2'b00) ? count : addr;
	
	// Instanciação do módulo externo chamado "VGA_interface" com o nome de instância "u1".
	VGA_interface u1(
		clk_vga,    // Conecta o clock dividido no clock do driver VGA.
		!rst,       // Conecta o reset invertido (transformando-o em ativo em alto para o driver).
		enable,     // Conecta o sinal de habilitação escolhido pelo multiplexador.
		t_color,    // Conecta a cor selecionada.
		t_addr,     // Conecta o endereço selecionado.
		vs, hs,     // Conecta as saídas físicas de sincronismo vertical e horizontal.
		r, g, b     // Conecta as saídas físicas de cor (Red, Green, Blue).
	);

endmodule // Fim do módulo vga_test.