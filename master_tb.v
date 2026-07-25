
module tb_i2c_master;

    reg clk_i;
    reg rst_i;
    reg m_w_r_i;
    reg m_start_i;
    reg m_stop_i;
    reg [6:0] m_slv_add_i;
    reg m_ack_i;
    reg [7:0] m_data_i;

    wire [7:0] m_data_o;
    wire m_busy_o;
    wire m_error_o;
    wire m_data_ready_o;
    wire sda;
    wire sca;
    i2c_master DUT (
        .clk_i(clk_i),
        .rst_i(rst_i),
        .m_w_r_i(m_w_r_i),
        .m_start_i(m_start_i),
        .m_stop_i(m_stop_i),
        .m_slv_add_i(m_slv_add_i),
        .m_ack_i(m_ack_i),
        .m_data_i(m_data_i),
        .m_data_o(m_data_o),
        .m_busy_o(m_busy_o),
        .m_error_o(m_error_o),
        .m_data_ready_o(m_data_ready_o),
        .sda(sda),
        .sca(sca)
    );       
   always #5 clk_i = ~clk_i;
    initial begin
        clk_i=0;
        rst_i = 1;
        m_start_i = 0;
        m_stop_i = 0;
        m_w_r_i = 0;             
        m_slv_add_i = 7'b1010000;
        m_data_i = 8'hA5;
        m_ack_i = 0;

        #20;
        rst_i = 0;
        #20;
        m_start_i = 1;
        #10;
        m_start_i = 0;
        #100;
        m_stop_i = 1;
        #20;
        m_stop_i = 0;
        #100;
        $finish;

    end

endmodule