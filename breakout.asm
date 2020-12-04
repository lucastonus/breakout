.model small

.stack 100H

.data

LOGO  DB ' ___              _            _','#',
      DB '| _ )_______ ____| |_____ _  _| |_','#',
      DB '| _ \  _/ -_) _  | / / _ \ || |  _|','#',
      DB '|___/_| \___\__,_|_\_\___/\_,_|\__|','$'
NOMES DB 'Leandro e Lucas','$'

MENU_OPCAO   DB 0
MENU_OPCAO_0 DB 'Jogar','$'
MENU_OPCAO_1 DB 'Sair','$'

ABRE_COLCHETES  DB '[','$'
FECHA_COLCHETES DB ']','$'
STR_SCORE DB 'SCORE: ','$'
STR_VIDAS DB 'VIDAS: ','$'

SCORE DW 12345
VIDAS DW 3
RAQUETE_POSICAO DW 36

SLEEP_MICRO_SEGUNDOS DW 61A8H
SLEEP_CX DW 6H
SLEEP_DX DW 1A80H

SETA_CIMA     EQU 72 ; Codigo da tecla seta para cima
SETA_BAIXO    EQU 80 ; Codigo da tecla seta para baixo
SETA_ESQUERDA EQU 75 ; Codigo da tecla para esquerda
SETA_DIREITA  EQU 77 ; Codigo da tecla para direita
ENTER         EQU 28 ; Codigo da tecla enter

COR_VERMELHO       EQU 004H
COR_VERMELHO_CLARO EQU 00CH
COR_VERDE          EQU 002H
COR_AMARELO        EQU 00EH
COR_MAGENTA_CLARO  EQU 00DH
COR_CINZA_CLARO    EQU 007H

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
    push AX
    push BX
    push DX
    push SI
    push DI
    
    ; Mostra o nome do jogo
    mov AH, 02H
    mov DI, 564
    mov SI, offset LOGO
    call ESCREVE_STRING
    
    ; Mostra os nomes dos alunos
    mov AH, 04H
    mov DI, 984
    mov SI, offset NOMES 
    call ESCREVE_STRING
    
    pop DI
    pop SI
    pop DX
    pop BX
    pop AX
    ret
endp

; Le a tecla pressionada e retorna em AH o codigo da tecla
LER_TECLA proc    
    mov AH, 0
    int 16H    
    ret
endp

SELECIONA_OPCAO_MENU proc
    push AX
    
    LOOP_OPCAO_MENU:
        call LER_TECLA
        
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
    
    call MODO_VIDEO
    
    cmp MENU_OPCAO, 0
    jne FIM_ACAO_MENU
    call START_BREAKOUT
    
    FIM_ACAO_MENU:
    pop CX
    pop BX
    ret
endp

LIMPAR_TELA proc ; Recebe em CX a quantidade de caracteres e em DI o offset
    push AX
    push CX
    push DI    
    
    LIMPAR_OPCOES:
        mov AX, 0020H
        stosw
        loop LIMPAR_OPCOES
    
    pop DI
    pop CX
    pop AX
    ret
endp

ATUALIZA_MENU proc
    push AX
    push BX
    push DX
    push DI
    push SI
    
    mov CX, 80
    mov DI, 1200
    call LIMPAR_TELA
    
    mov AH, 0FH
    mov DI, 1232
    
    cmp MENU_OPCAO, 0
    jne OPCAO_0
    
    ; Mostra [
    mov SI, offset ABRE_COLCHETES
    call ESCREVE_STRING
    
    OPCAO_0:
        add DI, 2
        mov SI, offset MENU_OPCAO_0
        call ESCREVE_STRING
    
    cmp MENU_OPCAO, 0
    jne PROXIMA_OPCAO
    
    ; Mostra ]
    add DI, 10
    mov SI, offset FECHA_COLCHETES
    call ESCREVE_STRING
    
    PROXIMA_OPCAO:
        mov DI, 1312
        cmp MENU_OPCAO, 1
        jne OPCAO_1
        
        ; Mostra [
        mov SI, offset ABRE_COLCHETES
        call ESCREVE_STRING
    
    OPCAO_1:
        add DI, 2
        mov SI, offset MENU_OPCAO_1
        call ESCREVE_STRING
    
    cmp MENU_OPCAO, 1
    jne MENU_FIM
    
    ; Mostra ]
    add DI, 8
    mov SI, offset FECHA_COLCHETES
    call ESCREVE_STRING
    
    MENU_FIM:
    
    pop SI
    pop DI
    pop DX
    pop BX
    pop AX
    ret
endp

ESCREVE_STRING proc
    push AX
    push SI
    push DI
    
    LOOP_ESCRITA_STRING:
        cmp byte ptr [SI], '#' ; Compara caractere para quebra de linha
        je NOVA_LINHA
        
        cmp byte ptr [SI], '$' ; Compara caractere de fim da string
        je FIM_ESCRITA_STRING
        
        mov AL, [SI]        ; Move endereco do caractere da string para registrador
        stosw
        inc SI              ; Incrementa indice da string para proximo caractere
        jmp LOOP_ESCRITA_STRING
        
        NOVA_LINHA:
            pop DI          
            add DI, 80 ; DI recebe o offset da proxima linha da memoria de video
            push DI
            inc SI     ; Incrementa SI para verificar o proximo caractere
        
        jmp LOOP_ESCRITA_STRING
        
    FIM_ESCRITA_STRING:        
    
    pop DI
    pop SI
    pop AX
    ret
endp

ESCREVE_UINT proc ; Recebe em AX o inteiro e em DI o offset para escrita na memoria de video
    push AX
    push BX
    push CX
    push DX
    push DI

    mov BX, 10 
    xor CX, CX

    LOOP_DIVISAO:
        xor DX, DX  
        div BX
    
        push DX
        inc CX      
    
        cmp AX, 0 
        jnz LOOP_DIVISAO 
        
    LOOP_ESCRITA:
        pop DX
        add DL, '0'
        
        mov ES:[DI], DL
        mov ES:[DI+1], 02H
        add DI, 2 
    
        loop LOOP_ESCRITA
    
    pop DI
    pop DX
    pop CX
    pop BX
    pop AX
    ret
endp

MOSTRA_SCORE_VIDAS proc    
    push AX
    push BX
    push CX
    push DX
    push SI
    push DI
    
    mov AH, 0FH
    mov DI, 0
    mov SI, offset STR_SCORE 
    call ESCREVE_STRING
    
    mov AH, 0FH
    mov DI, 62
    mov SI, offset STR_VIDAS 
    call ESCREVE_STRING
    
    mov CX, 40
    mov DI, 80
    LOOP_BORDA_SUPERIOR:       
        mov AX, 00FC4H
        stosw
        loop LOOP_BORDA_SUPERIOR
    
    pop DI
    pop SI
    pop DX
    pop CX
    pop BX
    pop AX
    ret
endp

ATUALIZAR_SCORE_VIDAS proc
    push AX
    push DI
    
    mov AX, SCORE
    mov DI, 14
    call ESCREVE_UINT
    
    mov AX, VIDAS
    mov DI, 76
    call ESCREVE_UINT
    
    pop DI
    pop AX
    ret
endp

ESCREVE_BLOCOS proc
    push AX
    push CX
    push DI
    
    mov AL, 0B2H ; Codigo do caractere
    mov DI, 164
       
    mov CX, 4
 
    LOOP_LINHA_BLOCO:
        call ATRIBUI_COR_BLOCO
        push CX
        
        mov CX, 6
        LOOP_BLOCO:
            push CX
        
            mov CX, 5
            LOOP_CARACTERE_BLOCO:       
                stosw 
                loop LOOP_CARACTERE_BLOCO
            add DI, 2 
            
        pop CX
        loop LOOP_BLOCO
        add DI, 88
        
    pop CX
    loop LOOP_LINHA_BLOCO
  
    pop DI
    pop CX
    pop AX
    ret
endp

ATRIBUI_COR_BLOCO proc
    COR_4:
        cmp CX, 4
        mov AH, COR_VERMELHO
        je FIM_COR_BLOCO        
    
    COR_3:
        cmp CX, 3
        mov AH, COR_VERMELHO_CLARO
        je FIM_COR_BLOCO
    
    COR_2: 
        cmp CX, 2
        mov AH, COR_VERDE
        je FIM_COR_BLOCO
    
    COR_1:
        mov AH, COR_AMARELO    
    
    FIM_COR_BLOCO:
    ret
endp

ESCREVE_RAQUETE proc
    push AX
    push CX
    push DI
    
    mov AL, 0B2H ; Codigo do caractere
    mov DI, 1920 ; Posicao inicial da ultima linha
    add DI, RAQUETE_POSICAO
         
    mov CX, 5
 
    LOOP_RAQUETE:
        call ATRIBUI_COR_BLOCO_RAQUETE
               
        stosw 
        loop LOOP_RAQUETE 
  
    pop DI
    pop CX
    pop AX
    ret
endp

ATRIBUI_COR_BLOCO_RAQUETE proc
    push DX
    push CX
    push AX
    
    xor DX, DX
    mov AX, 5
    div CX     
    
    cmp DX, 0
    
    pop AX
    mov AH, COR_MAGENTA_CLARO
    je FIM_COR_BLOCO_RAQUETE
    
    mov AH, COR_CINZA_CLARO    
    
    FIM_COR_BLOCO_RAQUETE:
    pop CX
    pop DX
    ret
endp

ATUALIZAR_DADOS_LOOP proc
    push AX
    push BX
    push DX
    
    xor DX, DX  
    
    mov AX, SLEEP_MICRO_SEGUNDOS
    mov BX, 1000H
    div BX
    mov SLEEP_CX, AX
    
    mov AX, SLEEP_MICRO_SEGUNDOS
    mov BX, 10H
    mul BX
    mov SLEEP_DX, AX
    
    pop DX
    pop BX
    pop AX
    ret
endp

MOVIMENTA_RAQUETE proc
    push AX
    push CX
    push DI
    
    mov AH, 01 ; Verifica se existe alguma tecla no buffer
    int 16H

    jz FIM_MOVIMENTA_RAQUETE
    
    mov AH, 0H ; Le e remove a tecla do buffer
    int 16H
    
    cmp AH, SETA_ESQUERDA
    jne VERIFICA_TECLA_DIREITA
    
    cmp RAQUETE_POSICAO, 0
    je  FIM_MOVIMENTA_RAQUETE
     
    sub RAQUETE_POSICAO, 2
    jmp ATUALIZA_RAQUETE
    
    VERIFICA_TECLA_DIREITA:
        cmp AH, SETA_DIREITA
        jne FIM_MOVIMENTA_RAQUETE
        
        cmp RAQUETE_POSICAO, 70
        je  FIM_MOVIMENTA_RAQUETE
    
        add RAQUETE_POSICAO, 2
    
    ATUALIZA_RAQUETE:
        mov CX, 40
        mov DI, 1920
        call LIMPAR_TELA
        call ESCREVE_RAQUETE     
           
    FIM_MOVIMENTA_RAQUETE:
    pop DI
    pop CX
    pop AX
    ret
endp

START_BREAKOUT proc
    push AX
    push CX
    push DX
    
    call MOSTRA_SCORE_VIDAS
    call ESCREVE_BLOCOS
    call ATUALIZAR_SCORE_VIDAS
    call ESCREVE_RAQUETE
    
    LOOP_BREAKOUT:
        call MOVIMENTA_RAQUETE    
        
        mov AH, 86H
        mov CX, SLEEP_CX
        mov DX, SLEEP_DX
        int 15H        
        jmp LOOP_BREAKOUT        
    
    pop DX
    pop CX
    pop AX
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
