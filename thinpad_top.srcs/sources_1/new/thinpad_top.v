`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ�����루���ã��ɲ��ӣ�

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�����"ON"ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�����ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�����ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲᣩ
    output wire [22:0]flash_a,      //Flash��ַ��a0��8bitģʽ����Ч��16bitģʽ����Ч
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ���������
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //֡ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ���ź�
    output wire video_de           //��������Ч�źţ���������������
);

    // ==================== ʱ������ ====================
    wire locked, clk_10M, clk_20M;
    pll_example_1 clock_gen 
     (
      // Clock in ports
      .clk_in1(clk_50M),  // �ⲿʱ������
      // Clock out ports
      .clk_out1(clk_10M), // ʱ�����1��Ƶ����IP�����þ���
      .clk_out2(clk_20M), // ʱ�����2��Ƶ����IP�����þ���
      // Status and control signals
      .reset(reset_btn), // PLL��λ����
      .locked(locked)    // PLL����ָʾ�����"1"ʱ��ʾʱ���ȶ�
                         // ������·��λ�ź�Ӧ���ӵ�locked�����·�
     );
    
    reg reset_of_clk50M;
    // �첽��λ��ͬ���ͷţ���locked�ź�תΪ������·�ĸ�λreset_of_clk50M
    always@(posedge clk_50M or negedge locked) begin
        if(~locked) reset_of_clk50M <= 1'b1;
        else        reset_of_clk50M <= 1'b0;
    end
    
    reg reset_of_clk20M;
    // �첽��λ��ͬ���ͷţ���locked�ź�תΪ������·�ĸ�λreset_of_clk20M
    always@(posedge clk_20M or negedge locked) begin
        if(~locked) reset_of_clk20M <= 1'b1;
        else        reset_of_clk20M <= 1'b0;
    end
    
    reg reset_of_clk10M;
    // �첽��λ��ͬ���ͷţ���locked�ź�תΪ������·�ĸ�λreset_of_clk10M
    always@(posedge clk_10M or negedge locked) begin
        if(~locked) reset_of_clk10M <= 1'b1;
        else        reset_of_clk10M <= 1'b0;
    end
    
    // ==================== CPU���ڴ�ӿ��ź� ====================
    wire[31:0] rom_addr;
    wire rom_ce;
    wire[31:0] rom_data;
    
    wire[31:0] ram_data2CPU;
    wire[31:0] ram_addr;
    wire[31:0] ram_data2RAM;
    wire ram_we_n;
    wire[3:0] ram_sel_n;
    wire ram_ce;
    wire ram_wb_ready;
    
    // ==================== CPUʵ���� ====================
    llyCPU u_llyCPU(
        .clk        (clk_10M),
        .rst        (reset_of_clk10M),
    
        .rom_data_i (rom_data),
        .rom_addr_o (rom_addr),
        .rom_ce_o   (rom_ce),
    
        .ram_data_i (ram_data2CPU),
        .ram_addr_o (ram_addr),
        .ram_data_o (ram_data2RAM),
        .ram_we_o   (ram_we_n),
        .ram_sel_o  (ram_sel_n),
        .ram_ce_o   (ram_ce),
        .ram_wb_ready_i(ram_wb_ready)
    );
    
    // ==================== ����ģ��ʵ���� ====================
    RAM_Serial RAM_Serial_0(
        .clk            (clk_10M),
    
        .rom_addr_i     (rom_addr),
        .rom_ce_i       (rom_ce),
        .rom_data_o     (rom_data),
    
        .ram_addr_i     (ram_addr),
        .ram_data_i     (ram_data2RAM),
        .ram_we_n       (ram_we_n),
        .ram_sel_n      (ram_sel_n),
        .ram_ce_i       (ram_ce),
        .ram_data_o     (ram_data2CPU),
    
        .base_ram_data  (base_ram_data),
        .base_ram_addr  (base_ram_addr),
        .base_ram_be_n  (base_ram_be_n),
        .base_ram_ce_n  (base_ram_ce_n),
        .base_ram_oe_n  (base_ram_oe_n),
        .base_ram_we_n  (base_ram_we_n),
    
        .ext_ram_data   (ext_ram_data),
        .ext_ram_addr   (ext_ram_addr),
        .ext_ram_be_n   (ext_ram_be_n),
        .ext_ram_ce_n   (ext_ram_ce_n),
        .ext_ram_oe_n   (ext_ram_oe_n),
        .ext_ram_we_n   (ext_ram_we_n),
    
        .txd            (txd),
        .rxd            (rxd),
        .wb_ready_o     (ram_wb_ready)
    );

    // 7���������������ʾ����number��16������ʾ�����������
    wire[7:0] number;
    SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0�ǵ�λ�����
    SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1�Ǹ�λ�����
    
    reg[15:0] led_bits;
    assign leds = led_bits;
    
    always@(posedge clock_btn or posedge reset_btn) begin
        if(reset_btn)begin //��λ���£�����LEDΪ��ʼֵ
            led_bits <= 16'h1;
        end
        else begin //ÿ�ΰ���ʱ�Ӱ�ť��LEDѭ������
            led_bits <= {led_bits[14:0],led_bits[15]};
        end
    end
    
    // ==================== δʹ�õ��źŴ��� ====================
    // Flash�ź� - ����Ĭ��״̬
    assign flash_a = 23'h0;
    assign flash_d = 16'hzzzz;
    assign flash_rp_n = 1'b1;
    assign flash_vpen = 1'b1;
    assign flash_ce_n = 1'b1;
    assign flash_oe_n = 1'b1;
    assign flash_we_n = 1'b1;
    assign flash_byte_n = 1'b1;
    
    // ��Ƶ�ź� - ����Ĭ��״̬
    assign video_red = 3'b000;
    assign video_green = 3'b000;
    assign video_blue = 2'b00;
    assign video_hsync = 1'b0;
    assign video_vsync = 1'b0;
    assign video_clk = 1'b0;
    assign video_de = 1'b0;

endmodule 