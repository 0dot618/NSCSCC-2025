`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入（备用，可不接）

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到"ON"时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,       //ExtRAM写使能，低有效

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号（参考 JS28F640 芯片手册）
    output wire [22:0]flash_a,      //Flash地址，a0在8bit模式下有效，16bit模式下无效
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧入
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效，在使用flash的16位模式时请设为1

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //帧同步（垂直同步）信号
    output wire video_clk,         //像素时钟信号
    output wire video_de           //行数据有效信号，用于区分行数据
);

    // ==================== 时钟生成 ====================
    wire locked, clk_10M, clk_20M;
    pll_example_1 clock_gen 
     (
      // Clock in ports
      .clk_in1(clk_50M),  // 外部时钟输入
      // Clock out ports
      .clk_out1(clk_10M), // 时钟输出1，频率由IP核设置决定
      .clk_out2(clk_20M), // 时钟输出2，频率由IP核设置决定
      // Status and control signals
      .reset(reset_btn), // PLL复位输入
      .locked(locked)    // PLL锁定指示，输出"1"时表示时钟稳定
                         // 后续电路复位信号应连接到locked，见下方
     );
    
    reg reset_of_clk50M;
    // 异步复位，同步释放，将locked信号转为后续电路的复位reset_of_clk50M
    always@(posedge clk_50M or negedge locked) begin
        if(~locked) reset_of_clk50M <= 1'b1;
        else        reset_of_clk50M <= 1'b0;
    end
    
    reg reset_of_clk20M;
    // 异步复位，同步释放，将locked信号转为后续电路的复位reset_of_clk20M
    always@(posedge clk_20M or negedge locked) begin
        if(~locked) reset_of_clk20M <= 1'b1;
        else        reset_of_clk20M <= 1'b0;
    end
    
    reg reset_of_clk10M;
    // 异步复位，同步释放，将locked信号转为后续电路的复位reset_of_clk10M
    always@(posedge clk_10M or negedge locked) begin
        if(~locked) reset_of_clk10M <= 1'b1;
        else        reset_of_clk10M <= 1'b0;
    end
    
    // ==================== CPU和内存接口信号 ====================
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
    
    // ==================== CPU实例化 ====================
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
    
    // ==================== 串口模块实例化 ====================
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

    // 7段数码管译码器演示，将number用16进制显示在数码管上面
    wire[7:0] number;
    SEG7_LUT segL(.oSEG1(dpy0), .iDIG(number[3:0])); //dpy0是低位数码管
    SEG7_LUT segH(.oSEG1(dpy1), .iDIG(number[7:4])); //dpy1是高位数码管
    
    reg[15:0] led_bits;
    assign leds = led_bits;
    
    always@(posedge clock_btn or posedge reset_btn) begin
        if(reset_btn)begin //复位按下，设置LED为初始值
            led_bits <= 16'h1;
        end
        else begin //每次按下时钟按钮，LED循环左移
            led_bits <= {led_bits[14:0],led_bits[15]};
        end
    end
    
    // ==================== 未使用的信号处理 ====================
    // Flash信号 - 保持默认状态
    assign flash_a = 23'h0;
    assign flash_d = 16'hzzzz;
    assign flash_rp_n = 1'b1;
    assign flash_vpen = 1'b1;
    assign flash_ce_n = 1'b1;
    assign flash_oe_n = 1'b1;
    assign flash_we_n = 1'b1;
    assign flash_byte_n = 1'b1;
    
    // 视频信号 - 保持默认状态
    assign video_red = 3'b000;
    assign video_green = 3'b000;
    assign video_blue = 2'b00;
    assign video_hsync = 1'b0;
    assign video_vsync = 1'b0;
    assign video_clk = 1'b0;
    assign video_de = 1'b0;

endmodule 