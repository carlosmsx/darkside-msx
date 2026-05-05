; =========================================================
; CAMPO DE ESTRELLAS - estrellitas saliendo desde el centro
; estrella.asm - incluido desde darkside.asm
; =========================================================

; --- Constantes RAM ---
NUM_STARS    .EQU  20       ; cantidad de estrellas simultáneas
STAR_SIZE    .EQU  5        ; bytes por estrella: Y, X, DX, DY, edad
MAX_AGE      .EQU  40       ; edad máxima antes de reiniciar al centro
STAR_TABLE   .EQU  08050h   ; tabla estrellas: 20 × 5 bytes = 100 bytes
SPR_BUF      .EQU  080B4h   ; buffer atributos sprites: 20 × 4 bytes = 80 bytes
RAND_SEED    .EQU  08105h   ; semilla del generador pseudo-aleatorio (1 byte)
STAR_PAT_TMP .EQU  08106h   ; variable temporal para patrón dentro del loop
STARS_ON     .EQU  08107h   ; flag: 1=estrellas activas, 0=desactivadas
STAR_DELAY   .EQU  08108h   ; ticks de espera entre actualizaciones (0=cada tick)
STAR_TICK    .EQU  08109h   ; contador regresivo para la próxima actualización

; --- Toggle estrellas (llamado desde TECLADO con tecla Espacio) ---
; Alterna STARS_ON entre 0 y 1. Si se desactivan, oculta todos los sprites.
TOGGLE_STARS:
	LD	A,(STARS_ON)
	XOR	1		; toggle 0↔1
	LD	(STARS_ON),A
	OR	A
	RET	NZ		; si se activaron, listo
	; estrellas desactivadas: ocultar sprites poniendo Y=208
	LD	HL,SPR_BUF
	LD	B,NUM_STARS
HIDE_LOOP:
	LD	(HL),0D0h	; Y=208 → sprite invisible en MSX
	INC	HL
	INC	HL
	INC	HL
	INC	HL
	DJNZ	HIDE_LOOP
	LD	HL,SPR_BUF
	LD	DE,01B00h
	LD	BC,NUM_STARS*4
	CALL	LDIRVM
	RET

; --- Patrones de sprite (4 tamaños: 2×2, 4×4, 6×6, 8×8 pixels) ---
SPRTBL:
    .db 00000000b
    .db 00000000b
    .db 00000000b
    .db 00011000b
    .db 00011000b
    .db 00000000b
    .db 00000000b
    .db 00000000b

    .db 00000000b
    .db 00000000b
    .db 00011000b
    .db 00111100b
    .db 00111100b
    .db 00011000b
    .db 00000000b
    .db 00000000b

    .db 00000000b
    .db 00011000b
    .db 00111100b
    .db 01111110b
    .db 01111110b
    .db 00111100b
    .db 00011000b
    .db 00000000b

    .db 00011000b
    .db 00111100b
    .db 01111110b
    .db 11111111b
    .db 11111111b
    .db 01111110b
    .db 00111100b
    .db 00011000b

; --- Posiciones iniciales de las 20 estrellas ---
; Estructura: Y, X, DX, DY, edad
; Posición inicial pre-calculada: Y = Yc+DY*edad, X = Xc+DX*edad
; DX/DY: +1=1, +2=2, -1=255(0FFh), -2=254(0FEh)
; Centro: Yc=82, Xc=124. Todas verificadas dentro de pantalla (0-191, 0-255)
STAR_INIT_DATA:
	.DB  82, 124,   2,   0,   0   ;  0  → derecha
	.DB  84, 128,   2,   1,   2   ;  1  → derecha-abajo suave
	.DB  90, 132,   2,   2,   4   ;  2  → diagonal DR rápida
	.DB  94, 130,   1,   2,   6   ;  3  → abajo-derecha empinado
	.DB  98, 124,   0,   2,   8   ;  4  → abajo
	.DB 102, 114, 255,   2,  10   ;  5  → abajo-izquierda empinado
	.DB 106, 100, 254,   2,  12   ;  6  → diagonal DL rápida
	.DB  96,  96, 254,   1,  14   ;  7  → izquierda-abajo suave
	.DB  82,  92, 254,   0,  16   ;  8  → izquierda
	.DB  64,  88, 254, 255,  18   ;  9  → izquierda-arriba suave
	.DB  42,  84, 254, 254,  20   ; 10  → diagonal UL rápida
	.DB  38, 102, 255, 254,  22   ; 11  → arriba-izquierda empinado
	.DB  34, 124,   0, 254,  24   ; 12  → arriba
	.DB  30, 150,   1, 254,  26   ; 13  → arriba-derecha empinado
	.DB  26, 180,   2, 254,  28   ; 14  → diagonal UR rápida
	.DB  52, 184,   2, 255,  30   ; 15  → derecha-arriba suave
	.DB 114, 156,   1,   1,  32   ; 16  → diagonal DR lenta
	.DB 116,  90, 255,   1,  34   ; 17  → diagonal DL lenta
	.DB  46,  88, 255, 255,  36   ; 18  → diagonal UL lenta
	.DB  44, 162,   1, 255,  38   ; 19  → diagonal UR lenta

; --- Tabla de direcciones (16 pares DX,DY distribuidos en 360°) ---
; Se elige uno al azar (4 bits → índice 0..15) al reiniciar cada estrella.
DIR_TABLE:
	.DB   2,   0   ;  0  derecha
	.DB   2,   1   ;  1  derecha-abajo suave
	.DB   2,   2   ;  2  diagonal DR
	.DB   1,   2   ;  3  abajo-derecha empinado
	.DB   0,   2   ;  4  abajo
	.DB 255,   2   ;  5  abajo-izquierda empinado
	.DB 254,   2   ;  6  diagonal DL
	.DB 254,   1   ;  7  izquierda-abajo suave
	.DB 254,   0   ;  8  izquierda
	.DB 254, 255   ;  9  izquierda-arriba suave
	.DB 254, 254   ; 10  diagonal UL
	.DB 255, 254   ; 11  arriba-izquierda empinado
	.DB   0, 254   ; 12  arriba
	.DB   1, 254   ; 13  arriba-derecha empinado
	.DB   2, 254   ; 14  diagonal UR
	.DB   2, 255   ; 15  derecha-arriba suave

; --- Generador pseudo-aleatorio: Galois LFSR de 8 bits, período 255 ---
; Polinomio x^8+x^4+x^3+x^2+1 → feedback = 1Dh
; Entrada/salida: A = nuevo byte aleatorio. Solo modifica A y flags.
RAND:
	LD   A, (RAND_SEED)
	OR   A                   ; ¿semilla = 0? (estado inválido)
	JR   NZ, RAND1
	INC  A                   ; si es 0, usar 1
RAND1:
	SLA  A                   ; shift izquierda: bit7 → carry, bit0 = 0
	JR   NC, RAND2
	XOR  1Dh                 ; realimentación cuando bit7 era 1
RAND2:
	LD   (RAND_SEED), A
	RET

; --- INIT_STARS: carga patrones en VRAM y copia datos iniciales a RAM ---
; Llama una vez desde INSTALL antes de EI.
INIT_STARS:
	LD   HL, SPRTBL          ; 4 patrones × 8 bytes = 32 bytes
	LD   DE, 03800h          ; tabla patrones sprites en VRAM
	LD   BC, 32
	CALL LDIRVM
	LD   HL, STAR_INIT_DATA  ; origen: ROM
	LD   DE, STAR_TABLE      ; destino: RAM
	LD   BC, NUM_STARS * STAR_SIZE  ; 100 bytes
	LDIR                     ; copia directa ROM → RAM
	; Seedear PRNG con el registro R del Z80.
	; R se incrementa en cada lectura de memoria (varía con el timing de boot),
	; así el efecto es distinto en cada ejecución.
	LD   A, R
	OR   A
	JR   NZ, IS_SEED_OK
	INC  A                   ; evitar semilla 0
IS_SEED_OK:
	LD   (RAND_SEED), A
	XOR  A
	LD   (STAR_DELAY), A     ; velocidad inicial: máxima (0=cada tick)
	LD   (STAR_TICK), A
	RET

; --- TICK_STARS: gestiona el contador de velocidad y llama UPDATE_STARS ---
; Llamar desde EJEC en cada tick. Reemplaza la llamada directa a UPDATE_STARS.
TICK_STARS:
	LD   A,(STARS_ON)
	OR   A
	RET  Z                   ; estrellas apagadas
	LD   A,(STAR_TICK)
	OR   A
	JR   Z,TS_UPDATE
	DEC  A
	LD   (STAR_TICK),A
	RET
TS_UPDATE:
	LD   A,(STAR_DELAY)
	LD   (STAR_TICK),A       ; recargar contador
	JP   UPDATE_STARS        ; tail call, UPDATE_STARS hace su propio RET

; --- STAR_FASTER / STAR_SLOWER: ajustan STAR_DELAY (llamadas desde TECLADO) ---
STAR_FASTER:
	LD   A,(STAR_DELAY)
	OR   A
	RET  Z                   ; ya en mínimo (0 = cada tick)
	DEC  A
	LD   (STAR_DELAY),A
	RET

STAR_SLOWER:
	LD   A,(STAR_DELAY)
	CP   15                  ; máximo: actualizar cada 16 ticks
	RET  Z
	INC  A
	LD   (STAR_DELAY),A
	RET

; --- UPDATE_STARS: mueve estrellas y actualiza sprites en VRAM cada frame ---
; Llamar desde el handler de interrupción cuando STARS_ON != 0.
UPDATE_STARS:
	LD   IX, STAR_TABLE      ; IX apunta a la primera estrella
	LD   HL, SPR_BUF         ; HL apunta al buffer de atributos
	LD   B, NUM_STARS        ; 20 estrellas
US_LOOP:
	; --- Incrementar edad y verificar reset ---
	LD   A, (IX+4)
	INC  A
	CP   MAX_AGE
	JR   NZ, US_MOVE
	; Reiniciar al centro con dirección aleatoria
	XOR  A
	LD   (IX+4), A           ; edad = 0
	LD   (IX+0), Yc          ; Y = centro
	LD   (IX+1), Xc          ; X = centro
	PUSH HL                  ; salvar puntero sprite buffer
	PUSH BC                  ; salvar contador loop (B)
	CALL RAND                ; A = byte aleatorio
	AND  0Fh                 ; índice 0..15
	RLCA                     ; × 2 (cada entrada de DIR_TABLE son 2 bytes)
	LD   E, A
	LD   D, 0
	LD   HL, DIR_TABLE
	ADD  HL, DE              ; HL = DIR_TABLE + índice*2
	LD   A, (HL)
	LD   (IX+2), A           ; DX aleatorio
	INC  HL
	LD   A, (HL)
	LD   (IX+3), A           ; DY aleatorio
	POP  BC
	POP  HL                  ; restaurar puntero sprite buffer
	JR   US_WRITE
US_MOVE:
	LD   (IX+4), A           ; guardar edad incrementada
	; Y += DY
	LD   A, (IX+0)
	ADD  A, (IX+3)
	LD   (IX+0), A
	; X += DX
	LD   A, (IX+1)
	ADD  A, (IX+2)
	LD   (IX+1), A
US_WRITE:
	; Patrón: edad >> 3  (0..7 → 0, 8..15 → 1, 16..23 → 2, 24+ → 3)
	LD   A, (IX+4)
	SRL  A
	SRL  A
	SRL  A
	CP   4
	JR   C, US_PAT_OK        ; si A < 4 está bien
	LD   A, 3                ; clamp a máximo 3
US_PAT_OK:
	LD   (STAR_PAT_TMP), A   ; guardar patrón en RAM (evita PUSH/POP AF)
	; Y-1 (convención MSX: el atributo Y se guarda como Y-1)
	LD   A, (IX+0)
	DEC  A
	LD   (HL), A
	INC  HL
	; X
	LD   A, (IX+1)
	LD   (HL), A
	INC  HL
	; Patrón (releer de RAM para no depender de flags)
	LD   A, (STAR_PAT_TMP)
	LD   (HL), A
	INC  HL
	; Color: blanco (15)
	LD   A, 15
	LD   (HL), A
	INC  HL
	; --- Avanzar IX en STAR_SIZE (5 bytes) ---
	PUSH HL                  ; salvar puntero buffer
	PUSH IX
	POP  HL
	LD   DE, STAR_SIZE
	ADD  HL, DE
	PUSH HL
	POP  IX
	POP  HL                  ; restaurar puntero buffer
	DJNZ US_LOOP
	; Enviar los 4 atributos de sprites a VRAM
	LD   HL, SPR_BUF
	LD   DE, 01B00h          ; tabla atributos sprites en VRAM
	LD   BC, NUM_STARS * 4   ; 20 sprites × 4 bytes = 80 bytes
	CALL LDIRVM
	RET
