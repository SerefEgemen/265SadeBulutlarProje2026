// ============================================================
// lfsr16.v
// 16-bit Fibonacci LFSR (Linear Feedback Shift Register)
//
// Polinom: x^16 + x^14 + x^13 + x^11 + 1  (maximal length, periyot = 2^16 - 1)
// Bu taps kombinasyonu 16 bitlik LFSR icin standart maximal-length
// polinomlardan biridir; deger 0'a asla dusmez cunku all-zero durumu
// bu polinomun dogal periyoduna dahil degildir (seed sifirdan farkli
// oldugu surece).
//
// Kurallar (proje gereksinimi):
//   - Reset sirasinda sifirdan farkli sabit bir seed yuklenir.
//   - LFSR resetten itibaren KESINTISIZ calisir (enable her zaman 1
//     olacak sekilde top modulden baglanmali, tur aralarinda durdurulmaz).
//   - Her turda BTNC pulse'unda o anki deger "snapshot" olarak baska
//     bir modulde (random_delay_gen) okunur; LFSR'nin kendisi asla durmaz.
// ============================================================

module lfsr16 #(
    parameter [15:0] SEED = 16'hACE1   // sifirdan farkli sabit seed
) (
    input  wire        clk,
    input  wire        rst,     // senkron, aktif-yuksek reset
    output reg  [15:0] deger    // her clock'ta guncellenen LFSR degeri
);

    wire feedback;

    // Taps: bit15, bit13, bit12, bit10 (0-indeksli, x^16,x^14,x^13,x^11'e karsilik gelir)
    assign feedback = deger[15] ^ deger[13] ^ deger[12] ^ deger[10];

    always @(posedge clk) begin
        if (rst)
            deger <= SEED;
        else
            deger <= {deger[14:0], feedback};
    end

endmodule
