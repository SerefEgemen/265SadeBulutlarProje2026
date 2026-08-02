`timescale 1ns / 1ps
/*
The module for finding out the final winner and if there's a tie or not.
inputs:
clk
rst
playersIn (4 bits)
    which players are in the game? We only need to concern ourselves with their scores
    
gameOver (1 bit)
    checks if the game is over or not. Look at ScoreCalc for details.

player1Total
player2Total
player3Total (all 7 bits)
player4Total
    the final scores of all 4 players. These will be compared

outputs:
winningScore (7 bits)
    the highest of all the scores.
    Since we only look at the players who are currently playing, even if an eliminated player has a higher score, it won't be included.

winners (4 bits)
    which players have the highest score?
    winners[0] = is player1 a winner or not?

tieExists (1 bit)
    did more than one player win?
    0 = no tie
    1 = there is a tie

calcFinished (1 bit)
    explains itself

*/


module ScoreCalcEndgame(input clk, rst, gameOver, input[3:0] playersIn, input[6:0] player1Total, player2Total, player3Total, player4Total,
output reg[3:0] winners, output reg[6:0] winningScore, output reg tieExists, calcFinished
    );
    reg[6:0] currentHighest = 7'd0;
    reg[3:0] currentWinners = 4'b0000;
    reg[3:0] tieFinder = 4'b0000;
    //3 stage pipeline: Find highest score, find which players have that score, find if there's a tie
    reg calcedHighest;
    reg calcedWinners;
    
    always@(posedge clk) begin
    if(rst) begin
    winners <= 4'b0;
    winningScore <= 6'b0;
    tieExists <= 1'b0;
    currentHighest <= 7'd0;
    currentWinners <= 4'b0000;
    tieFinder <= 4'b0000;
    calcedHighest <= 1'b0;
    calcedWinners <= 1'b0;
    calcFinished <= 1'b0;
    end else begin
    
    if(gameOver) begin //only work if all turns are over
    //for each player. Check the player is in the game. If their total is larger than the current highest, highest = that total
    if(playersIn[0]) begin
    if(currentHighest < player1Total) begin
    currentHighest = player1Total;
    end
    end
    if(playersIn[1]) begin
    if(currentHighest < player2Total) begin
    currentHighest = player2Total;
    end
    end
    if(playersIn[2]) begin
    if(currentHighest < player3Total) begin
    currentHighest = player3Total;
    end
    end
    if(playersIn[3]) begin
    if(currentHighest < player4Total) begin
    currentHighest = player4Total;
    end
    end
    calcedHighest <= 1'b1;
    end else begin
    calcedHighest <= 1'b0;
    end
    
    if(calcedHighest) begin
    //After finding out the high score. We figure out which players have the same score. (This covers ties)
    if(playersIn[0]) begin
    if(currentHighest == player1Total) begin
    currentWinners[0] <= 1'b1;
    end
    end
    if(playersIn[1]) begin
    if(currentHighest == player2Total) begin
    currentWinners[1] <= 1'b1;
    end
    end
    if(playersIn[2]) begin
    if(currentHighest == player3Total) begin
    currentWinners[2] <= 1'b1;
    end
    end
    if(playersIn[3]) begin
    if(currentHighest == player4Total) begin
    currentWinners[3] <= 1'b1;
    end
    calcedWinners <= 1'b1;
    end
    end else begin
    calcedWinners <= 1'b0;
    end
    
    if(calcedWinners) begin
    tieFinder <= (currentWinners[0] + currentWinners[1] + currentWinners[2] + currentWinners[3]); // a clever way to see if a tie exists
    if(tieFinder > 1) begin // if the sum of all bits is larger than one, there are at least 2 winners.
    tieExists <= 1'b1;
    end else begin
    tieExists <= 1'b0;
    end
    winners <= currentWinners;
    winningScore <= currentHighest;
    calcFinished <= 1'b1;
    end else begin
    calcFinished <= 1'b0;
    end
    
    
    end//notRst
    end//clk
    
    
endmodule




































































































/*
            The Knight had no chance if Asgore had his truck in the Dark World
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⡿⠿⣻⣭⣶⣾⣿⠿⢛⣫⣁⠴⠶⡇⣿⣿⣿⣿⣿⣿⣿⣿⡇⣿⣿⣿⡧⢼⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⡿⢁⣴⣿⣿⣿⡿⠋⣤⣵⡟⢻⣿⣷⡄⣧⢹⣿⣿⣿⣿⣿⣿⣿⡇⢿⣿⣿⢇⢺⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⡿⣠⣿⣿⣿⣿⣿⠁⠠⣛⡛⢿⠿⠟⡛⠵⠫⡜⣿⣿⣿⣿⣿⣿⣿⡇⢻⣿⣿⠎⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⢻⣿⣿⣿⣿⣿⣿⠄⣃⣤⣿⣿⣿⣿⣿⣿⣿⣧⣜⠻⣿⣿⣿⣿⣿⡇⢠⢻⣿⡛⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⡜⣿⣿⣿⢟⣭⣶⣿⡿⣫⣽⣶⣶⡶⣶⣧⣝⡻⢿⣾⣌⢝⠿⣿⠿⣣⣾⡜⣿⡱⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢘⣋⣛⣙⡉⣩⣬⣭⣶⣿⣿⠟⣭⣾⣟⡛⠿⣿⣿⣮⡿⣿⣿⣶⣍⢻⣿⣿⢖⣵⣿⣿⢳⣿⠥⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣷⢹⣿⣿⣿⡿⣡⣾⣿⣿⡿⠻⠧⡌⢿⣿⣿⣽⣿⣿⣿⣧⢻⣿⡧⢻⣿⠏⣼⣿⡧⣸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⢏⣵⣿⣿⣿⠟⣱⣿⣿⣿⣯⣵⣆⡰⣬⣌⡻⣿⢟⣿⡿⠛⠻⡇⣿⣿⡅⡋⣾⣿⣿⣷⣼⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠿⢃⣾⣿⣿⣿⡟⣼⣿⡿⢙⢿⣿⣿⣿⣿⣷⣾⣿⣿⣶⣶⠠⣬⣻⡇⣾⡟⣸⡇⢻⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡆⣾⣿⣿⣿⣿⢸⣿⣿⠷⣹⣷⢉⠿⠿⠿⣏⣿⡏⣹⢿⣿⣿⣿⣿⢱⣇⣸⣿⡇⢿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⢠⣿⣿⣿⣿⡏⣼⣿⢧⣾⡟⣛⡻⠷⣮⢿⣿⣿⣿⣿⣿⣾⠿⣿⣏⢸⢺⣿⣿⡇⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣾⣶⣶⣶⣻⠅⣿⡯⣾⡏⣼⣿⣧⠻⣾⣷⢽⡬⣿⣿⠿⣿⣗⢜⣧⢸⡱⣶⣶⣶⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⢇⣿⣦⡛⣱⡟⣼⣿⣿⣿⣷⣮⣟⡳⢿⣿⣾⣭⣷⣿⣷⣬⢼⣇⣉⢿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣟⡛⣧⣾⣛⣩⣼⣿⡧⢛⣽⣿⣿⣿⣿⣿⣿⡷⣾⣭⣿⣿⣿⣿⣷⣸⢿⡏⢡⣽⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣶⣍⢻⣿⣿⢫⣶⣿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⣿⣿⣿⡾⣰⣯⢻⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣷⡜⣿⡆⠛⣴⢸⣿⣿⣿⣿⣿⣿⣿⣿⡟⢫⣵⣿⣿⣿⢫⣼⣿⣿⡆⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⡷⠹⣿⣿⣿⡜⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣳⣿⣿⣿⣿⣧⢻⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⡟⣵⣧⢹⣿⣿⣿⣧⣹⣛⡿⣟⢸⡿⡋⣿⠿⠻⡿⣱⣿⣿⣿⣿⣿⡇⣶⣍⠻⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⠿⣫⣾⣿⣿⡄⢿⣿⣿⣿⣿⣿⣿⣿⣼⣾⣷⣵⢞⢱⣾⣿⣿⣿⣿⣿⡿⢔⣿⣿⣷⡝⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
*/
