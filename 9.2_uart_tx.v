 `timescale 1ns / 1ps

// DEFINITELY check for bugs.

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
        default: next_state = IDLE; //send to idle immediately, will go to next states if needed.
    endcase
    end
    always @(posedge clk) begin
    
    if(rst)begin
        current_state <= IDLE;
        TxD <= 1'b0;
        state_UARDTX <= 1'b0; //statis
        clock_count <= 0;
        bit_index <= 0;
    end else begin
        current_state <= next_state;
    end
        case (next_state)
        
            IDLE: begin end //all values default.
            
            FREE: begin
            
                TxD <= 1'b1; //uart idle
                state_UARDTX <= 1'b1; //code idle ready for usage
                //reset in values for a fresh start
                clock_count <= 0;
                bit_index <= 0;
                
                if (clk_trigger == 1'b1) begin //controller trigger
                    saved_data <= data_in; //take data immediately to save
                    state_UARDTX <= 1'b0;//busy now
                end
                
            end
            
            
            SEND: begin
            //count once
                if (clock_count < BAUD_LIMIT) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                end
                
            //twice then work
                if (clock_count < BAUD_LIMIT) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                    
                    if (bit_index < 7) begin
                        TxD <= saved_data[bit_index]; //send out info
                        bit_index <= bit_index + 1; // move to next bit
                    end
                end
            end
            
            DOWN: begin
            
                TxD <= 1'b1; //stopping bit
                
                if (clock_count < BAUD_LIMIT) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                    next_state <= IDLE; //everything is complete so ship to idle
                end
                
            end
            
        endcase
    end
endmodule
