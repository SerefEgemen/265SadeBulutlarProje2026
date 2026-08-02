`timescale 1ns / 1ps
/*
## endmodule 2 error vermekte, sebebini araştırmaya devam

BTNC : BTNC bas?m kontrol tur ilerlemesi için [U18]
player1 : BTNU [T18]
player2 : BTNL [W19]
player3 : BTNR [T17]
player4: BTND [U17]

!! playerLED ile ba?lanmal? fonksiyonlar birle?tirilirken !!

These are the inputs and outputs Main needs:

module gameLoop(input clk, rst, 
 configModeFinished, displayModeFinished, ScoreCalcFinished, countdownFinished,
 input[3:0] turnNo, currentTurn, playerNo,
 input BTNU, BTND, BTNL, BTNR, BTNC,
 output reg[29:0] player1Time, player2Time, player3Time, player4Time,
 output reg[3:0] timedOutPlayers, falselyStartedPlayers,
 output reg gameOver, turnOver, blackout,
 output reg[3:0] currentTurnNew
);

What should it do:
5 states:

if (rst):
state is IDLE

IDLE:
wait for config to finish.
if (configModeFinished):
change state to WAITING
blackout <= 0 (for 7SegmentDisplay, it uses the input inversely)

WAITING:
waiting for the display lights to turn off.
if any player presses a button now, give them a false start penalty (elimination will be done in ScoreCalc)
if(countDownFinished):
change state to SCORING

SCORING:
start the timers for all players that are in the game
also start the 5 second deadline timer
when a player presses the button, stop their timer and save their score
after the deadline timer ends: 
give all remaining players a timeout penalty
turnOver <= 1 (for ScoreCalc)
state change to CALCING

CALCING:
ScoreCalc is doing stuff in the background. Just wait for BTNC to be pressed.
if(BTNC):
increase the currentTurn (with currentTurnNew)
then check if the game should end or not (currentTurn > turnNo) or (only 1 player is left)
if (oneOfTheseTwo):
gameOver <= 1 (for a lot of stuff)
change state to ENDGAME
else:
reset all the stuff to their default values for the next turn
change state to IDLE

ENDGAME:
blackout <= 1 (to stop 7SegmentDisplay)


*/

module gameLoop(input clk, rst, turnNo, playerNo, BTNC, BTNU, BTNL, BTNR, BTND, eliminationModeInput, kararmaSinyali, 
                
output score[0:playerNo][0:turnNo]

);

reg [1:0] playerActive [0:3]; //playerlar?n olup olmad???n? assignlamak için 1 bit true/false switch input için açar main game'de
reg [2:0] playerOrderSpeed [0:playerNo]; //gameloopta s?ray? belirler, player no al?r S?n?rlar ?çi Basanlar
reg [1:0] falseStart [0:playerNo]; //victims

//main game loop
reg order = 0; //s?ralama yap?l?rken kullan?yor playerOrder side piece
reg end_time;

genvar i;
genvar j;
generate

always @ (posedge clk) begin

//player var m? a?a??daki gameloop için true/false vbvb CONFIG a?amas?
for(i = 0; i < 4; i = i + 1) begin

	if(i < playerNo) begin
	playerActive[i] = 1'b1;
	end else begin
	playerActive[i] <= 1'b0;
	end
	falseStart[i] <= 1'b0;
		
	for(j = 0; j < turnNo; j = j + 1 )begin
		score[i][j] <= 0;  //skor tablosu full 0 ba?lar
	end
	
end

//main gameloop alt config üst - main'de btnc basma ayarlanmal? fonksiyonun ça??r?lmas? için ça??r?l?nca ba?lar oyun otomatik

for(i = 0; (i < turnNo); i = i + 1) begin
    //inputlar bu k?s?mda aç?k, her input ile ledler s?ras?yla yanmal? playerlarla ba?lant?l?
    while(!kararmaSinyali) begin //falseStart victims
                if(playerActive[0]) begin//1. oyuncu
                      if(BTNU) begin
                                falseStart[0] <= 1'b1;
                          //playerled vb eklenmeli s?ra için. playerled inputu s?ra için order, playerNo için if döngüsü içindeki de?eri olarak ayarlanmal?
                      end 
                    end
                if(playerActive[1]) begin//2. oyuncu
                      if(BTNL) begin
                          falseStart[1] <= 1'b1;
                      end 
                    end
                if(playerActive[2]) begin
                      if(BTNR) begin
                          falseStart[2] <= 1'b1; //3. oyuncu
                      end 
                    end
                if(playerActive[3]) begin//4. oyuncu
                      if(BTND) begin//button press içi a?a??s? için
                                falseStart[3] <= 1'b1;
                      end 
                    end
    end //while
            
    for(j = 0; j < 10; j = j + 1) begin //5 sec wait - değeri nanosec'deki büyüklüğünden dolayı *10 kere 500000000 bekler
        end_time = $time + 500000000; 
        while($time <= end_time) begin
          //s?ras?yla input açar falsestart olmamalar?na göre
            if(playerActive[0] && !falseStart[0]) begin//1. oyuncu
              if(BTNU) begin
                        playerOrderSpeed[order] <= 2'b00;
                order <= order +1;
              end 
            end
            if(playerActive[1] && !falseStart[1]) begin//2. oyuncu
              if(BTNL) begin
                        playerOrderSpeed[order] <= 2'b01;
                order <= order +1;
              end 
            end
            if(playerActive[2] && !falseStart[2]) begin
              if(BTNR) begin
                        playerOrderSpeed[order] <= 2'b10; //3. oyuncu
                order <= order +1;
              end 
            end
            if(playerActive[3] && !falseStart[3]) begin//4. oyuncu
              if(BTND) begin//button press içi a?a??s? için
                        playerOrderSpeed[order] <= 2'b11;
                order <= order +1;
              end 
            end
            
            #5; //time goes on. there are 5 nanoseconds inbetween presses.
    end//while
    end//for
    
    //skor hesab? k?sm?
        for(j = 0; j < order; j = j + 1) begin 
        
            case(playerOrderSpeed[j])
              
                2'b00:  score[0][i] <= playerNo - j; //i olmas?n?n sebebi tura göre kaydetmesi
                2'b01:  score[1][i] <= playerNo - j;
                2'b10:  score[2][i] <= playerNo - j;
                2'b11:  score[3][i] <= playerNo - j;
                default: ;//bo? çünkü olmamal?
                //case'ler ilerletilebilir max player say?s?ma göre kapsamas? için
                    
            endcase
        
        end //for
    //timeout vb otomatik 0 olur ba?lang?ç config sayesinde
    
    //belki display s?ralama ? olabilir yap?labilir 
    
    //elimination
        if(eliminationModeInput) begin
            order <= order - 1; //aç?klama a?a?? blokta
            for(j = 0; j < playerNo; j = j + 1) begin
                
                /*
                oyuncu ba?? kontrol. skoru 0 olan ve playerOrderSpeed kategorisinde sonuncu olmayan her ki?i otomatikman ya timeout ya da falseStart grubuna ait olmak zorunda
                [order - 1] olmas?n?n sebebi yukar?da playerOrder'a veri koyduktan sonra otomatik +1 yapt?rmam, eksiltmeden bakarsam normal order'a null ya da out of bounds olacakt?r
                order for döngüsünün içinde 0'lanacak zaten ondan dolay? burada evirip çevirmemde bir s?k?nt? yok
                */
                
                if((score[j][i] == 0) && !(playerOrderSpeed[order] == j)) begin 
                    playerActive[j] <= 1'b0; //nuked
                end
    
              end //for
            end //if
    //^^ elimination modu aç?ksa order'da olmayan de?erlerin switchlerini kapat?r ^^ 
    
        for(j = 0; j < playerNo; j = j + 1) begin
            falseStart[j] <= 1'b0; //reset, does not affect eliminations because elimination is handled by another matrix
        end//for
                
    wait(BTNC); //bir sonraki tura geçirene kadar manuel olarak durdurur, teknik olarak tur burada bitti bir sonrakine geçe emri bekliyor **daha düzgün yaz
    
        order = 0;
end //main for loop

//game is over, so after this is the endgame part

//playerled s?ralama display vbvbvb yapılmalı

/*


⡴⠒⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠉⠳⡆⠀
⣇⠰⠉⢙⡄⠀⠀⣴⠖⢦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣆⠁⠙⡆
⠘⡇⢠⠞⠉⠙⣾⠃⢀⡼⠀⠀⠀⠀⠀⠀⠀⢀⣼⡀⠄⢷⣄⣀⠀⠀⠀⠀⠀⠀⠀⠰⠒⠲⡄⠀⣏⣆⣀⡍
⠀⢠⡏⠀⡤⠒⠃⠀⡜⠀⠀⠀⠀⠀⢀⣴⠾⠛⡁⠀⠀⢀⣈⡉⠙⠳⣤⡀⠀⠀⠀⠘⣆⠀⣇⡼⢋⠀⠀⢱
⠀⠘⣇⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⡴⢋⡣⠊⡩⠋⠀⠀⠀⠣⡉⠲⣄⠀⠙⢆⠀⠀⠀⣸⠀⢉⠀⢀⠿⠀⢸
⠀⠀⠸⡄⠀⠈⢳⣄⡇⠀⠀⢀⡞⠀⠈⠀⢀⣴⣾⣿⣿⣿⣿⣦⡀⠀⠀⠀⠈⢧⠀⠀⢳⣰⠁⠀⠀⠀⣠⠃
⠀⠀⠀⠘⢄⣀⣸⠃⠀⠀⠀⡸⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠈⣇⠀⠀⠙⢄⣀⠤⠚⠁⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⢹⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠀⠀⢘⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⢰⣿⣿⣿⡿⠛⠁⠀⠉⠛⢿⣿⣿⣿⣧⠀⠀⣼⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡀⣸⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⡀⢀⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡇⠹⠿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⡿⠁⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣤⣞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢢⣀⣠⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠲⢤⣀⣀⠀⢀⣀⣀⠤⠒⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀


🐺:3
^^
https://i.kym-cdn.com/entries/icons/original/000/042/980/bludthinkshesontheteam.jpg

*/

endmodule
