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
    input  wire        trigger,       // BTNC pulse (tek cycle'lik)
    input  wire [15:0] lfsr_value,    // lfsr16 modulunden gelen anlik deger
    input  wire        difficulty,    // 0 = kolay, 1 = zor
    output reg  [29:0] wait_cycles,   // hesaplanan bekleme suresi (cycle)
    output reg         wait_cycles_valid
);

    // Zorluk moduna gore sinir degerleri (100 MHz clock varsayimiyla)
    localparam [29:0] EASY_MIN  = 30'd200_000_000; // 2.0 s
    localparam [29:0] EASY_ARA = 30'd300_000_000; // 5.0s - 2.0s
    localparam [29:0] HARD_MIN  = 30'd50_000_000;  // 0.5 s
    localparam [29:0] HARD_ARA = 30'd450_000_000; // 5.0s - 0.5s

    reg [15:0] lfsr_anlik;
    reg [29:0] min_cycles;
    reg [29:0] ara;
    reg [45:0] asil_result;   // 16 bit * 30 bit = 46 bit genislik
    reg        stage1_valid, stage2_valid;

    // Zorluk secimine gore min/span degerlerini belirle (kombinasyonel)
    always @(*) begin
        if (difficulty == 1'b0) begin
            min_cycles = EASY_MIN;
            span       = EASY_ARA;
        end else begin
            min_cycles = HARD_MIN;
            span       = HARD_ARA;
        end
    end

    // 3 asamali pipeline: anlik -> carpma -> toplama
    always @(posedge clk) begin
        if (rst) begin
            lfsr_anlik     <= 16'd0;
            mult_result       <= 46'd0;
            wait_cycles       <= 30'd0;
            stage1_valid      <= 1'b0;
            stage2_valid      <= 1'b0;
            wait_cycles_valid <= 1'b0;
        end else begin
            // Stage 0 -> 1: trigger geldiginde LFSR'yi yakala ve carpmayi baslat
            if (trigger) begin
                lfsr_anlik <= lfsr_value;
                asil_result   <= lfsr_value * span;   // span, ayni cycle'daki (*) kombinasyonel degeri
                stage1_valid  <= 1'b1;
            end else begin
                stage1_valid  <= 1'b0;
            end

            // Stage 1 -> 2: carpma sonucunu olcekle (>>16) ve min_cycles ekle
            if (stage1_valid) begin
                wait_cycles  <= min_cycles + (mult_result >> 16);
                stage2_valid <= 1'b1;
            end else begin
                stage2_valid <= 1'b0;
            end

            // Stage 2 -> cikis gecerli
            wait_cycles_valid <= stage2_valid;
        end
    end

endmodule
