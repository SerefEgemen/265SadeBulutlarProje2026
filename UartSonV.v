`timescale 1ns / 1ps

module UART_Controller ( input clk, rst, gameOver, scoreCalcDone, tx_free,
/*inputs needed for mid-Game displays -MT*/
input[3:0] currentTurn, playersIn, timeoutPlayers, falseStartPlayers,
input[6:0] p1Total, p2Total, p3Total, p4Total,
input[29:0] p1Time, p2Time, p3Time, p4Time,
input[1:0] p1Place, p2Place, p3Place, p4Place,
/*inputs needed for endgame display -MT*/
input[3:0] winners, input[6:0] winnerScore, input tieExists,

    output reg tx_start,
    output reg [7:0] tx_data
);

// ================== Sabit mesajlar (ASCII karakter dizileri) ==================
reg [7:0] oyunBittiMsg [0:11];
reg [7:0] berabereMsg  [0:12];
reg [7:0] kazananMsg   [0:14];
reg [7:0] tieMsg       [0:4];   // "TIE: "
reg [7:0] wnrMsg       [0:4];   // "WNR: "

initial begin
    // "OYUN BITTI\r\n"
    oyunBittiMsg[0]=8'h4F; oyunBittiMsg[1]=8'h59; oyunBittiMsg[2]=8'h55;
    oyunBittiMsg[3]=8'h4E; oyunBittiMsg[4]=8'h20; oyunBittiMsg[5]=8'h42;
    oyunBittiMsg[6]=8'h49; oyunBittiMsg[7]=8'h54; oyunBittiMsg[8]=8'h54;
    oyunBittiMsg[9]=8'h49; oyunBittiMsg[10]=8'h0D;oyunBittiMsg[11]=8'h0A;

    // "BERABERLIK!\r\n"
    berabereMsg [0]=8'h42; berabereMsg [1]=8'h45; berabereMsg [2]=8'h52; berabereMsg [3]=8'h41;
    berabereMsg [4]=8'h42; berabereMsg [5]=8'h45; berabereMsg [6]=8'h52; berabereMsg [7]=8'h4C;
    berabereMsg [8]=8'h49; berabereMsg [9]=8'h4B; berabereMsg [10]=8'h21;
    berabereMsg [11]=8'h0D;berabereMsg [12]=8'h0A;

    // "KAZANAN VAR\r\n"
    kazananMsg[0]=8'h4B; kazananMsg[1]=8'h41; kazananMsg[2]=8'h5A; kazananMsg[3]=8'h41;
    kazananMsg[4]=8'h4E; kazananMsg[5]=8'h41; kazananMsg[6]=8'h4E; kazananMsg[7]=8'h20;
    kazananMsg[8]=8'h56; kazananMsg[9]=8'h41; kazananMsg[10]=8'h52;
    kazananMsg[11]=8'h0D;kazananMsg[12]=8'h0A;

    // "TIE: "
    tieMsg[0]=8'h54; tieMsg[1]=8'h49; tieMsg[2]=8'h45; tieMsg[3]=8'h3A; tieMsg[4]=8'h20;

    // "WNR: "
    wnrMsg[0]=8'h57; wnrMsg[1]=8'h4E; wnrMsg[2]=8'h52; wnrMsg[3]=8'h3A; wnrMsg[4]=8'h20;
end

// ================== FSM durum kodlamalarý (mid-game) ==================
localparam IDLE            = 0;
localparam CHECK_END_COND  = 1;
localparam TX_NORMAL_TURN  = 2;
localparam TX_GAME_OVER_MSG= 3;
localparam TX_CHECK_TIE    = 4;
localparam TX_TIE_MSG      = 5;
localparam TX_WINNER_MSG   = 6;
localparam TX_PRINT_SCORE  = 7;
localparam DONE            = 8;

reg [3:0] state;
reg [3:0] char_index;

// ================== FSM durum kodlamalarý (endgame) ==================
localparam EG_IDLE        = 0;
localparam EG_CHECK_TIE   = 1;
localparam EG_TX_TIE_MSG  = 2;
localparam EG_TX_WNR_MSG  = 3;
localparam EG_TX_WINNERS  = 4;
localparam EG_TX_SCORE    = 5;
localparam EG_DONE        = 6;

reg [3:0] eg_state;
reg [3:0] eg_char_index;
reg [1:0] player_index; // hangi oyuncu bitini yazdýðýmýzý takip eder (0-3)

// ================== BCD Converter ==================
wire [3:0]  onlar, birler;
reg  [3:0] yuzler; // skor max 64 olduðundan yüzler hanesi hep 0

Binary_to_BCD bcd1 (
    .binary_in(winnerScore),
    .onlar(onlar),
    .birler(birler)
);

always @(*) begin
    yuzler = 4'd0; // BCD modülü yüzler hanesi çýkýþý vermediði için sabit
end

// ================== Zaman -> ASCII fonksiyonu (modül seviyesinde) ==================
// p1Time (30 bit cycle sayýsý) -> "a.bc" ASCII, 4 byte döndürür
// {saniye_ascii, nokta_ascii, onlar_santisaniye_ascii, birler_santisaniye_ascii}
function [31:0] time_to_ascii;
    input [29:0] cycles;
    reg [29:0] kalan;
    reg [3:0]  saniye;
    reg [6:0]  santisaniye; // 0-99 arasi

    begin
        saniye      = cycles / 30'd100_000_000;   // 100_000_000 cycle = 1 saniye (100MHz varsayimiyla)
        kalan       = cycles % 30'd100_000_000;
        santisaniye = kalan / 30'd1_000_000;       // 1_000_000 cycle = 1 santisaniye (yani 0.01 sn)

        time_to_ascii = { 8'h30 + saniye[3:0],              // 'a'
                           8'h2E,                            // '.'
                           8'h30 + (santisaniye / 4'd10),    // 'b' (onlar hanesi)
                           8'h30 + (santisaniye % 4'd10) };  // 'c' (birler hanesi)
    end
endfunction

// ================== Ana FSM ==================
always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        tx_start <= 0;
        char_index <= 0;
        eg_state <= EG_IDLE;
        eg_char_index <= 0;
        player_index <= 0;
    end else begin

        if (!gameOver) begin //mid game terminal output -MT
            case (state)
                IDLE: begin
                    tx_start <= 0;
                    char_index <= 0;
                    if (scoreCalcDone) state <= CHECK_END_COND;
                end

                CHECK_END_COND: begin
                    // Eleme modunda tek kisi kalirsa veya turlar biterse gameOver 1 olur
                    if (gameOver) state <= TX_GAME_OVER_MSG;
                    else state <= TX_NORMAL_TURN;
                end

                TX_GAME_OVER_MSG: begin
                    if (tx_free && !tx_start) begin
                        if (char_index < 12) begin
                            tx_data <= oyunBittiMsg[char_index];
                            tx_start <= 1;
                        end else begin
                            char_index <= 0;
                            state <= TX_CHECK_TIE;
                        end
                    end else begin
                        tx_start <= 0;
                        if (tx_free) char_index <= char_index + 1;
                    end
                end

                TX_CHECK_TIE: begin
                    if (tieExists) state <= TX_TIE_MSG;
                    else state <= TX_WINNER_MSG;
                    char_index <= 0;
                end

                TX_TIE_MSG: begin
                    if (tx_free && !tx_start) begin
                        if (char_index < 13) begin
                            tx_data <= berabereMsg[char_index];
                            tx_start <= 1;
                        end else begin
                            char_index <= 0;
                            state <= TX_PRINT_SCORE;
                        end
                    end else begin
                        tx_start <= 0;
                        if (tx_free) char_index <= char_index + 1;
                    end
                end

                TX_WINNER_MSG: begin
                    if (tx_free && !tx_start) begin
                        if (char_index < 13) begin
                            tx_data <= kazananMsg[char_index];
                            tx_start <= 1;
                        end else begin
                            char_index <= 0;
                            state <= TX_PRINT_SCORE;
                        end
                    end else begin
                        tx_start <= 0;
                        if (tx_free) char_index <= char_index + 1;
                    end
                end

                TX_PRINT_SCORE: begin
                    if (tx_free && !tx_start) begin
                        if (char_index == 0) begin
                            tx_data <= 8'h50; // 'P'
                            tx_start <= 1;
                        end else if (char_index == 1) begin
                            tx_data <= 8'h3A; // ':'
                            tx_start <= 1;
                        end else if (char_index == 2) begin
                            tx_data <= yuzler + 8'h30; // Yüzler basamagý
                            tx_start <= 1;
                        end else if (char_index == 3) begin
                            tx_data <= onlar + 8'h30;  // Onlar basamagý
                            tx_start <= 1;
                        end else if (char_index == 4) begin
                            tx_data <= birler + 8'h30; // Birler basamagý
                            tx_start <= 1;
                        end else begin
                            state <= DONE;
                        end
                    end else begin
                        tx_start <= 0;
                        if (tx_free) char_index <= char_index + 1;
                    end
                end

                TX_NORMAL_TURN: begin
                    // Normal tur verilerini bas (Süreler, cezalar vs.)
                    // time_to_ascii fonksiyonu burada p1Time..p4Time için kullanilabilir
                    state <= DONE;
                end

                DONE: begin
                    // Sistem sifirlanana veya yeni tur baslayana kadar bekle
                    if (!scoreCalcDone) state <= IDLE;
                end

                default: state <= IDLE;
            endcase

        end else begin //endgame terminal output -MT
            case (eg_state)
                EG_IDLE: begin
                    eg_char_index <= 0;
                    player_index  <= 0;
                    if (scoreCalcDone) eg_state <= EG_CHECK_TIE;
                end

                EG_CHECK_TIE: begin
                    eg_char_index <= 0;
                    player_index  <= 0;
                    if (tieExists) eg_state <= EG_TX_TIE_MSG;
                    else            eg_state <= EG_TX_WNR_MSG;
                end

                // "TIE: " yazdýr
                EG_TX_TIE_MSG: begin
                    if (tx_free && !tx_start) begin
                        if (eg_char_index < 5) begin
                            tx_data  <= tieMsg[eg_char_index];
                            tx_start <= 1;
                        end else begin
                            eg_char_index <= 0;
                            player_index  <= 0;
                            eg_state <= EG_TX_WINNERS;
                        end
                    end else begin
                        tx_start <= 0;
                        if (tx_free) eg_char_index <= eg_char_index + 1;
                    end
                end

                // "WNR: " yazdýr
                EG_TX_WNR_MSG: begin
                    if (tx_free && !tx_start) begin
                        if (eg_char_index < 5) begin
                            tx_data  <= wnrMsg[eg_char_index];
                            tx_start <= 1;
                        end else begin
                            eg_char_index <= 0;
                            player_index  <= 0;
                            eg_state <= EG_TX_WINNERS;
                        end
                    end else begin
                        tx_start <= 0;
                        if (tx_free) eg_char_index <= eg_char_index + 1;
                    end
                end

                // winners[3:0] içindeki kazanan oyuncu numaralarýný yazdýr (ör: "1 3 " gibi)
                // Kazanmayan oyuncular tx_free beklemeden, ayný cycle'da atlanýr.
                EG_TX_WINNERS: begin
                    if (player_index < 4) begin
                        if (winners[player_index]) begin
                            if (tx_free && !tx_start) begin
                                tx_data      <= 8'h31 + player_index; // '1','2','3','4'
                                tx_start     <= 1;
                                player_index <= player_index + 1;
                            end else begin
                                tx_start <= 0; // tx_free gelene kadar bekle
                            end
                        end else begin
                            // bu oyuncu kazanmadý, hemen bir sonrakine geç
                            player_index <= player_index + 1;
                        end
                    end else begin
                        eg_state <= EG_TX_SCORE;
                    end
                end

                // " / " + skor (onlar/birler basamaðý, bcd1'den geliyor) + \r\n
                EG_TX_SCORE: begin
                    if (tx_free && !tx_start) begin
                        if (eg_char_index == 0) begin
                            tx_data <= 8'h2F; tx_start <= 1; 
                        end else if (eg_char_index == 1) begin
                            tx_data <= 8'h20; tx_start <= 1; 
                        end else if (eg_char_index == 2) begin
                            tx_data <= onlar + 8'h30; tx_start <= 1;
                        end else if (eg_char_index == 3) begin
                            tx_data <= birler + 8'h30; tx_start <= 1;
                        end else if (eg_char_index == 4) begin
                            tx_data <= 8'h0D; tx_start <= 1; 
                        end else if (eg_char_index == 5) begin
                            tx_data <= 8'h0A; tx_start <= 1; 
                        end else begin
                            eg_state <= EG_DONE;
                        end
                    end else begin
                        tx_start <= 0;
                        if (tx_free) eg_char_index <= eg_char_index + 1;
                    end
                end

                EG_DONE: begin
                    // Sistem sýfýrlanana veya yeni oyun baslayana kadar bekle
                    if (!scoreCalcDone) eg_state <= EG_IDLE;
                end

                default: eg_state <= EG_IDLE;
            endcase
        end
    end
end

endmodule





























/*
                ;'-. 
    `;-._        )  '---.._
      >  `-.__.-'          `'.__
     /_.-'-._         _,   ^ ---)
     `       `'------/_.'----```
                     `
*/
