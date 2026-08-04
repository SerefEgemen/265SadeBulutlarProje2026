`timescale 1ns / 1ps
/*
##patch notes
-logic error fixed where calcDone was only changed in 1 line of code, softlocking calculation after 1 usage
-improved readability
##

This module and ScoreCalcEndgame are going to be used in the game loop. 
In my head. the game loop module looks something like this:

if(turn not over/reset not pressed etc. etc.) begin ***

*use lfsr to get the value

*use RSO(value) to get the waitTime

*use 7SegmentDisplay(waitTime) to get the signal

*after getting the signal, begin the game and get the playerTimes.

*use ScoreCalc(playerTimes) and get placements and totals

*use playerLeds(placements)

if(the game is over) begin *-*
*use ScoreCalcEndgame(totals)
*use playerLEDs(totals)
end *-*
end ***



inputs:
clk (1 bit)
rst (1 bit)
    the classics

eliminate (1 bit)
    if eliminate is active, we must remove the penalized players from the active players

gameOver (1 bit)
    checks if the game is over or not. SCEndgame does the same thing. When one works the other one doesn't.
turnOver (1 bit)
    checks if the current turn is finished so it can calculate the totals.

player1Time
player2Time
player3Time (all of them 30 bits)
player4Time
    the time values the players got after the round finished

timeoutPlayers (4 bits)
falseStartPlayers (4 bits)
    flagged players that will be penalized
    eg: timeoutPlayers[0] = did player1 get a timeout

playersIn (4 bits)
    players that are currently in the game. Same as playerIn inside playerLEDs.

player1Total
player2Total
player3Total (all 7 bits)
player4Total
    total amount of ponts the players got since the start. Can't be below 0 or above 64 since max turn amount is 16 and max point from a turn is 4

outputs:
player1Place
player2Place
player3Place (all 2 bits)
player4Place
    placements of all 4 players. Draws are possible
    00 = 1st place. 11 = 4th place

playersLeft (4 bits)
    new value of playersIn after GETTING RID OF THE WEAK!!!!
    
player1newTotal
player2newTotal
player3newTotal (all 7 bits)
player4newTotal 
    updated totals after scoring.

calcDone (1 bit)
    finished calculating


UART can determine what to display each round from the placements.
00 = 1st place (displays 4)
01 = 2st place (displays 3)
01 = 3st place (displays 2)
01 = 4st place (displays 1)
player is penalized = display 0, disregard placement value
*/


module ScoreCalc(input clk, rst, eliminate, gameOver, turnOver, input[29:0] player1Time, player2Time, player3Time, player4Time, input[3:0] timeoutPlayers, falseStartPlayers, playersIn, input[6:0] player1Total, player2Total, player3Total, player4Total,
output reg[1:0] player1Place, player2Place, player3Place, player4Place, output reg[3:0] playersLeft, playersPenalized, output reg[6:0] player1newTotal, player2newTotal, player3newTotal, player4newTotal, output reg calcDone
    );
    
    always@(posedge clk) begin
    if(rst) begin
        player1Place <= 2'b00;
        player2Place <= 2'b00;
        player3Place <= 2'b00;
        player4Place <= 2'b00;
        playersLeft <= 4'b0000;
        playersPenalized <= 4'b0000;
        player1newTotal <= 7'b0;
        player2newTotal <= 7'b0;
        player3newTotal <= 7'b0;
        player4newTotal <= 7'b0;
        calcDone <= 1'b0;
    end else begin
    if(!gameOver) begin //only works if it's mid-game
    if(!calcDone) begin
        if(turnOver) begin //calculates when turn is over
        
        //get the old info first
        playersLeft <= playersIn;
        player1newTotal <= player1Total;
        player2newTotal <= player2Total; 
        player3newTotal <= player3Total; 
        player4newTotal <= player4Total;
        //now the score calc!!
             
        //first, say all of them are first place
        player1Place <= 2'b00;
        player2Place <= 2'b00;
        player3Place <= 2'b00;
        player4Place <= 2'b00;
        
        //second, penalize and possibly eliminate the faulty players.
        
        if(playersIn[0]) begin//player1
            if(timeoutPlayers[0] || falseStartPlayers[0]) begin
                //they are immediately 4th place. And they are tagged as penalized.
                player1Place <= 2'b11;
                playersPenalized[0] <= 1'b1;
                if(eliminate) begin //and remove them if elimination mode is active
                playersLeft[0] <= 1'b0;
                end
            end
        end
        
        if(playersIn[1]) begin//player2
            if(timeoutPlayers[1] || falseStartPlayers[1]) begin
                player2Place <= 2'b11;
                playersPenalized[1] <= 1'b1;
                if(eliminate) begin
                playersLeft[1] <= 1'b0;
                end
            end
        end
        
        if(playersIn[2]) begin//player3
            if(timeoutPlayers[2] || falseStartPlayers[2]) begin
                player3Place <= 2'b11;
                playersPenalized[2] <= 1'b1;
                if(eliminate) begin
                playersLeft[2] <= 1'b0;
                end
            end
        end
        
        if(playersIn[3]) begin//player4
            if(timeoutPlayers[3] || falseStartPlayers[3]) begin
                player4Place <= 2'b11;
                playersPenalized[3] <= 1'b1;
                if(eliminate) begin
                playersLeft[3] <= 1'b0;
                end
            end
        end
        
        
        //now we have the updated player list, we can calculate placements and scores
        
        if(playersIn[0]) begin //player1's placement
            if(!playersPenalized[0]) begin //if the player didn't get a penalty:
            
                //1) Check if another player is in. Then check if they're penalized or not.
                if(playersIn[1] && !playersPenalized[1]) begin
                //2) Compare their times, if this player's time is larger, add 1 to their playerPlace. (this drops their placement)
                if(player1Time > player2Time) begin //player1 vs player2
                player1Place = (player1Place + 1);
                end
                end
            
                //3) repeat comparing to the other players
                if(playersIn[2] && !playersPenalized[2]) begin
                if(player1Time > player3Time) begin //player1 vs player3
                player1Place = (player1Place + 1);
                end
                end
                
                if(playersIn[3] && !playersPenalized[3]) begin
                if(player1Time > player4Time) begin //player1 vs player4
                player1Place = (player1Place + 1);
                end
                end
                //This way, The playerPlace is increased for each time smaller than the player's time.
                
            
            end
        end
        
        //now we do this for the other 3 players. We DO compare them with the players we already compared previously. And we only increase the main player's placement
        //This way, each player is compared with others exactly twice, and we will not increase the placement wrongly. So the final placements should be correct. Even works with ties, giving them the same placement.
        
        if(playersIn[1]) begin //player2's placement
            if(!playersPenalized[1]) begin
            
                if(playersIn[0] && !playersPenalized[0]) begin
                if(player2Time > player1Time) begin //player2 vs player1
                player2Place = (player2Place + 1);
                end
                end
            
                if(playersIn[2] && !playersPenalized[2]) begin
                if(player2Time > player3Time) begin //player2 vs player3
                player2Place = (player2Place + 1);
                end
                end
            
                if(playersIn[3] && !playersPenalized[3]) begin
                if(player2Time > player4Time) begin //player2 vs player4
                player2Place = (player2Place + 1);
                end
                end
            end
        end
        
        if(playersIn[2]) begin //player3's placement
            if(!playersPenalized[2]) begin
            
                if(playersIn[0] && !playersPenalized[0]) begin
                if(player3Time > player1Time) begin //player3 vs player1
                player3Place = (player3Place + 1);
                end
                end
                
                if(playersIn[1] && !playersPenalized[1]) begin
                if(player3Time > player2Time) begin //player3 vs player2
                player3Place = (player3Place + 1);
                end
                end
                
                if(playersIn[3] && !playersPenalized[3]) begin
                if(player3Time > player4Time) begin //player3 vs player4
                player3Place = (player3Place + 1);
                end
                end
            end
        end
        
        if(playersIn[3]) begin //player4's placement
            if(!playersPenalized[3]) begin
            
                if(playersIn[0] && !playersPenalized[0]) begin
                if(player4Time > player1Time) begin //player4 vs player1
                player4Place = (player4Place + 1);
                end
                end
                
                if(playersIn[1] && !playersPenalized[1]) begin
                if(player4Time > player2Time) begin //player4 vs player2
                player4Place = (player4Place + 1);
                end
                end
                
                if(playersIn[2] && !playersPenalized[2]) begin
                if(player4Time > player3Time) begin //player4 vs player3
                player4Place = (player4Place + 1);
                end
                end
            end
        end
        //(I know this is a mess. Just work with me, OK?)
    
    
        if(playersIn[0]) begin //player1's total
            if(!playersPenalized[0]) begin //if the player didn't get a penalty:
                case(player1Place)
                    2'b00: begin
                    player1newTotal <= (player1Total + 4);
                    end
                    2'b01: begin
                    player1newTotal <= (player1Total + 3);
                    end
                    2'b10: begin
                    player1newTotal <= (player1Total + 2);
                    end
                    2'b11: begin
                    player1newTotal <= (player1Total + 1);
                    end
                endcase
            end
        end
        
        if(playersIn[1]) begin //player2's total
            if(!playersPenalized[1]) begin 
                case(player2Place)
                    2'b00: begin
                    player2newTotal <= (player2Total + 4);
                    end
                    2'b01: begin
                    player2newTotal <= (player2Total + 3);
                    end
                    2'b10: begin
                    player2newTotal <= (player2Total + 2);
                    end
                    2'b11: begin
                    player2newTotal <= (player2Total + 1);
                    end
                endcase
            end
        end
        
        if(playersIn[2]) begin //player3's total
            if(!playersPenalized[2]) begin 
                case(player3Place)
                    2'b00: begin
                    player3newTotal <= (player3Total + 4);
                    end
                    2'b01: begin
                    player3newTotal <= (player3Total + 3);
                    end
                    2'b10: begin
                    player3newTotal <= (player3Total + 2);
                    end
                    2'b11: begin
                    player3newTotal <= (player3Total + 1);
                    end
                endcase
            end
        end
        
        if(playersIn[3]) begin //player4's total
            if(!playersPenalized[3]) begin
                case(player4Place)
                    2'b00: begin
                    player4newTotal <= (player4Total + 4);
                    end
                    2'b01: begin
                    player4newTotal <= (player4Total + 3);
                    end
                    2'b10: begin
                    player4newTotal <= (player4Total + 2);
                    end
                    2'b11: begin
                    player4newTotal <= (player4Total + 1);
                    end
                endcase
            end
        end
        
        calcDone <= 1'b1;
        end//turnOver
        
    end else begin //calcdone check
        calcDone <= 1'b0;
    end //calcDonecheck end
    
    end//gameOver
    
    end //rst check
    end //always
    
endmodule











































































/*
On that grind for the strawberry
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓  
▓▓▓▓▓▓▓▓████████████████████▓▓▓▓▓▓  ▓▓▓▓▓▓██████░░████▓▓▓▓▓▓
▓▓██████▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▓▓██▓▓▓▓▓▓▓▓▓▓██    ██░░    ██▓▓▓▓
██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓██▓▓▓▓▓▓██  ░░  ██░░  ██▓▓▓▓▓▓
██▒▒▒▒▒▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▒▒▓▓▒▒▒▒██▓▓▓▓▓▓██    ░░    ░░██████▓▓
██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓▓▓▓▒▒██▓▓▓▓▓▓██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
▓▓██████▒▒▒▒▒▒▒▒▒▒▓▓░░░░░░░░████▓▓▓▓██▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒██
▓▓▓▓▓▓▓▓████▒▒▒▒▓▓░░░░░░░░░░████▓▓▓▓██░░▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒██
▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓░░░░░░██▓▓██▓▓▓▓██░░▒▒░░▒▒▒▒▒▒░░▒▒▒▒░░██
▓▓▓▓▓▓▓▓██▓▓▒▒▒▒▒▒▒▒▒▒▓▓▓▓████▓▓▓▓▓▓▓▓██▒▒▒▒▒▒▒▒▒▒░░░░▒▒██▓▓
▓▓▓▓▓▓▓▓██▒▒▒▒▒▒▒▒▒▒░░░░▒▒▒▒░░██▓▓▓▓▓▓▓▓██▒▒▒▒▒▒▒▒░░▒▒██▓▓▓▓
  ▓▓▓▓▓▓██▒▒▒▒▓▓▒▒▒▒░░░░▒▒▒▒░░██▓▓▓▓▓▓▓▓▓▓██▒▒▒▒▒▒▒▒██▓▓▓▓▓▓
▓▓▓▓▓▓▓▓██░░▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓▓▓▓▓▓████████▓▓▓▓▓▓▓▓
▓▓▓▓▓▓██░░▒▒▒▒▓▓▓▓▒▒▒▒▒▒▒▒▓▓██▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓██░░░░██▓▓▒▒▒▒▓▓▓▓▓▓▒▒██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓████▓▓██▒▒▒▒▒▒██▒▒▒▒██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▒▒░░██▒▒░░██▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓████▓▓██████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒▒  ▓▓▓▓▓▓▓▓▓▓
*/
