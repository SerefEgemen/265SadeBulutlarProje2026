// ============================================================
// random_delay_gen.v
// LFSR'den gelen 16-bit degeri, zorluk moduna gore belirlenen
// zaman araligina (clock cycle sayisina) esler.
//
// Kolay mod : 2.0s - 5.0s  -> 200_000_000 - 500_000_000 cycle (100 MHz)
// Zor  mod  : 0.5s - 5.0s  ->  50_000_000 - 500_000_000 cycle (100 MHz)
//
// Calisma mantigi:
//   1) 'trigger' pulse geldiginde (BTNC ile tur basladiginda) o anki
//      lfsr_value bir registera "snapshot" olarak alinir.
//   2) span degeri ile carpilip >>16 yapilarak 0-span araligina olceklenir
//      (scaled_offset = (lfsr_snapshot * span) >> 16).
//   3) min_cycles eklenerek nihai wait_cycles degeri elde edilir.
//   4) 2 clock'luk kisa bir "hesapla" pipeline'i kullanilir (carpma islemi
//      tek cycle'da guvenli bitmeyebilir), sonuc valid oldugunda
//      'wait_cycles_valid' 1 olur.
//
// NOT: Bu modul LFSR'yi durdurmaz / resetlemez; sadece disaridan gelen
// lfsr_value girisini anlik olarak okur (LFSR ayri modulde surekli calisir).
// ============================================================

module random_delay_gen (
    input  wire        clk,
    input  wire        rst,
    input  wire        tetiklenme,       // BTNC pulse (tek cycle'lik)
    input  wire        turnOver,
    input  wire [15:0] lfsr_deger,    // lfsr16 modulunden gelen anlik deger
    input  wire        zorluk,    // 0 = kolay, 1 = zor
    output reg  [29:0] sure_bekleme,   // hesaplanan bekleme suresi (cycle)
    output reg         sure_bekleme_gecerli 
);

    // Zorluk moduna gore sinir degerleri (100 MHz clock varsayimiyla)
    localparam [29:0] KOLAY_MIN  = 30'd200_000_000; // 2.0 s
    localparam [29:0] KOLAY_ARA = 30'd300_000_000; // 5.0s - 2.0s
    localparam [29:0] ZOR_MIN  = 30'd50_000_000;  // 0.5 s
    localparam [29:0] ZOR_ARA = 30'd450_000_000; // 5.0s - 0.5s

    reg [15:0] lfsr_anlik;
    reg [29:0] min_sure;
    reg [29:0] ara;
    reg [45:0] asil_sonuc;   // 16 bit * 30 bit = 46 bit genislik
    reg        asama1_gecerli, asama2_gecerli;
    
    reg tetik;

    // Zorluk secimine gore min/span degerlerini belirle (kombinasyonel)
    always @(*) begin
        if (zorluk == 1'b0) begin
            min_sure = KOLAY_MIN;
            ara      = KOLAY_ARA;
        end else begin
            min_sure = ZOR_MIN;
            ara      = ZOR_ARA;
        end
    end

    // 3 asamali pipeline: anlik -> carpma -> toplama
    always @(posedge clk) begin
        if (rst) begin
            lfsr_anlik     <= 16'd0;
            asil_sonuc       <= 46'd0;
            sure_bekleme       <= 30'd0;
            asama1_gecerli      <= 1'b0;
            asama2_gecerli      <= 1'b0;
            sure_bekleme_gecerli <= 1'b0;
        end else begin
            // Stage 0 -> 1: trigger geldiginde LFSR'yi yakala ve carpmayi baslat
            if(tetiklenme) begin
            tetik <= 1'b1;
            end else if(turnOver)begin
            tetik <= 1'b0;
            end
            if (tetik) begin
                lfsr_anlik <= lfsr_deger;
                asil_sonuc   <= lfsr_deger * ara;   // span, ayni cycle'daki (*) kombinasyonel degeri
                asama1_gecerli  <= 1'b1;
            end else begin
                asama1_gecerli  <= 1'b0;
            end

            // Stage 1 -> 2: carpma sonucunu olcekle (>>16) ve min_cycles ekle
            if (asama1_gecerli) begin
                sure_bekleme  <= min_sure + (asil_sonuc >> 16);
                asama2_gecerli <= 1'b1;
            end else begin
                asama2_gecerli <= 1'b0;
            end

            // Stage 2 -> cikis gecerli
            sure_bekleme_gecerli  <= asama2_gecerli;
        end
    end

endmodule








/*
RNG, Balatro, or something idk I'm exhausted
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░░░▓▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░░░░░▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░▓▓░░▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░░▓▓▓▒░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░░░▓▓▒░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░▓▓░░░▓▒░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░▓▓░░░▓▒░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓░░░░▓░░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░░▓▓░▓▒░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓░░░░▓░░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░░▓▓░░▓▒░░░░░░░▓▓▓▓▓▓░▓▓▓▓▓▓▓▓▓▓▓▓▓▓░▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░ 
 ░░░░░░▓▓▒▒░░░░░░▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░░ 
 ░░░░░░▓▓▒▒▒░░░░▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░ 
 ░░░░░▒▓▓░░▓▒░░░▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▒▒▒▒░░░░░░░░░░░░░░░ 
 ░░░░░░░░░░░░░░▓▒▒▒▓▒░▒▒▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▒▒░▒▓▒▒▒▓░░░░░░░░░░░░░░ 
 ░░░░░░▓▓░░▓░░░▒▒▒▓░░░░▓▒▓▓▓▓▒▒▒░░░░▒▒▒▓▓▓▓▒▓░░░░▓▒▒▒░░░░░░░░░░░░░░ 
 ░░░░░░▓▓▓▓▒░░▒░░░░▓░░░▓▓▓▓▓░░░░░░░░░░░░▓▓▓▓▓░░░▓░░░░▓░░░░░░░░░░░░░ 
 ░░░░░░▓▓░░░░░░▓░░▓░░░▓▓▓▓▒▒▒▒▒▒░░░░▒▒▒▒▒▒▓▓▓▓░░░▓░░▓░░░░░░░░░░░░░░ 
 ░░░░░▓▓▓▓▓▓▒░░░░░░░░░▓▓▓░░▒░▓▓░▒░░░░▒▓░▒░░▓▓▓░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░▓▓▓▓▓▒░░░░░░░░░░░▓▓░░░░░░░░░░░░░░░░░░▓▓░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░░▓▓░░▒▒░░░░░░░░░▓░░░▓░░░░░░░░░░░░░░▓░░░▓░░░░░░░░░░▓▒░▒▓░░░░░░ 
 ░░░░░░▓▓▓▓▒░░░░░░░░░░▓░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░▓░░░░░░░░░░▒▓▓▓▓░░░░░░ 
 ░░░░░░▓▓░░▓▒░░░░░░░░░░░▓░░░▓▓▒░░░░░░▒▓▓░░░▓░░░░░░░░░░░░▒░░▒▓░░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░░░░▓░░░▓▓▓▓▓▓▓▓▓▓░░░▓░░░░░░░░░░░░░▒▓▓▓▓▓░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░░▓▓▓░░░░░░▓▓▓▓░░░░░░▓▓▓▓░░░░░░░░░░▓▓▓▓▓▓░░░░░ 
 ░░░░░░░░░░░░░░░░░▓▓▒▒▒▒▒▒▒▒░░░░░░░░░░░░▒▒▒▒▒▒▒▒▓▓░░░░░░░░░▒▓░░░░░░ 
 ░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒░░░▒▒▒▒░░░▒▒▒▒▒░░▒░▒▒▒▒▒▒▒▒░░░░▓▓▓▓░░░░░░ 
 ░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▓░░▒░░▒▓░░░░░░ 
 ░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒░▒▒▒▒▒▒░░░░░░░░░░░░ 
 ░░░░░░░░░░░░▒▒▒▒▒▒▒▒░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░▓▒░▓▓▒░░░░░ 
 ░░░░░░░░░░░░▒▓▒▒▒▒▓▓▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▓▒░░▒▒░▓▓░░░░░░ 
 ░░░░░░░░░░░░▒▓▓▓▓▒░░░▓▒▒▒▒▒▒▒▒▓▒░░▒▓▒▒▒▒▒▒▒▒▓░░░▒▓▓▓▓░░░▒▓▓▓░░░░░░ 
 ░░░░░░░░░░░░▒▓▓▓▓░░░░▓▒▒▒▒▒▒▒▓▒░░░░▒▓▒▒▒▒▒▒▒▓░░░░▓▓▓▒░▒▓▒░▒▓░░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░▓▒▒▒▒▒▒▓░░░░░░░░▓▒▒▒▒▒▒▓░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░▓▓▓▒▒▓░░░░░░░░░░░░▓▓▒▓▓▓░░░░░░░░░░▒▓░▒▓░░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓░░░░░░░░░░░░░░▓▓▓▓▓░░░░░░░░░░▓▒░░▓▓░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▒░░▓▓░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓░░░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓▓▓░░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓░░▓▓░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▓░░░░░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓░░░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 
 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 
  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  
    ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    


*/
