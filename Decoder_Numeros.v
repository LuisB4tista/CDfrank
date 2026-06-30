module Decoder_Numeros(
    input [2:0] chaves,
    output reg [6:0] display 
);

always @(*) begin
	case (chaves)
		 3'b000: display = 7'b1000000; //0
		 3'b001: display = 7'b1111001; //1
		 3'b010: display = 7'b0100100; //2
		 3'b011: display = 7'b0110000; //3
		 3'b100: display = 7'b0011001; //4
		 3'b101: display = 7'b0010010; //5
		 3'b110: display = 7'b0000010; //6
		 3'b111: display = 7'b1111000; //7
		 default: display = 7'b1111111; //Desligado
endcase

end

endmodule
