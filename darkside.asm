; Tribute to Pink Floyd - Dark Side of the Moon
; 2025 by Carlos Escobar
;
; Compiled by Telemark Assembler (TASM) version 3.2
;

#include "notas.asm"
#define	RomSize(kbytes) .fill	(kbytes * 1024) - $ + StartProgram   ; para obtener siempre 
								     ; un archivo objeto de tamaño [kbytes]
        .ORG     4000h

StartProgram:

PITCH_POS 	.EQU	28
SUSTAIN_POS 	.EQU	PITCH_POS+32
NOISE_POS 	.EQU	SUSTAIN_POS+32
P_EVOL_POS 	.EQU	NOISE_POS+32
TITULO_POS 	.EQU	0
ALBUM_POS 	.EQU	TITULO_POS+32
AUTHOR_POS 	.EQU	ALBUM_POS+32
VERSION_POS 	.EQU	AUTHOR_POS+96
DEVELOPER_POS 	.EQU	VERSION_POS+64

Xc      .equ 128-4
Yc      .equ 86-4


DELAY   .EQU    08000h
CONT    .EQU    08002h
NOISE	.EQU    08004h
SUSTAIN .EQU    08006H
P_EVOL  .EQU    08007H

STAT_A  .EQU    08010H
STAT_B  .EQU    08020H
STAT_C  .EQU    08030H

BOTTOM  .EQU    0FC48H
; PROCNM	.EQU	0FD89h
; GTSTCK	.EQU	000D5h

CHSNS	.EQU	0009Ch ; Tests the status of the keyboard buffer. Zero flag set if it is empty, otherwise not set
CHGET	.EQU	0009Fh ; One character input (waiting), A - ASCII code of the input character 

DISSCR  .equ 041h   ; Apaga pantalla
ENASCR  .equ 044h   ; Enciende pantalla
WRTVDP  .equ 047h   ; Escribe registro del VDP (B=valor, C=reg)
RDVRM   .equ 04Ah   ; Lee 1 byte de VRAM (HL=addr -> A)
WRTVRM  .equ 04Dh   ; Escribe 1 byte en VRAM (HL=addr, A=dato)
SETRD   .equ 050h   ; Prepara VDP para lectura secuencial (HL)
SETWRT  .equ 053h   ; Prepara VDP para escritura secuencial (HL)
FILVRM  .equ 056h   ; Llena VRAM (HL inicio, BC len, A dato)
LDIRMV  .equ 059h   ; VRAM -> RAM  (HL vram, DE ram, BC len)
LDIRVM  .equ 05Ch   ; RAM  -> VRAM (HL ram,  DE vram, BC len)

CHGMOD  .equ 05Fh   ; Cambia modo (A = 0..3). Para SCREEN 2: A=2
CHGCLR  .equ 062h   ; Aplica FORCLR/BAKCLR/BDRCLR al VDP
CLRSPR  .equ 069h   ; Inicializa (borra) sprites

INITXT  .equ 06Ch   ; Inicializa SCREEN 0
INIT32  .equ 06Fh   ; Inicializa SCREEN 1
INIGRP  .equ 072h   ; Inicializa SCREEN 2 (Graphics 2)
INIMLT  .equ 075h   ; Inicializa SCREEN 3
SETTXT  .equ 078h   ; Solo setea VDP a modo texto (sin tocar tablas)
SETT32  .equ 07Bh   ; Solo setea VDP a modo text32
SETGRP  .equ 07Eh   ; Solo setea VDP a modo gráfico (G2)
SETMLT  .equ 081h   ; Solo setea VDP a multicolor

; ==============================
; Variables de sistema (RAM BIOS)
; ==============================
; Colores (usados por CHGCLR)
FORCLR  .equ 0F3E9h ; Color de tinta
BAKCLR  .equ 0F3EAh ; Color de fondo
BDRCLR  .equ 0F3EBh ; Color de borde

; Tablas VRAM por modo (punteros que INIxxx/SETxxx usan/copian)
; SCREEN 2 (Graphics 2)
GRPNAM  .equ 0F3C7h ; Base Name Table
GRPCOL  .equ 0F3C9h ; Base Color Table
GRPCGP  .equ 0F3CBh ; Base Pattern Generator
GRPATR  .equ 0F3CDh ; Base Sprite Attribute Table
GRPPAT  .equ 0F3CFh ; Base Sprite Pattern (generator)

; Punteros “actuales” segun modo (útiles para cálculos)
NAMBAS  .equ 0F922h ; Name table actual
CGPBAS  .equ 0F924h ; Pattern generator actual
PATBAS  .equ 0F926h ; Sprite pattern actual
ATRBAS  .equ 0F928h ; Sprite attribute actual

; Otros útiles
SCRMOD  .equ 0FCB0h ; Modo de pantalla vigente (0..3)

; ROM header

ID:     .DB      41h, 42h        ; aca van los bytes que identifican una ROM, sin esto la BIOS simplemente ignora la ROM
INIT:   .DW    	 INSTALL         ; tenemos una rutina START en la inicializacion de la ROM
STAT:	.DW	 0	   	 ; no agrega sentencias extendidas (CALL)
DEV:    .DW      0               ; no agrega dispositivos (devices)
TEXT:   .DW      0               ; no tiene programa en BASIC
        .DB      0,0,0,0,0,0	 ; estos 6 bytes deben ser 0 y estan reservados para futuros usos de la norma

EJEC:	
	DI
	PUSH	HL
	PUSH	BC
	PUSH	DE
	PUSH	IX
	PUSH	AF

        LD      HL,(CONT)       ;decremento contador de retardo principal
	DEC	HL
        LD      (CONT),HL
	LD	A,H		;comparo si contador=0
	OR	L
	RET	NZ		;si no es cero retorna

        LD      HL,(DELAY)      ;restauro contador a valor inicial
        LD      (CONT),HL

	LD	IX,STAT_A	; ejecuto canal A
	CALL	PLAY

	LD	IX,STAT_B	; ejecuto canal B
	CALL	PLAY

	LD	IX,STAT_C	; ejecuto canal C
	CALL	PLAY

	CALL	CHECK
	CALL	TECLADO
	CALL	TICK_STARS

        POP     AF
        POP     IX
        POP     DE
        POP     BC
        POP     HL
	EI
	RET

HOOK:	RST	30h
	.DB	1
	.DW	EJEC
	RET

INSTALL:
	CALL	PRISMA
	DI

        LD      HL,(BOTTOM)
        LD      DE,36
        ADD     HL,DE
        LD      (BOTTOM),HL

	LD	DE,0FD9FH
	LD	HL,HOOK
	LD	BC,5
	LDIR

        LD      HL,1
        LD      (DELAY),HL
        LD      (CONT),HL

;para debugeo del engine de audio

;	LD	HL,CANALB
;	LD	DE,CANALA
;	SCF
;	CCF
;	SBC	HL,DE
;       LD      (LARGO),HL
	; LD	A,3
	; LD	(ITER),A

	CALL	SET00
	CALL	VOL0
	CALL	SET0
	CALL	INIT_STARS
	EI

infinito:
	JR	infinito

PRISMA:
        ; 1) apagar pantalla
        call    DISSCR
        ; 2) SCREEN 2
        ld      a,2
        call    CHGMOD
        ; 3) inicializar modo gráfico
        call    INIGRP
        ; 4) colores (tinta=15, fondo=1, borde=1 como ejemplo)
        ld      a,0ffh
        ld      (FORCLR),a
        ld      a,1
        ld      (BAKCLR),a
        ld      (BDRCLR),a
        call    CHGCLR
        ; 5) limpiar sprites
        call    CLRSPR
	;color 15,1
	LD	HL,2000h
	LD	BC,768*8
	LD	A,0f1h 
	CALL	FILVRM
	LD	HL,1a00h
	LD	BC,256
	LD	A,32 
	CALL	FILVRM
	LD	HL,7103
	LD	DE,1000h
	LD	BC,256*8
	CALL	LDIRVM

;NUMEROS
	LD	HL,7487
	LD	B,80
	IN	A,(99h)
	LD	A,080h
	OUT	(99h),A
	LD	A,040H + 011h
	OUT	(99h),A
PRISMA_LOOP1:
	LD	A,(HL)
	LD	C,A
	SRL	A
	OR	C
	OUT	(98h),A
	INC	HL
	DJNZ	PRISMA_LOOP1
;LETRAS
	LD	HL,7623
	LD	B,208
	IN	A,(99h)
	LD	A,08h
	OUT	(99h),A
	LD	A,040H + 012h
	OUT	(99h),A
PRISMA_LOOP2:
	LD	A,(HL)
	LD	C,A
	SRL	A
	OR	C
	OUT	(98h),A
	INC	HL
	DJNZ	PRISMA_LOOP2

;LETRAS MINUSCULAS
	LD	HL,7871
	LD	B,208
	IN	A,(99h)
	LD	A,0
	OUT	(99h),A
	LD	A,040H + 013h
	OUT	(99h),A
PRISMA_LOOP3:
	LD	A,(HL)
	LD	C,A
	SRL	A
	OR	C
	OUT	(98h),A
	INC	HL
	DJNZ	PRISMA_LOOP3

;COLORES LETRAS
	IN	A,(99h)
	LD	A,0
	OUT	(99h),A
	LD	A,040H + 030h
	OUT	(99h),A
	LD	B,0 ;256
PRISMA_LOOP4:
	LD	A,0E0h
	OUT	(98h),A
	LD	A,0E0h
	OUT	(98h),A
	LD	A,0f0h
	OUT	(98h),A
	LD	A,0f0h
	OUT	(98h),A
	LD	A,0f0h
	OUT	(98h),A
	LD	A,0e0h
	OUT	(98h),A
	LD	A,0E0h
	OUT	(98h),A
	LD	A,0E0h
	OUT	(98h),A
	DJNZ	PRISMA_LOOP4

;COLORES NUMEROS
	IN	A,(99h)
	LD	A,080h
	OUT	(99h),A
	LD	A,040H + 031h
	OUT	(99h),A
	LD	B,10
PRISMA_LOOP5:
	LD	A,0A0h
	OUT	(98h),A
	LD	A,0A0h
	OUT	(98h),A
	LD	A,0B0h
	OUT	(98h),A
	LD	A,0B0h
	OUT	(98h),A
	LD	A,0B0h
	OUT	(98h),A
	LD	A,0A0h
	OUT	(98h),A
	LD	A,0A0h
	OUT	(98h),A
	LD	A,0A0h
	OUT	(98h),A
	DJNZ	PRISMA_LOOP5

	LD	HL,PRISMA_DAT+1
PRISMA1_POS:
	LD	A,(HL)		; parte baja POS
	INC	HL
	CP	0
	JR	Z,PRISMA1_END	; si es 0, fin
	OUT	(99h),A
	LD	A,(HL)
	INC	HL		; apunto al primer byte de datos
	OR	40h
	OUT	(99h),A
PRISMA1_1:
	LD	A,(HL)
	INC	HL
	CP	0
	JR	Z,PRISMA1_POS
PRISMA1_2:
	OUT	(98h),A
	INC	HL
	JR	PRISMA1_1
PRISMA1_END:

	LD	HL,PRISMA_DAT+1
PRISMA2_POS:
	LD	A,(HL)		; parte baja POS
	INC	HL
	CP	0
	JR	Z,PRISMA2_END	; si es 0, fin
	OUT	(99h),A
	LD	A,(HL)
	INC	HL		; apunto al primer byte de datos
	ADD	A,20h
	OR	40h
	OUT	(99h),A
PRISMA2_1:
	LD	A,(HL)
	INC	HL
	CP	0
	JR	Z,PRISMA2_POS
PRISMA2_2:
	LD	A,(HL)
	INC	HL
	OUT	(98h),A
	JR	PRISMA2_1
PRISMA2_END:

	LD	HL,TITULO
	LD	A,TITULO_POS
	CALL	PRINTSTR
	LD	HL,ALBUM
	LD	A,ALBUM_POS
	CALL	PRINTSTR
	LD	HL,AUTHOR
	LD	A,AUTHOR_POS
	CALL	PRINTSTR
	LD	HL,VERSION
	LD	A,VERSION_POS
	CALL	PRINTSTR
	LD	HL,DEVELOPER
	LD	A,DEVELOPER_POS
	CALL	PRINTSTR


; ; --- Inicializa screen 2 y sprites
;     ld      hl,SPRTBL       ; dirección tabla de patrones
;     ld      de,03800h       ; dirección VRAM patrón de sprite
;     ld      bc,32*4          ; 4 patrones de 8x8
;     call    LDIRVM

;     xor     a
;     ld      hl,01b00h       ; color del sprite (VRAM)
;     ld      b,4
; setcol:
;     out     (98h),a
;     djnz    setcol


        ; 6) encender pantalla
        call    ENASCR

	ret

PRISMA_DAT:
#include "prisma.asm"

PRINTSTR:
	PUSH	AF
	IN	A,(99h)
	POP	AF
	OUT	(99h),A
	LD	A,040h + 1ah ;tercera franja
	OUT	(99h),A
PRINTSTR1:
	LD	A,(HL)
	CP	0
	RET	Z
	OUT	(98h),A
	INC	HL
	JR	PRINTSTR1

HEX:	PUSH	AF
	SRL	A
	SRL	A
	SRL	A
	SRL	A
	CP	10
	JR	C,HEX1
	ADD	A,'A'-'0'-10
HEX1:	ADD	A,'0'
	OUT	(98h),A
	POP	AF
	AND	0Fh
	CP	10
	JR	C,HEX2
	ADD	A,'A'-'0'-10
HEX2:	ADD	A,'0'
	OUT	(98h),A
	RET

TECLADO:
	CALL	CHSNS
	RET	Z
	CALL	CHGET
	CP	'q'
	JR	Z, ARRIBA
	CP	'a'	
	JR	Z, ABAJO
	CP	'w'
	JR	Z,SUSTAIN_UP
	CP	's'
	JR	Z,SUSTAIN_DOWN
	CP	'e'
	JP	Z,NOISE_UP
	CP	'd'
	JP	Z,NOISE_DOWN
	CP	'r'
	JP	Z,P_EVOL_UP
	CP	'f'
	JP	Z,P_EVOL_DOWN
	CP	't'
	JP	Z,STAR_FASTER
	CP	'g'
	JP	Z,STAR_SLOWER
	CP	' '
	JP	Z,TOGGLE_STARS
	RET

ARRIBA:
	LD	IX,STAT_B
	LD	L,(IX+10)
	LD	H,(IX+11)
	INC	HL
	LD	(IX+10),L
	LD	(IX+11),H
	JR	PITCH_PRINT
ABAJO:
	LD	IX,STAT_B
	LD	L,(IX+10)
	LD	H,(IX+11)
	DEC	HL
	LD	(IX+10),L
	LD	(IX+11),H
PITCH_PRINT:
	IN	A,(99h)
	LD	A,PITCH_POS
	OUT	(99h),A
	LD	A,040h + 1ah ;tercera franja
	OUT	(99h),A
	LD	A,H
	CALL	HEX
	LD	A,L
	CALL	HEX
	RET

SUSTAIN_UP:
	LD	A,(SUSTAIN)
	INC	A
	LD	(SUSTAIN),A
	JR 	SUSTAIN_PRINT
SUSTAIN_DOWN:
	LD	A,(SUSTAIN)
	DEC	A
	LD	(SUSTAIN),A
SUSTAIN_PRINT:
	PUSH	AF
	IN	A,(99h)
	LD	A,SUSTAIN_POS ;10+32
	OUT	(99h),A
	LD	A,040h + 1ah ; tercera franja
	OUT	(99h),A
	POP	AF
	CALL	HEX
	RET

NOISE_UP:
	LD	A,(NOISE)
	INC	A
	LD	(NOISE),A
	JR	NOISE_PRINT
NOISE_DOWN:
	LD	A,(NOISE)
	DEC	A
	LD	(NOISE),A
NOISE_PRINT:
	PUSH	AF
	LD	E,A
	LD	A,6
	CALL	WR_PSG
	IN	A,(99h)
	LD	A,NOISE_POS
	OUT	(99h),A
	LD	A,040h + 1ah ; tercera franja
	OUT	(99h),A
	POP	AF
	CALL	HEX
	RET

P_EVOL_UP:
	LD	A,(P_EVOL)
	INC	A
	LD	(P_EVOL),A
	JR	P_EVOL_PRINT
P_EVOL_DOWN:
	LD	A,(P_EVOL)
	DEC	A
	LD	(P_EVOL),A
P_EVOL_PRINT:
	PUSH	AF
	IN	A,(99h)
	LD	A,P_EVOL_POS
	OUT	(99h),A
	LD	A,040h + 1ah ; tercera franja
	OUT	(99h),A
	POP	AF
	CALL	HEX
	RET


; SETR7_1:LD	A,7
; 	LD	E,10111100b
; 	CALL	WR_PSG
; 	RET

; SETR7_2:LD	A,7
; 	LD	E,10011100b
; 	CALL	WR_PSG
; 	RET

; SETR7_3:LD	A,7
; 	LD	E,10011100b
; 	CALL	WR_PSG
; 	; LD	A,3		;reset counter 
; 	; LD	(ITER),A
; 	RET

SET00:
        LD      IX,STAT_A
	LD	(IX+10),0
	LD	(IX+11),0
	LD	(IX+12),0
	LD	(IX+13),0
        LD      IX,STAT_B
	LD	(IX+10),0
	LD	(IX+11),0
	LD	(IX+12),0
	LD	(IX+13),0
        LD      IX,STAT_C
	LD	(IX+10),0
	LD	(IX+11),0
	LD	(IX+12),0
	LD	(IX+13),0
	LD	IX,SUSTAIN
	LD	(IX+0),0
	LD	IX,NOISE
	LD	(IX+0),0
	LD	IX,P_EVOL
	LD	(IX+0),4
	LD	A,1
	LD	(STARS_ON),A	; estrellas activas por defecto
	RET
SET0:	
        ; LD	A,(ITER)
	; DEC	A
	; LD	(ITER),A
	; CP	2
	; CALL	Z,SETR7_1
	; CP	1
	; CALL	Z,SETR7_2
	; CP	0
	; CALL	Z,SETR7_3

	PUSH	HL
	LD	HL,CANALA
        LD      (STAT_A),HL
        LD      IX,STAT_A
        LD      (IX+7),8
        LD      (IX+8),0
        LD      (IX+9),1
	CALL	FETCH

	LD	HL,CANALB
        LD      (STAT_B),HL
        LD      IX,STAT_B
        LD      (IX+7),9
        LD      (IX+8),2
        LD      (IX+9),3
	CALL	FETCH

	LD	HL,CANALC
        LD      (STAT_C),HL
        LD      IX,STAT_C
        LD      (IX+7),10
        LD      (IX+8),4
        LD      (IX+9),5
	CALL	FETCH

	POP	HL
	RET

; FINAL:	DI
; 	LD A,0C9H
; 	LD (0FD9FH),A
; 	EI

; 	CALL	VOL0
; 	RET

VOL0:	LD	A,8
	LD	E,0
	CALL	WR_PSG
	LD	A,9
	LD	E,0
	CALL	WR_PSG
	LD	A,10
	LD	E,0
	CALL	WR_PSG
	LD	A,(NOISE)
	LD	E,A
	LD	A,6
	CALL	WR_PSG
	LD	A,7
	LD	E,10011100B
	CALL	WR_PSG
	RET

	;esta rutina chequea si el canal principal terminó
CHECK:  LD      HL,(STAT_A)
	LD	DE,CANALB
	SCF
	CCF
	SBC	HL,DE
	LD	A,H
	OR	L	
	RET	NZ

	CALL	SET0
	RET
;registro de estado por canal
; +0: puntero a nota actual (2 bytes) en CANALx
; +2: contador de duracion (1 byte) se va decrementando por cada tick
; +3: puntero a tabla envolvente (2 bytes) se va incrementando
; +5: parametro frecuencia nota (2 bytes)
; +7: registro volumen
; +8: registro frecuencia (8 bits fine tune)
; +9: registro frecuencia (4 bits coarse tune)
; +10: pitch (2 bytes)
; +12: evol (2 byte)


FETCH:	LD	L,(IX+0)	; recupera nota actual
	LD	H,(IX+1)
	PUSH	HL
	POP	IY

	LD	A,(P_EVOL)
	LD	B,A
	LD	A,(IY+0)	; lee duracion
	LD	C,A
MULT:	ADD	A,C
	DJNZ	MULT

	LD	(IX+2),A	; inicializa duracion
	LD	H,(IY+1)	; lee tabla envolvente
	LD	L,0		; transforma en puntero a tabla evol(H)
	LD	DE, EVOL0
	ADD	HL,DE

	PUSH	HL
	LD	HL,STAT_C
	PUSH	IX
	POP	DE
	SBC	HL,DE
	LD	A,H
	OR	L
	POP	HL
	JR	Z,skip_sustain

	LD	A,(SUSTAIN)
	LD	E,0
	LD	D,A
	ADD	HL,DE

skip_sustain:
	LD	(IX+3),L	; inicializa puntero a tabla evol(H)
	LD	(IX+4),H
	LD	L,(IY+2);	; lee octava/nota
	LD	H,0
	LD	DE,TABLA	; calcula parametros frecuencia nota
        ADD     HL,HL
	ADD	HL,DE
	LD	A,(HL)		; inicializa parametros frec. nota
	LD	(Ix+5),A	
	INC	HL
	LD	A,(HL)
	LD	(IX+6),A

	RET

SETVOL: LD      L,(IX+3)        ; recupero puntero a tabla evol
	LD	H,(IX+4)
	LD	A,(HL)		; recupero volumen actual y lo guardo en E i corresponde
	CP	255		; verifico si fin de DATA
	RET	Z		; retorna si fin DATA
	AND	0FH		; despejo el volumen
	LD	E,A		; guardo el volumen en E
	LD	A,(IX+7)	; recupera registro volumen correspondiente al canal
	CALL	WR_PSG

	; LD	A,(HL)		; recupero vol actual y tomo la parte alta como pitch
	; SRA	A		; desplazo con signo 4 veces a la derecha
	; SRA	A
	; SRA	A
	; SRA	A
	; LD	C,A
	; SRA	A
	; SRA	A
	; SRA	A
	; SRA	A
	; LD	B,A


	; LD	C,(IX+10)
	; LD	B,(IX+11)
	; en BC queda el pitch

	INC	HL		; apunta a sigte
	LD	(IX+3),L	; guarda sigte
	LD	(IX+4),H
	RET

NOTA:	LD	H,(IX+5)	; recupero valor bajo de frecuencia nota
	LD	L,(IX+6)	; recupero valor alto de frecuencia nota
	LD	C,(IX+10)
	LD	B,(IX+11)
	ADD	HL,BC
	LD	E,H
	LD	A,(IX+9)	; recupero registro
	CALL	WR_PSG
	LD	E,L
	LD	A,(IX+8)	; recupero registro
	CALL	WR_PSG
	RET

PLAY:	CALL	SETVOL
	CALL	NOTA

	LD	A,(IX+2)	; recupero contador de duracion
	DEC	A		; actualizo cuenta
	LD	(IX+2),A
        OR      A
	RET	NZ		; si no llega a cero termina

NEXT:	LD	L,(IX+0)	; actualizo puntero a nota
	LD	H,(Ix+1)
	INC	HL
        INC     HL
        INC     HL
	LD	(IX+0),L
	LD	(IX+1),H
	CALL	FETCH		; seteo los valores para la sigte nota
	RET

WR_PSG:	PUSH	AF
	OUT	(0A0H),A
	LD	A,E
	OUT	(0A1H),A
	POP	AF
	RET


	;Index = octava*16 + nota
	;octava (0-6)
	;nota (1=C,2=C#,3=D,4=D#,5=E,6=F,7=F#,8=G,9=G#,10=A,11=A#,12=B) other values are "silence" note

TABLA:	.DB 0,0,13,92,12,156,11,231,11,60,10,154,10,2,9,114,8,234,8,106,7,241,7,127,7,19,0,0,0,0,0,0
	.DB 0,0,6,174,6,78,5,243,5,158,5,77,5,1,4,185,4,117,4,53,3,248,3,191,3,137,0,0,0,0,0,0
	.DB 0,0,3,87,3,39,2,249,2,207,2,166,2,128,2,92,2,58,2,26,1,252,1,223,1,196,0,0,0,0,0,0
	.DB 0,0,1,171,1,147,1,124,1,103,1,83,1,64,1,46,1,29,1,13,0,254,0,239,0,226,0,0,0,0,0,0
	.DB 0,0,0,213,0,201,0,190,0,179,0,169,0,160,0,151,0,142,0,134,0,127,0,119,0,113,0,0,0,0,0,0
	.DB 0,0,0,106,0,100,0,95,0,89,0,84,0,80,0,75,0,71,0,67,0,63,0,59,0,56,0,0,0,0,0,0
	.DB 0,0,0,53,0,50,0,47,0,44,0,42,0,40,0,37,0,35,0,33,0,31,0,29,0,28,0,0,0,0,0,0

EVOL0:	.DB 13,12,11,11,10,10,10,9,9,9,9,8,8,8,7,7,7,6,6,6,5,5,5,4,4,4,4,3,3,3,3,2
	.DB 2,2,2,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	.DB 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,255

EVOL1:	.DB 15,14,14,13,13,13,12,12,12,12,11,11,11,11,11,10,10,10,10,10,9,9,9,8,8,8,7,7,7,8,8,8
	.DB 9,9,7,7,5,5,7,7,9,9,7,7,5,5,7,7,9,9,7,7,5,5,7,7,9,9,7,7,5,5,7,7
	.DB 9,9,7,7,5,5,7,7,9,9,7,7,5,5,7,7,9,9,7,7,5,5,7,7,9,9,7,7,5,5,7,7
	.DB 8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5
	.DB 8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5,8,5,1,5
	.DB 7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4
	.DB 7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4,7,4,1,4
	.DB 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,2,2,2,2,2,2,2,2,2,2,2,2,2,255

EVOL2:	.DB 15,14,14,13,13,13,13,12,12,12,12,12,12,11,11,11,11,11,11,11,11,10,10,10,10,10,10,10,10,10,10,10
	.DB 9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,8
	.DB 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8
	.DB 8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,7
	.DB 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	.DB 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	.DB 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7
	.DB 7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,255

EVOL3:	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,255

EVOL4:	.DB 10,11,12,13,14,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,255

EVOL5:	.DB 5,9,10,13,14,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15
	.DB 15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,15,255

EVOL6:	.DB 1fh,1eh,1eh,1dh,1dh,1dh,1dh,1ch,1ch,1ch,1ch,1ch,1ch,1bh,1bh,1bh,1bh,1bh,1bh,1bh,1bh,1ah,1ah,1ah,1ah,1ah,1ah,1ah,1ah,1ah,1ah,1ah
	.DB 19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,19h,18h
	.DB 18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h
	.DB 18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,18h,17h
	.DB 17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h
	.DB 17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h
	.DB 17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h
	.DB 17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,17h,255

; EVOL3:
; 	.DB 00Fh,00Eh,00Eh,00Dh,00Dh,00Dh,00Dh,00Ch,00Ch,00Ch,00Ch,00Ch,00Ch,00Bh,00Bh,00Bh
; 	.DB 00Bh,00Bh,00Bh,00Bh,00Bh,00Ah,00Ah,00Ah,00Ah,00Ah,00Ah,00Ah,00Ah,00Ah,00Ah,00Ah
; 	.DB 019h,019h,019h,019h,009h,009h,009h,009h,0F9h,0F9h,0F9h,0F9h,009h,009h,009h,009h
; 	.DB 019h,029h,019h,009h,0f9h,0e9h,0f9h,009h,019h,029h,019h,009h,0f9h,0e9h,0f9h,008h
; 	.DB 028h,028h,028h,028h,028h,028h,028h,028h,028h,028h,028h,028h,028h,028h,028h,028h
; 	.DB 028h,028h,028h,028h,028h,028h,028h,028h,028h,028h,028h,028h,028h,028h,028h,028h
; 	.DB 037h,037h,037h,037h,037h,037h,037h,037h,037h,037h,037h,037h,037h,037h,037h,037h
; 	.DB 037h,037h,037h,037h,037h,037h,037h,037h,037h,037h,037h,037h,037h,037h,037h,037h
; 	.DB 046h,046h,046h,046h,046h,046h,046h,046h,046h,046h,046h,046h,046h,046h,046h,046h
; 	.DB 046h,046h,046h,046h,046h,046h,046h,046h,046h,046h,046h,046h,046h,046h,046h,046h
; 	.DB 055h,055h,055h,055h,055h,055h,055h,055h,055h,055h,055h,055h,055h,055h,055h,055h
; 	.DB 055h,055h,055h,055h,055h,055h,055h,055h,055h,055h,055h,055h,055h,055h,055h,055h
; 	.DB 064h,064h,064h,064h,064h,064h,064h,064h,064h,064h,064h,064h,064h,064h,064h,064h
; 	.DB 064h,064h,064h,064h,064h,064h,064h,064h,064h,064h,064h,064h,064h,064h,064h,064h
; 	.DB 073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,073h
; 	.DB 073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,073h,0FFh
; EVOL3_RND:
; 	.DB 0AFh,04Eh,0EEh,0ADh,03Dh,08Dh,0FDh,0BCh,0ACh,07Ch,0DCh,09Ch,04Ch,0BBh,02Bh,06Bh
; 	.DB 09Bh,0EBh,01Bh,0CBh,0FAh,01Ah,00Ah,07Ah,09Ah,0CAh,02Ah,0EAh,08Ah,04Ah,06Ah,0BAh
; 	.DB 089h,0F9h,059h,019h,09Ah,0DAh,0EAh,05Ah,009h,0D9h,0A9h,039h,0E9h,069h,0C9h,029h
; 	.DB 0D9h,039h,009h,079h,0B9h,019h,0F9h,039h,019h,0E9h,0F9h,059h,099h,079h,0C9h,088h
; 	.DB 0C8h,068h,088h,0A8h,0E8h,018h,058h,0A8h,078h,0C8h,0A8h,038h,0F8h,048h,098h,058h
; 	.DB 028h,0D8h,0C8h,088h,0B8h,048h,0E8h,038h,098h,078h,018h,058h,0C8h,0E8h,0B8h,028h
; 	.DB 017h,037h,0C7h,097h,0B7h,0F7h,067h,087h,0D7h,027h,0E7h,047h,007h,0A7h,0F7h,077h
; 	.DB 0C7h,0E7h,0B7h,027h,0A7h,067h,0F7h,017h,0D7h,097h,077h,037h,0B7h,0C7h,097h,087h
; 	.DB 046h,0E6h,0A6h,016h,0B6h,0F6h,0D6h,066h,096h,0C6h,076h,0A6h,026h,056h,086h,0E6h
; 	.DB 0C6h,0B6h,0F6h,046h,056h,016h,0A6h,0D6h,076h,026h,096h,0E6h,046h,086h,0B6h,0C6h
; 	.DB 055h,095h,0D5h,0B5h,0E5h,025h,0F5h,045h,085h,0C5h,005h,065h,0A5h,035h,075h,0D5h
; 	.DB 025h,0E5h,055h,015h,0F5h,095h,0C5h,075h,045h,0A5h,065h,0D5h,0B5h,035h,0C5h,095h
; 	.DB 0E4h,0C4h,034h,0A4h,0F4h,004h,094h,074h,044h,0D4h,054h,084h,024h,0B4h,064h,014h
; 	.DB 094h,0E4h,0C4h,044h,0F4h,0A4h,004h,084h,054h,0B4h,074h,024h,0D4h,064h,034h,0C4h
; 	.DB 073h,0B3h,013h,0F3h,033h,093h,0D3h,053h,0A3h,023h,063h,083h,043h,0E3h,073h,013h
; 	.DB 0B3h,093h,0D3h,043h,063h,023h,083h,0F3h,033h,0C3h,0A3h,053h,013h,073h,0E3h,0FFh
EVOL3_RND2:
	.DB 01Fh,010h,00Eh,01Dh,00Dh,0EDh,00Dh,01Ch,0FCh,00Ch,00Ch,0ECh,01Ch,00Bh,0FBh,0EBh
	.DB 01Bh,00Bh,0EBh,0FBh,00Bh,0EBh,00Bh,01Bh,0FBh,0FBh,0FBh,0EBh,00Bh,01Bh,0EBh,0EBh
	.DB 009h,019h,0F9h,009h,0E9h,0E9h,019h,009h,009h,019h,0F9h,009h,0E9h,0E9h,009h,0F9h
	.DB 0E9h,019h,009h,0E9h,019h,009h,0E9h,019h,009h,009h,019h,0F9h,009h,019h,0E9h,008h
	.DB 028h,0F8h,008h,0E8h,0E8h,028h,0E8h,0F8h,0E8h,008h,028h,0F8h,0E8h,0F8h,0E8h,0F8h
	.DB 0F8h,028h,028h,0E8h,008h,0E8h,028h,0F8h,008h,0E8h,0E8h,008h,0F8h,028h,0F8h,028h
	.DB 017h,0F7h,037h,0F7h,0E7h,037h,0D7h,037h,0E7h,037h,0F7h,0E7h,0F7h,037h,0F7h,037h
	.DB 0E7h,0D7h,037h,0F7h,0F7h,037h,0F7h,0E7h,037h,0E7h,017h,037h,0E7h,037h,0F7h,037h
	.DB 046h,0E6h,0F6h,026h,0E6h,0F6h,016h,026h,0F6h,0F6h,0E6h,026h,026h,0F6h,0F6h,0E6h
	.DB 026h,0E6h,0F6h,026h,0E6h,016h,046h,0F6h,016h,0E6h,0E6h,016h,0F6h,046h,026h,0C6h
	.DB 015h,035h,0F5h,0D5h,025h,005h,035h,0E5h,015h,025h,0E5h,0F5h,0F5h,025h,035h,0E5h
	.DB 035h,0F5h,025h,005h,025h,035h,0F5h,015h,035h,0F5h,025h,0F5h,025h,0E5h,0F5h,095h
	.DB 0E4h,014h,0C4h,034h,0F4h,0C4h,034h,0E4h,024h,0E4h,014h,0C4h,0E4h,024h,014h,0F4h
	.DB 034h,0C4h,0E4h,024h,0F4h,034h,0E4h,0F4h,014h,0E4h,0C4h,0E4h,0F4h,0F4h,0E4h,0C4h
	.DB 073h,033h,0F3h,0D3h,013h,0E3h,013h,073h,0F3h,033h,013h,0E3h,033h,013h,0F3h,0D3h
	.DB 013h,0B3h,0F3h,0B3h,033h,073h,013h,0E3h,033h,0B3h,013h,0B3h,0E3h,0F3h,0E3h,0FFh

	;duracion (144=redonda,72=blanca,48=negra,24=corchea,12=scorchea,6=fusa,3=sfusa)
	;tabla_vol (0-3)
	;nota 
CANALA: 
	.DB	1,1,E1, 1,1,G1, 1,1,A1, 1,1,G1 ; 4/4
	.DB	1,1,D2, 1,1,C2, 1,1,D2, 1,1,E2 ; 4/4
CANALB:	
	.DB	1,1,E1, 1,1,G1, 1,1,A1, 1,1,G1 ; 4/4
	.DB	1,1,D2, 1,1,C2, 1,1,D2, 1,1,E2 ; 4/4

CANALC:	
	.DB	4,0,E1, 3,0,E1, 1,0,E1 ; 4/4

#include "estrella.asm"

TITULO:	.DB ">ON THE RUN",0
ALBUM:	.DB " THE DARK SIDE OF THE MOON",0
AUTHOR:	.DB " MUSIC BY PINK FLOYD 1973",0
VERSION:
	.DB "           Tributo a PF",0
DEVELOPER:	
	.DB "          CarlosMSX 2025",0
	.DB "carlosmsx@gmail.com"
	RomSize(16)


	.END

