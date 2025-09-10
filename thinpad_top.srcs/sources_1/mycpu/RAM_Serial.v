`include "defines.v"

`define CLK_FREQ    211000000

module RAM_Serial (
    input wire clk,

    // ȡָ��ROM
    input wire[`InstAddrBus]rom_addr_i,
    input wire              rom_ce_i, 
    output wire[`InstBus]   rom_data_o, 

    // �ô�����RAM
    input wire[`RegBus] ram_addr_i, 
    input wire[`RegBus] ram_data_i,
    input wire          ram_we_n,  
    input wire[3:0]     ram_sel_n, 
    input wire          ram_ce_i, 
    output wire[`RegBus]ram_data_o, 

    // BaseRAM����ź�
    inout wire[`InstBus]base_ram_data,
    output wire[19:0]   base_ram_addr,
    output wire[3:0]    base_ram_be_n, 
    output wire         base_ram_ce_n,
    output wire         base_ram_oe_n,
    output wire         base_ram_we_n,

    // ExtRAM����ź�
    inout wire[`RegBus] ext_ram_data,
    output wire[19:0]   ext_ram_addr,
    output wire[3:0]    ext_ram_be_n,  
    output wire         ext_ram_ce_n, 
    output wire         ext_ram_oe_n,
    output wire         ext_ram_we_n, 

    input wire          rxd,
    output wire         txd,
    // Write buffer֧��
    output wire         wb_ready_o // �ڴ�׼���ý���д����
);

    /*----------------------���ڱ���----------------------*/
    wire [7:0]  RxD_data;
    reg [7:0]  TxD_data;
    wire RxD_data_ready;
    wire TxD_busy;
    reg TxD_start;
    wire RxD_clear;
    reg [`RegBus] serial_o;
    
    
    /*----------------------��ַӳ��----------------------*/
    wire is_SerialState =  ~|(ram_addr_i ^ 32'hBFD003FC);
    wire is_SerialData =  ~|(ram_addr_i ^ 32'hBFD003F8);
    wire is_base_ram = ~|(ram_addr_i[31:22] ^ 10'b1000000000);
    wire is_ext_ram = ~|(ram_addr_i[31:22] ^ 10'b1000000001);
    
    
    /*----------------------����ͨ��----------------------*/
    async_receiver #(.ClkFrequency(`CLK_FREQ),.Baud(9600))
        ext_uart_r(
            .clk(clk),
            .RxD(rxd),                          // ����
            .RxD_data_ready(RxD_data_ready),    // ���ݽ�����ɣ���������
            .RxD_clear(RxD_clear),              // �����������
            .RxD_data(RxD_data)                 // ���յ���8λ����
        );
    
    async_transmitter #(.ClkFrequency(`CLK_FREQ),.Baud(9600))
        ext_uart_t(
            .clk(clk),
            .TxD(txd),                          // ���
            .TxD_busy(TxD_busy),                // ������æ�����ڴ������ݣ�
            .TxD_start(TxD_start),              // �������ݴ���
            .TxD_data(TxD_data)                 // Ҫ���͵�8λ����
        );

    // ����״̬��ֵ
    assign RxD_clear = (RxD_data_ready && is_SerialData && ram_we_n == `WriteDisable_n);
    always @(*) begin
        // Ĭ��ֵ����
        TxD_start = 1'b0;
        serial_o = `ZeroWord;
        TxD_data = 8'h00;
        if(is_SerialState) begin        //��ȡ����״̬
            serial_o = {{30{1'b0}}, {RxD_data_ready, !TxD_busy}};
        end else if(is_SerialData) begin    
            if(ram_we_n == `WriteDisable_n) begin   //��ȡ��������
                serial_o = {24'h000000, RxD_data};
            end else if(!TxD_busy) begin            //���ڲ���æ״̬�����Է���
                TxD_start = 1'b1;
                TxD_data = ram_data_i[7:0];
            end
            // �����������Ĭ��ֵ
        end
    end

    
    /*----------------------�ڴ����----------------------*/
    wire[`InstBus] base_ram_o;
    wire[`RegBus] ext_ram_o;
    assign base_ram_data = (is_base_ram && ram_we_n == `WriteEnable_n) ? ram_data_i : 32'hzzzzzzzz;
    assign base_ram_o = base_ram_data;
    assign ext_ram_data = (is_ext_ram && ram_we_n == `WriteEnable_n) ? ram_data_i : 32'hzzzzzzzz;
    assign ext_ram_o = ext_ram_data;
    assign rom_data_o = is_base_ram ? `ZeroWord : base_ram_o;
    
    assign base_ram_addr = is_base_ram ? ram_addr_i[21:2] : rom_addr_i[21:2];
    assign base_ram_be_n = is_base_ram ? ram_sel_n : 4'b0000;
    assign base_ram_ce_n = 1'b0;
    assign base_ram_oe_n = is_base_ram ? ~ram_we_n : 1'b0;
    assign base_ram_we_n = is_base_ram ? ram_we_n : 1'b1;
    
    assign ext_ram_addr = is_ext_ram ? ram_addr_i[21:2] : 20'h00000;
    assign ext_ram_be_n = is_ext_ram ? ram_sel_n : 4'b1111;
    assign ext_ram_ce_n = is_ext_ram ? 1'b0 : 1'b1;
    assign ext_ram_oe_n = is_ext_ram ? ~ram_we_n : 1'b1;
    assign ext_ram_we_n = is_ext_ram ? ram_we_n : 1'b1;
    
    /*----------------------����ѡ���ٲ�----------------------*/
    // �ֽ�ѡ���߼�
    wire[`RegBus] base_ram_sel, ext_ram_sel;
    
    // �ֽ���չ����
    function [`RegBus] byte_extend;
        input [7:0] byte_data;
        begin
            byte_extend = {{24{byte_data[7]}}, byte_data};
        end
    endfunction
    
    // �����ֽ�ѡ���ź�ѡ������
    assign base_ram_sel = (ram_sel_n == 4'b1110) ? byte_extend(base_ram_o[7:0]) :
                          (ram_sel_n == 4'b1101) ? byte_extend(base_ram_o[15:8]) :
                          (ram_sel_n == 4'b1011) ? byte_extend(base_ram_o[23:16]) :
                          (ram_sel_n == 4'b0111) ? byte_extend(base_ram_o[31:24]) :
                          base_ram_o;
    
    assign ext_ram_sel = (ram_sel_n == 4'b1110) ? byte_extend(ext_ram_o[7:0]) :
                         (ram_sel_n == 4'b1101) ? byte_extend(ext_ram_o[15:8]) :
                         (ram_sel_n == 4'b1011) ? byte_extend(ext_ram_o[23:16]) :
                         (ram_sel_n == 4'b0111) ? byte_extend(ext_ram_o[31:24]) :
                         ext_ram_o;
    
    assign ram_data_o = is_ext_ram ? ext_ram_sel :
                        (is_base_ram ? base_ram_sel :
                        ((is_SerialState | is_SerialData) ? serial_o : `ZeroWord));
    
    // Write buffer ready�ź�
    // ����BaseRAM��ExtRAM������׼���ý���д����
    // ���ڴ��ڣ�ֻ���ڲ�æ��ʱ���׼����
    assign wb_ready_o = (is_base_ram || is_ext_ram) ? 1'b1 :
                        (is_SerialData && ram_we_n == `WriteEnable_n) ? !TxD_busy : 1'b1;


endmodule