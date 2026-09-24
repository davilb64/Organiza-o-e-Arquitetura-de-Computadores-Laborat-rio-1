.data
a: .word 1, 2, 3, 4, 5
b: .half 7, 6, 5, 4, 5
c: .byte 6, 5, 4, 3, 2
d: .string "a casa é azul."


.text
lui t1, 0x1001
addi t2, zero, 4
sll t1, t1, t2
lw t2, 0(t1)
sw t2, 32(t1)
add t3, t2, t1
sub t3, t1, t3
and t4, t1, t2
or t4, t1, t2
xor t4, t1, t2
jal rotulo
beq t1, t2, rotulo
lhu t5, 32(t1)
rotulo: slti t1, t2, -1