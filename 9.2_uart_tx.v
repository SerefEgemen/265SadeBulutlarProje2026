 `timescale 1ns / 1ps

/* 
update 1 patch notes:
-explanations added
-a system for preventing data leak vbvb. was added in case of rst mid transmission
-1 unnecessary clock deleted, only 2 grace-periods exist now: pre-transmission and post-transmission. this clock can be edited to be lowered in case of slowness etc.
-cleaned up a bit of code
-ascii art baptism has been added. welcome to the family uart_fx

patch 1.1:
-syntax errors checked. 1 found: i wrote saved_date instead of saved_data in line 138.
-actually finished my explanation in FREE - i apparently forgot the first time
-changed bit index to 8 from 7. because it needs to. send the 7th one. you know. the 8th bit. life-changing revelation right there
-checked uart.v . tx_start seems to be my clk_trigger. tx_start changes happen after the transmission is Done done, so, my logic seems to be correct. rejoice

THINGS TO DO:
my code gives out 0 when busy, and 1 when free. uart.v seems to get the opposite. lets check the logics and see if they align before we ship this out
definitely should be checked. making sure.
*/

module UART_TX (
    input clk, rst,              
    input [7:0] data_in,
    input clk_trigger,
    
    output reg TxD, //output bit
    output reg state_UARDTX //to communicate with controller
);

    reg [13:0] clock_count = 0;
    // to limit baud rate in code
    reg [2:0] bit_index = 0;
    // to send bits per index
    reg [7:0] saved_data = 0;
    // to limit changes to data_in per cycle/mid transmission


    // 9600 baud rate -> 10417 cycles per bit max
    localparam BAUD_LIMIT = 14'd10416; 
    
    //states for fsm + setup
    
    reg [1:0] current_state, next_state;

    localparam IDLE = 2'b00;
    localparam FREE = 2'b01;
    localparam SEND = 2'b11;
    localparam DOWN = 2'b10;
    //also used gray code system here. i think its neat
    
    always @(*) begin
    //prevent latches
    next_state = current_state;
    
    case(current_state)
        IDLE: if(!rst) next_state <= FREE; 
        FREE: if(!state_UARDTX) next_state <= SEND;
        SEND: if(bit_index == 8) next_state <= DOWN; 
        DOWN: ; //will auto send inside the code case. it's a counting down machine. send does it before sending data too
        default: next_state = IDLE; //send to idle immediately, will go to next states if in those states of course.
    endcase
    end
    always @(posedge clk) begin
    
    if(rst)begin
        current_state <= IDLE;
    end else begin
        current_state <= next_state;
    end
        case (next_state)
        
            IDLE: begin 
            TxD <= 1'b1;
            //this bit is in HIGH position when in idle, to be able to tell apart wire damages etc. 
            state_UARDTX <= 1'b0; //statis
            clock_count <= 0;
            bit_index <= 0;
             
            /*
            ## explanation for the if usage below ##
            for detailed introduction to logic, head to FREE for the explanation part.
            the code below allows me to reset everything up if the controller check is failed. i do this so that the code does not get locked up,
            in a state of rst > !clk_trigger > !rst, which was the weakness of saving data up until patched here.
            after rst, the code automatically goes to FREE. in rst, if clk_trigger is gone, so is the data.
            */
             
            if((saved_data != 0) && !clk_trigger)begin
            saved_data <= 0;
            bit_index <= 0;
            end
            end //all values default.
            
            FREE: begin
            
                TxD <= 1'b1; //uart idle still
                state_UARDTX <= 1'b1; //code idle -> free - module ready for usage
             
                //reset values for a fresh start
                clock_count <= 0;
                bit_index <= 0;
             
                /*
                Explanation for Code Below
                in here, we get our data into an array for it to not change or get altered mid transmission, and to be able to transit the first taken data fully.
                in the DOWN period, the system resets saved_data back to 0 to wipe out and get ready for another transmission.
                this allows us to return to transmitting data even if statis mode is called mid-transmission, and it will be able to continue onwards without any data leaks.
                basically, if a transmission is interrupted, we continue onwards after the error is gone.
                */
             
                if (clk_trigger == 1'b1) begin //controller trigger
                 if(saved_data == 0) begin
                    saved_data <= data_in; //take data immediately to save
                 end
                    state_UARDTX <= 1'b0;//busy now
                end
                
            end
            
            
            SEND: begin 
             //the clock is here to give the receiver a time frame to get ready for the next frame. 
                if (clock_count < BAUD_LIMIT) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                    
                 if (bit_index < 8) begin
                        TxD <= saved_data[bit_index]; //send out info
                        bit_index <= bit_index + 1; // move to next bit
                    end
                end
            end
            
            DOWN: begin
            
                TxD <= 1'b1; //stopping bit
                
                if (clock_count < BAUD_LIMIT) begin
                    clock_count <= clock_count + 1; //same thing here. time frame for all devices to have a breathing room. 
                end else begin
                    clock_count <= 0;
                    saved_data <= 0;
                    next_state <= IDLE; //everything is complete so ship to idle
                end
                
            end
            
        endcase
    end
endmodule

/*

⠀⠠⢀⠰⣰⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿
⠀⡁⠂⠔⡹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿
⠀⠄⠡⡈⣔⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⢿⣿⡿⡿⠿⢿⣿⣿⣿⠿⢿⡿⠿⠿⣿⣿⣿⡿⢿⣿⣿⣿⣿⣿⣿⣿⣿
⠀⠌⡁⢒⡹⣿⣿⣿⣿⠟⢛⣉⣩⣩⣭⡥⣶⣤⣧⣤⣤⣾⡁⠂⢶⣶⡿⣀⣰⣯⣬⣶⡟⠀⣾⢾⠆⣠⣯⣭⣷⠆⠈⠩⡍⠙⠛⢿⣿⣿
⠀⢂⠐⢤⣃⣿⣿⣿⣿⢸⣷⣾⠿⢿⡋⢐⣠⣿⣷⣿⣾⣄⠐⠂⠨⠟⠛⡿⣹⠟⠫⡧⠈⢓⣥⣶⣶⣶⣮⡭⠓⠀⠀⠻⣿⠁⡆⢸⣿⣿
⣼⣄⢧⣿⣿⣿⣿⣿⣿⡇⣼⡇⠀⡄⣿⣼⣿⣿⣿⣿⣿⣿⠃⠀⠀⠀⠀⠛⠻⡄⢀⠿⣣⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠘⠄⠀⣧⣿⣿
⠐⡌⣻⣿⣯⣷⣿⣿⣧⢋⣿⣯⣴⣾⣿⣿⣿⣿⡿⠿⢿⠯⡐⢀⢻⡄⠀⠀⠀⠙⠸⣿⣿⣿⣿⣿⡿⠟⠿⠟⡀⢡⣃⠀⠀⠁⠀⢹⣿⣿
⠈⡔⢠⢳⢿⣿⣿⣿⣟⡬⣿⣟⠀⣿⣿⣿⡿⠁⠀⠀⠀⠀⠢⢡⠸⣗⠀⠀⠀⠀⣸⣿⣿⣿⣿⠇⠀⠀⠀⠀⠐⡀⢻⡆⠀⠀⠁⣔⣿⣿
⡐⢌⠢⢌⠻⣿⣿⣿⣿⡷⢻⢷⡇⣿⣿⣿⠁⠀⠀⠀⠀⠀⠀⠃⣺⠏⠀⢀⣤⠀⢹⣿⣿⡿⠏⠀⠀⠀⠀⠀⠀⠀⣹⡇⠀⠀⢘⣿⣿⣿
⣘⢤⢓⣾⣿⣿⣿⣿⣿⠿⣼⣟⠠⢺⣿⣿⡄⠀⠀⠀⠀⠀⠀⣨⠋⠀⢀⣿⡯⠄⠀⠙⣿⣧⡀⠀⠀⠀⠀⠀⠀⢀⡿⠀⠀⠀⢸⣿⣿⣿
⣽⣞⡧⣿⣻⣿⣿⣿⣿⣬⢻⣷⣴⠳⣿⣿⣿⣦⣄⡀⡀⠔⢊⣁⡴⠊⣹⡿⢅⡈⠄⠀⠈⠻⠿⠦⡄⡀⢀⠀⠄⠋⠁⠀⠀⠀⢀⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡜⡟⣽⣷⣿⣿⡿⢿⣾⡷⠯⢟⠫⠋⠒⠁⢸⣽⠆⡐⠀⠀⠀⠀⠰⠓⠒⠒⠒⠀⠀⠀⠀⠀⠠⠠⣼⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢓⣷⠟⣫⠻⣿⣿⣷⣦⣠⡦⠕⠂⠀⢀⣠⣴⣟⡀⠄⠀⠀⠀⠀⠀⠀⢄⣀⡀⡀⣀⡐⠈⠰⠠⠉⣾⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⢻⢸⠸⠭⡞⠿⣿⣿⡿⠛⠀⠌⠒⣰⣿⣿⣿⣿⣷⣄⠀⠀⡀⠀⠀⠈⠀⠀⠋⠛⢿⡿⣯⡆⡇⢉⣾⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣇⣿⣄⠚⢙⣻⠋⠋⡡⠋⠀⣦⣼⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⣀⠀⠁⠀⠁⠀⠂⠀⠉⠻⠟⡇⢸⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢱⣿⡇⣿⣿⡇⢹⠆⣱⠀⢀⣿⣿⣿⡿⠿⠉⠉⠁⠈⠉⠉⠹⠿⣶⠀⠀⠀⠸⣷⣆⢷⡀⠀⢀⢸⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣟⣿⣧⢽⡧⣿⣿⡁⠀⠖⠀⢀⣜⠟⠋⠁⣀⣤⣤⡄⢠⣤⣤⡀⠀⠀⠈⠑⠀⠀⠀⢛⣿⣿⠫⠃⡀⣴⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣮⣻⣼⡿⣸⣿⠆⠀⡀⢢⣿⠏⠀⣠⣶⣿⣿⡿⠿⠸⠿⠟⠄⢠⣶⠀⠀⠀⠀⠀⠈⠋⠉⣵⠰⠁⢿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⣏⠟⠉⢸⣿⣿⢿⠃⠀⠘⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⡿⠀⢰⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠹⣿⢃⢰⣼⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢹⣿⣿⡿⢟⣉⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡄⠀⠀⠠⠀⠀⠠⣻⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢸⣿⡇⡠⣼⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⡃⠀⠀⠀⠀⠀⣸⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡆⣿⣆⣩⣞⣹⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⢴⢶⡂⠀⠀⠀⠀⠀⣿⠁⠀⠀⢠⡿⠀⠘⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡏⣿⡿⠟⠙⣿⣿⣧⠀⠀⠀⠀⠀⢠⣰⠲⠀⢠⡆⠈⡄⠀⠀⠐⠀⠰⣿⠀⠀⠶⠛⣇⠀⠱⣿⣿⣿⣿⣿
⣿⣷⣽⢻⣿⡝⣿⣿⣿⣿⣿⣷⣙⢁⣄⣠⣾⣻⣿⠀⠀⠀⠀⠀⣺⢧⠆⠁⢲⠍⣏⠀⡀⠀⠀⠀⢰⡏⠀⠀⠀⣸⠇⠀⣼⣿⢿⠿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⢺⣿⣿⣿⡏⠀⡟⡅⠀⠀⠀⠀⡎⡟⠊⠀⠈⣷⠈⠁⡄⠀⠀⠀⣿⠁⠀⠀⠀⠀⠀⠀⣾⣿⣧⣷⣾⣿
⣿⣿⣿⣿⣿⣟⣿⣿⣿⣿⣿⡇⢺⠛⠏⠉⢧⢤⣷⣿⠀⠀⠀⠀⣣⡘⠅⠀⢠⠗⡞⡰⠀⠀⠀⢀⡏⠀⠀⢠⠀⠀⡐⠀⠸⣼⠿⣿⣿⣿
⣽⢾⣽⢻⣟⢿⡻⣾⣿⣿⣿⠭⣾⣷⣦⣿⡟⠈⢈⣽⣦⠀⠀⠀⡏⡈⡅⠀⢸⣃⣁⠖⡁⠀⠀⠈⠀⠀⠀⠰⠿⡿⠕⠀⢱⣭⢍⡟⣿⢿
⢎⡷⣸⢳⣏⢾⡱⣻⢯⠻⣝⣓⠝⠋⠙⠋⠀⠘⢿⠩⠿⣷⣄⡀⢼⡷⠀⠀⢸⣿⣦⡤⠐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⣽⢿⡾⣿⣿⢿
⣯⠰⣉⠗⢮⡓⠧⡙⢮⠓⡸⣹⠆⣷⣤⡀⠀⣀⣠⣶⣤⣦⣝⡓⢯⡒⠁⠀⢸⣿⠯⡕⠂⠀⠀⠀⠀⠀⠀⠀⠴⠖⠂⠐⣛⣯⢫⡸⢯⣏
⢦⡱⣀⠊⠴⡁⢎⡱⠌⡈⠅⡌⢡⣏⣩⣍⢭⣩⢉⣉⣉⠍⣉⠍⣷⡍⠀⠀⢸⣿⣿⡥⡐⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠟⡴⢫⡏⠘⠌

*/
