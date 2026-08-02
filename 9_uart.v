module UART_Controller ( input clk, rst, gameOver, scoreCalcDone,
/*inputs needed for mid-Game displays -MT*/
input[3:0] currentTurn, playersIn, timeoutPlayers, falseStartPlayers,
input[6:0] p1Total, p2Total, p3Total, p4Total,
input[29:0] p1Time, p2Time, p3Time, p4Time,
input[1:0] p1Place, p2Place, p3Place, p4Place,
/*inputs needed for endgame display -MT*/
input[3:0] winners, input[6:0] winnerScore, input tieExists,
//You know how these inputs work from other modules. -MT
    
    
    output reg tx_start,
    output reg [7:0] tx_data,
    input wire tx_busy
);

    // FSM Durum Kodlamaları
    localparam IDLE = 0;
    localparam CHECK_END_COND = 1;
    localparam TX_NORMAL_TURN = 2;
    localparam TX_GAME_OVER_MSG = 3;
    localparam TX_CHECK_TIE = 4;
    localparam TX_TIE_MSG = 5;
    localparam TX_WINNER_MSG = 6;
    localparam TX_PRINT_SCORE = 7;
    localparam DONE = 8;

    reg [3:0] state;
    reg [3:0] char_index;

    // BCD Çıkışları (İşte senin çözmen gereken kısım burası)
    wire [3:0] yuzler, onlar, birler;
    
    // --- EKSİK PARÇA: BCD CONVERTER ---
    // Binary_to_BCD converter_inst (
    //     .binary_in(winningScore), 
    //     .yuzler(yuzler), 
    //     .onlar(onlar), 
    //     .birler(birler)
    // );

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            tx_start <= 0;
            char_index <= 0;
        end else begin
        if(!gameOver) begin//mid game terminal output -MT
        /*
        The terminal output should be something like this:
        T: [[currentTurn]]
        P1: [[p1Time]] / [[p1Place]]
        P2: [[p2Time]] / [[p2Place]]
        P3: [[p3Time]] / [[p3Place]]
        P4: [[p4Time]] / [[p4Place]]
        TO: [[timeoutPlayers]]
        FS: [[falseStartPlayers]]
        TS:
        1: [[p1Total]]
        2: [[p2Total]]
        3: [[p3Total]]
        4: [[p4Total]]
        
        I have no idea how to do this -MT
        */
            case (state)
                IDLE: begin
                    tx_start <= 0;
                    char_index <= 0;
                    if (scoreCalcDone) state <= CHECK_END_COND;
                end

                CHECK_END_COND: begin
                    // Eleme modunda tek kişi kalırsa veya turlar biterse gameOver 1 olur
                    if (gameOver) state <= TX_GAME_OVER_MSG;
                    else state <= TX_NORMAL_TURN;
                end

                TX_GAME_OVER_MSG: begin
                    // "OYUN BITTI" mesajını yollama rutini
                    // (Buraya ilgili ASCII kodlarını basan bir yapı kurulacak)
                    // ...
                    state <= TX_CHECK_TIE;
                end

                TX_CHECK_TIE: begin
                    if (tieExists) state <= TX_TIE_MSG;
                    else state <= TX_WINNER_MSG;
                    char_index <= 0;
                end

                TX_TIE_MSG: begin
                    // "BERABERLIK!" yazdır.
                    // winners maskesine bakıp berabere kalanları listele.
                    state <= TX_PRINT_SCORE;
                    char_index <= 0;
                end

                TX_WINNER_MSG: begin
                    // "KAZANAN: OYUNCU X" yazdır.
                    state <= TX_PRINT_SCORE;
                    char_index <= 0;
                end

                TX_PRINT_SCORE: begin
                    if (!tx_busy && !tx_start) begin
                        if (char_index == 0) begin
                            tx_data <= 8'h50; // 'P'
                            tx_start <= 1;
                        end else if (char_index == 1) begin
                            tx_data <= 8'h3A; // ':'
                            tx_start <= 1;
                        end else if (char_index == 2) begin
                            tx_data <= yuzler + 8'h30; // Yüzler basamağı
                            tx_start <= 1;
                        end else if (char_index == 3) begin
                            tx_data <= onlar + 8'h30;  // Onlar basamağı
                            tx_start <= 1;
                        end else if (char_index == 4) begin
                            tx_data <= birler + 8'h30; // Birler basamağı
                            tx_start <= 1;
                        end else begin
                            state <= DONE; 
                        end
                    end else begin
                        tx_start <= 0; 
                        if (!tx_busy) char_index <= char_index + 1;
                    end
                end

                TX_NORMAL_TURN: begin
                    // Normal tur verilerini bas (Süreler, cezalar vs.)
                    state <= DONE;
                end

                DONE: begin
                    // Sistem sıfırlanana veya yeni tur başlayana kadar bekle
                    if (!scoreCalcDone) state <= IDLE;
                end
            endcase
            end else begin//endgame terminal output -MT
            if(tieExists) begin //there is a tie -MT
            /*The Terminal output should be something like this -MT
            TIE: [[winners]] / [[winningScore]]
            -MT
            */
            end else begin// there is no tie -MT
            /*The Terminal output should be something like this -MT
            WNR: [[winners]] Since there is no tie, this will only have 1 winner anyways
            -MT
            */
            end
            end
        end
    end
endmodule
