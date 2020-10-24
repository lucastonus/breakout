.model small

.stack 100H

.data

LOGO  DB ' ___              _            _','#','| _ )_______ ____| |_____ _  _| |_','#','| _ \  _/ -_) _  | / / _ \ || |  _|','#','|___/_| \___\__,_|_\_\___/\_,_|\__|','$'
NOMES DB 'Leandro e Lucas','$'

MENU_OPCAO   DB 0
MENU_OPCAO_0 DB 'Jogar','$'
MENU_OPCAO_1 DB 'Sair','$'

ABRE_COLCHETES  DB '[','$'
FECHA_COLCHETES DB ']','$'

SETA_CIMA  EQU 72 ; Codigo da tecla seta para cima
SETA_BAIXO EQU 80 ; Codigo da tecla seta para baixo
ENTER      EQU 28 ; Codigo da tecla enter

.code

MODO_VIDEO proc ; Define o modo de video
    push AX
    
    mov AX, 0B800H ; Atribui ao extra segment o endereco inicial da memoria de video
    mov ES, AX

    mov AH, 0H  ; Seta o modo de video
    mov AL, 01H ; Modo de video 40 x 25 16 cores
    int 10H     ; Interrupcao de configuracao de video
    
    pop AX
    ret
endp

MOSTRA_INTRO proc ; Mostra tela inicial do jogo
    push BX
    push DX
    push SI
    
    ; Mostra o nome do jogo
    mov DH, 02H
    mov BX, 282
    mov SI, offset LOGO
    call ESCREVE_STRING
    
    ; Mostra os nomes dos alunos
    mov DH, 04H
    mov BX, 492
    mov SI, offset NOMES 
    call ESCREVE_STRING
    
    pop SI
    pop DX
    pop BX
    ret
endp

; Le a tecla pressionada e retorna em AH o codigo da tecla
LER_TECLA proc
    mov AH, 0
    int 16h    
    ret
endp

SELECIONA_OPCAO_MENU proc
    push AX
    
    LOOP_OPCAO_MENU:
        call LER_TECLA
    
    TECLA_CIMA:    
        cmp AH, SETA_CIMA
        jne TECLA_BAIXO
        
        mov MENU_OPCAO, 0
        call ATUALIZA_MENU
    
    TECLA_BAIXO:
        cmp AH, SETA_BAIXO
        jne TECLA_ENTER
        
        mov MENU_OPCAO, 1
        call ATUALIZA_MENU       
    
    TECLA_ENTER:
        cmp AH, ENTER
        jne LOOP_OPCAO_MENU
    
    pop AX
    ret
endp

ACAO_MENU proc
    push BX
    push CX
    
    cmp MENU_OPCAO, 0
    je ACAO_0
    jne ACAO_1
    
    ACAO_0:
        call START_BREAKOUT
    
    ACAO_1:
        mov CX, 1000
        mov BX, 0
        call LIMPAR_TELA 
    
    pop CX
    pop BX
    ret
endp

LIMPAR_TELA proc ; Recebe em CX a quantidade de caracteres e em BX o offset
    push AX
    
    ; Limpa as duas linhas do menu
    LIMPAR_OPCOES:
        mov ES:[BX], ' '
        inc BX
        mov ES:[BX], 0H
        inc BX
        loop LIMPAR_OPCOES
    
    pop AX
    ret
endp

ATUALIZA_MENU proc
    push BX
    push DX
    push SI
    
    mov CX, 80
    mov BX, 1200
    call LIMPAR_TELA
    
    mov DH, 0FH
    mov BX, 616
    
    cmp MENU_OPCAO, 0
    jne OPCAO_0
    
    ; Mostra [
    mov SI, offset ABRE_COLCHETES
    call ESCREVE_STRING
    
    OPCAO_0:
        inc BX
        mov SI, offset MENU_OPCAO_0
        call ESCREVE_STRING
    
    cmp MENU_OPCAO, 0
    jne PROXIMA_OPCAO
    
    ; Mostra ]
    add BX, 5
    mov SI, offset FECHA_COLCHETES
    call ESCREVE_STRING
    
    PROXIMA_OPCAO:
        mov BX, 656
        cmp MENU_OPCAO, 1
        jne OPCAO_1
        
        ; Mostra [
        mov SI, offset ABRE_COLCHETES
        call ESCREVE_STRING
    
    OPCAO_1:
        inc BX
        mov SI, offset MENU_OPCAO_1
        call ESCREVE_STRING
    
    cmp MENU_OPCAO, 1
    jne MENU_FIM
    
    ; Mostra ]
    add BX, 4
    mov SI, offset FECHA_COLCHETES
    call ESCREVE_STRING
    
    MENU_FIM:
    
    pop SI
    pop DX
    pop BX
    ret
endp

ESCREVE_STRING proc
    push AX
    push DI
    
    mov DI, BX ; DI recebe o offset para escrita na memoria de video
    
    LOOP_ESCRITA_LOGO:
        cmp byte ptr [SI],'#' ; Compara caractere para quebra de linha
        je NOVA_LINHA
        
        cmp byte ptr [SI],'$' ; Compara caractere de fim da string
        je FIM_ESCRITA_LOGO
        
        mov DL, [SI]        ; Move endereco do caractere da string para registrador
        mov ES:[BX+DI], DL  ; Escreve valor do caractere na memoria do video
        inc DI              ; Incrementa DI para atribuir cores
        mov ES:[BX+DI], DH ; 0 cor do background, 2 cor da fonte
        inc DI              ; Incrementa DI para proxima escrita
        inc SI              ; Incrementa indice da string para proximo caractere
        jmp LOOP_ESCRITA_LOGO
        
        NOVA_LINHA:          
            add BX, 40 ; Soma 40 para ir para proxima linha
            mov DI, BX ; DI recebe o offset da proxima linha da memoria de video
            inc SI     ; Incrementa SI para verificar o proximo caractere
        
        jmp LOOP_ESCRITA_LOGO
        
    FIM_ESCRITA_LOGO:        
    
    pop DI
    pop AX
    ret
endp

START_BREAKOUT proc
    
    ret
endp


INICIO:
    mov AX, @DATA
    mov DS, AX
    
    call MODO_VIDEO
    call MOSTRA_INTRO
    call ATUALIZA_MENU
    call SELECIONA_OPCAO_MENU
    call ACAO_MENU

    mov AH, 4CH
    int 21H
end INICIO
