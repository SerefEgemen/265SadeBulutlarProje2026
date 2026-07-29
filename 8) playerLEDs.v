`timescale 1ns / 1ps
/*
inputs:

player1Place (2 bits)
player2Place (2 bits)
player3Place (2 bits)
player4Place (2 bits)
    Gets these after the current turn is over. Lights the leds depending on the placement
    00 = first place = 4 leds
    01 = second place = 3 leds
    10 = third place = 2 leds
    11 = fourth place = 1 led
    if there are less than 4 players, these inputs are unused. The module using it can just dump them as anything it wants. (Don't care)

playersIn (4 bits)
    Checks if these players are in the game. If there are less than 4 players, or some players are eliminated. the inputs for them become 0
    playersIn[0] = is player1 in the game or not
    playersIn[1] = is player2 in the game or not
    playersIn[2] = is player3 in the game or not
    playersIn[3] = is player4 in the game or not

clk (1 bit)
rst (1 bit)
    classic

gameOver (1 bit)
    if the game is over, only light the winning player's lights
winner (2 bits)
    who won the entire game? only here for the gameOver scenario. has to be compared and figured out elsewhere. If the game is not over yet. Don't care
    00 = player1
    01 = player2
    10 = player3
    11 = player4

outputs:
leds (16 bits)
    the led displays.

This module only displays the lights. Whatever's calculating the scores after the turn is over has to give this the placements for it to light the lights
The previous turn's lights stay lit until the next turn is over.

*/


module playerLEDs(input clk, rst, input[1:0] player1Place, player2Place, player3Place, player4Place, input[3:0] playersIn, input gameOver, input[1:0] winner,
output reg[15:0] leds
    );
    
    reg[3:0] player1Leds;
    reg[3:0] player2Leds;
    reg[3:0] player3Leds;
    reg[3:0] player4Leds;
    //changes these 4 values depending on the placements. So the LED assigning code is smaller
    
    always@ (posedge clk) begin
    
    if(rst) begin
    player1Leds <= 4'b0;
    player2Leds <= 4'b0;
    player3Leds <= 4'b0;
    player4Leds <= 4'b0;
    leds <= 16'b1000_0000_0000_0000; //only the reset light is on
    
    end//of reset
    else begin
    
    if(gameOver) begin //the game is over. Displaying only the winner
    case(winner) //who is the final winner? This value is irrelevant if the final turn isn't over
    //We don't need to know if there are less than 4 players here. winner won't be affected by that.
    4'b00: begin//Player1 won the game
    player1Leds <= 4'b1111;
    player2Leds <= 4'b0000;
    player3Leds <= 4'b0000;
    player4Leds <= 4'b0000;
    end
    4'b01: begin//Player2 won the game
    player2Leds <= 4'b1111;
    player1Leds <= 4'b0000;
    player3Leds <= 4'b0000;
    player4Leds <= 4'b0000;    
    end
    4'b10: begin//Player3 won the game
    player3Leds <= 4'b1111;
    player2Leds <= 4'b0000;
    player1Leds <= 4'b0000;
    player4Leds <= 4'b0000;    
    end
    4'b11: begin//Player4 won the game
    player4Leds <= 4'b1111;
    player2Leds <= 4'b0000;
    player3Leds <= 4'b0000;
    player1Leds <= 4'b0000;    
    end
    endcase
    end//of the "game is over"
    
    else begin //the game is not over, displaying the 4 placements
    
    //player1
    if(playersIn[0]) begin //The player is playing
    case(player1Place)
    2'b00: begin
    player1Leds <= 4'b1111; //1st place, 4 lights
    end
    2'b01: begin
    player1Leds <= 4'b0111; //2nd place, 3 lights
    end
    2'b10: begin
    player1Leds <= 4'b0011; //3rd place, 2 lights
    end
    2'b11: begin
    player1Leds <= 4'b0001; //4th place, 1 light
    end
    endcase //repeat this for the other 3 players. Draws are also possible with this
    end
    else begin //The player is not playing. Either eliminated or the game was started with less players
    player1Leds <= 4'b0000;
    end
    
    //player2
    if(playersIn[1]) begin
    case(player2Place)
    2'b00: begin
    player2Leds <= 4'b1111;
    end
    2'b01: begin
    player2Leds <= 4'b0111;
    end
    2'b10: begin
    player2Leds <= 4'b0011;
    end
    2'b11: begin
    player2Leds <= 4'b0001;
    end
    endcase
    end
    else begin
    player2Leds <= 4'b0000;
    end
    
    //player3
    if(playersIn[2]) begin
    case(player3Place)
    2'b00: begin
    player3Leds <= 4'b1111;
    end
    2'b01: begin
    player3Leds <= 4'b0111;
    end
    2'b10: begin
    player3Leds <= 4'b0011;
    end
    2'b11: begin
    player3Leds <= 4'b0001;
    end
    endcase
    end
    else begin
    player3Leds <= 4'b0000;
    end 
      
    //player4
    if(playersIn[4]) begin
    case(player4Place)
    2'b00: begin
    player4Leds <= 4'b1111;
    end
    2'b01: begin
    player4Leds <= 4'b0111;
    end
    2'b10: begin
    player4Leds <= 4'b0011;
    end
    2'b11: begin
    player4Leds <= 4'b0001;
    end
    endcase
    end
    else begin
    player4Leds <= 4'b0000;
    end
    
    end//of "the game is not over"
    
    //LEDS
    leds[0:3] <= player1Leds;
    leds[4:7] <= player2Leds;
    leds[8:11] <= player3Leds;
    leds[12:15] <= player4Leds;
    
    end
    
    end//of clock
                
endmodule






























































































































/*

                                                                                 
                                                                                 
                                                                                 
                            .*@@@@@@@@@:                                         
                        *@@@@@@@@@@@@@@@@@@.                                     
                      @@@@@@@@@@@@@@@@@@@@@@@                                    
                    @@@@@@@@@@@@@@@@@@@@@@@@@@                                   
                  .@@@@@@@@@@@@@@@@@@@%=+@@@@@.                                  
                 :@@@@@@@@@@@+          @@@@@@.                                  
                 @@@@@@@@@@             @@@@@@.                                  
                +@@@@@@@@@              @@@@#@                                   
                @@@@@@@@@@#@@#:   .@@%  @@@# @                                   
                @@@@@@@@*      :@@#      @@  @                                   
                @@@@@@                   @.  #                                   
         =####=:@@@@@*  #@@@#**.        .+   =@@+.                               
      -@-       #@@@+*%@-       .@@-:-@@@    #   :@@=                            
     @*             @@@        ##@@#   @@            .@@=                        
    %+            %+          .@@@@@@# =@                .*@%:                   
    @    =@@@*   %:           @@@@@@@@@ @                     +@@+               
    @  @%     *@**            @@@@@@@@@@@-                        :%@=           
   -%-@.        @.           #@@@@@@@@@@+@.                            %@+       
    @@          %         +@   .@@@@@@@@  @:                              =@%.   
    *@          %*       %-       =%@@#    %#        #%@@@@@@@@@%%%%@%#----...   
           :.#@@ #+      #     %@@@@@@@@@@@..@:      @                           
           #@.     @%.   @   :%   :@           =@=   @.                          
             .:.@. @@@@@@@@. @@@@@@..@@.        @@@@ *+                          
                 @*@:       @@     @  :=         .@@@@@                          
                  .-@                 =-@@@  @@@@@@@@@@                          
                   *+   -- -          @@@@@++@@@@@@@@@@                          
                  =@    ::::           @@@@@@@@@@@@@@@                           
                  @                   .@@@@@@@@@@@@@@                            
                 *#                   :@@@@@@@@@@@@:                             
                 @.                    :@@@@@@@@+                                
                 @                       @-                                      
                =@                        +@                                     
                =@                          @.                                   
                 @                           +@                                  
                 @                             @                                 
                 %=                           :*                                 
                 :@                          .#                                  
                  *=                        @=                                   
                   @                      @*                                     
                    +@#-              .@@-                                       
                           *@@@@@@@@=  @.                                        
                             @          *%                                       
                              @          @                                       
                             +*          @                                       
                             .                                                   
                                                                                 
                                                                                 
START AGAIN START AGAIN START AGAIN START AGAIN START AGAIN START AGAIN START AGAIN START AGAIN START AGAIN START AGAIN                                                                                
                                                                                 



*/
