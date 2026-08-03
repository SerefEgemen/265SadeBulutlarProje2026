`timescale 1ns / 1ps
/*
NOTES: 
displayModeFinished'in kararmaSinyali olduğunu düşünüyorum ?? hata olabilir hatırlayamadım tam
//displayModeFinished = bitisSinyali; blackout = kararmaSinyali -MT
output'ta istenen currentTurnNew'ın ne olduğunu tam olarak bilmiyorum ? 
//module has to update the current turn but you can't just wire an input to an output. ct becomes ctNew outside the gameLoop in Main. -MT 
gerekirse gray code'dan decimal geçebiliriz eğlenceli geldi araştırınca ondan öyle yazdım. 

//I fixed some stuff. But there might still be bugs here -MT

hatırlatma:
BTNC : BTNC basım kontrol tur ilerlemesi için [U18]
player1 : BTNU [T18]
player2 : BTNL [W19]
player3 : BTNR [T17]
player4: BTND [U17]
*/
module gameLoop(
    input clk, rst, configModeFinished, displayModeFinished, ScoreCalcFinished,
    input[3:0] turnNo, currentTurn, playerNo,
    input BTNU,
    input BTND,
    input BTNL,
    input BTNR,
    input BTNC,
    output reg[29:0] player1Time, player2Time, player3Time, player4Time,
    output reg[3:0] timedOutPlayers, falseStartPlayers, currentTurnNew,
    output reg gameOver, turnOver, blackout
    );
    
    reg[29:0] end_time = 30'd0;
    
    reg[2:0] current_state, next_state;
    
    reg[2:0] noOfPlayers = 3'b000;
    
    localparam IDLE = 3'b000;
    localparam CONFIG = 3'b001;
    localparam TURN = 3'b011;
    localparam CALC = 3'b010;
    localparam END = 3'b110;
    
    //preferred a gray code system to lower power cost + reduce practical errors
    
    always @(*) begin 
    //to prevent latches
    next_state = current_state;
    
    case(current_state)
    
        CONFIG: begin
            if(configModeFinished) begin
            next_state = TURN;
            end
        end
        TURN: begin
            if(turnOver) begin
            next_state = CALC;
            end
        end
        CALC: begin
            if(gameOver) begin
            next_state = END;
            end else if(ScoreCalcFinished) begin
            next_state = TURN;
            end
        end
        END: next_state = IDLE;
        IDLE: if(!rst) next_state = CONFIG; //goes auto to config, and it will cycle if it is in a state after config
        default: next_state = IDLE;
        
    endcase
    end
    
    always @(posedge clk) begin
    if(rst)begin
    current_state <= IDLE;
    next_state <= 3'b101; //something that isn't a state so it doesn't mess with anything else
    player1Time <= 30'd0;
    player2Time <= 30'd0;
    player3Time <= 30'd0;
    player4Time <= 30'd0;
    timedOutPlayers <= 4'd0;
    falseStartPlayers <= 4'd0;
    currentTurnNew <= 4'd0;
    gameOver <= 1'b0;
    turnOver <= 1'b0;
    blackout <= 1'b1;
    end_time <= 30'd0;
    noOfPlayers <= 3'b000;
    end else begin
    current_state <= next_state;
    end
    
    case(next_state)
    IDLE: begin
    end //idle, all values are default values
    
    CONFIG: begin 
    if (configModeFinished) begin
    blackout <= 1'b0;
    end
    end //give the signal for 7Segment
    
    TURN: begin 
    /* 
    en başta herkesi timeout'a alma sebebim kontrolünün daha rahat olması. ek 8927346832 adımlı if döngüsü yazmamak için. 
    aktif olarak oynayan playerlar timeout'da başlar. düğmeye basılmasıyla timeout'dan çıkarılır.
    */
    if(playerNo[0]) begin
    timedOutPlayers[0] = 1'b1;
    end
    if(playerNo[1]) begin
    timedOutPlayers[1] = 1'b1;
    end
    if(playerNo[2]) begin
    timedOutPlayers[2] = 1'b1;
    end
    if(playerNo[3]) begin
    timedOutPlayers[3] = 1'b1;
    end
    
    if(!displayModeFinished) begin
            if(BTNU && playerNo[0]) begin
            falseStartPlayers[0] = 1'b1;
            timedOutPlayers[0] = 1'b0;
            end
            if(BTNL && playerNo[1]) begin
            falseStartPlayers[1] = 1'b1;
            timedOutPlayers[1] = 1'b0;
            end
            if(BTNR && playerNo[2]) begin
            falseStartPlayers[2] = 1'b1;
            timedOutPlayers[2] = 1'b0;
            end
            if(BTND && playerNo[3]) begin
            falseStartPlayers[3] = 1'b1;
            timedOutPlayers[3] = 1'b0;
            end
    end else if(displayModeFinished) begin
            end_time = $time + 2000000000;
            end_time = end_time + 2000000000;
            end_time = end_time + 1000000000;
            if($time <= end_time) begin
            // why so many steps? > 5000000000 nanoseconds are too big for it to register properly, so i added it up in bite-sized pieces.
            
                if(BTNU && !falseStartPlayers[0] && playerNo[0]) begin
                    player1Time = $time;
                    timedOutPlayers[0] = 1'b0;
                end
                if(BTNL && !falseStartPlayers[1] && playerNo[1]) begin
                    player2Time = $time;
                    timedOutPlayers[1] = 1'b0;
                end
                if(BTNR && !falseStartPlayers[2] && playerNo[2]) begin
                    player3Time = $time;
                    timedOutPlayers[2] = 1'b0;
                end
                if(BTND && !falseStartPlayers[3] && playerNo[3]) begin
                    player4Time = $time;
                    timedOutPlayers[3] = 1'b0;
                end
                
            #5;
            end //5 seconds of grace over, so i finish the turn after this.
            turnOver = 1'b1; 
        end
    end   
    
    CALC: begin 
        if(BTNC) begin //waiting for another btnc before advancing.
        
        //current turn is an input, so it should go up! gameOver is an output, so i adjust it by checking here.
        currentTurnNew = (currentTurn + 1'b1);
        //Check if the new turn would be bigger than the amount of turns. There might be an error here because the turnNo is a 4 bit number.
        if(currentTurnNew > turnNo)begin
        gameOver = 1'b1;
        end else begin
        noOfPlayers = (playerNo[0] + playerNo[1] + playerNo[2] + playerNo[3]);
        if(noOfPlayers < 2) begin
        gameOver = 1'b1;
        end else begin //new turn incoming, everything used need to be wiped clean again
        player1Time <= 30'd0;
        player2Time <= 30'd0;
        player3Time <= 30'd0;
        player4Time <= 30'd0;
        timedOutPlayers <= 4'd0;
        falseStartPlayers <= 4'd0;
        currentTurnNew <= 4'd0;
        gameOver <= 1'b0;
        turnOver <= 1'b0;
        blackout <= 1'b1;
        end_time <= 30'd0;
        noOfPlayers <= 3'b000;
        end
        end
        end
        
    end  //nothing else to do,, idle waiting time for scores etc.
    END: begin end //nothing to do
    
    endcase
    end//always
    
endmodule

/*
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠛⡛⠿⠿⠿⠿⠿⠿⠿⠿⠻⠛⠛⠛⠉⠋⠉⠉⠁⢀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠿⢿⠿⠿⠿⠿⠿⢿⣿⠀⠁⠠⢀⠐⣀⣂⣐⣠⣀⣴⠤⠦⢰⠀⢰⣶⣷⣾⠊⠁
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⠁⠀⠀⠀⠈⠀⠀⠀⠀⠀⠁⠀⠀⠀⠈⠁⠀⠁⠲⣿⣿⣿⣿⣿⡇⠀⠀⢸⠀⣽⣿⣿⣿⠂⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⢿⣿⣿⣿⡇⠀⠀⢞⠀⣿⣿⣿⣿⡃⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⣀⣀⢠⡠⡄⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿⠁⠀⠀⡇⣨⣿⣿⡿⣿⠄⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⢀⣤⣿⣿⣿⣷⣿⣿⣾⣶⣧⣶⣶⣄⡀⠀⠀⠀⠀⠀⠀⠀⢛⣿⠀⠀⠀⣈⠴⣋⠼⠁⢸⡁⠀
⡿⡿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠅⢠⡖⠀⣄⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣀⠀⠀⠀⠀⠀⠀⡎⠀⠀⠀⡇⣰⠃⠖⠀⠸⡄⠀
⠀⠙⡆⠈⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡁⣠⣿⠃⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡷⣭⢲⡤⠀⠀⠀⠀⠈⠀⠀⠀⡇⢸⠃⢈⠀⠸⡅⠀
⠀⠀⠁⠈⢉⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠿⠿⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⢣⡟⢣⠀⠀⠀⡀⠀⠀⠀⡇⢸⠁⠀⡀⠸⡅⠀
⠀⠀⢌⠀⠀⠌⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⢉⡇⢀⣀⡀⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣍⠃⠀⠀⠀⡇⠀⠀⠀⡇⢸⠂⠀⠀⢰⡃⠀
⠀⠀⠀⠀⠀⠀⠈⠟⠻⠛⠟⠛⠛⠛⠛⢃⠚⢰⣿⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡊⠅⠀⡀⠀⠀⡀⠀⠀⡇⢸⠀⠈⠀⢠⡇⠀
⠀⠀⠀⠀⠀⠀⠀⠱⡀⠀⠀⠀⠀⠀⠀⠈⠀⠘⠿⡛⠇⣻⣿⣯⣭⣍⡛⠛⠛⠛⠻⣿⣿⣿⡿⠟⠿⠿⠟⠿⣛⠛⠭⠓⠈⢠⡿⣿⠀⠰⢀⠀⡇⢸⠂⠀⠄⠠⡇⠀
⠀⠀⢀⠀⠀⠀⠀⢈⠳⡄⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⣻⠟⠭⠛⠽⠛⠖⠆⢀⢠⣽⣿⣿⣄⠀⠀⠠⡔⡞⡴⢋⠆⡁⠂⠰⢉⡛⠄⠀⠃⠀⡇⢸⠀⢀⠂⢈⡇⠀
⠀⠈⠀⠁⠀⠀⠀⠀⠢⡙⢦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢽⢣⡄⣄⣀⣀⣠⣤⣭⣿⣿⣿⣿⣿⣷⢦⣀⠀⠀⠀⠀⠀⡀⠄⠀⠀⠀⠀⠀⠀⠘⡄⢸⠀⠀⠠⢈⡆⠀
⠀⠀⠀⠀⠀⠀⠀⠄⠠⠱⢌⠳⣄⠀⠀⠀⠀⠀⠀⠀⠀⢪⢗⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣚⣿⣿⣿⣶⣣⠒⡀⠂⠀⠀⠀⠀⠀⠀⢸⠀⣸⠀⠌⡀⢰⠁⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⢀⠃⠹⢶⣄⠀⠀⠀⠀⠀⠀⠀⡛⢿⣿⣿⣿⣿⣿⡿⠿⢿⣿⣿⠿⠟⢷⣹⢿⣿⡿⢷⠉⠄⠀⠀⠀⠀⠀⠀⠀⢸⠀⣽⠀⠀⠀⢸⡁⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠠⠈⠄⢃⠚⢿⣶⣶⣤⣤⡤⣄⠑⡨⠐⢯⣿⣿⣯⡀⢀⠀⠀⠀⠀⠀⠠⣿⠧⡙⠘⠀⠂⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⡇⠠⢸⣿⣿⣿⣿
⠀⠀⠀⣈⠀⡀⠠⠄⠀⠀⠀⡘⡐⢦⣉⠆⡜⣯⢯⡝⠉⠀⠡⢣⣛⡼⢻⢿⣿⣿⣿⣿⣷⣶⣶⣆⣷⢻⠳⣄⢠⠀⠀⠀⠀⣀⠀⢀⠀⠀⠀⠆⠀⣧⣠⣹⣿⣿⠿⠿
⠀⠀⠀⠀⠄⡀⠐⡌⢢⡁⢆⠰⣌⣢⣜⣩⣒⣝⣺⠇⠀⠀⠀⠁⠞⡵⢣⠌⠛⠿⢛⠻⣙⠟⠛⠫⠛⠈⠡⢘⠂⠁⠀⠀⠀⠩⢽⣼⠀⠀⠀⡇⢸⣯⣽⣩⣍⣿⠀⠀
⠀⡄⢂⣩⢶⣀⢧⣜⣧⣿⠾⡷⠿⣟⣛⣟⣿⣿⣿⣿⣄⠀⠀⠀⠀⠈⢑⠊⠙⠾⢿⣷⣮⣴⣿⡗⠂⢀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠛⠀⠀⢀⡇⢸⣿⣿⣿⣿⡿⠀⠀
⣾⣼⣭⣭⣿⣽⣾⣾⣶⢿⣿⣿⣿⣛⠿⣿⣿⣟⣿⣿⣿⣦⠀⠀⠀⠀⠀⠃⠄⠀⠂⠉⠙⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⠁⣸⣿⣿⣿⣿⡏⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⣞⣳⡞⣿⣿⣿⡗⣬⡛⣿⣮⠿⣿⡛⣖⡀⠀⠀⠀⠀⠌⢤⡀⣄⢀⡀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠤⢛⠻⣿⣿⡇⠀⠀
⣿⣿⣿⣿⣿⣿⣿⣿⡞⣵⡻⢧⡻⣿⣿⣆⠹⡄⠻⣿⡔⠻⡄⠣⠐⠀⠀⠀⠀⠀⠈⠀⠃⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⠂⢠⢀⠂⡀⢱⡙⢮⡱⣌⠻⠇⠀⠀
⣿⣿⡿⣝⡿⣿⣻⣷⣛⢷⣛⡯⢷⡹⣟⣮⠓⡜⣥⣄⣛⠷⣌⡤⣁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠈⠀⣌⢣⢎⡲⠁⡄⢛⢧⠳⡜⡌⠒⡄⠀
⣿⣿⡟⣼⢻⣵⣛⡶⣏⠿⡼⣽⢣⡟⣵⢫⡟⣘⠶⣿⣿⣷⣤⣁⠊⠱⠈⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡐⠈⠀⢠⢜⡢⢏⢮⡑⣜⠠⠈⣏⡳⢭⡐⠭⡐⠥
⡷⣿⡝⣎⡟⣶⢹⣚⡭⢻⣱⢋⡷⡹⢭⡓⡿⣌⠿⣿⡻⣟⡿⣾⣝⡦⣂⢄⡘⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣇⠠⡘⣆⠯⡜⣭⠖⡸⡬⢇⡡⠈⣗⠣⢨⡑⢌⠣
⠳⣝⠾⣱⢺⢬⣓⢮⡱⢏⠶⣩⠖⣝⡣⢏⠜⡮⣝⣳⡽⣎⡷⣹⢞⡳⣝⠦⣘⠥⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠰⣎⠐⡱⢎⡳⣽⠲⢠⢏⡱⢋⠴⣀⠈⠅⠦⡑⢊⠔
⠙⡼⣫⡕⣫⠖⡭⣖⡹⣘⢎⡱⢚⠴⣩⢋⡌⢱⢎⡷⣻⣝⡷⣹⢎⠵⣊⠵⣨⢓⠀⡁⢂⠐⠠⢀⠐⡀⢁⠠⣘⠧⢨⢵⣫⢵⣋⠅⣘⠢⢅⠋⢶⡩⠆⠀⠣⠜⡁⠎
⠀⠼⣱⢚⡥⢫⡕⣎⢖⡱⣊⠵⣩⠒⡥⢎⡐⠈⠜⡸⢱⠫⡜⡱⢊⠳⢌⠢⣙⢎⠀⡐⠠⢈⠐⢤⣲⣿⣮⡱⢌⡇⡘⢮⡵⣋⠖⠠⢌⠒⣌⠹⣢⠝⡀⢀⠀⠃⠌⡐
⠄⡸⢥⢫⡜⣣⠞⡼⣘⠲⢥⠳⣌⠳⡜⣢⠱⢈⠀⠄⡁⠒⠠⢁⠊⡐⡈⠰⡭⢎⠠⢠⠑⣌⣾⣿⣿⣿⣿⣷⣯⠄⣹⢳⡼⣁⠂⠰⣈⠒⣌⠳⡔⡃⠀⢆⠀⠀⠐⡌
*/
