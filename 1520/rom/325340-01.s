		; 1520 ROM 01 disassembly

		; 2014 Soci/Singular

RAM_SIZE	= $40
ROM_START	= $800

WIDTH		= 480
HEIGHT		= 999
COLORS		= 4
LINE_HEIGHT	= 10
FONT_WIDTH	= 6
FONT_SIZES	= 4
DASH_LENGTHS	= 16
MARGIN_STEPS	= 30
SETTLE_WAIT	= 11382

IEC_ATN_IN	= %00000001
IEC_CLK_IN	= %00000010
IEC_ATN_ACK	= %00100000
IEC_DATA_OUT	= %01000000
IEC_DATA_IN	= %10000000
IEC_FIRST_DEVICE = 4
IEC_DEVICE_NUMBERS = 8
IEC_LISTEN	= $20
IEC_SECOND	= $60
IEC_WAIT	= 2662

PEN_IDLE	= %00
PEN_PICK_UP	= %01
PEN_PUT_DOWN	= %10
PEN_WAIT	= 4743
PEN_STEPS	= 30

		; I/O

port_a		= $80			; ATNIN=0, CLKIN=1, ATNACK=5, DATAOUT=6, DATAIN=7
port_b		= $81			; DEVICE=0-2, LED=4, REMOVE=5, CHANGE=6, FEED=7
port_c		= $82			; PENDOWN=0, PENUP=1, COLORSWITH=7
port_d		= $83			; STEPX=0-3, STEPY=4-7
port_iec	= port_a
port_io		= port_b
port_pen	= port_c
port_stepper	= port_d
latch_l		= $85
latch_now	= $88
control		= $8f

		; RAM

accu		= $0
longer		= $2
shorter		= $4
cmd_x		= $6
cmd_y		= $8
absorig_x	= $a
absorig_y	= $c
relorig_x	= $e
relorig_y	= $10
num_temp	= $12
num_neg		= $14
count		= $15
fontp		= $16
upper_lower	= $18
quote_counter	= $19
underline	= $1a
font_tmp	= $1b
char_size	= $1c
current_color	= $1d
color		= $1e
cmd_use_pen	= $1f
pen_state	= $20
char_rotation	= $21
dashed		= $22
dash_counter	= $23
step_x		= $25
sign_x		= $26
step_y		= $27
sign_y		= $28
stepper_x	= $29
was_x		= $2a
stepper_y	= $2b
serial_buf	= $2c
serial_eot	= $2d

		*= ROM_START
;
; Font format:
;
; %EXXXYYYP
; E - last command in list (1)
; X - x coordinate (0-7)
; Y - y coordinate (0-7)
; P - use pen (1), or just move (0)
;
FONT_LOW_LINE	= $5c
FONT_PI		= $5e
FONT_SQUARE	= $5f

font:
		.byte $ff
;SPACE
		.byte $80
;EXCLAMATION MARK
		.byte $22, $25, $35, $33, $23, $26, $2f, $3f, $37, $a7

;QUOTATION MARK
		.byte $1e, $1d, $3e, $bd
;NUMBER SIGN
		.byte $14, $1d, $3c, $35, $46, $07, $0a, $cb
;DOLLAR SIGN
		.byte $14, $35, $47, $39, $19, $0b, $1d, $3d, $2e, $a3

;PERCENT SIGN
		.byte $04, $4d, $1c, $0d, $0b, $1b, $1d, $36, $47, $45, $35, $b7

;AMPERSAND
		.byte $42, $0b, $0d, $1f, $2d, $2b, $07, $05, $13, $23, $c7

;APOSTROPHE
		.byte $2a, $af
;LEFT PARENTHESIS
		.byte $32, $23, $15, $1d, $2f, $bf
;RIGHT PARENTHESIS
		.byte $22, $33, $45, $4d, $3f, $af
;ASTERISK
		.byte $04, $4d, $0c, $45, $2c, $a5
;PLUS SIGN
		.byte $24, $2d, $08, $c9
;COMMA
		.byte $20, $33, $35, $25, $23, $b3
;HYPHEN-MINUS
		.byte $08, $c9
;FULL STOP
		.byte $22, $25, $35, $33, $a3
;SOLIDUS
		.byte $02, $dd
;DIGIT ZERO
		.byte $04, $4d, $3f, $1f, $0d, $05, $13, $33, $45, $cd

;DIGIT ONE
		.byte $1c, $2f, $23, $12, $b3
;DIGIT TWO
		.byte $0c, $1f, $3f, $4d, $4b, $03, $c3
;DIGIT THREE
		.byte $0c, $1f, $3f, $4d, $4b, $39, $29, $38, $47, $45, $33, $13, $85

;DIGIT FOUR
		.byte $32, $3f, $09, $07, $c7
;DIGIT FIVE
		.byte $04, $13, $33, $45, $49, $3b, $0b, $0f, $cf

;DIGIT SIX
		.byte $08, $1b, $3b, $49, $45, $33, $13, $05, $0d, $1f, $3f, $cd

;DIGIT SEVEN
		.byte $02, $4b, $4f, $8f
;DIGIT EIGHT
		.byte $18, $0b, $0d, $1f, $3f, $4d, $4b, $39, $47, $45, $33, $13, $05, $07, $19, $b9

;DIGIT NINE
		.byte $04, $13, $33, $45, $4d, $3f, $1f, $0d, $0b, $19, $39, $cb

;COLON
		.byte $14, $17, $27, $25, $15, $1a, $1d, $2d, $2b, $9b

;SEMICOLON
		.byte $12, $25, $27, $17, $15, $25, $2a, $2d, $1d, $1b, $ab

;LESS-THAN SIGN
		.byte $42, $19, $cf
;EQUALS SIGN
		.byte $16, $47, $1a, $cb
;GREATER-THAN SIGN
		.byte $12, $49, $9f
;QUESTION MARK
		.byte $0c, $1f, $3f, $4d, $4b, $39, $29, $27, $24, $a3

;COMMERCIAL AT
		.byte $36, $3b, $1b, $15, $35, $47, $4b, $3d, $1d, $0b, $05, $13, $c3

;LATIN CAPITAL LETTER A
		.byte $02, $0b, $2f, $4b, $43, $08, $c9
;LATIN CAPITAL LETTER B
		.byte $02, $0f, $3f, $4d, $4b, $39, $08, $39, $47, $45, $33, $83

;LATIN CAPITAL LETTER C
		.byte $44, $33, $13, $05, $0d, $1f, $3f, $cd
;LATIN CAPITAL LETTER D
		.byte $02, $0f, $3f, $4d, $45, $33, $83
;LATIN CAPITAL LETTER E
		.byte $42, $03, $0f, $4f, $38, $89
;LATIN CAPITAL LETTER F
		.byte $02, $0f, $4f, $08, $b9
;LATIN CAPITAL LETTER G
		.byte $4c, $3f, $1f, $0d, $05, $13, $43, $49, $a9

;LATIN CAPITAL LETTER H
		.byte $02, $0f, $4e, $43, $08, $c9
;LATIN CAPITAL LETTER I
		.byte $12, $33, $22, $2f, $1e, $bf
;LATIN CAPITAL LETTER J
		.byte $04, $13, $23, $35, $bf
;LATIN CAPITAL LETTER K
		.byte $02, $0f, $4e, $07, $18, $c3
;LATIN CAPITAL LETTER L
		.byte $0e, $03, $c3
;LATIN CAPITAL LETTER M
		.byte $02, $0f, $2b, $29, $2b, $4f, $c3
;LATIN CAPITAL LETTER N
		.byte $02, $0f, $0c, $45, $4e, $c3
;LATIN CAPITAL LETTER O
		.byte $04, $0d, $1f, $3f, $4d, $45, $33, $13, $85

;LATIN CAPITAL LETTER P
		.byte $02, $0f, $3f, $4d, $4b, $39, $89
;LATIN CAPITAL LETTER Q
		.byte $26, $43, $32, $13, $05, $0d, $1f, $3f, $4d, $45, $b3

;LATIN CAPITAL LETTER R
		.byte $02, $0f, $3f, $4d, $4b, $39, $09, $18, $c3

;LATIN CAPITAL LETTER S
		.byte $04, $13, $33, $45, $47, $39, $19, $0b, $0d, $1f, $3f, $cd

;LATIN CAPITAL LETTER T
		.byte $22, $2f, $0e, $cf
;LATIN CAPITAL LETTER U
		.byte $0e, $05, $13, $33, $45, $cf
;LATIN CAPITAL LETTER V
		.byte $0e, $07, $23, $47, $cf
;LATIN CAPITAL LETTER W
		.byte $0e, $03, $27, $28, $27, $43, $cf
;LATIN CAPITAL LETTER X
		.byte $02, $05, $4d, $4f, $0e, $0d, $45, $c3
;LATIN CAPITAL LETTER Y
		.byte $22, $29, $4d, $4f, $0e, $0d, $a9
;LATIN CAPITAL LETTER Z
		.byte $0e, $4f, $4d, $05, $03, $c3
;LEFT SQUARE BRACKET
		.byte $22, $03, $0f, $af
;POUND SIGN
		.byte $5c, $4d, $3b, $35, $23, $13, $05, $17, $33, $53, $28, $c9

;RIGHT SQUARE BRACKET
		.byte $12, $33, $3f, $9f
;UPWARDS ARROW
		.byte $22, $2d, $08, $2d, $c9
;LEFTWARDS ARROW
		.byte $24, $09, $2d, $08, $d9
;BOX DRAWINGS LIGHT HORIZONTAL
		.byte $08, $f9
;LATIN SMALL LETTER A
		.byte $34, $23, $13, $05, $07, $19, $29, $37, $0a, $2b, $39, $35, $c3

;LATIN SMALL LETTER B
		.byte $0e, $03, $23, $35, $39, $2b, $8b
;LATIN SMALL LETTER C
		.byte $34, $23, $13, $05, $09, $1b, $2b, $b9
;LATIN SMALL LETTER D
		.byte $3a, $1b, $09, $05, $13, $33, $bf
;LATIN SMALL LETTER E
		.byte $06, $37, $39, $2b, $1b, $09, $05, $13, $b3

;LATIN SMALL LETTER F
		.byte $22, $2f, $3f, $18, $b9
;LATIN SMALL LETTER G
		.byte $02, $11, $21, $33, $39, $2b, $1b, $09, $07, $15, $25, $b7

;LATIN SMALL LETTER H
		.byte $02, $0f, $0a, $2b, $39, $b3
;LATIN SMALL LETTER I
		.byte $22, $29, $2a, $ad
;LATIN SMALL LETTER J
		.byte $02, $11, $21, $33, $39, $3a, $bd
;LATIN SMALL LETTER K
		.byte $32, $17, $0e, $03, $04, $bb
;LATIN SMALL LETTER L
		.byte $1e, $13, $a3
;LATIN SMALL LETTER M
		.byte $02, $0b, $08, $1b, $29, $23, $28, $3b, $49, $c3

;LATIN SMALL LETTER N
		.byte $02, $0b, $09, $1b, $2b, $39, $b3
;LATIN SMALL LETTER O
		.byte $04, $09, $1b, $2b, $39, $35, $23, $13, $85

;LATIN SMALL LETTER P
		.byte $04, $25, $37, $39, $2b, $0b, $81
;LATIN SMALL LETTER Q
		.byte $40, $31, $3b, $1b, $09, $07, $15, $b5
;LATIN SMALL LETTER R
		.byte $0a, $19, $13, $18, $2b, $bb
;LATIN SMALL LETTER S
		.byte $04, $13, $23, $35, $27, $17, $09, $1b, $2b, $b9

;LATIN SMALL LETTER T
		.byte $0a, $2b, $1e, $13, $a3
;LATIN SMALL LETTER U
		.byte $0a, $03, $33, $bb
;LATIN SMALL LETTER V
		.byte $0a, $07, $23, $47, $cb
;LATIN SMALL LETTER W
		.byte $0a, $05, $13, $25, $27, $25, $33, $45, $cb

;LATIN SMALL LETTER X
		.byte $02, $4b, $0a, $c3
;LATIN SMALL LETTER Y
		.byte $0a, $09, $25, $4a, $49, $81
;LATIN SMALL LETTER Z
		.byte $0a, $4b, $03, $c3
;BOX DRAWINGS LIGHT VERTICAL
		.byte $30, $bf
;LOW LINE
		.byte $70, $81
;WHITE UP-POINTING TRIANGLE
		.byte $02, $39, $63, $83
;GREEK CAPITAL LETTER PI
		.byte $06, $19, $39, $33, $12, $19, $39, $cb
;WHITE MEDIUM SQUARE
		.byte $02, $0f, $5f, $53, $83
;---------------
reset:		sei
		ldx #RAM_SIZE-1
		txs
		lda #255-IEC_DATA_OUT
		sta port_iec
		ldx #$ff
		stx port_io
		stx port_pen
		inx
		stx port_stepper
		lda #%11100000
		sta control
		txa
		ldx #RAM_SIZE-3
zp_init:	sta 0,x
		dex
		bne zp_init
		jsr line_feed
		lda #4
		sta count
		lsr
		sta char_size
stepper_init:	ldx #(WIDTH + MARGIN_STEPS * 2 + MARGIN_STEPS / 2 + 2) / 4
		jsr stepper_left
		dec count
		bne stepper_init
		lda #COLORS * 3
		sta count
pen_init:	jsr stepper_rl
		lda port_pen
		bpl pen_ok
		dec count
		bne pen_init
flash_led:	dex
		stx port_io
		jsr wait_settle
		sta port_stepper
		beq flash_led
pen_ok:		ldx #PEN_STEPS + MARGIN_STEPS + 2
		jsr stepper_right
b1:		jsr next_color
		ldx #FONT_SQUARE
		jsr print_char
		lda color
		bne b1
		dec char_size
paper_feed:	jsr carriage_return
idle_loop:	jsr wait_settle
		sta port_stepper
iec_loop2:	jsr atnack_hi
iec_loop:	lda port_io
		bpl paper_feed
		asl
		bmi nchange
		jsr next_color
		beq idle_loop
nchange:	asl
		bmi nremove
		lda #<WIDTH
		sta cmd_x
		lda #>WIDTH
		sta cmd_x+1
		jsr move_abs_pup
nremove:	jsr check_iec
		bpl iec_loop
		jsr data_lo
		jsr atn_hi
		jsr wait_iec
		jsr iecin
		lda port_io
		and #IEC_DEVICE_NUMBERS-1
		clc
		adc #IEC_LISTEN + IEC_FIRST_DEVICE
		cmp serial_buf
		beq device_ok
iec_skip:	jsr data_hi_check
		bmi iec_skip
		bpl iec_loop2

device_ok:	jsr check_iec
		bcs device_ok
		lda #IEC_SECOND
		sta serial_buf
		jsr check_iec
		bpl f1
		jsr iecin
f1:		lda serial_buf
		and #%11110000
		cmp #IEC_SECOND
		bne iec_skip
		lda serial_buf
		and #7
		asl
		tay
		lda modes+1,y
		pha
		lda modes,y
		pha
		cpy #with_param - modes
		bcc f2
		jsr iecin_number
		tya
f2:		rts

modes:		.word petscii_mode-1
		.word plotter_mode-1
with_param:	.word set_color-1
		.word set_size-1
		.word set_rotation-1
		.word set_dashed-1
		.word set_uplower-1
		.word reset-1
;---------------
set_color:	and #COLORS-1
		sta color
		jsr select_pen
		beq skip_rest
;---------------
set_size:	and #FONT_SIZES-1
		sta char_size
		bpl skip_rest
;---------------
set_rotation:	sta char_rotation
		bpl skip_rest
;---------------
set_dashed:	and #DASH_LENGTHS-1
		sta dashed
		bpl skip_rest
;---------------
set_uplower:	and #1
		lsr
		ror
		sta upper_lower
		bcc skip_rest
b2:		jsr iecin
skip_rest:	lda serial_eot
		beq b2
		jmp idle_loop
;---------------
iecin2:		lda serial_eot
		eor #%11111111
		beq at_eot
;---------------
iecin:		jsr check_iec
		bcs iecin
b3:		jsr data_hi_check
		and #IEC_DATA_IN / 4
		bne b3
		sta serial_eot
		ldx #9
b4:		jsr check_iec
		bcs neot
		dex
		bne b4
		jsr data_lo
		dec serial_eot
		ldx #7
b5:		dex
		bne b5
		jsr data_hi_check
neot:		ldx #8
iecbitloop:	lda port_iec
		and #IEC_CLK_IN
		beq iecbitloop
b6:		lda port_iec
		and #IEC_CLK_IN
		bne b6
		lda port_iec
		eor #$ff
		asl			;data
		ror serial_buf
		dex
		bne iecbitloop
b7:		jsr check_iec		;clk?
		bcc b7
		jsr data_lo
		ldx #20
b8:		dex
		bne b8
		lda serial_eot
		bpl f3
		jsr atnack_hi
f3:		lda serial_buf
		cmp #$0d		;"{cr}"
at_eot:		rts
;---------------
atn_hi:		lda #IEC_ATN_ACK
		bne set_iec_lines
;---------------
data_lo:	lda #IEC_DATA_OUT
;---------------
set_iec_lines:	ora port_iec
		bne sta_iec
;---------------
atnack_hi:	lda #255-IEC_ATN_ACK	;atnack
		and port_iec
		sta port_iec
;---------------
data_hi_check:	lda #255-IEC_DATA_OUT	;data
		and port_iec
sta_iec:	sta port_iec
;---------------
check_iec:	lda port_iec
		cmp port_iec
		bne check_iec
		lsr
		ror
		rts
;---------------
petscii_mode:	jsr iecin
		beq do_cr
		cmp #$0a		;"{lf}"
		beq do_cr
		cmp #$8d		;"{shift return}"
		beq do_shcr
		cmp #$ff		;"{pi}"
		bne f4
		lda #FONT_PI + $80
f4:		cmp #$22		;'"'
		bne f5
		inc quote_counter
f5:		eor upper_lower
		sta serial_buf
		and #%01111111
		sec
		sbc #32
		bcs f6
		lda quote_counter
		and #1
		sta underline
		beq nextchar
		lda serial_buf
		and #%01111111
		ora #%00100000
f6:		cmp #64
		bcs nextchar
		cmp #32
		bcc f7
		ldx serial_buf
		bpl f7
		adc #%00011111
f7:		sta serial_buf
		jsr in_printarea_x
		bcc f8
		jsr carriage_return
f8:		jsr print_buf
		lsr underline
		bcc nextchar
		jsr set_absorigin
		ldx #FONT_LOW_LINE
		jsr print_char
nextchar:	lda serial_eot
		beq petscii_mode
		jmp idle_loop

do_cr:		jsr carriage_return
		stx quote_counter
		stx underline
		beq nextchar
do_shcr:	jsr move_left_side
		beq nextchar
;---------------
plotter_mode:	jsr iecin
		stx cmd_use_pen
		cmp #$49		;"i"
		bne f9
		jsr set_relorigin
f9:		cmp #$48		;"h"
		bne f10
		jsr set_absorigin
f10:		cmp #$4d		;"m"
		beq nuse_pen
		cmp #$52		;"r"
		beq nuse_pen
		cmp #$44		;"d"
		beq f11
		cmp #$4a		;"j"
		bne skip_rest2
f11:		inc cmd_use_pen
nuse_pen:	pha
		jsr iecin_number
		sty cmd_x
		sta cmd_x+1
		jsr iecin_number
		sty cmd_y
		sta cmd_y+1
		pla
		and #%00000100
		beq f12
		jsr move_abs
		beq skip_rest2
f12:		jsr move_rel
skip_rest2:	jmp skip_rest
;---------------
iecin_number:	lda #3
		sta count
		jsr num_clr
b9:		jsr iecin2
		beq num_end
		cmp #$2e		;"."
		beq digits_finished
		cmp #$2d		;"-"
		bne f13
		dec num_neg
f13:		jsr is_digit
		bcs b9
next_digit:	pha
		asl num_temp
		rol num_temp+1
		ldx num_temp
		ldy num_temp+1
		asl num_temp
		rol num_temp+1
		asl num_temp
		rol num_temp+1
		clc
		txa
		adc num_temp
		sta num_temp
		tya
		adc num_temp+1
		sta num_temp+1
		pla
		clc
		adc num_temp
		sta num_temp
		bcc f14
		inc num_temp+1
f14:		dec count
		beq digits_finished
		jsr iecin2
		beq num_end
		jsr is_digit
		bcc next_digit
b10:		cmp #$45		;"e"
		bne f15
		jsr num_clr
f15:		cmp #$20		;" "
		beq num_end
		cmp #$2c		;","
		beq num_end
digits_finished: jsr iecin2
		bne b10
num_end:	ldy num_temp
		lda num_temp+1
		ldx num_neg
		beq nneg
;---------------
negate:		pha
		tya
		eor #$ff
		tay
		pla
		eor #$ff
		iny
		bne nneg
		clc
		adc #1
nneg:		rts
;---------------
num_clr:	lda #0
		sta num_neg
		sta num_temp
		sta num_temp+1
		rts
;---------------
is_digit:	tax
		sec
		sbc #$30		;"0"
		bcc f16
		cmp #10
		bcc its_digit
f16:		txa
		sec
its_digit:	rts
;---------------
print_buf:	ldx serial_buf
;---------------
print_char:	inx
		lda #>font
		sta fontp+1
		ldy #<font
		sty fontp
b11:		lda (fontp),y
		bpl f17
		dex
		beq char_found
f17:		inc fontp
		bne b11
		inc fontp+1
		bne b11
char_found:	jsr set_relorigin
print_loop:	ldy #1
		lda (fontp),y		;exxxyyyp
		sta font_tmp
print_last:	lsr
		tax
		and #%111
		sta cmd_y
		lda #0
		sta cmd_x+1
		sta cmd_y+1
		rol
		sta cmd_use_pen
		txa
		lsr
		lsr
		lsr
		and #%111
		sta cmd_x
		ldx font_tmp
		inx
		beq f18
		lda char_rotation
		beq f18
		ldy cmd_y
		lda cmd_x
		eor #%111
		sta cmd_y
		sty cmd_x
f18:		ldx char_size
		beq f19
b12:		asl cmd_x
		rol cmd_x+1
		asl cmd_y
		rol cmd_y+1
		dex
		bne b12
f19:		jsr move_rel
		inc fontp
		bne f20
		inc fontp+1
f20:		lda font_tmp
		bpl print_loop
		cmp #$ff
		beq f21
		lda #$ff
		sta font_tmp
		lda #$80 + (FONT_WIDTH * 16)
		bne print_last

f21:		rts
;---------------
move_rel:	ldx #2
b13:		clc
		lda cmd_x,x
		adc relorig_x,x
		sta cmd_x,x
		lda cmd_x+1,x
		adc relorig_x+1,x
		sta cmd_x+1,x
		dex
		dex
		beq b13
;---------------
move_abs:	ldx #2
b14:		sec
		lda cmd_x,x
		sbc absorig_x,x
		sta cmd_x,x
		lda cmd_x+1,x
		sbc absorig_x+1,x
		sta cmd_x+1,x
		dex
		dex
		beq b14

		ldx #2
b15:		ldy cmd_x,x
		lda cmd_x+1,x
		sta sign_x,x
		bpl f22
		jsr negate
		sta cmd_x+1,x
		sty cmd_x,x
f22:		dex
		dex
		beq b15

		sec
		lda cmd_y
		sbc cmd_x
		lda cmd_y+1
		sbc cmd_x+1
		lda #0
		sta dash_counter
		rol
		rol
		tax
		lda cmd_x+1,x
		sta longer+1
		lsr
		sta accu+1
		lda cmd_x,x
		sta longer
		ror
		sta accu
		txa
		eor #2
		tax
		sta was_x
		lda cmd_x,x
		sta shorter
		lda cmd_x+1,x
		sta shorter+1

move_loop:	lda cmd_x
		ora cmd_x+1
		bne f23
		lda cmd_y
		ora cmd_y+1
		bne move_v1
		rts

f23:		lda cmd_y
		ora cmd_y+1
		beq move_h1

		sec
		lda accu
		sbc shorter
		sta accu
		lda accu+1
		sbc shorter+1
		sta accu+1
		bcc overf

		lda was_x
		beq move_v1
move_h1:	inc step_x
		bne f24

overf:		clc
		lda accu
		adc longer
		sta accu
		lda accu+1
		adc longer+1
		sta accu+1

		inc step_x
move_v1:	inc step_y

f24:		ldx #2
move_xy_loop:	lda sign_x,x
		bmi f25
		jsr step1
f25:		ldy absorig_x,x
		lda absorig_x+1,x
		bpl f26
		jsr negate
f26:		pha
		tya
		sec
		sbc #<HEIGHT
		pla
		sbc #>HEIGHT
		bcs f27
		txa
		bne move_ib
		jsr in_printarea_x
		bcc move_ib
f27:		rol cmd_use_pen
		sec
		ror cmd_use_pen
		bmi move_oob

move_ib:	lda step_x,x
		beq nstep
		lda sign_x,x
		bmi f28
		inc stepper_x,x
		inc stepper_x,x
f28:		dec stepper_x,x

move_oob:	lda step_x,x
		beq nstep
		lda cmd_x,x
		bne f29
		dec cmd_x+1,x
f29:		dec cmd_x,x

nstep:		lda sign_x,x
		bpl f30
		jsr step1
f30:		dex
		dex
		beq move_xy_loop

		lda cmd_use_pen
		bpl f31
		and #1
		sta cmd_use_pen
		lsr
f31:		beq pen_up
		ldx dashed
		beq pen_down
		lda dash_counter
		bne skip_pen
		stx dash_counter
		lda pen_state
		and #PEN_PICK_UP
		beq pen_down
;---------------
pen_up:		ldx #255-PEN_PICK_UP
		bne f32

pen_down:	ldx #255-PEN_PUT_DOWN
f32:		cpx pen_state
		beq skip_pen
		cpx #255-PEN_PUT_DOWN
		beq f33
		jsr wait_pen
f33:		stx port_pen
		stx pen_state
		jsr wait_pen
		lda #255-PEN_IDLE
		sta port_pen
skip_pen:	jsr set_stepper
		sta step_x
		sta step_y
		dec dash_counter
		jmp move_loop
;---------------
step1:		ldy step_x,x
		beq f34
		asl
		bcs step1_m
		inc absorig_x,x
		bne f34
		inc absorig_x+1,x
f34:		rts

step1_m:	lda absorig_x,x
		bne f35
		dec absorig_x+1,x
f35:		dec absorig_x,x
		rts
;---------------
in_printarea_x: sec
		lda absorig_x
		sbc #<WIDTH
		lda absorig_x+1
		sbc #>WIDTH
		rts
;---------------
set_stepper:	lda stepper_x
		and #%11
		tay
		lda stepconst_x,y
		pha
		lda stepper_y
		and #%11
		tay
		pla
		ora stepconst_y,y
		sta port_stepper
;---------------
wait_iec:	lda #<IEC_WAIT
		ldy #>IEC_WAIT
		bne wait
;---------------
wait_pen:	lda #<PEN_WAIT
		ldy #>PEN_WAIT
		bne wait
;---------------
wait_settle:	lda #<SETTLE_WAIT
		ldy #>SETTLE_WAIT
wait:		sta latch_l
		sty latch_now
b16:		lda control
		bpl b16
		lda #0
		rts

stepconst_x:	.byte %00001001,%00001010,%00000110,%00000101
stepconst_y:	.byte %10010000,%10100000,%01100000,%01010000
;---------------
carriage_return: jsr move_left_side
;---------------
line_feed:	ldx char_size
		inx
		lda #LINE_HEIGHT / 2
b17:		asl
		dex
		bne b17
		sta absorig_y
		stx absorig_y+1
		jsr move_abs_pup
;---------------
set_relorigin:	ldx #4
b18:		lda absorig_x-1,x
		sta relorig_x-1,x
		dex
		bne b18
		rts
;---------------
set_absorigin:	ldx #4
b19:		lda relorig_x-1,x
		sta cmd_x-1,x
		dex
		bne b19
		beq move_abs_pup
;---------------
move_left_side: lda #0
		sta cmd_x
		sta cmd_x+1
move_horiz:	lda absorig_y
		sta cmd_y
		lda absorig_y+1
		sta cmd_y+1
;---------------
move_abs_pup:	lda #0
		sta cmd_use_pen
		jmp move_abs
;---------------
next_color:	inc color
		lda color
		and #COLORS-1
		sta color
;---------------
select_pen:	lda current_color
		cmp color
		beq same_color
		lda absorig_x
		pha
		lda absorig_x+1
		pha
		jsr pen_up
		jsr move_left_side
b20:		ldx #PEN_STEPS + MARGIN_STEPS
		jsr stepper_left
		jsr stepper_rl
		jsr stepper_rl
		ldx #PEN_STEPS + MARGIN_STEPS
		jsr stepper_right
		inc current_color
		lda current_color
		and #COLORS-1
		sta current_color
		cmp color
		bne b20
		pla
		sta cmd_x+1
		pla
		sta cmd_x
		jmp move_horiz
;---------------
stepper_rl:	jsr stepper_r
		ldx #PEN_STEPS
;---------------
stepper_left:	dec stepper_x
		jsr set_stepper
		dex
		bne stepper_left
same_color:	rts
;---------------
stepper_r:	ldx #PEN_STEPS
;---------------
stepper_right:	inc stepper_x
		jsr set_stepper
		dex
		bne stepper_right
		rts

		.byte $aa

		.word reset, reset, reset
