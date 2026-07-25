module i2c_master (
    input  wire       clk_i, 
    input  wire       rst_i,          
    input  wire       m_w_r_i,        
    input  wire       m_start_i,     
    input  wire       m_stop_i,       
    input  wire [6:0] m_slv_add_i,    
    input  wire       m_ack_i,      
    input  wire [7:0] m_data_i,     
    output reg  [7:0] m_data_o,       
    output reg        m_busy_o,       
    output reg        m_error_o,      
    output reg        m_data_ready_o, 
    inout  wire       sda,           
    output reg        sca             
);
    parameter IDLE       = 4'd0;
    parameter START      = 4'd1;
    parameter ADDR       = 4'd2;
    parameter ADDR_ACK   = 4'd3;
    parameter WRITE_DATA = 4'd4;
    parameter WRITE_ACK  = 4'd5;
    parameter READ_DATA  = 4'd6;
    parameter SEND_ACK   = 4'd7;
    parameter STOP       = 4'd8;
    reg [3:0] state;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
    reg       sda_out;
    reg       sda_oe; 
    assign sda = (sda_oe) ? sda_out : 1'bz;
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            sca <= 1'b1;
        end else begin
            if (state == IDLE) begin
                sca <= 1'b1;
            end else begin
                sca <= ~sca; 
            end
        end
    end
    always @(posedge clk_i or negedge rst_i) begin
        if (!rst_i) begin
            state          <= IDLE;
            m_busy_o       <= 1'b0;
            m_error_o      <= 1'b0;
            m_data_ready_o <= 1'b0;
            m_data_o       <= 8'd0;
            sda_out        <= 1'b1;
            sda_oe         <= 1'b1;
            bit_cnt        <= 3'd7;
            shift_reg      <= 8'd0;
        end else begin
            case (state)

                IDLE: begin
                    sda_out        <= 1'b1;
                    sda_oe         <= 1'b1;
                    m_busy_o       <= 1'b0;
                    m_data_ready_o <= 1'b0;
                    m_error_o      <= 1'b0;

                    if (m_start_i) begin
                        m_busy_o <= 1'b1;
                        state    <= START;
                    end
                end

                START: begin
                    
                    sda_out   <= 1'b0;
                    shift_reg <= {m_slv_add_i, m_w_r_i};
                    bit_cnt   <= 3'd7;
                    state     <= ADDR;
                end

                ADDR: begin
    
                    if (sca == 1'b0) begin
                        sda_out <= shift_reg[bit_cnt];
                        sda_oe  <= 1'b1;
                    end
                    else begin
                        if (bit_cnt == 3'd0) begin
                            state  <= ADDR_ACK;
                            sda_oe <= 1'b0; 
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                ADDR_ACK: begin
                    if (sca == 1'b1) begin
                        if (sda == 1'b1) begin
                            m_error_o <= 1'b1;
                            state     <= STOP;
                        end else begin
                            bit_cnt <= 3'd7;
                            if (shift_reg[0] == 1'b0) begin 
                                shift_reg <= m_data_i;
                                state     <= WRITE_DATA;
                            end else begin 
                                state     <= READ_DATA;
                            end
                        end
                    end
                end

                WRITE_DATA: begin
                    if (sca == 1'b0) begin
                        sda_out <= shift_reg[bit_cnt];
                        sda_oe  <= 1'b1;
                    end else begin
                        if (bit_cnt == 3'd0) begin
                            state  <= WRITE_ACK;
                            sda_oe <= 1'b0;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end
                WRITE_ACK: begin
                    if (sca == 1'b1) begin
                        if (sda == 1'b1) begin
                            m_error_o <= 1'b1;
                        end
                        if (m_stop_i) begin
                            state <= STOP;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end

                READ_DATA: begin
                    sda_oe <= 1'b0; 
                    if (sca == 1'b1) begin
                        shift_reg[bit_cnt] <= sda; 
                        if (bit_cnt == 3'd0) begin
                            state <= SEND_ACK;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end

                SEND_ACK: begin
                    if (sca == 1'b0) begin
                        sda_oe  <= 1'b1;
                        sda_out <= m_ack_i;
                    end else begin
                        m_data_o       <= shift_reg;
                        m_data_ready_o <= 1'b1;
                        if (m_stop_i) begin
                            state <= STOP;
                        end else begin
                            state <= IDLE;
                        end
                    end
                end

                STOP: begin
                    if (sca == 1'b0) begin
                        sda_oe  <= 1'b1;
                        sda_out <= 1'b0;
                    end else begin
                        sda_out  <= 1'b1;
                        m_busy_o <= 1'b0;
                        state    <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule