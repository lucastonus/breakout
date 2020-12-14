.model small

.stack 100H

.data

LOGO DB ' ___              _            _','#',
     DB '| _ )_______ ____| |_____ _  _| |_','#',
     DB '| _ \  _/ -_) _  | / / _ \ || |  _|','#',
     DB '|___/_| \___\__,_|_\_\___/\_,_|\__|','$'

FIM_JOGO DB ' ___       __  ___      __  __  __','#',
         DB '|__ ||\/| |  \|__     |/  \/ _`/  \','#',
         DB '|   ||  | |__/|___ \__/\__/\__>\__/','$'

NOMES DB 'Leandro e Lucas','$'

MENU_OPCAO   DB 0
MENU_OPCAO_0 DB 'Jogar','$'
MENU_OPCAO_1 DB 'Sair','$'

ABRE_COLCHETES  DB '[','$'
FECHA_COLCHETES DB ']','$'
STR_SCORE       DB 'SCORE: ','$'
STR_VIDAS       DB 'VIDAS: ','$'

SCORE DW ?
VIDAS DW ?
QTD_BLOCOS_DESTRUIDOS DW 0

RAQUETE_POSICAO DW ?
BOLA_POSICAO    DW ?
BOLA_X DW 2 ; 2 = Direita, -2 Esquerda
BOLA_Y DW -80 ; 80 = Baixo, -80 Cima
BOLA   DW 0FFEH

SLEEP_MICRO_SEGUNDOS DW 61A8H
SLEEP_CX DW 6H
SLEEP_DX DW 1A80H

SETA_CIMA     EQU 72 ; Codigo da tecla seta para cima
SETA_BAIXO    EQU 80 ; Codigo da tecla seta para baixo
SETA_ESQUERDA EQU 75 ; Codigo da tecla para esquerda
SETA_DIREITA  EQU 77 ; Codigo da tecla para direita
ENTER         EQU 28 ; Codigo da tecla enter

CODIGO_BLOCO       EQU 0B2H
COR_BRANCO         EQU 0FH
COR_VERMELHO       EQU 004H
COR_VERMELHO_CLARO EQU 00CH
COR_VERDE          EQU 002H
COR_AMARELO        EQU 00EH
COR_MAGENTA_CLARO  EQU 00DH
COR_CINZA_CLARO    EQU 007H
CORES  DB COR_AMARELO, COR_VERDE, COR_VERMELHO_CLARO, COR_VERMELHO
SCORES DW 1, 3, 5, 7 ; Score de cada bloco respectivo a posicao do array CORES

.code

MODO_VIDEO proc ; Define o modo de video
    push AX

    mov AX, 0B800H ; Atribui ao extra segment o endereco inicial da memoria de video
    mov ES, AX

    mov AH, 0H  ; Seta o modo de video
    mov AL, 01H ; Modo de video 40 x 25, 16 cores
    int 10H     ; Interrupcao de configuracao de video

    pop AX
    ret
endp

MOSTRA_INTRO proc ; Mostra tela inicial do jogo
    push AX
    push SI
    push DI

    ; Mostra o nome do jogo na cor verde
    mov AH, COR_VERDE
    mov DI, 564
    mov SI, offset LOGO
    call ESCREVE_STRING

    ; Mostra os nomes dos alunos na cor vermelha
    mov AH, COR_VERMELHO
    mov DI, 984
    mov SI, offset NOMES
    call ESCREVE_STRING

    pop DI
    pop SI
    pop AX
    ret
endp

; Le a tecla pressionada e retorna em AH o codigo da tecla
LER_TECLA proc
    mov AH, 0
    int 16H
    ret
endp

;MENU_OPCAO = 0: Jogar
;MENU_OPCAO = 1: Sair
SELECIONA_OPCAO_MENU proc
    push AX
    
    ; Teclas aceitas: Setas esquerda e direita e enter
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

; Executa uma acao de acordo com a opcao escolhida do menu
ACAO_MENU proc
    push AX

    call LIMPAR_TELA

    cmp MENU_OPCAO, 0
    jne FIM_ACAO_MENU
    call START_BREAKOUT

    mov AH, 7H
    int 21H

    call MOSTRAR_TELA_INICIAL

    FIM_ACAO_MENU:

    pop AX
    ret
endp

; Recebe em CX a quantidade de caracteres e em DI o offset na memoria de video
LIMPAR_TELA_PARCIALMENTE proc
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

; Scroll up na tela de video para limpar a tela
LIMPAR_TELA proc
    push AX
    push BX
    push CX
    push DX

    mov AH, 06H
    mov AL, 0H

    xor BH, BH
    xor CX, CX

    mov DH, 24
    mov DL, 39

    int 10H

    pop DX
    pop CX
    pop BX
    pop AX
    ret
endp

; Atualiza colchetes na opcao selecionada no menu
ATUALIZA_MENU proc
    push AX
    push BX
    push DX
    push DI
    push SI

    mov CX, 80
    mov DI, 1200
    call LIMPAR_TELA_PARCIALMENTE

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

; Escreve uma string localizada em SI na posicao especificada em DI
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

; Recebe em AX um inteiro e em DI o offset para escrita na memoria de video na cor verde
ESCREVE_UINT proc
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
        mov ES:[DI+1], COR_VERDE
        add DI, 2

        loop LOOP_ESCRITA

    pop DI
    pop DX
    pop CX
    pop BX
    pop AX
    ret
endp

; Escreve strings de score e vidas, e uma borda branca abaixo da escrita
; para separar as informacoes dos blocos
MOSTRA_STR_SCORE_VIDAS proc
    push AX
    push CX
    push SI
    push DI

    mov AH, COR_BRANCO
    
    xor DI, DI
    mov SI, offset STR_SCORE
    call ESCREVE_STRING

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
    pop CX
    pop AX
    ret
endp

; Atualiza em tela os valores de score e vidas
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

; Escreve os blocos nas respectivas cores definidas no array de CORES
ESCREVE_BLOCOS proc
    push AX
    push BX
    push CX
    push DI

    mov AL, CODIGO_BLOCO
    mov DI, 164

    mov CX, 4

    LOOP_LINHA_BLOCO:
        mov BX, CX
        dec BX
        mov AH, CORES[BX]

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
    pop BX
    pop AX
    ret
endp

ESCREVE_RAQUETE proc
    push AX
    push CX
    push DI
    
    ; Limpa a penultima e ultima linha
    mov CX, 80
    mov DI, 1840
    call LIMPAR_TELA_PARCIALMENTE

    mov AL, CODIGO_BLOCO
    mov DI, 1920 ; Posicao inicial da ultima linha
    add DI, RAQUETE_POSICAO
    
    ; Escreve a raquete em tela
    mov CX, 5

    LOOP_RAQUETE:
        call ATRIBUI_COR_BLOCO_RAQUETE
        stosw
        loop LOOP_RAQUETE

    mov DI, BOLA_POSICAO
    mov AX, BOLA
    stosw

    pop DI
    pop CX
    pop AX
    ret
endp

ATRIBUI_COR_BLOCO_RAQUETE proc
    push DX
    push CX
    push AX
    
    ; Divisao inteira por 5
    xor DX, DX
    mov AX, 5
    div CX

    cmp DX, 0

    pop AX
    ; Se for 1 ou 5, atribui cor magenta, se nao, cinza
    mov AH, COR_MAGENTA_CLARO
    je FIM_COR_BLOCO_RAQUETE

    mov AH, COR_CINZA_CLARO

    FIM_COR_BLOCO_RAQUETE:
    pop CX
    pop DX
    ret
endp

; Atualiza variaveis SLEEP_CX e SLEEP_DX, de acordo com variavel SLEEP_MICRO_SEGUNDOS 
ATUALIZAR_DADOS_SLEEP proc
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
    
    ; Se for pressionada tecla esquerda
    cmp AH, SETA_ESQUERDA
    jne VERIFICA_TECLA_DIREITA

    cmp RAQUETE_POSICAO, 0
    je  FIM_MOVIMENTA_RAQUETE

    sub RAQUETE_POSICAO, 2
    jmp ATUALIZA_RAQUETE
    
    ; Se for pressionada tecla direita
    VERIFICA_TECLA_DIREITA:
        cmp AH, SETA_DIREITA
        jne FIM_MOVIMENTA_RAQUETE

        cmp RAQUETE_POSICAO, 70
        je  FIM_MOVIMENTA_RAQUETE

        add RAQUETE_POSICAO, 2
    
    ; Atualiza a posicao da raquete em video, limpando a ultima linha antes
    ATUALIZA_RAQUETE:
        mov CX, 40
        mov DI, 1920
        call LIMPAR_TELA_PARCIALMENTE
        call ESCREVE_RAQUETE

    FIM_MOVIMENTA_RAQUETE:
    pop DI
    pop CX
    pop AX
    ret
endp

; Retorna em DX um inteiro de 0 a 9
; Utilizada interrupcao 1AH (hora do sistema)
UINT_ALEATORIO proc
    push AX
    push BX
    push CX

    mov AH, 0H
    int 1AH

    mov AX, DX
    xor DX, DX
    mov CX, 10
    div CX

    pop CX
    pop BX
    pop AX
    ret
endp

; Atribui posicao da raquete aleatoriamente, com a bola no meio da raquete
ATRIBUI_POSICAO_RAQUETE_BOLA proc
    push AX
    push BX
    push CX
    push DX

    LOOP_CX:
        call UINT_ALEATORIO
        cmp DX, 7
        ja LOOP_CX

    inc DX

    xor AX, AX
    mov CX, DX
    LOOP_POSICAO_RAQUETE:
        call UINT_ALEATORIO
        add AX, DX
        loop LOOP_POSICAO_RAQUETE

    push AX
    and AX, 1
    pop AX
    jz POSICAO_RAQUETE_PAR

    inc AX

    POSICAO_RAQUETE_PAR:
        mov RAQUETE_POSICAO, AX

    mov BOLA_POSICAO, 1840
    add BOLA_POSICAO, AX
    add BOLA_POSICAO, 4

    call UINT_ALEATORIO
    mov AX, DX
    xor DX, DX
    mov BX, 2
    div BX

    cmp DL, 0
    jne FIM_ATRIBUI_POSICAO_RAQUETE_BOLA
        neg BOLA_X

    FIM_ATRIBUI_POSICAO_RAQUETE_BOLA:
    pop DX
    pop CX
    pop BX
    pop AX
    ret
endp

MOVIMENTA_BOLA proc
    push DI

    ; Limpa bola de sua posicao anterior
    mov DI, BOLA_POSICAO
    xor AX, AX
    stosw

    ; Atualiza variavel BOLA_POSICAO com a nova posicao da bola
    mov AX, BOLA_POSICAO
    add AX, BOLA_X
    add AX, BOLA_Y
    mov BOLA_POSICAO, AX

    call VERIFICA_COLISAO_BLOCO

    ;Escreve bola na nova posicao
    mov DI, BOLA_POSICAO
    mov AX, BOLA
    stosw

    pop DI
    ret
endp

AUMENTAR_VELOCIDADE proc
    push AX
    push BX
    push CX
    push DX

    mov CX, BX
    
    ; Verifica se o bloco e da cor vermelha, se for diminui tempo do sleep para 100ms
    cmp CH, COR_VERMELHO
    je ATRIBUIR_VELOCIDADE_MAXIMA

    cmp CH, COR_VERMELHO_CLARO
    je ATRIBUIR_VELOCIDADE_MAXIMA
    jne DIMINUIR_50_MS

    ATRIBUIR_VELOCIDADE_MAXIMA:
        mov SLEEP_MICRO_SEGUNDOS, 186AH
        call ATUALIZAR_DADOS_SLEEP
        jmp FIM_AUMENTAR_VELOCIDADE
    
    ; Se a cor do bloco for verde ou amarelo, diminui tempo do sleep em 50ms
    ; se a quantidade de blocos destruidos for divisivel por 4
    DIMINUIR_50_MS:
        xor DX, DX
        mov AX, QTD_BLOCOS_DESTRUIDOS
        mov BX, 4
        div BX

        cmp DL, 0
        jne FIM_AUMENTAR_VELOCIDADE

        cmp SLEEP_MICRO_SEGUNDOS, 186AH
        je FIM_AUMENTAR_VELOCIDADE
        sub SLEEP_MICRO_SEGUNDOS, 0C35H
        call ATUALIZAR_DADOS_SLEEP

    FIM_AUMENTAR_VELOCIDADE:

    pop DX
    pop CX
    pop BX
    pop AX
    ret
endp

; Suspende a execucao do programa pelo tempo determinado nas variaveis: SLEEP_CX e SLEEP_DX 
SLEEP proc
    push AX
    push CX
    push DX

    mov AH, 86H
    mov CX, SLEEP_CX
    mov DX, SLEEP_DX
    int 15H

    pop DX
    pop CX
    pop AX
    ret
endp

; Verifica se a bola esta adjacente as paredes laterais e superior
VERIFICA_COLISAO_PAREDES proc
    push AX
    push BX
    push DX
    
    ; Se a posicao da bola for divisivel por 80, inverte a posicao de X (parede esquerda)
    xor DX, DX
    mov AX, BOLA_POSICAO
    mov BX, 80
    div BX

    cmp DL, 0
    je INVERTE_X
    
    ; Se a posicao da bola menos 78 for divisivel por 80, inverte a posicao de X (parede direita)
    cmp BOLA_POSICAO, 78
    jb FIM_VERIFICA_COLISAO_PAREDES_X

    xor DX, DX
    mov AX, BOLA_POSICAO
    sub AX, 78
    mov BX, 80
    div BX

    cmp DL, 0
    jne FIM_VERIFICA_COLISAO_PAREDES_X

    INVERTE_X:
        cmp BOLA_POSICAO, 1840
        je FIM_VERIFICA_COLISAO_PAREDES_X
        
        cmp BOLA_POSICAO, 1919
        je FIM_VERIFICA_COLISAO_PAREDES_X
    
        neg BOLA_X

    FIM_VERIFICA_COLISAO_PAREDES_X:
    
    ; Se a posicao da bola for inferior a 239, inverte posicao de Y (parede superior)
    cmp BOLA_POSICAO, 239
    ja FIM_VERIFICA_COLISAO_PAREDES_Y

    INVERTE_Y_SUPERIOR:
        neg BOLA_Y

    FIM_VERIFICA_COLISAO_PAREDES_Y:

    pop DX
    pop BX
    pop AX
    ret
endp

VERIFICA_COLISAO_INFERIOR proc
    push AX
    push SI
    
    ; Verifica se a posicao da bola e inferior a 1840, nao ha colisao
    cmp BOLA_POSICAO, 1840
    jb FIM_VERIFICA_COLISAO_INFERIOR
    
    ; Se a posicao da bola for superior a 1918 (ultima linha), decrementa a vida
    cmp BOLA_POSICAO, 1918
    ja JMP_DECREMENTAR_VIDA
    
    ; Verifica se na posicao abaixo da bola existe um caratere igual ao bloco
    mov SI, BOLA_POSICAO
    add SI, 80

    mov AX, ES:[SI]

    cmp AL, CODIGO_BLOCO
    jne FIM_VERIFICA_COLISAO_INFERIOR
    
    ; Se o bloco for da cor cinza, inverte Y
    cmp AH, COR_CINZA_CLARO
    je INVERTE_Y_INFERIOR
    
    ; Se o bloco for da cor magenta e difetente das extremidades inverte X
    ; (proc de colisao das paredes ja inverte X)
    cmp BOLA_POSICAO, 1840
    je INVERTE_Y_INFERIOR
    
    cmp BOLA_POSICAO, 1919
    je INVERTE_Y_INFERIOR
    
    neg BOLA_X

    INVERTE_Y_INFERIOR:
        cmp QTD_BLOCOS_DESTRUIDOS, 0
        je FIM_VERIFICA_COLISAO_INFERIOR
        neg BOLA_Y

    jmp FIM_VERIFICA_COLISAO_INFERIOR
    
    JMP_DECREMENTAR_VIDA:
        call DECREMENTAR_VIDA

    FIM_VERIFICA_COLISAO_INFERIOR:

    pop SI
    pop AX
    ret
endp

; Verifica se a posicao da bola esta colidindo com um bloco
VERIFICA_COLISAO_BLOCO proc
    push AX
    push BX
    push CX
    push SI
    push DI
    
    ; Se a posicao da bola nao colide com um bloco, pula para o fim da proc
    mov SI, BOLA_POSICAO
    mov AX, ES:[SI]
    cmp AL, CODIGO_BLOCO
    jne FIM_VERIFICA_COLISAO_BLOCO

    mov BX, AX
    
    ; Move para DI a posicao inicial do bloco colidido
    LOOP_COLISAO_BLOCO:
        sub SI, 2
        mov AX, ES:[SI]
        cmp AL, CODIGO_BLOCO
        je LOOP_COLISAO_BLOCO
    
    ; Remove o bloco da tela
    mov CX, 5
    mov DI, SI
    inc DI
    xor AX, AX
    LOOP_REMOVE_BLOCO:
        stosw
        loop LOOP_REMOVE_BLOCO
    
    call SOMA_SCORE
    call SOMA_QTD_BLOCOS_DESTRUIDOS
    call AUMENTAR_VELOCIDADE

    FIM_VERIFICA_COLISAO_BLOCO:

    pop DI
    pop SI
    pop CX
    pop BX
    pop AX
    ret
endp

; Recebe em BX o caractere do bloco
SOMA_SCORE proc 
    push AX
    push BX
    push SI
    
    ; Compara a posicao da cor respectiva no array de SCORES
    xor SI, SI
    LOOP_SOMA_SCORE:
        cmp BH, CORES[SI]
        je OBTEM_SCORE_COR
        inc SI
        jne LOOP_SOMA_SCORE

    OBTEM_SCORE_COR:
        mov BX, 2
        mov AX, SI
        mul BX
        mov SI, AX
        
        ; Soma score do bloco no score do jogador
        mov AX, SCORE
        add AX, SCORES[SI]
        mov SCORE, AX
    
    ; Atualiza score da variavel SCORE na tela
    call ATUALIZAR_SCORE_VIDAS

    pop SI
    pop BX
    pop AX
    ret
endp

; Incrementa a quantidade de blocos destruidos
SOMA_QTD_BLOCOS_DESTRUIDOS proc
    inc QTD_BLOCOS_DESTRUIDOS
    
    ; Se o bloco destruido nao for o ultimo, inverte direcao de Y da bola
    cmp QTD_BLOCOS_DESTRUIDOS, 24
    jne INVERTER_DIRECAO_DESTRUCAO_BLOCO
    
    ; Se for o ultimo bloco, zera variavel de controle e reescreve os blocos em tela
    mov QTD_BLOCOS_DESTRUIDOS, 0
    call INICIAR_INTERFACE
    mov BOLA_Y, -80
    jmp FIM_SOMA_QTD_BLOCOS_DESTRUIDOS

    INVERTER_DIRECAO_DESTRUCAO_BLOCO:
        cmp BH, COR_VERMELHO
        je FIM_SOMA_QTD_BLOCOS_DESTRUIDOS
        neg BOLA_Y

    FIM_SOMA_QTD_BLOCOS_DESTRUIDOS:
    ret
endp

; Decrementa a vida em 1
DECREMENTAR_VIDA proc
    push CX
    push DI

    dec VIDAS
    call ATUALIZAR_SCORE_VIDAS
    
    ; Se a vida nao for a ultima, reposiciona a raquete
    cmp VIDAS, -1
    jne REPOSICIONAR_RAQUETE
    
    ; Se for a ultima vida, exibe a mensagem de fim de jogo
    call MOSTRAR_FIM_JOGO
    jmp FIM_DECREMENTAR_VIDA

    REPOSICIONAR_RAQUETE:
        neg BOLA_Y
        call ATRIBUI_POSICAO_RAQUETE_BOLA

        mov CX, 40
        mov DI, 1920
        call LIMPAR_TELA_PARCIALMENTE
        call ESCREVE_RAQUETE
        
        ; Aguarda 1 segundo antes de continuar o jogo
        mov AH, 86H
        mov CX, 1EH
        mov DX, 8480H
        int 15H

    FIM_DECREMENTAR_VIDA:
    pop DI
    pop CX
    ret
endp

; Inicia elementos visuais da interface grafica
INICIAR_INTERFACE proc
    call MOSTRA_STR_SCORE_VIDAS
    call ATUALIZAR_SCORE_VIDAS
    call ESCREVE_BLOCOS
    call ATRIBUI_POSICAO_RAQUETE_BOLA
    call ESCREVE_RAQUETE
    ret
endp

; Proc que inicia o jogo, atribuindo a quantidade de vidas e score inicial
START_BREAKOUT proc
    mov SCORE, 0
    mov VIDAS, 3

    call INICIAR_INTERFACE
    
    ; Loop principal responsavel pela velocidade de movimentacao da bola
    LOOP_BREAKOUT:
        call VERIFICA_COLISAO_PAREDES
        call VERIFICA_COLISAO_INFERIOR

        cmp VIDAS, -1
        je FIM_BREAKOUT

        call MOVIMENTA_RAQUETE
        call MOVIMENTA_BOLA

        call SLEEP
        jmp LOOP_BREAKOUT

    FIM_BREAKOUT:
    ret
endp

; Exibe mensagem de fim de jogo e score feito
MOSTRAR_FIM_JOGO proc
    push AX
    push SI
    push DI

    call LIMPAR_TELA

    mov AH, COR_VERMELHO
    mov DI, 724
    mov SI, offset FIM_JOGO
    call ESCREVE_STRING

    mov AH, 0FH
    mov DI, 1148
    mov SI, offset STR_SCORE
    call ESCREVE_STRING

    mov AX, SCORE
    mov DI, 1162
    call ESCREVE_UINT

    pop DI
    pop SI
    pop AX
    ret
endp

MOSTRAR_TELA_INICIAL proc
    call MODO_VIDEO
    call MOSTRA_INTRO
    call ATUALIZA_MENU
    call SELECIONA_OPCAO_MENU
    call ACAO_MENU
    ret
endp

INICIO:
    mov AX, @DATA
    mov DS, AX
    
    call MOSTRAR_TELA_INICIAL

    mov AH, 4CH
    int 21H
end INICIO
