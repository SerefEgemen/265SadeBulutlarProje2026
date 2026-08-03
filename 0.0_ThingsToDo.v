`timescale 1ns / 1ps
/*
25/7/2026:
I've written this file as some sort of a map for us: It serves no other purpose 
-Mete

Things to do:

------------------------------------------------------------------------------------------------

1) Reset vs Game:

There is the SW15 (switch 15) on the Basys3 card. It will give 1 bit inputs.

SW15 = 0 => reset
SW15 = 1 => set

When set, The game configs will begin. And after the configs are done, the game will begin.

------------------------------------------------------------------------------------------------

2) Config:

Config needs 3 inputs and 8 bits in total.

1. Player Count (2 bits):
The game can be played by 2, 3, or 4, people. So 2 bits is enough.
playerCount = 00 => This Shouldn't Happen
playerCount = 01 => First option: 2 players
playerCount = 10 => Second option: 3 players
playerCount = 11 => Third option: 4 Players

2. Turn Count (4 bits):
The amount of turns is equal to the (exact bit counter + 1).
turnCount = 0000 => 1 turn
turnCount = 1111 => 16 turns
and everything in between.

3. Elimination Mode (1 bit):
The game loop should have this as an input so it can KILL players when the time comes!!!!!!!
eliminate = 0 => off
eliminate = 1 => on

4. Hard Mode (1 bit):
Not the game loop, but the thing that determines the times should have this as an input.
hardMode = 0 => Easy
hardMode = 1 => Hard


There are 16 switches on the board. (#5 on manual) We can assign these into the switches:
From left to right:

Switch 0, 1, and 2 = PlayerCount
1 = 01 / 2 = 10 / 3 = 11
Make it so only one of these switches can be pressed at the time. Turning on one should turn off the others
(If no switches are on, make the default value 01)

Switch 4, 5, 6, and 7 = turnCount
We can just make it so the turnCount 16 bit number is equal to [s5 s6 s7 s8].

Switch 9 = eliminate

Switch 11 = hardMode

And Switch 15 is already assigned as the set/reset switch.

I seperated the config switch groups by 1 so it looks more clean.

Btw: We also have to light up the LEDs above the switches if they are on.
(Don't turn on the LED if the switch is useless. Like Switch 16 or something) (#6 on manual)

Pressing the BTNC button (#7 on manual) saves the config settings and starts the first round.
This button also starts the other rounds.

------------------------------------------------------------------------------------------------

3) The Randomized Timer

We have to have a randomized timer. Why we need this is explained in Display.

A Lean Feedback Shift Register starts working after the game exits resets and does not stop. ever.
Unless it's on reset again, where the value should be 1

The LFSR shifts through the numbers in the background without showing us. (it should not become 0 when shifting)
When BTNC is pressed. The code will read what LFSR happened to be. And based on the hardMode input, will assign the randomized timer.

if(hardMode)
the timer should fall between 0.5 and 5.0 seconds.
if(!hardMode)
the timer should fall between 2.0 and 5.0 seconds.

(We can figure out the math for this later when we made the LFSR)


------------------------------------------------------------------------------------------------

4) The Display:

There are 4 numbers on the display. It's the rythm game part of this.
They light up one by one. Once they all light up. They will wait for the Waiting Time. And they will all turn off.
Once they turn off, the player should hit their buttons.

If the turn number is even, the numbers are 1 2 3 4
If the turn number is odd, the numbers are 5 6 7 8
We can track this with a single bit input or something

According to the manual they gave us: these lights have 7 bits each. So:
we have display1 display2, display3, display4.

They have a lightUp method, and a lightOff method
The main souce that manages lights will call these methods:
display1.lightUp => wait 1 second => display2.lightUp => wait 1 second => 
display3.lightUp => wait 1 second => display4.lightUp => wait the random time =>
all lights turn off and the score calculating begins

display1's lightUp:
if(even)
7'b(1001111) [1]
if(!even)
7'b(0100100) [5]

display2's lightUp:
if(even)
7'b(0010010) [2]
if(!even)
7'b(0100000) [6]

display3's lightUp:
if(even)
7'b(0000110) [3]
if(!even)
7'b(0001111) [7]

display4's lightUp:
if(even)
7'b(1001100) [4]
if(!even)
7'b(0000000) [8]

lightOff for all displays is just
7'b(1111111) [No number/off]

------------------------------------------------------------------------------------------------

5) Player Buttons and LEDs:

There are 5 cardinal buttons on the board: (#7 on manual)

BTNU: Player1 (Up button)

BTNL: Player2 (Left Button)

BTNR: Player3 (Right Button)

BTND: Player4 (Down Button)

BTNC: used for config and game start stuff. (Center button)

If the player number is less than 4, the unused button inputs should be don't care.

We also need to figure out what debounce is. Since "All button inputs need to be Debounced".


All players also have the previously mentioned LEDs assigned to them after config is over.
Player1 = LED0, 1, 2, 3
Player2 = LED4, 5, 6, 7
Player3 = LED8, 9, 10, 11
Player4 = LED12, 13, 14, 15

When a game turn is over, the player placements for that round (not the total) indicate how many LEDs are on.
1st place = 4 lights
2nd = 3 lights
3rd = 2 lights
4th = 1 light.

After all turns are done, only the total winner's lights are on.

------------------------------------------------------------------------------------------------

6) The Game Loop

After the display lights go out. (the randomized timer thing), each player must hit the button as fast as possible.

Start a counter that tracks how many miliseconds have passed for each player.
Stop each player's counters as they press the button.
Compare the stop times. Lesser value = higher placement.

1st place gets 4 points
2nd = 3 points
3rd = 2 points
4th = 1 point.

If two players press at the exact same milisecond, it's a tie and they get the same point.
We must also keep track of the total points after each round. Because it will be needed.

(Also I was wrong. Elimination does not eliminate the last place. It only does stuff for the penalties.)

------------------------------------------------------------------------------------------------

7) Penalty

There are two penalties that can happen on the game loop.

1. False Start:
If a player presses the button before the display lights turn off.

2. Timeout:
If a player does not press the button for 5 seconds after the lights turn off.

If any of these penalties happen, the player gets 0 points.
If Elimination Mode is active, they are also removed from the game. So their button inputs become don't care.
(So, we must also add a seperate win condition: If only one player is left, the game is over and that player wins)

We must keep track of which penalty was triggered. It is wanted on display
Which players fell to False Start
Which players fell to Timeout.

------------------------------------------------------------------------------------------------

8) UART output

After each round, some info about that round is displayed on the terminal with UART (we need to learn what this is)

The settings for UART:
Baud Rate: 9600
Data Format: 8N1 (8 data bits, no parity, 1 stop bit)

Info required to display after each round is over:
Turn number
Each player's reaction time
False Start penalties
Timeout penalties
Turn scores
Total scores

Eg:
Turn 4
Player1 = 234ms
Player2 = 411ms
Player3 = NA
Player4 = 100ms

False Start = 
Timeout = Player3

Turn Scores:
Player1 = 3
Player2 = 2
Player3 = 0
Player4 = 4

Total Scores:
Player1 = 10
Player2 = 7
Player3 = 2
Player4 = 3

After all turns are over, display the player who won
Eg:
Winner = Player1

If there's a tie on the final scores, Show the tie and their scores (No need to show the score if no tie)
Eg:
Winner = It's a tie! [Player1, Player2, Player3] (Score: 25)

------------------------------------------------------------------------------------------------

As a summary, our tasks are:

1) Reset switch / the main game file that connects everything else
2) Config menu before the turns start
3) The randomized timer for the quick-time event using LFSR
4) The 7-Segment number display (quick-time event)
5) Assigning the players their buttons and LEDs (and lighting up the correct ones)
6) The main game loop and score calculation
7) The penalties and elimination
8) The game info display using UART



2/8/2026:

Stuff we need to do after a week has passed:

Remaining modules needed:
UART_Controller (need to display all the correct info)
UART_TX

(and TestBenches?)

--------------------------------------------

Modules needing ASCII art:
TusKontrolu
lfsr16
random_delay_gen

(and testBenches)

--------------------------------------------

Other:
PDF file, or updating Main's comment

--------------------------------------------

3/8/2026:
One day before the deadline.

Who did what:
Design Sources:
Main                    Mete
ConfigMenu              Mete
debounce                Meriç
TusKontrolu             Meriç
lfsr16                  Egemen
random_delay_gen        Egemen
gameLoop                İpek
segmentDisplay7         Meriç
ScoreCalc (& Endgame)   Mete
playerLEDs (& Endgame)  Mete
UART_Controller         Egemen
Binary_to_BCD           Egemen
UART_TX                 İpek

Constraints:
basys3Assigning         Digilent (Mete copied it from their official Github Account, They hope this is allowed since it's not a module)

Simulation Sources:
random_delay_gen_tb     Egemen


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

















I think that's all. So here's an ASCII art of Sans Undertale:
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣰⣶⣶⣶⣶⣶⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣾⣿⡿⠿⠿⢿⣿⣿⣿⡿⠿⠿⢿⣿⣷⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⣿⠁⠀⢀⡀⠀⣿⣿⣿⠀⢀⡀⠀⠈⣿⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠙⣦⣄⡀⠀⣰⡟⠀⢻⣆⠈⢀⣠⣴⠊⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⢰⡟⠋⡓⢾⣿⣧⣤⣼⣿⣷⠺⠉⢻⡆⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢀⣀⠈⢿⣷⣀⡳⠆⣶⢰⣶⢰⠆⣠⣾⡿⢁⣠⣄⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠛⠻⠶⣄⡉⠛⠻⠶⠶⠶⠶⠶⠞⠛⠉⣰⡾⠋⠐⢀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢀⠀⠈⠁⡶⠀⠐⣶⣶⡆⡀⣀⠠⠒⠋⠀⡀⠀⠈⢃⡀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⡇⣰⠀⣤⣥⡀⣸⣨⠀⠀⠀⣠⡆⠀⠀⠀⢱⡀⠀⠀
⠀⢠⡆⠀⠀⠀⡘⠓⠉⠁⢰⡠⡆⣿⣿⡇⡯⢴⢠⠐⠋⠁⢣⠀⠀⠀⠈⠁⠀⠀
⠀⠀⠑⠆⡀⠀⡇⠀⠀⠀⠘⡐⡇⣿⣿⡇⡗⣎⠎⠀⠀⠀⢸⠀⠀⢀⡰⠂⠀⠀
⠀⠀⠀⠀⠛⠀⣷⣄⣀⣀⣀⠷⠷⠖⠒⠒⠳⠧⠀⠠⠤⢤⡞⠠⠖⠈⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⡀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⣤⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢸⠀⣾⠁⠀⠀⠀⢠⢢⠀⠀⠀⣿⡀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⡆⢰⡏⠀⠀⠀⠀⡼⠈⡆⠀⠀⢿⡇⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠇⠸⠇⣀⣀⣀⣀⠇⠀⠇⣀⡀⢸⣇⣀⠀⠸⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢀⣀⡀⠀⣀⡀⠀⠀⠀⠀⠀⠀⢠⣀⣀⣀⠀⢀⣀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢰⣿⣿⣿⣷⡘⣃⠀⠀⠀⠀⠀⢀⣛⣛⡛⣴⣾⣿⣿⣿⠆⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

*/


module ThingsToDo();
endmodule












































































/*
PS:⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ 
if anyone used AI generated code for a module and committed academic misconduct, please do not punish the entire group. I warned everyone several times about not using it. 
So, here I am, hiding my comment under this useless module, hoping other people will be distracted by the ASCII art or just won't check this module.
You can determine who coded what by looking at this module.
And if anyone from group sees this, I am so sorry! I'm just scared. And I have told you to not copy-paste AI code!
I will delete this comment when all code I suspect is AI is gone.
-Mete Sipahi
*/
