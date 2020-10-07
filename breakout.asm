.model small

.stack 100H

.data

LOGO DB ' ___              _            _','#','| _ )_______ ____| |_____ _  _| |_','#','| _ \  _/ -_) _  | / / _ \ || |  _|','#','|___/_| \___\__,_|_\_\___/\_,_|\__|','$'
NOMES DB 'Leandro e Lucas','$'
MENU_OPCOES DB '[Jogar]# Sair','$'

.code


MODO_VIDEO proc ; Define o modo de video
    push AX

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
    
    mov DH, 02H
    mov BX, 282
    mov SI, offset LOGO
    call ESCREVE_STRING
    
    mov DH, 04H
    mov BX, 492
    mov SI, offset NOMES 
    call ESCREVE_STRING
    
    mov DH, 0FH
    mov BX, 616
    mov SI, offset MENU_OPCOES
    call ESCREVE_STRING
    
    pop SI
    pop DX
    pop BX
    ret
endp

ESCREVE_STRING proc
    push AX
    push DI
            
    mov AX, 0B800H ; Endereco inicial de memoria
    mov ES, AX     ; Extra Segment recebe endereco de memoria do video
    
    mov DI, BX          ; DI recebe o offset para escrita na memoria de video
    
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


INICIO:
    mov AX, @DATA
    mov DS, AX
    
    call MODO_VIDEO
    call MOSTRA_INTRO

    mov AH, 4CH
    int 21H
end INICIO