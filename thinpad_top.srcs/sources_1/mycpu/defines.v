/*----------------------基础控制----------------------*/
`define RstEnable 1'b1
`define RstDisable 1'b0
`define ZeroWord 32'h00000000
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define WriteDisable_n 1'b1 //输出给ram，外设是低有效
`define WriteEnable_n 1'b0
`define Branch 1'b1
`define NotBranch 1'b0
`define Stop 1'b1
`define NoStop 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0


/*----------------------指令OPCODE----------------------*/
`define SPECIAL_OP  6'b000000
`define REGIMM_OP   6'b000001

`define MUL_OP      6'b011100

`define ADDI_OP     6'b001000
`define ADDIU_OP    6'b001001
`define ANDI_OP     6'b001100
`define ORI_OP      6'b001101
`define XORI_OP     6'b001110
`define LUI_OP      6'b001111

`define BEQ_OP      6'b000100
`define BNE_OP      6'b000101
`define BLEZ_OP     6'b000110
`define BGTZ_OP     6'b000111

`define J_OP        6'b000010
`define JAL_OP      6'b000011

`define LB_OP       6'b100000
`define LW_OP       6'b100011
`define SB_OP       6'b101000
`define SW_OP       6'b101011


/*----------------------指令FUN----------------------*/
`define ADD_FUNC        6'b100000
`define ADDU_FUNC       6'b100001
`define SUB_FUNC        6'b100010
`define SLT_FUNC        6'b101010

`define AND_FUNC        6'b100100
`define OR_FUNC         6'b100101
`define XOR_FUNC        6'b100110

`define SLL_FUNC        6'b000000
`define SRL_FUNC        6'b000010
`define SRA_FUNC        6'b000011

`define SLLV_FUNC       6'b000100
`define SRLV_FUNC       6'b000110
`define SRAV_FUNC       6'b000111

`define MUL_FUNC        6'b000010
`define DIV_FUNC        6'b011010

`define MFHI_FUNC       6'b010000
`define MTHI_FUNC       6'b010001
`define MFLO_FUNC       6'b010010
`define MTLO_FUNC       6'b010011

`define JR_FUNC         6'b001000
`define JALR_FUNC       6'b001001


/*----------------------指令特殊判断----------------------*/
`define BLTZ_RT         5'b00000
`define BGEZ_RT         5'b00001


/*----------------------跳转相关指令类型----------------------*/
`define JR              4'b0000
`define JALR            4'b0001
`define BEQ             4'b0010
`define BNE             4'b0011
`define BGEZ            4'b0100
`define BGTZ            4'b0101
`define BLEZ            4'b0110
`define BLTZ            4'b0111
`define J               4'b1000
`define JAL             4'b1001


/*----------------------EX操作----------------------*/
`define EXE_NOP_OP      5'b00000       // 空

`define EXE_ADD_OP      5'b00001       // 加法
`define EXE_SUB_OP      5'b00010       // 减法
`define EXE_SLT_OP      5'b00011       // 小于则置位
`define EXE_SLTU_OP     5'b00100       // 小于则置位

`define EXE_AND_OP      5'b00101       // 按位与
`define EXE_OR_OP       5'b00110       // 按位或
`define EXE_XOR_OP      5'b00111       // 按位异或
`define EXE_NOR_OP      5'b01000       // 按位异或

`define EXE_SLL_OP      5'b01001       // 逻辑左移
`define EXE_SRL_OP      5'b01010       // 逻辑右移
`define EXE_SRA_OP      5'b01011       // 算数右移

`define EXE_MUL_OP      5'b01100       // 乘法

`define EXE_JAL_OP      5'b01101       // 跳转并链接

`define EXE_LB_OP       5'b01110       // LB
`define EXE_LW_OP       5'b01111       // LW
`define EXE_SB_OP       5'b10000       // SB
`define EXE_SW_OP       5'b10001       // SW

`define EXE_DIV_OP      5'b10010       // DIV
`define EXE_MFHI_OP     5'b10011       //MFHI
`define EXE_MTHI_OP     5'b10100       //MTHI
`define EXE_MFLO_OP     5'b10101       //MFLO
`define EXE_MTLO_OP     5'b10110       //MRLO

`define MEM_NOP_OP      3'b000
`define MEM_LB_OP       3'b001
`define MEM_LW_OP       3'b011
`define MEM_SB_OP       3'b101
`define MEM_SW_OP       3'b111


/*----------------------Reg相关----------------------*/
`define RegAddrBus 4:0
`define RegBus 31:0
`define DoubleRegBus 63:0
`define AluOpBus 4:0
`define NOPRegAddr 5'b00000


/*----------------------Inst相关----------------------*/
`define InstAddrBus 31:0
`define InstBus 31:0
