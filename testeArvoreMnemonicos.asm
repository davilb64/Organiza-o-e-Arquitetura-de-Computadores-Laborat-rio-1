main:
    add x5, x6, x7
    sub x8, x9, x10
    and x11, x12, x13
    or x14, x15, x16
    xor x17, x18, x19

    addi x20, x21, 10
    andi x22, x23, 15
    ori x24, x25, 20
    xori x26, x27, 25

    lw x5, 0(x6)
    sw x7, 4(x8)
    lhu x9, 2(x10)

    jal x1, rotulo_teste
    jalr x2, x3, 8

rotulo_teste:
    beq x5, x6, main
    bne x7, x8, fim

    slt x9, x10, x11
    slti x12, x13, 5

    lui x14, 0x12345
    auipc x15, 0x1000

    sll x16, x17, x18
    srl x19, x20, x21
-
fim:
