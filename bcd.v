module Binary_to_BCD (
    input  [6:0] binary_in,
    output reg [3:0] onlar,
    output reg [3:0] birler
);
    reg [6:0] gecici;
    always @(*) begin
        gecici = binary_in;
        onlar = gecici / 10;
        birler = gecici % 10;
    end
endmodule