.data

	# program counters
	pc_text: .word 0x00000000 # vai incrementando conforme instruções
	pc_data: .word 0x00000000 #  vai incrementando conforme espaços reservados
	
	acumulador_dados: .word 0 
	contador_bytes_dados: .word 0 
	
	secao_atual: .word 0 # data: 0, # text: 1
	
	tabela_rotulos: .space 2400 # tabela onde vamos guardar os rotulos em pares (20 bytes pro texto e 4 bytes para o endereco)
	ponteiro_tabela: .word 0 # aponta pro ultimo elemento da tabela
	
	buffer: .space 2048 # espaco pra ler o arquivo
	buffer_palavra: .space 20 # espaco pra ler palavras
	msg_erro: .string "Erro ao abrir o arquivo\n"
	
	buffer_saida_data: .space 32768 # arquivo de saida do data
	buffer_saida_text: .space 32768 # arquivo de saida do text
	
	ponteiro_saida_data: .word 0 # pos atual data
	ponteiro_saida_text: .word 0 # pos atual text
	
	cabecalho_data: .string "DEPTH = 32768;\nWIDTH = 32;\nADDRESS_RADIX = HEX;\nDATA_RADIX = HEX;\nCONTENT\nBEGIN\n"
	cabecalho_text: .string "DEPTH = 16384;\nWIDTH = 32;\nADDRESS_RADIX = HEX;\nDATA_RADIX = HEX;\nCONTENT\nBEGIN\n"
	
	end_arquivo: .string "END;\n"
	
	msg_entrada: .string "Digite o caminhdo do arquivo .asm: "
	nome_arquivo: .space 256
	
	nome_arquivo_text: .space 256
	nome_arquivo_data: .space 256
	sufixo_text: .string "_text.mif"
	sufixo_data: .string "_data.mif"
	
	str_quebra_linha: .string "\n"
	str_dois_pnts: .string " : "
	str_pnt_virg: .string ";\n"
	
	buffer_hex: .space 9 # espaco pra gravar 8 letras em hex
	
	passagem_atual: .word 1
	
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
	# pede arquivo
	li a7, 4 # syscall print
	la a0, msg_entrada
	ecall
	
	# le digitacao
	li a7, 8 # syscall leitura
	la a0, nome_arquivo
	li a1, 256
	ecall
	
	la t0, nome_arquivo

limpa_enter: # tira o '\n' do final do texto
	lbu t1, 0(t0)
	beq t1, zero, abre_arquivo # se achar NULL, abre o arquivo
	li t2, 10 # '\n'
	beq t1, t2, remove_enter
	addi t0, t0, 1
	j limpa_enter
	
remove_enter:
	sb zero, 0(t0)
	
gera_nomes_saida:
	la t0, nome_arquivo
	la t1, nome_arquivo_text
	la t2, nome_arquivo_data
	
loop_copia:
	lbu t3, 0(t0)
	li t4, 46 # '.'
	beq t3, t4, concatena_nome
	beq t3, zero, concatena_nome
	
	sb t3, 0(t1) # letra para text
	sb t3, 0(t2) # letra para data
	
	addi t0, t0, 1 # avanca nome e destinos
	addi t1, t1, 1
	addi t2, t2, 1
	
	j loop_copia
	
concatena_nome:
	la a0, sufixo_text
	
loop_text:
	lbu t3, 0(a0)
	sb t3, 0(t1)
	beq t3, zero, prepara_data
	addi a0, a0, 1 # avanca string sufixo
	addi t1, t1, 1 # avanca nome
	j loop_text

prepara_data:
	 la a0, sufixo_data

loop_data:
	lbu t3, 0(a0)
	sb t3, 0(t2)
	beq t3, zero, abre_arquivo
	addi a0, a0, 1 # avanca string sufixo
	addi t2, t2, 1 # avanca nome
	j loop_data
	
abre_arquivo:
	# abre arquivo 
	addi a7, zero, 1024 # syscall abre arquivo
	la a0, nome_arquivo 
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
	
	# cabecalho .text
	la a0, cabecalho_text
	la a1, buffer_saida_text
	la a2, ponteiro_saida_text
	jal ra, escreve_string_buffer
	
	# cabecalho .data
	la a0, cabecalho_data
	la a1, buffer_saida_data
	la a2, ponteiro_saida_data
	jal ra, escreve_string_buffer
	
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
	
	beq zero, t0, fim_arquivo # fim arquivo
	
	li t1, 58 # ':'
	beq t0, t1, rotulo # se o char eh ':', pula pra tratamento de rotulo
	
	li t1, 32 # ' '
	beq t0, t1, avalia_espaco # se o char eh ' ', pula pra tratamento de espaco
	
	li t1, 9 # '	(tab)'
	beq t0, t1, avalia_espaco # se o char eh '	(tab)', pula pra tratamento de espaco
	
	li t1, 10 # '\n'
    	beq t0, t1, avalia_espaco # se o char eh '\n', pula pra tratamento de espaco
	
	li t1, 46 # '.'
	beq t0, t1, trata_secao # se o char eh '.', pula pra tratar a secao
	
	sb t0, 0(s2) # grava o char
	addi s2, s2, 1 #avanca gravacao da palavra no buffer
	addi s1, s1, 1 # avanca no arquivo
	j le_char
	

move_ponteiro:
	addi s1, s1, 1
	j le_char
	
rotulo:
	sb zero, 0(s2) # fecha string do rotulo
	
	la t0, tabela_rotulos # pos inicial tabela
	la t1, ponteiro_tabela # endereco do ponteiro
	lw t2, 0(t1)
	add t0, t0, t2 # avanca para pos atual da tabela
	
	addi t3, t0, 0 # inicio da entrda em t3
	
	la t1, buffer_palavra # end do texto do rotulo
	
	
copia_rotulo:
	lbu t2, 0(t1)
	sb t2, 0(t0)
	
	beq t2, zero, salva_endereco_rotulo
	
	addi t0, t0, 1 # incrementa o buffer e a tabela
	addi t1, t1, 1 
	j copia_rotulo
	
salva_endereco_rotulo:
	# verifica secao
	la t1, secao_atual
	lw t2, 0(t1)
	beq t2, zero, grava_em_data
	
	la t1, pc_text # grava em text
	j grava_pc_tabela
	
grava_em_data:
	la t1, pc_data
	
grava_pc_tabela:
	lw t2, 0(t1)
	# coloca o endereço logo apos o nome do rotulo
	sw t2, 20(t3)
	
	la t1, ponteiro_tabela
	lw t2, 0(t1)
	addi t2, t2, 24 # avanca pra prox entrada
	sw t2, 0(t1)
	
	addi s1, s1, 1 # pula ":"
	j inicia_nova_palavra
	
avalia_espaco:
	la t3, buffer_palavra
	beq t3, s2, move_ponteiro # se nao entrou nada no buffer palavra, volta a ler os char
	
	sb zero, 0(s2) # fecha a palavra com NULL
	
	addi s1, s1, 1 # avanca o espaco entre o registrador e o mnemonico
	la a0, buffer_palavra # guarda o end inicial da palavra em a0
	j identifica_instrucao
	
trata_secao:
	lbu t5, 1(s1)
	
	li t0, 100 # 'd'
	beq t5, t0, muda_para_data
	li t0, 68 # 'D'
	beq t5, t0, muda_para_data
	
	li t0, 116 # 't'
	beq t5, t0, muda_para_text
	li t0, 84 # 'T'
	beq t5, t0, muda_para_text
	
	li t0, 119 # 'w' .word
	beq t5, t0, muda_para_word
	li t0, 87 # 'W' WORD
	beq t5, t0, muda_para_word
	
	li t0, 104 # 'h' .half
	beq t5, t0, muda_para_half
	li t0, 72 # 'H' .HALF
	beq t5, t0, muda_para_half
	
	li t0, 98 # 'b' .byte
	beq t5, t0, muda_para_byte
	li t0, 66 # 'B' .BYTE
	beq t5, t0, muda_para_byte
	
	li t0, 115 # 's' .string
	beq t5, t0, muda_para_string
	li t0, 83 # 'S' .STRING
	beq t5, t0, muda_para_string
	
muda_para_data:
	la t1, secao_atual
	sw zero, 0(t1)
	j procura_quebra_linha
	
muda_para_text:
	li t0, 1
	la t1, secao_atual
	sw t0, 0(t1)
	j procura_quebra_linha
	
# secao em data
muda_para_word:
	addi s1, s1, 5 # incrementa o ponteiro pra pular ".word"
	j implementacao_word
	
muda_para_half:
	addi s1, s1, 5 # incrementa o ponteiro pra pular ".half"
	j implementacao_half

muda_para_byte:
	addi s1, s1, 5 # incrementa o ponteiro pra pular ".byte"
	j implementacao_byte

muda_para_string:
	addi s1, s1, 7 # incrementa o ponteiro pra pular ".byte"
	j implementacao_string

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
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha

	la a0, str_lw
    	j teste
    	
implementacao_OR:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_or
    	j teste

implementacao_SW:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_sw
    	j teste

implementacao_ADD:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_add
    	j teste
    	
implementacao_AND:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_and
    	j teste

implementacao_BNE:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_bne
    	j teste

implementacao_BEQ:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_beq
    	j teste

implementacao_JAL:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_jal
    	j teste

implementacao_LUI:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_lui
    	j teste

implementacao_LHU:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_lhu
    	j teste

implementacao_ORI:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_ori
    	j teste

implementacao_SUB:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_sub
    	j teste

implementacao_SLT:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_slt
    	j teste

implementacao_SLL:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_sll
    	j teste

implementacao_SRL:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_srl
    	j teste

implementacao_XOR:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_xor
    	j teste

implementacao_ADDI:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_addi
    	j teste

implementacao_ANDI:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_andi
    	j teste

implementacao_JALR:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_jalr
    	j teste

implementacao_SLTI:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_slti
    	j teste

implementacao_XORI:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_xori
    	j teste

implementacao_AUIPC:
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, procura_quebra_linha
	
	la a0, str_auipc
    	j teste
    	
# implementacoes data
implementacao_word:
	# TODO ler os numeros e quebrar em 4 bytes, chamar processa_byte_data para cada byte
	j procura_quebra_linha
	
implementacao_half:
	# TODO ler os numeros e quebrar em 2 bytes, chamar processa_byte_data para cada byte
	j procura_quebra_linha

implementacao_byte:
	# TODO ler os numero, chamar processa_byte_data para o byte
	j procura_quebra_linha

implementacao_string:
	# TODO ler as letras e ate o nulo (0x00), chamar processa_byte_data para cada char
	j procura_quebra_linha

# -- temporario
teste:
	# olha secao atual
	la t0, secao_atual
	lw t1, 0(t0)
	beq t1, zero, prepara_data_buffer
	
prepara_text_buffer:
	la a1, buffer_saida_text
	la a2, ponteiro_saida_text
	j grava_string_buffer
	
prepara_data_buffer:
	la a1, buffer_saida_data
	la a2, ponteiro_saida_data

grava_string_buffer:
	jal ra, escreve_string_buffer # 'grava o mnemonico no buffer'
	la a0, str_quebra_linha
	jal ra, escreve_string_buffer # quebra linha	
# --

procura_quebra_linha:
	lbu t0, 0(s1)
	beq t0, zero, fim_arquivo # fim de arquivo
    
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
	
fim_arquivo: # só finaliza se estiver na segunda passagem
	la t0, passagem_atual
	lw t1, 0(t0)
	
	li t2,1
	beq t1, t2, comeca_segunda
	
	j exit
	
comeca_segunda:
	li t1, 2
	sw t1, 0(t0) # grava que estamos na segunda passagem
	
	la t0, pc_text # zera o pc da text
	sw zero, 0(t0)
	
	la t0, pc_data # zera o pc da data
	sw zero, 0(t0)
	
	la t0, secao_atual # retorna para o comeco da . data
	sw zero, 0(t0)
	
	j inicia_scanner

exit:
	# verifica passagem atual pra gerar o padding
	la t0, passagem_atual
	lw t1, 0(t0)
	li t2, 2
	bne t1, t2, finaliza_arquivos 
	
	la t0, secao_atual
	sw zero, 0(t0) # vai pra data para dar o padding
	
loop_padding_data:
	la t0, pc_data
	lw t1, 0(t0)
	li t2, 4096 # 1024 linhas x 4 bytes
	bge t1, t2, finaliza_arquivos
	
	li a0, 0 # preenche com 0x00
	jal ra, processa_byte_data
	j loop_padding_data
	
finaliza_arquivos:
	la a0, end_arquivo # grava 'END;' nos dois arquivos
	la a1, buffer_saida_data
	la a2, ponteiro_saida_data
	
	jal ra, escreve_string_buffer
	
	la a0, end_arquivo
	la a1, buffer_saida_text
	la a2, ponteiro_saida_text
	
	jal ra, escreve_string_buffer

	li a7, 1024 # syscall abrir arquivo
	la a0, nome_arquivo_text 
	li a1, 1 # flag de apenas escrita
	ecall
	blt a0, zero, salva_data # se der qualquer erro -1, tenta salvar a data
	addi s3, a0, 0 # salva o file descriptor
	
	li a7, 64 # syscall de escrita no arquivo
	addi a0, s3, 0
	la a1, buffer_saida_text
	la t0, ponteiro_saida_text
	lw a2, 0(t0) # tamanho do text
	ecall
	
	li a7, 57 # syscall fechar arquivo
	addi a0, s3, 0
	ecall
	
salva_data:
	li a7, 1024 # syscall abrir arquivo
	la a0, nome_arquivo_data 
	li a1, 1 # flag de apenas escrita
	ecall
	blt a0, zero, encerra_programa # se der qualquer erro -1, encerra
	addi s3, a0, 0 # salva o file descriptor
	
	li a7, 64 # syscall de escrita no arquivo
	addi a0, s3, 0
	la a1, buffer_saida_data
	la t0, ponteiro_saida_data
	lw a2, 0(t0) # tamanho do data
	ecall
	
	li a7, 57 # syscall fechar arquivo
	addi a0, s3, 0
	ecall	

encerra_programa:
	addi a7, zero, 10 # syscall encerrar o programa
	ecall
	
# procedimento
# a0 = endereco da string a ser gravada
# a1 = endereco do buffer de saida
# a2 = endereco do ponteiro do buffer
escreve_string_buffer:
	lw t0, 0(a2) # deslocamento do buffer
	add t1, t0, a1 # endereco inicial da escrita

loop_escrita:
	lbu t2, 0(a0)
	beq t2, zero, fim_escreve_string_buffer
	
	sb t2, 0(t1) # salva char no buffer
	
	addi t1, t1, 1 # avanca buffer
	addi a0, a0, 1 # avanca string
	addi t0, t0, 1 # avanca tamanho do ponteiro
	j loop_escrita
	
fim_escreve_string_buffer:
	sw t0, 0(a2) # novo tamanho do ponteiro
	jr ra
	
# procedimento verificar passagem (ret a0 = 0 se segunda passagem. ret a0 = 1 se primeira passagem)
verifica_primeira_passagem:
	la t0, secao_atual
	lw t1, 0(t0)
	bne t1, zero, incrementa_text
	j checa_passagem
	
incrementa_text:
	la t0, pc_text
	lw t1, 0(t0)
	addi t1, t1, 4
	sw t1, 0(t0)
	
checa_passagem:
	la t0, passagem_atual
	lw t1, 0(t0)
	
	li t2, 1
	beq t1, t2, primeira_passagem
	
	li a0, 0 # segunda passagem
	jr ra
	
primeira_passagem:	
	li a0, 1
	jr ra
	
# procedimento
# converte inteiro (em a0) para string hex
# a1 = end de destino

int_to_hex_string:
	li t0, 8 # contador de digitos
	add t1, a0, zero # armazena int em a1
	add t2, a1, zero # ponteiro de gravacao

loop_hex:
	srli t3, t1, 28 # coloca em t3 o nibble mais significativo
	andi t3, t3, 0xF # salva apenas o nible a direita
	
	li t4, 9
	ble t3, t4, num_hex
	
letra_hex:
	addi t3, t3, 55 # casa com o correspondente a A - F na table ascii
	j salva_hex
	
num_hex:
	addi t3, t3, 48 # casa com correspondende 0 - 9 na table ascii
	
salva_hex:
	sb t3, 0(t2) # salva char no buffer
	 slli t1, t1, 4 # bits processados sao descartados
	 addi t2, t2, 1 # avanca ponteiro buffer
	 addi t0, t0, -1 # avanca contador (diminui)
	 bne t0, zero, loop_hex
	 
	 sb zero, 0(t2) # null no fim da string
	 jr ra
	 
# procedimento
# guardar linha no .mif ("end : instrucao;\n")
# a0 = instrucao binaria
grava_linha_mif:
	#reserva 2 espacos na pilha
	addi sp, sp, -8
	sw ra, 4(sp) # salva ra atual na pilha
	sw a0, 0(sp) # salva instrucao na pilha
	
	la t0, secao_atual # escolhe o pc da secao atual
	lw t1, 0(t0)
	beq t1, zero, pc_data_mif
	
pc_text_mif:
	la t0, pc_text
	lw t2, 0(t0)
	la a1, buffer_saida_text
	la a2, ponteiro_saida_text
	j calcula_end_mif
	
pc_data_mif:
	la t0, pc_data
	lw t2, 0(t0)
	la a1, buffer_saida_data
	la a2, ponteiro_saida_data
	j calcula_end_mif

calcula_end_mif:
	# voltamos 4 no pc pois a verifica_passagem já somou 4
	addi t2, t2, -4
	# dividimos por 4 usando o deslocamento para esquerda duas vezes
	srli a0, t2, 2 # fazemos isso porque o arquivo .mif anda de 1 em 1 ao inves de 4 em 4
	
	# salvamos o buffer e ponteiro na pila
	addi sp, sp, -8
	sw a1, 4(sp)
	sw a2, 0 (sp)
	
	la a1, buffer_hex
	jal ra, int_to_hex_string # converte o endereco para hex
	# grava
	la a0, buffer_hex
	lw a1, 4(sp)
	lw a2, 0(sp)
	jal ra, escreve_string_buffer # grava no buffer de saida
	
	la a0, str_dois_pnts
	lw a1, 4(sp)
	lw a2, 0(sp)
	jal ra, escreve_string_buffer # grava no buffer de saida
	
	# recuperamos a a0 inicial (instrucao)
	lw a0, 8(sp)
	la a1, buffer_hex
	jal ra, int_to_hex_string # converte a instrucao
	la a0, buffer_hex
	lw a1, 4(sp)
	lw a2, 0(sp)
	jal ra, escreve_string_buffer  # grava instrucao no buffer de saida

	# grava, por fim ";\n"
	la a0, str_pnt_virg
	lw a1, 4(sp)
	lw a2, 0(sp)
	jal ra, escreve_string_buffer
	
	# recupera a pilha
	addi sp, sp, 8
	lw a0, 0(sp)
	lw ra, 4(sp)
	addi sp, sp, 8
	jr ra
	
# procedimento
# processa o byte para adicionar em .data
# a0 = byte em hex a ser processado

processa_byte_data:
	addi sp, sp, -16 # abre 4 espacos na pilha
	sw ra, 12(sp) # salva ra
	sw a0, 8(sp) # salva byte a ser processado
	
	la t0, pc_data # incrementa pc_data
	lw t1, 0(t0)
	addi t1, t1, 1
	sw t1, 0(t0)
	
	# se for primeira passagem, nao continua
	jal ra, verifica_primeira_passagem
	li t0, 1
	beq a0, t0, pb_fim
	
pb_segunda_passagem:
	lw a0, 8(sp) # recupera o byte passado
	
	la t0, contador_bytes_dados
	lw t1, 0(t0) # olha quantos bytes já estão processados
	
	slli t2, t1, 3 # multiplica o contador por 8 para achar quanto precisa deslocar os 32 bits
	sll a0, a0, t2
	
	la t3, acumulador_dados
	lw t4, 0(t3)
	or t4, t4, a0 # com a ou ele realiza uma "colagem" no acumulador
	sw t4, 0(t3)
	
	addi t1, t1, 1 # prox byte
	sw t1, 0(t0)
	
	# verifica se fechou a word
	li t5, 4
	bne t1, t5, pb_fim
	
	# se fechou, grava a linha
	add a0, t4, zero # a0 recebe a word montada
	jal ra, grava_linha_mif
	
	# esvazia para prox word
	la t0, contador_bytes_dados
	sw zero, 0(t0)
	la t3, acumulador_dados
	sw zero, 0(t3)
	
pb_fim:
	# recupera pilha
	lw ra, 12(sp)
	addi sp, sp, 16
	jr ra
	