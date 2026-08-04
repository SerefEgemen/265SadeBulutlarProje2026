`timescale 1ns / 1ps
/*
This is the Main module. The module that links the board inputs to everything else using the constraint file.
And every module with others using their "I am finished" flags. This way each module works in tandem with one another.

For the detailed instructions on how individual modules work, check the modules themselves.

PS: All design sources have a tiny ASCII art at the end. This is done because
1) It gives our project a unique signature
2) It's funny
3) We're so tired as a 4 person group and need this slight bit of whimsy to keep going.

Group "Plain Clouds" (Sade Bulutlar):
Mete Sipahi
İpek Ceren Yılmaz
Meriç Şeref Gültekin
Şeref Egemen Yılmaz

You can also check out our Github Repository we made for this project and see the commit history:
https://github.com/SerefEgemen/265SadeBulutlarProje2026
*/


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
wire centerForConfigSpecifically;

/*
ThingsToDo broThinksHesPartOfTheTeam();
//Didn't want it be left alone whe it was with us since the beginning. I guess it can stay here as a comment.
*/

//Debouncing BTNC specifically for ConfigMenu. The rest is debounced with TusKontrolu
debounce dbC(btnC, clk, rst, centerForConfigSpecifically);

//Config Menu
wire hardMode;
wire elimination;
wire[3:0] playersIn;
wire[3:0] turnNo;
wire[3:0] currentTurn;
wire[15:0] ledsConfig;
wire confinish; //config is over
ConfigMenu configM(clk, rst, sw[2:0], sw[7:4], sw[9], sw[11], centerForConfigSpecifically, playersIn, turnNo, currentTurn, elimination, hardMode, confinish, ledsConfig);

//Debouncing other buttons
TusKontrolu buttons(clk, rst, playersIn, btnC, btnU, btnL, btnR, btnD, center, up, left, right, down);



//lfsr
wire[15:0] randVal;
lfsr16 lfsrModule(clk, rst, randVal);

//Wait time generator
wire[29:0] waitTime;
wire waitTimeValid;
random_delay_gen RNGesus(clk, rst, center, randVal, hardMode, waitTime, waitTimeValid);


//The Game Loop
wire gameOver;
wire turnOver;
wire displinish;
wire calcinish;
wire turnOffDisplay;
wire[29:0] p1Time, p2Time, p3Time, p4Time;
wire[3:0] timedOut, falselyStarted, allNaughtyBois;
wire[3:0] currentTurnNew;

gameLoop theMainTroublemaker(clk, rst, confinish, displinish, calcinish, turnNo, currentTurn, playersIn, up, down, left, right, center, p1Time, p2Time, p3Time, p4Time, timedOut, falselyStarted, currentTurnNew, gameOver, turnOver, turnOffDisplay);
assign currentTurn = currentTurnNew;


//7Segment Display
segmentDisplay7 countVonCount(clk, rst, currentTurn, turnOffDisplay, seg, an, displinish);

//Score Calculator

//Mid Game Score Calculator
wire[6:0] p1Total, p2Total, p3Total, p4Total;
wire[6:0] p1TotalNew, p2TotalNew, p3TotalNew, p4TotalNew;
wire[3:0] playersLeft;
wire[1:0] p1Place, p2Place, p3Place, p4Place; //for one round only, totals will determine the final order.
wire midCalcinish;
ScoreCalc calcIsShortForCalculatorBtw(clk, rst, elimination, gameOver, turnOver, 
p1Time, p2Time, p3Time, p4Time, timedOut, falselyStarted, playersIn,
p1Total, p2Total, p3Total, p4Total, p1Place, p2Place, p3Place, p4Place,
playersLeft, allNaughtyBois, p1TotalNew, p2TotalNew, p3TotalNew, p4TotalNew, midCalcinish);
assign p1Total = p1TotalNew;
assign p2Total = p2TotalNew;
assign p3Total = p3TotalNew;
assign p4Total = p4TotalNew;
assign playersIn = playersLeft;
//Endgame Score Calculator
wire[3:0] winners;
wire[6:0] winnerscore;
wire tie;
wire finalCalcinish;
ScoreCalcEndgame calcIsShortForCalculatorBtwButFinal(clk, rst, gameOver, playersIn, p1Total, p2Total, p3Total, p4Total, winners, winnerscore, tie, finalCalcinish);
assign calcinish = ((gameOver)? finalCalcinish : midCalcinish); //which Calculator am I using rn?
//LEDs
wire[15:0] ledsGame;
wire[15:0] ledsMidgame;
wire[15:0] ledsEndgame;
playerLEDs midgameLeds(clk, rst, gameOver, calcinish, p1Place, p2Place, p3Place, p4Place, playersIn, allNaughtyBois, ledsMidgame);
playerLEDsEndgame endgameLeds(clk, rst, gameOver, calcinish, winners, ledsEndgame);
assign dp = 1'b1; //turn off the decimal point
assign ledsGame = ((gameOver)? ledsEndgame : ledsMidgame); //game leds call scoreCalc or scoreCalcEndgame
assign led = ((confinish)? ledsGame : ledsConfig); //leds call Config or the mess one line above

//UART
wire[7:0] terminalData;
wire txStartSignal;
wire txFree;
//Controller
UART_Controller hadNoTimeToOverseeThis(clk, rst, gameOver, calcinish, txFree,
/*Inputs for MidGame Terminal output*/
currentTurn, playersIn, timedOut, falselyStarted,
p1Total, p2Total, p3Total, p4Total,
p1Time, p2Time, p3Time, p4Time,
p1Place, p2Place, p3Place, p4Place,
/*Inputs for Endgame Terminal output*/
winners, winnerscore, tie,
txStartSignal, terminalData);
//TX
UART_TX ughh(clk, rst, terminalData, txStartSignal, txFree, RsTx);


endmodule









































/*
            I AM SO CONFUSED AND TIRED AND I DON'T KNOW WHAT I'M DOING ANYMORE!!!!!!!
                                                                                                 
                                       ░░░░░░░░░░░░░░░                                           
                                   ░░░░█▓▓▓▓▓▓▓▓▓▓▓▓▓█░░░▒                                       
                                 ░░█▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓█░░░                                     
                               ░░█▓▓▓████████████████▓▓▓▓▓▓░░░                                   
                             ░░█▓▓██████████████████████▓▓▓▓█░░                                  
           ▒░░░░░░░         ░░▓▓███████████████████████████▓▓▓░░                                 
      ░░░░░░▒▓▓▓▒▒░░░░░░  ▒░░▓▓██████████████████████████████▓▓░░                                
    ░░█░░░░░░░░░░░░░░░░█░░░░▓██████████████████████████████████▓░░                               
   ░░░░░░░░░░░░░░░░░░░░░░█░█████████████████████████████████████▓░░                              
   ░░░░░░██░░░░█░░░░█▓░░░█████████████████████████████████████████░░         ░                   
    ░░▓░░░░░░░░░░░░░░░░░█░▓████████████████████████████████████████░░      ░░▒░▒                 
      ░░░██▓░░░░░░░██░░░░▒█████████████████████████████████████████▓░▓      ░▓█░░                
         ░░░░░░░░░░▒░░ ░░███████████████████████████████████████████░░     ░░▓██░░░              
                ░░░░░░░░░████████████████████████████████████████████░░░░░░█▓████▓░░             
                       ░░█████████████████████████████████████████████▓▓▓▓▓▓███████░             
                       ▒░▓█████████████████████████████████████████████████████████░░            
                        ░░█████████████████████████████████████████████████████████░░            
                        ░░███████████████████▓██▓████▒░░░██████████████████████████░░        ░░  
                         ░░███████████████████████░░░░░███████████████████████████▒░▒      ░░█░░ 
                     ░░░ ░░█████▒░░░░███████████▓░░░██████████████████████████████░░░░░░░░░█▓▓░░ 
                   ▓░▒▓▓░░░░████████████████████████████████████████████████████████▓███▓▓▓▓▓█░░ 
                   ░░███▓▓▓▓▓███████████████████████████████████████████████████████▓▓▓███████░░ 
                   ▒░▒████████████████████████████████████████████████████████████████████████░░ 
     ░░░░░▒         ░░███████████▓██████░░░░░░░░░░░░▓██░▒████████████████████████████████████░░  
   ░░█▓██▓░░░░░░░░░░░░░██▓▓▓░░░░▒▒▒▒▒▒██░░░░░░░░░░░░░█░░░░▒▒▒███████████████████████████████▓░▒  
  ░░░▓▓░░░░░░░░▓░░░░░░░░░░░░▓▓░▒▒▒██▓▒█░░░░░░░░░░░░░░░░░░░▒▒▒▒▒█████████████████████████████░░   
 ░░▒░▒░░░░░▓▒░▒░░░░▒░░░░░▓░░▓▓░░▒▒▒▒▒▒▒▓███████████████████████████████████████████████████░░    
 ░░░░░░░▓░░░░░░░▓░░░░░░░░░▒░▓▒▒▒▒█▒████▒▒████████████████████████████████████████████████░░░░    
 ░░▒▒▒▒▒▒▒▒▒▒▓▒▒▒▒▒▒▒▓▓▒▒▒▒▒▒▓█▒▒▒▒█▒██▒▒▒█████████████████████████████████████████████▒█▓░░     
 ▒░▒▒▒▒▒▒▒▓▒▒▒▒█▓▒▒▒▒▒▒▒▓█▓▒▒▒▒▓▒▒█▓▓▒▓▒▒▒▒████████████████████████████████████████████▓█░░      
   ░░█▒▒▒█░░░░░▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▓█▓█▒█▒▒▒▒▒████████████████████████████████████████████░░        
     ░░░░░░    ░░█▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒███████████████████████████████████████▓░░░          
                 ░░█▒░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒█████████████████████████████▓███████░░             
                  ░░█░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒█████████████████████████████▓███████░░            
                  ░░░█░░░░░░░░░░░░░░░░░░▒██████████████████████████████████████████░░            
                 ░░█████░░░░░░░░░░░░░░▓███████████████████████▓▓████████████████████░░           
               ░░▓████████▒░░░░░░░░░░██▒▒▒▒▒████████████████████▓███████████████▓███░░           
               ░░▓██░░░█░░░░░░░░░░░░░░░░░░░▒▒▒▒█████████████████████████████████▒████░░          
               ░░███░░░░░░░░░░░░░░░░░░░░░░░░░▒▒▒█████████████████▓███████████████████░░          
              ░░▓████▓███▒░░░░░░░░░░░░░░░░█████▓█████████████████████████████████████░░          
              ▒░▓██▓███████░░░░░░░░░░░░░░██████████████▓██████████████████████████████░░         
               ░░█████░░░░░░░░░░░░░░░░░░████████████████▓██████████████████████▓▒█████░░         
               ░░█████░█░░░░░░░░░░░░░░░▒█▒░▒▒▒▒▓█████████▓█████████████████████▓░█████░░         
               ░░▓████░░░░░░░░░░░░░░░░░░░░░░░▒▒████████████████████████████████▓░█████░░         
                ░░█████░░░░░░░░░░░░░░░░░░░░▒▒▒▒█████████████████████████████████░█████░░         
                 ░░███░░░░░░░░░░░░░░░░░░░▒▒▒▒▒▒████████████▓███████████████████░░█████░░         
                  ░░█▒░░░░░░░░░░░░░░░░░▒▒▒▒▒▒▒█████████████████████████████████░░█████░░         
                  ░░▓▒░░░░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▓████████████████████████████████▓░██████░░         
                 ░░█▒▒░░░░░░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒█████████████████████████████████░░██████░░         
                ░░▓▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████████████████████████████████░░██████░░          
                 ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░           
                                                                                                 


*/
