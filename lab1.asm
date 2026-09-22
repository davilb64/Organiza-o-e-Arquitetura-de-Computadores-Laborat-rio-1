.data
	arquivo: .string "/home/davi/Área de trabalho/ORGANIZAÇÃO E ARQUITETURA DE COMPUTADORES/Lab1/testeArvoreMnemonicos.asm"
	buffer: .space 1024 # espaco pra ler o arquivo
	buffer_palavra: .space 20 # espaco pra ler palavras
	msg_erro: .string "Erro ao abrir o arquivo\n"
	
	# prints de teste
	str_lw: .string "LW"
    	str_or: .string "OR"
    	str_sw: .string "SW"
    	str_add: .string "ADD"
    	str_and: .string "AND"
    	str_bne: .string "BNE"
    	str_beq: .string "BEQ"
    	str_jal: .string "JAL"
    	str_lui: .string "LUI"
    	str_lhu: .string "LHU"
    	str_ori: .string "ORI"
    	str_sub: .string "SUB"
    	str_slt: .string "SLT"
    	str_sll: .string "SLL"
    	str_srl: .string "SRL"
    	str_xor: .string "XOR"
    	str_addi: .string "ADDI"
    	str_andi: .string "ANDI"
    	str_jalr: .string "JALR"
    	str_slti: .string "SLTI"
    	str_xori: .string "XORI"
    	str_auipc: .string "AUIPC"
.text

main:
	# abre arquivo 
	addi a7, zero, 1024 # syscall abre arquivo
	la a0, arquivo 
	addi a1, zero, 0
	ecall
	blt a0, zero, erro_abertura # desvia se o fd for menor que zero
	addi s0, a0, 0 # salva o fd em s0
	
	# le arquivo
	addi a7, zero, 63 # syscall leitura do arquivo
	addi a0, s0, 0
	la a1, buffer
	addi a2, zero, 1024
	ecall
	
	# fecha o arquivo
	addi a7, zero, 57
	addi a0, s0, 0
	ecall
	j inicia_scanner

erro_abertura:
	addi a7, zero, 64 # syscall escrita
	addi a0, zero, 1 # flag pra print no console
	la a1, msg_erro # endereco da mensagem de erro
	addi a2, zero, 24 # tamanho do texto
	ecall
	j exit
	
inicia_scanner:
	la s1, buffer # ponteiro da leitura do arquivo
	
inicia_nova_palavra:
    	la s2, buffer_palavra # ponteiro de gravacao da palavra
    	
le_char:
	lbu t0, 0(s1) # carrega um char por vez
	
	beq zero, t0, exit # fim arquivo
	
	li t1, 58 # ':'
	beq t0, t1, rotulo # se o char eh ':', pula pra tratamento de rotulo
	
	li t1, 32 # ' '
	beq t0, t1, avalia_espaco # se o char eh ' ', pula pra tratamento de espaco
	
	li t1, 9 # '	(tab)'
	beq t0, t1, avalia_espaco # se o char eh '	(tab)', pula pra tratamento de espaco
	
	li t1, 10 # '\n'
    	beq t0, t1, avalia_espaco # se o char eh '\n', pula pra tratamento de espaco
	
	sb t0, 0(s2) # grava o char
	addi s2, s2, 1 #avanca gravacao da palavra no buffer
	addi s1, s1, 1 # avanca no arquivo
	j le_char
	

move_ponteiro:
	addi s1, s1, 1
	j le_char
	
rotulo:
	addi s1, s1, 1
	j inicia_nova_palavra # futuramente deve gravar endereco do rotulo junto dele para usar nos jumps
	
avalia_espaco:
	la t3, buffer_palavra
	beq t3, s2, move_ponteiro # se nao entrou nada no buffer palavra, volta a ler os char
	
	sb zero, 0(s2) # fecha a palavra com NULL
	
	addi s1, s1, 1 # avanca o espaco entre o registrador e o mnemonico
	la a0, buffer_palavra # guarda o end inicial da palavra em a0
	j identifica_instrucao


identifica_instrucao:
	lbu t5, 0(a0)
	
	li t0, 65 # 'A'
	beq t5, t0, mne_A
	li t0, 97 # 'a'
	beq t5, t0, mne_A
	
	li t0, 66 # 'B'
	beq t5, t0, mne_B
	li t0, 98 # 'b'
	beq t5, t0, mne_B
	
	li t0, 74 # 'J'
	beq t5, t0, mne_J
	li t0, 106 # 'j'
	beq t5, t0, mne_J
	
	li t0, 76 # 'L'
	beq t5, t0, mne_L
	li t0, 108 # 'j'
	beq t5, t0, mne_L
	
	li t0, 79 # 'O'
	beq t5, t0, mne_O
	li t0, 111 # 'o'
	beq t5, t0, mne_O
	
	li t0, 83 # 'S'
	beq t5, t0, mne_S
	li t0, 115 # 's'
	beq t5, t0, mne_S
	
	li t0, 88 # 'X'
	beq t5, t0, mne_X
	li t0, 120 # 'x'
	beq t5, t0, mne_X

instrucao_nao_existe:
	# futuramente colocar um print
    	lbu t0, 0(s1)
    	beq t0, zero, exit # fim de arquivo
    
    	li t1, 10 # '\n'
   	 beq t0, t1, quebra_linha 
    
    	addi s1, s1, 1
    	j instrucao_nao_existe
	
mne_A:
	lbu t5, 1(a0)

	li t0, 68 # 'D'
	beq t5, t0, mne_AD
	li t0, 100 # 'd'
	beq t5, t0, mne_AD
	
	li t0, 78 #'N'
	beq t5, t0, mne_AN
	li t0, 110 # 'n'
	beq t5, t0, mne_AN
	
	li t0, 85 #'U'
	beq t5, t0, mne_AU
	li t0, 117 # 'u'
	beq t5, t0, mne_AU
	
	j instrucao_nao_existe
	
mne_B:
	lbu t5, 1(a0)
	
	li t0, 78 #'N'
	beq t5, t0, mne_BN
	li t0, 110 # 'n'
	beq t5, t0, mne_BN
	
	li t0, 69 # 'E'
	beq t5, t0, mne_BE
	li t0, 101 # 'e'
	beq t5, t0, mne_BE
	
	j instrucao_nao_existe
	
mne_J:
	lbu t5, 1(a0)
	
	li t0, 65 # 'A'
	beq t5, t0, mne_JA
	li t0, 97 # 'a'
	beq t5, t0, mne_JA
	
	j instrucao_nao_existe
	
mne_L:
	lbu t5, 1(a0)
	
	li t0, 87 # 'W'
	beq t5, t0, mne_LW
	li t0, 119 # 'w'
	beq t5, t0, mne_LW
	
	li t0, 85 #'U'
	beq t5, t0, mne_LU
	li t0, 117 # 'u'
	beq t5, t0, mne_LU
	
	li t0, 72 #'H'
	beq t5, t0, mne_LH
	li t0, 104 # 'h'
	beq t5, t0, mne_LH
	
	j instrucao_nao_existe

mne_O:
	lbu t5, 1(a0)
	
	li t0, 82 #'R'
	beq t5, t0, mne_OR
	li t0, 114 # 'r'
	beq t5, t0, mne_OR
	
	j instrucao_nao_existe

mne_S:
	lbu t5, 1(a0)
	
	li t0, 85 #'U'
	beq t5, t0, mne_SU
	li t0, 117 # 'u'
	beq t5, t0, mne_SU

	li t0, 76 # 'L'
	beq t5, t0, mne_SL
	li t0, 108 # 'j'
	beq t5, t0, mne_SL
	
	li t0, 82 #'R'
	beq t5, t0, mne_SR
	li t0, 114 # 'r'
	beq t5, t0, mne_SR
	
	li t0, 87 # 'W'
	beq t5, t0, mne_SW
	li t0, 119 # 'w'
	beq t5, t0, mne_SW
	
	j instrucao_nao_existe
	
mne_X:
	lbu t5, 1(a0)
	
	li t0, 79 # 'O'
	beq t5, t0, mne_XO
	li t0, 111 # 'o'
	beq t5, t0, mne_XO
	
	j instrucao_nao_existe
	
# segunda letra

mne_AD:
	lbu t5, 2(a0)
	
	li t0, 68 # 'D'
	beq t5, t0, mne_ADD
	li t0, 100 # 'd'
	beq t5, t0, mne_ADD
	
	j instrucao_nao_existe

mne_AN:
	lbu t5, 2(a0)
	
	li t0, 68 #'D'
	beq t5, t0, mne_AND
	li t0, 100 # 'd'
	beq t5, t0, mne_AND
	
	j instrucao_nao_existe

mne_AU:
	lbu t5, 2(a0)
	
	li t0, 73 #'I'
	beq t5, t0, mne_AUI
	li t0, 105 # 'i'
	beq t5, t0, mne_AUI
	
	j instrucao_nao_existe

mne_BN:
	lbu t5, 2(a0)
	
	li t0, 69 # 'E'
	beq t5, t0, mne_BNE
	li t0, 101 # 'e'
	beq t5, t0, mne_BNE
	
	j instrucao_nao_existe

mne_BE:
	lbu t5, 2(a0)
	
	li t0, 81 # 'Q'
	beq t5, t0, mne_BEQ
	li t0, 113 # 'q'
	beq t5, t0, mne_BEQ
	
	j instrucao_nao_existe

mne_JA:
	lbu t5, 2(a0)
	
	li t0, 76 #'L'
	beq t5, t0, mne_JAL
	li t0, 108 # 'l'
	beq t5, t0, mne_JAL
	
	j instrucao_nao_existe

mne_LW:
	lbu t5, 2(a0)
	beq t5, zero, implementacao_LW # null
	j instrucao_nao_existe
	
mne_LU:
	lbu t5, 2(a0)
	
	li t0, 73 #'I'
	beq t5, t0, mne_LUI
	li t0, 105 # 'i'
	beq t5, t0, mne_LUI
	
	j instrucao_nao_existe
	
mne_LH:
	lbu t5, 2(a0)
	
	li t0, 85 #'U'
	beq t5, t0, mne_LHU
	li t0, 117 # 'u'
	beq t5, t0, mne_LHU
	
	j instrucao_nao_existe
	
mne_OR:
	lbu t5, 2(a0)
	
	li t0, 73 #'I'
	beq t5, t0, mne_ORI
	li t0, 105 # 'i'
	beq t5, t0, mne_ORI
	beq t5, zero, implementacao_OR
	
	j instrucao_nao_existe
	
mne_SU:
	lbu t5, 2(a0)
	
	li t0, 66 # 'B'
	beq t5, t0, mne_SUB
	li t0, 98 # 'b'
	beq t5, t0, mne_SUB
	
	j instrucao_nao_existe
	
mne_SL:
	lbu t5, 2(a0)
	
	li t0, 84 # 'T'
	beq t5, t0, mne_SLT
	li t0, 116 # 't'
	beq t5, t0, mne_SLT
	
	li t0, 76 # 'L'
	beq t5, t0, mne_SLL
	li t0, 108 # 'l'
	beq t5, t0, mne_SLL
	
	j instrucao_nao_existe
	
mne_SR:
	lbu t5, 2(a0)
	
	li t0, 76 #'L'
	beq t5, t0, mne_SRL
	li t0, 108 # 'l'
	beq t5, t0, mne_SRL
	
	j instrucao_nao_existe
	
mne_SW:
	lbu t5, 2(a0)
	beq t5, zero, implementacao_SW
	j instrucao_nao_existe 

mne_XO:
	lbu t5, 2(a0)
	
	li t0, 82 #'R'
	beq t5, t0, mne_XOR
	li t0, 114 # 'r'
	beq t5, t0, mne_XOR
	
	j instrucao_nao_existe 

# terceira letra

mne_ADD:
	lbu t5, 3(a0)
	
	li t0, 73 #'I'
	beq t5, t0, mne_ADDI
	li t0, 105 # 'i'
	beq t5, t0, mne_ADDI
	beq t5, zero, implementacao_ADD
	
	j instrucao_nao_existe

mne_AND:
	lbu t5, 3(a0)
	
	li t0, 73 #'I'
	beq t5, t0, mne_ANDI
	li t0, 105 # 'i'
	beq t5, t0, mne_ANDI
	beq t5, zero, implementacao_AND
	
	j instrucao_nao_existe	

mne_AUI:
	lbu t5, 3(a0)
	
	li t0, 80 #'P'
	beq t5, t0, mne_AUIP
	li t0, 112 # 'p'
	beq t5, t0, mne_AUIP
	
	j instrucao_nao_existe	
	
mne_BNE:
	lbu t5, 3(a0)
	beq t5, zero, implementacao_BNE
	j instrucao_nao_existe	
	
mne_BEQ:
	lbu t5, 3(a0)
	beq t5, zero, implementacao_BEQ
	j instrucao_nao_existe	

mne_JAL:
	lbu t5, 3(a0)
	
	li t0, 82 #'R'
	beq t5, t0, mne_JALR
	li t0, 114 # 'r'
	beq t5, t0, mne_JALR
	beq t5, zero, implementacao_JAL
	
	j instrucao_nao_existe	

mne_LUI:
	lbu t5, 3(a0)
	beq t5, zero, implementacao_LUI
	j instrucao_nao_existe	

mne_LHU:
	lbu t5, 3(a0)
	beq t5, zero, implementacao_LHU
	j instrucao_nao_existe	

mne_ORI:
	lbu t5, 3(a0)
	beq t5, zero, implementacao_ORI
	j instrucao_nao_existe

mne_SUB:
	lbu t5, 3(a0)
	beq t5, zero, implementacao_SUB
	j instrucao_nao_existe

mne_SLT:
	lbu t5, 3(a0)
	
	li t0, 73 #'I'
	beq t5, t0, mne_SLTI
	li t0, 105 # 'i'
	beq t5, t0, mne_SLTI
	beq t5, zero, implementacao_SLT
	
	j instrucao_nao_existe
	
mne_SLL:
	lbu t5, 3(a0)
	beq t5, zero, implementacao_SLL
	j instrucao_nao_existe

mne_SRL:
	lbu t5, 3(a0)
	beq t5, zero, implementacao_SRL
	j instrucao_nao_existe
	
mne_XOR:
	lbu t5, 3(a0)
	
	li t0, 73 #'I'
	beq t5, t0, mne_XORI
	li t0, 105 # 'i'
	beq t5, t0, mne_XORI
	beq t5, zero, implementacao_XOR
	
	j instrucao_nao_existe

# quarta_letra

mne_ADDI:
	lbu t5, 4(a0)
	beq t5, zero, implementacao_ADDI
	j instrucao_nao_existe

mne_ANDI:
	lbu t5, 4(a0)
	beq t5, zero, implementacao_ANDI
	j instrucao_nao_existe

mne_AUIP:
	lbu t5, 4(a0)
	
	li t0, 67 #'C'
	beq t5, t0, mne_AUIPC
	li t0, 99 # 'c'
	beq t5, t0, mne_AUIPC
	
	j instrucao_nao_existe

mne_JALR:
	lbu t5, 4(a0)
	beq t5, zero, implementacao_JALR
	j instrucao_nao_existe

mne_SLTI:
	lbu t5, 4(a0)
	beq t5, zero, implementacao_SLTI
	j instrucao_nao_existe

mne_XORI:
	lbu t5, 4(a0)
	beq t5, zero, implementacao_XORI
	j instrucao_nao_existe

# quinta letra

mne_AUIPC:
	lbu t5, 5(a0)
	beq t5, zero, implementacao_AUIPC
	j instrucao_nao_existe


# implementacaoes:

implementacao_LW:
	la a0, str_lw
    	j teste
    	
implementacao_OR:
	la a0, str_or
    	j teste

implementacao_SW:
	la a0, str_sw
    	j teste

implementacao_ADD:
	la a0, str_add
    	j teste
    	
implementacao_AND:
	la a0, str_and
    	j teste

implementacao_BNE:
	la a0, str_bne
    	j teste

implementacao_BEQ:
	la a0, str_beq
    	j teste

implementacao_JAL:
	la a0, str_jal
    	j teste

implementacao_LUI:
	la a0, str_lui
    	j teste

implementacao_LHU:
	la a0, str_lhu
    	j teste

implementacao_ORI:
	la a0, str_ori
    	j teste

implementacao_SUB:
	la a0, str_sub
    	j teste

implementacao_SLT:
	la a0, str_slt
    	j teste

implementacao_SLL:
	la a0, str_sll
    	j teste

implementacao_SRL:
	la a0, str_srl
    	j teste

implementacao_XOR:
	la a0, str_xor
    	j teste

implementacao_ADDI:
	la a0, str_addi
    	j teste

implementacao_ANDI:
	la a0, str_andi
    	j teste

implementacao_JALR:
	la a0, str_jalr
    	j teste

implementacao_SLTI:
	la a0, str_slti
    	j teste

implementacao_XORI:
	la a0, str_xori
    	j teste

implementacao_AUIPC:
	la a0, str_auipc
    	j teste

teste:
	li a7, 4 # printa string em a0
	ecall
	
	li a7, 11 # prin ta \n
	li a0, 10 
	ecall 
	
procura_quebra_linha:
	lbu t0, 0(s1)
	beq t0, zero, exit # fim de arquivo
    
    	li t1, 10 # '\n' quebra de linha
    	beq t0, t1, quebra_linha
    
    	li t1, 13 # '\r' carriage return
    	beq t0, t1, consome_cr
    
    	addi s1, s1, 1
    	j procura_quebra_linha

consome_cr:
    	addi s1, s1, 1 # Pula o '\r'
    	j procura_quebra_linha

quebra_linha:
    	addi s1, s1, 1 # Pula o '\n'
    	j limpa_espacos_iniciais

limpa_espacos_iniciais:
    	lbu t0, 0(s1)
    	li t1, 32 # ' '
    	beq t0, t1, avanca_espaco_ini
    	li t1, 9 # '\t'
    	beq t0, t1, avanca_espaco_ini
    	j inicia_nova_palavra

avanca_espaco_ini:
    	addi s1, s1, 1
    	j limpa_espacos_iniciais
	

exit:
	addi a7, zero, 10 # syscall encerrar o programa
	ecall
