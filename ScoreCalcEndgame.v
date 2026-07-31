`timescale 1ns / 1ps
/*
The module for finding out the final winner and if there's a tie or not.
inputs:
clk
rst
playersIn (4 bits)
    which players are in the game? We only need to concern ourselves with their scores

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

*/


module ScoreCalcEndgame(input clk, rst, input[3:0] playersIn, input[6:0] player1Total, player2Total, player3Total, player4Total,
                        output reg[3:0] winners, output reg[6:0] winningScore, output reg tieExists
    );
    reg[64:0] currentHighest = 7'b0;
    reg[3:0] currentWinners = 4'b0000;
    reg[2:0] tieFinder = 2'b0;
    
    always@(posedge clk) begin
    if(rst) begin
    winners <= 4'b0;
    winningScore <= 7'b0;
    tieExists = 1'b0;
    end else begin
    //for each player. Check the player is in the game. If their total is larger than the current highest, highest = that total
    if(playersIn[0]) begin
    if(currentHighest < player1Total) begin
    currentHighest <= player1Total;
    end
    end
    if(playersIn[1]) begin
    if(currentHighest < player2Total) begin
    currentHighest <= player2Total;
    end
    end
    if(playersIn[2]) begin
    if(currentHighest < player3Total) begin
    currentHighest <= player3Total;
    end
    end
    if(playersIn[3]) begin
    if(currentHighest < player4Total) begin
    currentHighest <= player4Total;
    end
    end
    
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
    end
    
    tieFinder = (currentWinners[0] + currentWinners[1] + currentWinners[2] + currentWinners[3]); // a clever way to see if a tie exists
    if(tieFinder > 1) begin // if the sum of all bits is larger than one, there are at least 2 winners.
    tieExists = 1'b1;
    end else begin
    tieExists = 1'b0;
    end
    
    winners <= currentWinners;
    winningScore <= currentHighest;
    
    end
    end
    
    
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
