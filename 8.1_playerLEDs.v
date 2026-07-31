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
    
playersPenalized (4 bits)
    same thing as playersIn. But if the elimination Mode isn't active, we have to make a distinction

clk (1 bit)
rst (1 bit)
    classic

outputs:
leds (16 bits)
    the led displays.

This module only displays the lights. Whatever's calculating the scores after the turn is over has to give this the placements for it to light the lights
The previous turn's lights stay lit until the next turn is over.

The final LED placement uses a different module.

*/


module playerLEDs(input clk, rst, input[1:0] player1Place, player2Place, player3Place, player4Place, input[3:0]playersIn, playersPenalized,
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
    
    //player1
    if(playersIn[0]) begin //The player is playing
    if(playersPenalized[0]) begin //the player got penalized but not eliminated. This is specifically here because the elimination mode can be off.
    player1Leds <= 4'b0000;
    end else begin
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
    end
    else begin //The player is not playing. Either eliminated or the game was started with less players
    player1Leds <= 4'b0000;
    end
    
    //player2
    if(playersIn[1]) begin
    if(playersPenalized[1]) begin
    player2Leds <= 4'b0000;
    end else begin
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
    end
    else begin
    player2Leds <= 4'b0000;
    end
    
    //player3
    if(playersIn[2]) begin
    if(playersPenalized[2]) begin
    player2Leds <= 4'b0000;
    end else begin
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
    end
    else begin
    player3Leds <= 4'b0000;
    end 
      
    //player4
    if(playersIn[3]) begin
    if(playersPenalized[3]) begin
    player2Leds <= 4'b0000;
    end else begin
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
    end
    else begin
    player4Leds <= 4'b0000;
    end
    
    //LEDS
    leds[3:0] <= player1Leds;
    leds[7:4] <= player2Leds;
    leds[11:8] <= player3Leds;
    leds[15:12] <= player4Leds;
    
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
