`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/31/2026 10:27:39 AM
// Design Name: 
// Module Name: Main
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Main(input clk, input[15:0] sw, input btnC, btnU, btnL, btnR, btnD, 
output wire[15:0] led, output wire[6:0] seg, output wire dp, output wire[3:0] an, output wire RsTx);

//reset = sw[15]
wire rst = sw[15];
//Buttons
wire up;
wire down;
wire left;
wire right;
wire center;


//Debouncing the button inputs
debounce dbU(btnU, clk, rst, up);
debounce dbD(btnD, clk, rst, down);
debounce dbL(btnL, clk, rst, left);
debounce dbR(btnR, clk, rst, right);
debounce dbC(btnC, clk, rst, center);

//Config Menu
wire hardMode;
wire elimination;
wire[1:0] playerNo;
wire[3:0] turnNo;
wire confinish; //config is over
ConfigMenu configM(clk, rst, sw[2:0], sw[7:4], sw[9], sw[11], center, playerNo, turnNo, elimination, hardMode, confinish, led);

//lfsr
wire[15:0] currentRandVal;
lfsr16 lfsrModule(clk, sw[15], currentRandVal);

//The Game Loop
wire[6:0] winningScore;
wire[3:0] winningPlayers;
//main game loop goes here...
/*mainGame does:
    repeats gameLoop for the amount of turns.
    waits until btnC for next turn
    finishes loop if currentTurn = turnNo
    runs ScoreCalcEndgame after the loop is over
    runs finalUARTDisplay
        each gameLoop:
            runs one turn
            runs ScoreCalc
            runs UARTDisplay
           
*/

//uhhhh...






endmodule
