// ============================================================
// random_delay_gen_tb.v 
// Kontrol: 1) sure_bekleme atanan aralikta mi
//          2) gecerli_bekleme_sure dogru zamanda 1 oluyor mu
//          3) farkli LFSR degerleri farkli sure_bekleme uretiyor mu
// Sonuclari gormek icin: fail_sayi ve distinct_count degiskenlerini
// simulator waveform / Tcl console uzerinden incele.
// ============================================================
`timescale 1ns/1ps

module random_delay_gen_tb;

    reg         clk;
    reg         rst;
    reg         tetiklenme;
    reg         zorluk;
    wire [15:0] lfsr_deger;
    wire [29:0] sure_bekleme;
    wire        gecerli_bekleme_sure;

    integer i;
    integer fail_sayi;
    integer degisim_sayi;
    reg [29:0] son_bekleme_sure;

    lfsr16 #(.SEED(16'hACE1)) lfsr_dut (
        .clk   (clk),
        .rst   (rst),
        .deger (lfsr_deger)
    );

    random_delay_gen dut (
        .clk                  (clk),
        .rst                  (rst),
        .tetiklenme           (tetiklenme),
        .lfsr_deger           (lfsr_deger),
        .zorluk               (zorluk),
        .sure_bekleme         (sure_bekleme),
        .sure_bekleme_gecerli (gecerli_bekleme_sure)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task run_one_round(input diff_mode, input [29:0] min_bound, input [29:0] max_bound);
        begin
            zorluk     = diff_mode;
            tetiklenme = 1'b1;
            @(posedge clk);
            tetiklenme = 1'b0;

            @(posedge clk);
            @(posedge clk);

            if (!gecerli_bekleme_sure || sure_bekleme < min_bound || sure_bekleme > max_bound)
                fail_sayi = fail_sayi + 1;

            if (sure_bekleme !== son_bekleme_sure)
                degisim_sayi = degisim_sayi + 1;
            son_bekleme_sure = sure_bekleme;

            repeat (20) @(posedge clk);
        end
    endtask

    initial begin
        fail_sayi        = 0;
        degisim_sayi   = 0;
        son_bekleme_sure = 30'hFFFFFFFF;
        tetiklenme       = 0;
        zorluk           = 0;

        rst = 1;
        @(posedge clk);
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        for (i = 0; i < 10; i = i + 1)
            run_one_round(1'b0, 30'd200_000_000, 30'd500_000_000);

        for (i = 0; i < 10; i = i + 1)
            run_one_round(1'b1, 30'd50_000_000, 30'd500_000_000);

        $finish;
    end

endmodule