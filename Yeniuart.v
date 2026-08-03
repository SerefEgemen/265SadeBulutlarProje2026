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
// Sabit mesajlar (ASCII karakter dizileri)
reg [7:0] oyunBittiMsg [0:11];
reg [7:0] berabereMsg      [0:12];
reg [7:0] kazananMsg   [0:14];

initial begin
    // "OYUN BITTI\r\n yaziyor"
    oyunBittiMsg[0]=8'h4F; oyunBittiMsg[1]=8'h59; oyunBittiMsg[2]=8'h55;
    oyunBittiMsg[3]=8'h4E; oyunBittiMsg[4]=8'h20; oyunBittiMsg[5]=8'h42;
    oyunBittiMsg[6]=8'h49; oyunBittiMsg[7]=8'h54; oyunBittiMsg[8]=8'h54;
    oyunBittiMsg[9]=8'h49; oyunBittiMsg[10]=8'h0D;oyunBittiMsg[11]=8'h0A;

    // "BERABERLIK!\r\n yaziyor"
    berabereMsg [0]=8'h42; berabereMsg [1]=8'h45; berabereMsg [2]=8'h52; berabereMsg [3]=8'h41;
    berabereMsg [4]=8'h42; berabereMsg [5]=8'h45; berabereMsg [6]=8'h52; berabereMsg [7]=8'h4C;
    berabereMsg [8]=8'h49; berabereMsg [9]=8'h4B; berabereMsg [10]=8'h21;
    berabereMsg [11]=8'h0D;berabereMsg [12]=8'h0A;

    // "KAZANAN VAR\r\n yaziyor"
    kazananMsg[0]=8'h4B; kazananMsg[1]=8'h41; kazananMsg[2]=8'h5A; kazananMsg[3]=8'h41;
    kazananMsg[4]=8'h4E; kazananMsg[5]=8'h41; kazananMsg[6]=8'h4E; kazananMsg[7]=8'h20;
    kazananMsg[8]=8'h56; kazananMsg[9]=8'h41; kazananMsg[10]=8'h52;
    kazananMsg[11]=8'h0D;kazananMsg[12]=8'h0A;
end
    // FSM Durum Kodlamalarý
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

    
    
   
    // --- EKSÝK PARÇA: BCD CONVERTER ---
    wire [3:0]  onlar, birler,yuzler;

Binary_to_BCD bcd1 (
    .binary_in(winnerScore),
    .onlar(onlar),
    .birler(birler)
);
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
                    // Eleme modunda tek kiþi kalýrsa veya turlar biterse gameOver 1 olur
                    if (gameOver) state <= TX_GAME_OVER_MSG;
                    else state <= TX_NORMAL_TURN;
                end




               TX_GAME_OVER_MSG: begin
    if (!tx_busy && !tx_start) begin
        if (char_index < 12) begin
            tx_data <= oyunBittiMsg[char_index];
            tx_start <= 1;
        end else begin
            char_index <= 0; 
            state <= TX_CHECK_TIE;
        end
    end else begin
        tx_start <= 0;
        if (!tx_busy) char_index <= char_index + 1;
    end
end





                TX_CHECK_TIE: begin
                    if (tieExists) state <= TX_TIE_MSG;
                    else state <= TX_WINNER_MSG;
                    char_index <= 0;
                end






              TX_TIE_MSG: begin
    if (!tx_busy && !tx_start) begin
        if (char_index < 13) begin
            tx_data <= berabereMsg[char_index];
            tx_start <= 1;
        end else begin
            char_index <= 0;
            state <= TX_PRINT_SCORE;
        end
    end else begin
        tx_start <= 0;
        if (!tx_busy) char_index <= char_index + 1;
    end
end






                TX_WINNER_MSG: begin
    if (!tx_busy && !tx_start) begin
        if (char_index < 13) begin
            tx_data <= kazananMsg[char_index];
            tx_start <= 1;
        end else begin
            char_index <= 0;
            state <= TX_PRINT_SCORE;
        end
    end else begin
        tx_start <= 0;
        if (!tx_busy) char_index <= char_index + 1;
    end
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
                            tx_data <= yuzler + 8'h30; // Yüzler basamaðý
                            tx_start <= 1;
                        end else if (char_index == 3) begin
                            tx_data <= onlar + 8'h30;  // Onlar basamaðý
                            tx_start <= 1;
                        end else if (char_index == 4) begin
                            tx_data <= birler + 8'h30; // Birler basamaðý
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
                    // Sistem sýfýrlanana veya yeni tur baþlayana kadar bekle
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
