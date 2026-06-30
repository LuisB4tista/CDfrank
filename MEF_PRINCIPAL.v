module MEF_PRINCIPAL(
	input [2:0] coluna,
	input [2:0] linha,
	input clk, rst,
	input push_buttom,
	output [3:0] r, g, b,   
	output hs, vs,
	output [6:0] disp_colunas,
	output [6:0] disp_linhas,
	output [6:0] disp_pontos_d,
	output [6:0] disp_pontos_u
	);

	//----------------------------------------
	// Estados
	reg [1:0] estado_atual;
	reg [1:0] proximo_estado;

	localparam INICIO = 2'b00;
	localparam JOGADA_DE_DEFESA = 2'b01;
	localparam JOGADA_DE_ATAQUE = 2'b10;
	localparam FIM = 2'b11;

	//----------------------------------------
	//Baramentos:
	wire [3:0] dado_leitura;
	wire [1:0] tipo_navio;
	wire complete;
	wire [5:0] endereco_video;
	wire[5:0] pontos_de_vida;
	wire game_over;
	wire rst_vga = !rst;
	//----------------------------------------
	//Registradores:
	reg escrita;
	reg count_en;
	reg count_sig;
	reg [1:0] cor;
	reg [5:0] video_count;
	reg [3:0] dado_escrita;
	reg clk_vga;
	//----------------------------------------


//----------------------------------------
//Divisor de Frequência 25MHz
	always @(posedge clk) begin
		if (!rst)
			clk_vga <= 1'b0;
		else
			clk_vga <= !clk_vga;
	end

//----------------------------------------
// Contador utilizado no estado INICIO.
	always @(posedge clk_vga) begin
		if (!rst)
			video_count <= 6'd0;
		else if (estado_atual == INICIO) begin
			if (video_count == 6'd63)
				video_count <= 6'd0;
			else
				video_count <= video_count + 1'b1;
		end
		else
			video_count <= 6'd0;
	end

// FSM sequencial — síncrona a clk_vga, reset síncrono ativo-baixo
	always @(posedge clk_vga) begin
		if (!rst)
			estado_atual <= INICIO;
		else
			estado_atual <= proximo_estado;
	end

//----------------------------------------
// Lógica combinacional
	always @(*) begin

		// defaults
		dado_escrita   = 4'b0000;
		escrita        = 1'b0;
		count_en 	   = 1'b0;
		count_sig      = 1'b0;
		proximo_estado = estado_atual;
		cor = 2'b00;

		case (estado_atual)

			INICIO: begin
				escrita = 1'b1;

				cor = 2'b01; // Azul          
				dado_escrita = {cor, 2'b00}; // Matriz também azul

				if (video_count == 6'd63)
					proximo_estado = JOGADA_DE_DEFESA;
				else
					proximo_estado = INICIO;
				end
				
			JOGADA_DE_DEFESA: begin
				if (!push_buttom && complete != 1'b1) begin

					if (dado_leitura > 4'b1011) begin
						proximo_estado = JOGADA_DE_DEFESA;
					end else if (dado_leitura > 4'b0011 && dado_leitura < 4'b1000) begin
						escrita = 1'b1;
						dado_escrita = {2'b11, tipo_navio};
						end
              end 
				  else begin
                    proximo_estado = JOGADA_DE_ATAQUE;
              end
         end

         JOGADA_DE_ATAQUE: begin
				if (push_buttom && !game_over) begin
					if ((dado_leitura < 4'b0100) || (dado_leitura > 4'b0111 && dado_leitura < 4'b1100)) begin//Vermelho ou amarelo== jogador atirou onde já havia atirado
						proximo_estado = JOGADA_DE_ATAQUE;
					end else if (dado_leitura > 4'b0011 && dado_leitura < 4'b1000) begin//Azul == Jogador errou o tiro
						proximo_estado = JOGADA_DE_ATAQUE;
						escrita = 1'b1;
						count_en = 1'b1;
						cor = 2'b10;
						dado_escrita = {cor, dado_leitura[1:0]}; // Amarelo       
						count_sig = 1'b0;//Sinal para subtrair
					end else if (dado_leitura > 4'b1011) begin //Branco == Jogador acertou um navio
						proximo_estado = JOGADA_DE_ATAQUE;
						escrita = 1'b1;
						count_en = 1'b1;
						cor = 2'b00;
						dado_escrita = {cor, dado_leitura[1:0]}; // Vermelho
						count_sig = 1'b1;//Sinal para Somar
					end
				end
				else if (game_over) begin
					proximo_estado = FIM;
				end
			end

         FIM: begin
              escrita = 1'b0;
              count_en = 1'b0;
              count_sig = 1'b0;
              proximo_estado = FIM;
         end
         
         default: proximo_estado = INICIO;

         endcase
    end
	 assign endereco_video = (estado_atual == 2'b00) ? video_count :{linha, coluna};
	 
//---------------------------------------------------
//INSTÂNCIAS
// Todos os submódulos agora recebem clk_vga, mantendo um único domínio
// de clock em todo o projeto (evita reabrir bugs de cruzamento de clock).
			MEF_posicionamento jogada_de_defesa(
			 .count_sig(push_buttom),
			 .clk(clk_vga),
			 .reset(rst),
			 .tipo_navio(tipo_navio),
			 .complete(complete)
		);

			Matriz_registradores matriz(

				 .dado_in(dado_escrita),

				 .clk(clk_vga),
				 .rst(rst),

				 .escrita(escrita),

				 .linha_jogo(linha),
				 .coluna_jogo(coluna),

				 .dado_jogo(dado_leitura)

			);
		
		Pontos Total(
			 .clk(clk_vga),
			 .rst(rst),
			 .enable(count_en),
			 .tipo_navio(dado_escrita[1:0]),
			 .erro_ou_acerto(count_sig),
			 .count_total(pontos_de_vida),
			 .game_over(game_over)
		);

//---------------------------------------------------

	// Instância VGA
		VGA_interface u1(
			 .clk_25mhz(clk_vga),
			 .reset(rst_vga),
			 .write_enable(escrita),
			 .data(cor),
			 .address(endereco_video),
			 .v_sync(vs),
			 .h_sync(hs),
			 .R(r),
			 .G(g),
			 .B(b)
		);
//----------------------------------------
	//Decoder dos Displays:
		Decoder_Letras Linhas(
			.chaves(linha),
			.display(disp_linhas)
			);
			
		Decoder_Numeros Colunas(
			.chaves(coluna),
			.display(disp_colunas)
			);
		Decoder_Pontuacao (
			.numero(pontos_de_vida),       
			.display_dez(disp_pontos_d), 
			.display_uni(disp_pontos_u)  
);
	endmodule
