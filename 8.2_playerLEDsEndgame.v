`timescale 1ns / 1ps
/*
I seperated playerLEDs with the final turn.
For details, refer to that.
inputs:
clk
rst
winners (4 bits)
    who won the entire game? only here for the gameOver scenario. has to be compared and figured out elsewhere. If the game is not over yet. Don't care.
    Has to account for ties
    winner[0] = did player1 win the game
    winner[1] = did player2 win the game etc..
    Normally usually one bit is one, but ties are possible

outputs:
leds (16 bits)
    the led displays.


*/


module playerLEDsEndgame(input clk, rst, input[3:0] winners, output reg[15:0] leds
    );
    
    reg[3:0] player1Leds;
    reg[3:0] player2Leds;
    reg[3:0] player3Leds;
    reg[3:0] player4Leds;
    //same as playerLEDs
    
    always@ (posedge clk) begin
    
    if(rst) begin
    player1Leds <= 4'b0;
    player2Leds <= 4'b0;
    player3Leds <= 4'b0;
    player4Leds <= 4'b0;
    leds <= 16'b1000_0000_0000_0000; //only the reset light is on
    end//of reset
    else begin
    //the game is over. Displaying only the winner
    //who are the final winners? This value is irrelevant if the final turn isn't over
    //We don't need to know if there are less than 4 players here. winner won't be affected by that.
    if(winners[0]) begin//Player1 won the game
    player1Leds <= 4'b1111;
    end
    if(winners[1]) begin//Player2 won the game
    player2Leds <= 4'b1111;   
    end
    if(winners[2]) begin//Player3 won the game
    player3Leds <= 4'b1111;   
    end
    if(winners[3]) begin//Player4 won the game
    player4Leds <= 4'b1111;
    end
    
    //leds
    leds[3:0] <= player1Leds;
    leds[7:4] <= player2Leds;
    leds[11:8] <= player3Leds;
    leds[15:12] <= player4Leds;
    
    
    end
    end
    
    
endmodule
