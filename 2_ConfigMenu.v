`timescale 1ns / 1ps
/*
inputs:
clk: for the clock, uses posedge (1 bit)
reset: for the reset switch. Assigned to sw[15] (1 bit)
playerNoInput: determines the playerNo. Assigned to sw[0], sw[1], sw[2]. (3 bits)
turnNoInput: determines turnNo. Assigned to sw[4], sw[5], sw[6], sw[7]. (4 bits)
eliminationInput: determines elimination. Assigned to sw[9]. (1 bit)
hardInput: determines hardMode. Assigned to sw[11]. (1 bit)
finishedInput: determines if the configs are done or not. Assigned to btnC. (1 bit)

outputs:
playerNo: playerNo[0] = player1 is in the game etc. (4 bits)
turnNo: 0000 = 1 turn, ..., 1111 = 16 turns. (4 bits)
currentTurn: Begin the game by setting the current turn to 0. (4 bits)
elimination: 0 = Elimination Mode off, 1 = on. (1 bit)
hardMode: 0 = Easy, 1 = Hard. (1 bit)
finished: 0 = still on config mode, 1 = config mode finished. (1 bit)
leds: outputs for the LED lights. Lights for the assigned switches turn on when switched. (16 bits)
*/


module ConfigMenu(input clk, reset, input[2:0] playerNoInput, input[3:0] turnNoInput, input eliminationInput, hardInput, finishedInput, 
    output reg[3:0] playerNo, output reg[3:0] turnNo, output reg elimination, hardMode, finished, output reg[15:0] leds
    );
    
    always@ (posedge clk) begin
    
    if(reset) begin // default values
    playerNo <= 4'b0011; //2 players
    turnNo <= 4'b0000; //1 turn
    elimination <= 1'b0;
    hardMode <= 1'b0;
    finished <= 1'b0;
    leds <= 16'b1000_0000_0000_0000; //reset is active, so sw[15]'s LED is on
    end//end of reset
    
    else if(!finished) begin
    //Number of Players: (Switches 0, 1, 2)
    //Bigger switch overrides the value. Looks cooler this way.
    if(playerNoInput[2])        //sw[2] = 4 players. Overrides sw[1] and [0] 
    playerNo <= 4'b1111;
    else if(playerNoInput[1])   //sw[1] = 3 players. Overrides sw[0]
    playerNo <= 4'b0111;
    else                        //sw[0] or no switches. Both equal to the default value (2 players)
    playerNo <= 4'b0011;
    
    //Number of turns: (Switches 4, 5, 6, 7)
    //turns the switch into the 4 bit value. 0000 = 1 turn
    turnNo <= turnNoInput;
    
    //elimination and hard mode: (Switches 9, 11)
    elimination <= eliminationInput;
    hardMode <= hardInput;
    
    //LED displays
    leds[2:0] <= playerNoInput;
    leds[7:4] <= turnNoInput;
    leds[9] <= eliminationInput;
    leds[11] <= hardInput;
    leds[15] <= 1'b0;
    
    
    
    //is BTNC pressed to finish config
    if(finishedInput) begin
    finished <= 1'b1;
    end
    
    end//end of "not finished"
    end//end of clock
    
    
    
    
    
endmodule

































































/*
Now every module has to have an ASCII art. It's a rule

⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡴⠞⢳⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡔⠋⠀⢰⠎⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⢆⣤⡞⠃⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⢠⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⣀⣾⢳⠀⠀⠀⠀⢸⢠⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⣀⡤⠴⠊⠉⠀⠀⠈⠳⡀⠀⠀⠘⢎⠢⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀
⠳⣄⠀⠀⡠⡤⡀⠀⠘⣇⡀⠀⠀⠀⠉⠓⠒⠺⠭⢵⣦⡀⠀⠀⠀
⠀⢹⡆⠀⢷⡇⠁⠀⠀⣸⠇⠀⠀⠀⠀⠀⢠⢤⠀⠀⠘⢷⣆⡀⠀
⠀⠀⠘⠒⢤⡄⠖⢾⣭⣤⣄⠀⡔⢢⠀⡀⠎⣸⠀⠀⠀⠀⠹⣿⡀
⠀⠀⢀⡤⠜⠃⠀⠀⠘⠛⣿⢸⠀⡼⢠⠃⣤⡟⠀⠀⠀⠀⠀⣿⡇
⠀⠀⠸⠶⠖⢏⠀⠀⢀⡤⠤⠇⣴⠏⡾⢱⡏⠁⠀⠀⠀⠀⢠⣿⠃
⠀⠀⠀⠀⠀⠈⣇⡀⠿⠀⠀⠀⡽⣰⢶⡼⠇⠀⠀⠀⠀⣠⣿⠟⠀
⠀⠀⠀⠀⠀⠀⠈⠳⢤⣀⡶⠤⣷⣅⡀⠀⠀⠀⣀⡠⢔⠕⠁⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠫⠿⠿⠿⠛⠋⠁⠀⠀⠀⠀




*/
