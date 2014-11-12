;************************************************************************************
;************************************************************************************
; This file was included in the Project 64 Repository after the efforts to contact
; Lee Davison, the original author ware proven unsuccessful. The inclusion is meant
; to honour his sterling work on providing us with the very best document on every
; bit of the Commodore 64's firmware content. We want this to remain available to
; the public and allow other members to benefit from Lee's original, excellent job.
;************************************************************************************
; $VER:C64LD11.S, included on 2014-11-12
;************************************************************************************
;
; The almost completely commented C64 ROM disassembly. V1.01 Lee Davison 2012
;
; This is a bit correct assembly listing for the C64 BASIC and kernal ROMs as two 8K
; ROMs. You should be able to assemble the C64 ROMs from this with most 6502 assemblers,
; as no macros or 'special' features were used. This has been tested using Michal
; Kowalski's 6502 Simulator assemble function. See http://exifpro.com/utils.html for
; this program.
;
; Many references were used to complete this disassembly including, but not limited to,
; "Mapping the Vic 20", "Mapping the C64", "C64 Programmers reference", "C64 user
; guide", "The complete Commodore inner space anthology", "VIC Revealed" and various
; text files, pictures and other documents.

;************************************************************************************
;************************************************************************************
;
; first a whole load of equates

LAB_00	= $00			; 6510 I/O port data direction register
					; bit	default
					; ---	-------
					;  7	unused
					;  6	unused
					;  5	1 = output
					;  4	0 = input
					;  3	1 = output
					;  2	1 = output
					;  1	1 = output
					;  0	1 = output

LAB_01	= $01			; 6510 I/O port data register
					; bit	name		function
					; ---	----		--------
					;  7	unused
					;  6	unused
					;  5	cass motor	1 = off,	0 = on
					;  4	cass sw	1 = off,	0 = on
					;  3	cass data
					;  2	CHAREN	1 = I/O,	0 = chraracter ROM
					;  1	HIRAM		1 = Kernal,	0 = RAM
					;  0	LORAM		1 = BASIC,	0 = RAM

;LAB_02	= $02			; unused

; This vector points to the address of the BASIC routine which converts a floating point
; number to an integer, however BASIC does not use this vector. It may be of assistance
; to the programmer who wishes to use data that is stored in floating point format. The
; parameter passed by the USR command is available only in that format for example.

LAB_03	= $03			; float to fixed vector low byte
LAB_04	= $04			; float to fixed vector high byte

; This vector points to the address of the BASIC routine which converts an integer to a
; floating point number, however BASIC does not use this vector. It may be used by the
; programmer who needs to make such a conversion for a machine language program that
; interacts with BASIC.  To return an integer value with the USR command for example.

LAB_05	= $05			; fixed to float vector low byte
LAB_06	= $06			; fixed to float vector high byte

; These locations hold searched for characters when BASIC is searching for the end of
; a srting or crunching BASIC lines

LAB_07	= $07			; search character
LAB_08	= $08			; scan quotes flag

; The cursor column position prior to the TAB or SPC is moved here from $D3, and is used
; to calculate where the cursor ends up after one of these functions is invoked.

; Note that the value contained here shows the position of the cursor on a logical line.
; Since one logical line can be up to four physical lines long, the value stored here
; can range from 0 to 87.

LAB_09	= $09			; TAB column save

; The routine that converts the text in the input buffer into lines of executable program
; tokes, and the routines that link these program lines together, use this location as an
; index into the input buffer area. After the job of converting text to tokens is done,
; the value in this location is equal to the length of the tokenized line.

; The routines which build an array or locate an element in an array use this location to
; calculate the number of DIMensions called for and the amount of storage required for a
; newly created array, or the number of subscripts when referencing an array element.

LAB_0A	= $0A			; load/verify flag, 0 = load, 1 = verify
LAB_0B	= $0B			; temporary byte, line crunch/array access/logic operators

; This is used as a flag by the routines that build an array or reference an existing
; array. It is used to determine whether a variable is in an array, whether the array
; has already been DIMensioned, and whether a new array should assume the default size.

LAB_0C	= $0C			; DIM flag

; This flag is used to indicate whether data being operated upon is string or numeric. A
; value of $FF in this location indicates string data while a $00 indicates numeric data.

LAB_0D	= $0D			; data type flag, $FF = string, $00 = numeric

; If the above flag indicates numeric then a $80 in this location identifies the number
; as an integer, and a $00 indicates a floating point number.

LAB_0E	= $0E			; data type flag, $80 = integer, $00 = floating point

; The garbage collection routine uses this location as a flag to indicate that garbage
; collection has already been tried before adding a new string. If there is still not
; enough memory, an OUT OF MEMORY error message will result.

; LIST uses this byte as a flag to let it know when it has come to a character string in
; quotes. It will then print the string,rather than search it for BASIC keyword tokens.

; This location is also used during the process of converting a line of text in the BASIC
; input buffer into a linked program line of BASIC keyword tokens to flag a DATA line is
; being processed.

LAB_0F	= $0F			; garbage collected/open quote/DATA flag

; If an opening parenthesis is found, this flag is set to indicate that the variable in
; question is either an array variable or a user-defined function.

LAB_10	= $10			; subscript/FNx flag

; This location is used to determine whether the sign of the value returned by the
; functions SIN, COS, ATN or TAN is positive or negative.

; Also the comparison routines use this location to indicate the outcome of the compare.
; For A <=> B the value here will be $01 if A > B, $02 if A = B, and $04 if A < B. If
; more than one comparison operator was used to compare the two variables then the value
; here will be a combination of the above values.

LAB_11	= $11			; input mode flag, $00 = INPUT, $40 = GET, $98 = READ
LAB_12	= $12			; ATN sign/comparison evaluation flag

; When the default input or output device is used the value here will be a zero, and the
; format of prompting and output will be the standard screen output format. The location
; $B8 is used to decide what device actually to put input from or output to.

LAB_13	= $13			; current I/O channel

; Used whenever a 16 bit integer is used e.g. the target line number for GOTO, LIST, ON,
; and GOSUB also the number of a BASIC line that is to be added or replaced. additionally
; PEEK, POKE, WAIT, and SYS use this location as a pointer to the address which is the
; subject of the command.

LAB_14	= $14			; temporary integer low byte
LAB_15	= $15			; temporary integer high byte

; This location points to the next available slot in the temporary string descriptor
; stack located at $19-$21.

LAB_16	= $16			; descriptor stack pointer, next free

; This contains information about temporary strings which hve not yet been assigned to
; a string variable.

LAB_17	= $17			; current descriptor stack item pointer low byte
LAB_18	= $18			; current descriptor stack item pointer high byte
LAB_19	= $19			; to $21, descriptor stack

; These locations are used by BASIC multiplication and division routines. They are also
; used by the routines which compute the size of the area required to store an array
; which is being created.

LAB_22	= $22			; misc temp byte
LAB_23	= $23			; misc temp byte
LAB_24	= $24			; misc temp byte
LAB_25	= $25			; misc temp byte

LAB_26	= $26			; temp mantissa 1
LAB_27	= $27			; temp mantissa 2
LAB_28	= $28			; temp mantissa 3
LAB_29	= $29			; temp mantissa 4

; Two byte pointer to where the BASIC program text is stored.

LAB_2B	= $2B			; start of memory low byte
LAB_2C	= $2C			; start of memory high byte

; Two byte pointer to the start of the BASIC variable storage area.

LAB_2D	= $2D			; start of variables low byte
LAB_2E	= $2E			; start of variables high byte

; Two byte pointer to the start of the BASIC array storage area.

LAB_2F	= $2F			; end of variables low byte
LAB_30	= $30			; end of variables high byte

; Two byte pointer to end of the start of free RAM.

LAB_31	= $31			; end of arrays low byte
LAB_32	= $32			; end of arrays high byte

; Two byte pointer to the bottom of the string text storage area.

LAB_33	= $33			; bottom of string space low byte
LAB_34	= $34			; bottom of string space high byte

; Used as a temporary pointer to the most current string added by the routines which
; build strings or move them in memory.

LAB_35	= $35			; string utility ptr low byte
LAB_36	= $36			; string utility ptr high byte

; Two byte pointer to the highest address used by BASIC +1.

LAB_37	= $37			; end of memory low byte
LAB_38	= $38			; end of memory high byte

; These locations contain the line number of the BASIC statement which is currently being
; executed. A value of $FF in location $3A means that BASIC is in immediate mode.

LAB_39	= $39			; current line number low byte
LAB_3A	= $3A			; current line number high byte

; When program execution ends or stops the last line number executed is stored here.

LAB_3B	= $3B			; break line number low byte
LAB_3C	= $3C			; break line number high byte

; These locations contain the address of the start of the text of the BASIC statement
; that is being executed.  The value of the pointer to the address of the BASIC text
; character currently being scanned is stored here each time a new BASIC statement begins
; execution.

LAB_3D	= $3D			; continue pointer low byte
LAB_3E	= $3E			; continue pointer high byte

; These locations hold the line number of the current DATA statement being READ. If an
; error concerning the DATA occurs this number will be moved to $39/$3A so that the error
; message will show the line that contains the DATA statement rather than in the line that
; contains the READ statement.

LAB_3F	= $3F			; current DATA line number low byte
LAB_40	= $40			; current DATA line number high byte

; These locations point to the address where the next DATA will be READ from. RESTORE
; sets this pointer back to the address indicated by the start of BASIC pointer.

LAB_41	= $41			; DATA pointer low byte
LAB_42	= $42			; DATA pointer high byte

; READ, INPUT and GET all use this as a pointer to the address of the source of incoming
; data, such as DATA statements, or the text input buffer.

LAB_43	= $43			; READ pointer low byte
LAB_44	= $44			; READ pointer high byte

LAB_45	= $45			; current variable name first byte
LAB_46	= $46			; current variable name second byte

; These locations point to the value of the current BASIC variable Specifically they
; point to the byte just after the two-character variable name.

LAB_47	= $47			; current variable address low byte
LAB_48	= $48			; current variable address high byte

; The address of the BASIC variable which is the subject of a FOR/NEXT loop is first
; stored here before being pushed onto the stack.

LAB_49	= $49			; FOR/NEXT variable pointer low byte
LAB_4A	= $4A			; FOR/NEXT variable pointer high byte

; The expression evaluation routine creates this to let it know whether the current
; comparison operation is a < $01, = $02 or > $04 comparison or combination.

LAB_4B	= $4B			; BASIC execute pointer temporary low byte/precedence flag
LAB_4C	= $4C			; BASIC execute pointer temporary high byte
LAB_4D	= $4D			; comparrison evaluation flag

; These locations are used as a pointer to the function that is created during function
; definition . During function execution it points to where the evaluation results should
; be saved.

LAB_4E	= $4E			; FAC temp store/function/variable/garbage pointer low byte
LAB_4F	= $4F			; FAC temp store/function/variable/garbage pointer high byte

; Temporary Pointer to the current string descriptor.

LAB_50	= $50			; FAC temp store/descriptor pointer low byte
LAB_51	= $51			; FAC temp store/descriptor pointer high byte

LAB_53	= $53			; garbage collection step size

; The first byte is the 6502 JMP instruction $4C, followed by the address of the required
; function taken from the table at $C052.

LAB_54	= $54			; JMP opcode for functions
LAB_55	= $55			; functions jump vector low byte
LAB_56	= $56			; functions jump vector high byte

LAB_57	= $57			; FAC temp store
LAB_58	= $58			; FAC temp store
LAB_59	= $59			; FAC temp store
LAB_5A	= $5A			; FAC temp store
LAB_5B	= $5B			; block end high byte
LAB_5C	= $5C			; FAC temp store
LAB_5D	= $5D			; FAC temp store
LAB_5E	= $5E			; FAC temp store
LAB_5F	= $5F			; FAC temp store
LAB_60	= $60			; block start high byte

; floating point accumulator 1

LAB_61	= $61			; FAC1 exponent
LAB_62	= $62			; FAC1 mantissa 1
LAB_63	= $63			; FAC1 mantissa 2
LAB_64	= $64			; FAC1 mantissa 3
LAB_65	= $65			; FAC1 mantissa 4
LAB_66	= $66			; FAC1 sign
LAB_67	= $67			; constant count/-ve flag
LAB_68	= $68			; FAC1 overflow

; floating point accumulator 2

LAB_69	= $69			; FAC2 exponent
LAB_6A	= $6A			; FAC2 mantissa 1
LAB_6B	= $6B			; FAC2 mantissa 2
LAB_6C	= $6C			; FAC2 mantissa 3
LAB_6D	= $6D			; FAC2 mantissa 4
LAB_6E	= $6E			; FAC2 sign
LAB_6F	= $6F			; FAC sign comparrison
LAB_70	= $70			; FAC1 rounding

LAB_71	= $71			; temp BASIC execute/array pointer low byte/index
LAB_72	= $72			; temp BASIC execute/array pointer high byte

LAB_0073	= $73			; increment and scan memory, BASIC byte get
LAB_0079	= $79			; scan memory, BASIC byte get
LAB_7A	= $7A			; BASIC execute pointer low byte
LAB_7B	= $7B			; BASIC execute pointer high byte
LAB_80	= $80			; numeric test entry

LAB_8B	= $8B			; RND() seed, five bytes

; kernal work area

LAB_90	= $90			; serial status byte
					;	function
					; bit	casette		serial bus
					; ---	--------		----------
					;  7	end of tape		device not present
					;  6	end of file		EOI
					;  5	checksum error
					;  4	read error
					;  3	long block
					;  2	short block
					;  1				time out read
					;  0				time out write

; This location is updated every 1/60 second during the IRQ routine. The value saved is
; the keyboard c7 column byte which contains the stop key

LAB_91	= $91			; stop key column
					; bit	key, 0 = pressed
					; ---	--------
					;  7	[RUN]
					;  6	Q
					;  5	[CBM]
					;  4	[SP]
					;  3	2
					;  2	[CTL]
					;  1	[LFT]
					;  0	1

; This location is used as an adjustable timing constant for tape reads to allow for
; slight speed variations on tapes.

LAB_92	= $92			; timing constant for tape read

; The same routine is used for both LOAD and VERIFY, the flag here determines which
; that routine does.

LAB_93	= $93			; load/verify flag, load = $00, verify = $01

; This location is used to indecate that a serial byte is waiting to be sent.

LAB_94	= $94			; serial output: deferred character flag
					; $00 = no character waiting, $xx = character waiting

; This location holds the serial character waiting to be sent. A value of $FF here
; means no character is waiting.

LAB_95	= $95			; serial output: deferred character
					; $FF = no character waiting, $xx = waiting character

LAB_96	= $96			; cassette block synchronization number

; X register save location for routines that get and put an ASCII character.

LAB_97	= $97			; X register save

; The number of currently open I/O files is stored here. The maximum number that can be
; open at one time is ten. The number stored here is used as the index to the end of the
; tables that hold the file numbers, device numbers, and secondary addresses.

LAB_98	= $98			; open file count

; The default value of this location is 0, the keyboard.

LAB_99	= $99			; input device number

; The default value of this location is 3, the screen.

LAB_9A	= $9A			; output device number
					; number	device
					; ------	------
					;  0		keyboard
					;  1		cassette
					;  2		RS-232C
					;  3		screen
					;  4-31	serial bus

LAB_9B	= $9B			; tape character parity
LAB_9C	= $9C			; tape byte received flag

LAB_9D	= $9D			; message mode flag,
					; $C0 = both control and kernal messages,
					; $80 = control messages only,
					; $40 = kernal messages only,
					; $00 = neither control or kernal messages

LAB_9E	= $9E			; tape Pass 1 error log/character buffer

LAB_9F	= $9F			; tape Pass 1 error log/character index

; These three locations form a counter which is updated 60 times a second, and serves as
; a software clock which counts the number of jiffies that have elapsed since the computer
; was turned on. After 24 hours and one jiffy these locations are set back to $000000.

LAB_A0	= $A0			; jiffy clock high byte
LAB_A1	= $A1			; jiffy clock mid byte
LAB_A2	= $A2			; jiffy clock low byte

LAB_A3	= $A3			; EOI flag byte/tape bit count

; b0 of this location reflects the current phase of the tape output cycle.

LAB_A4	= $A4			; tape bit cycle phase
LAB_A5	= $A5			; cassette synchronization byte count/serial bus bit count

LAB_A6	= $A6			; tape buffer index
LAB_A7	= $A7			; receiver input bit temp storage
LAB_A8	= $A8			; receiver bit count in
LAB_A9	= $A9			; receiver start bit check flag, $90 = no start bit
					; received, $00 = start bit received
LAB_AA	= $AA			; receiver byte buffer/assembly location
LAB_AB	= $AB			; receiver parity bit storage

LAB_AC	= $AC			; tape buffer start pointer low byte
					; scroll screen ?? byte
LAB_AD	= $AD			; tape buffer start pointer high byte
					; scroll screen ?? byte
LAB_AE	= $AE			; tape buffer end pointer low byte
					; scroll screen ?? byte
LAB_AF	= $AF			; tape buffer end pointer high byte
					; scroll screen ?? byte

LAB_B0	= $B0			; tape timing constant min byte
LAB_B1	= $B1			; tape timing constant max byte

; Thess two locations point to the address of the cassette buffer. This pointer must
; be greater than or equal to $0200 or an ILLEGAL DEVICE NUMBER error will be sent
; when tape I/O is tried. This pointer must also be less that $8000 or the routine
; will terminate early.

LAB_B2	= $B2			; tape buffer start pointer low byte
LAB_B3	= $B3			; tape buffer start pointer high byte

; RS232 routines use this to count the number of bits transmitted and for parity and
; stop bit manipulation. Tape load routines use this location to flag when they are
; ready to receive data bytes.

LAB_B4	= $B4			; transmitter bit count out

; This location is used by the RS232 routines to hold the next bit to be sent and by the
; tape routines to indicate what part of a block the read routine is currently reading.

LAB_B5	= $B5			; transmitter next bit to be sent

; RS232 routines use this area to disassemble each byte to be sent from the transmission
; buffer pointed to by $F9.

LAB_B6	= $B6			; transmitter byte buffer/disassembly location

; Disk filenames may be up to 16 characters in length while tape filenames be up to 187
; characters in length.

; If a tape name is longer than 16 characters the excess will be truncated by the
; SEARCHING and FOUND messages, but will still be present on the tape.

; A disk file is always referred to by a name. This location will always be greater than
; zero if the current file is a disk file.

; An RS232 OPEN command may specify a filename of up to four characters. These characters
; are copied to locations $293 to $296 and determine baud rate, word length, and parity,
; or they would do if the feature was fully implemented.

LAB_B7	= $B7			; file name length

LAB_B8	= $B8			; logical file
LAB_B9	= $B9			; secondary address
LAB_BA	= $BA			; current device number
					; number	device
					; ------	------
					;  0		keyboard
					;  1		cassette
					;  2		RS-232C
					;  3		screen
					;  4-31	serial bus
LAB_BB	= $BB			; file name pointer low byte
LAB_BC	= $BC			; file name pointer high byte
LAB_BD	= $BD			; tape write byte/RS232 parity byte

; Used by the tape routines to count the number of copies of a data block remaining to
; be read or written.

LAB_BE	= $BE			; tape copies count

LAB_BF	= $BF			; tape parity count

LAB_C0	= $C0			; tape motor interlock
LAB_C1	= $C1			; I/O start addresses low byte
LAB_C2	= $C2			; I/O start addresses high byte

LAB_C3	= $C3			; kernal setup pointer low byte
LAB_C4	= $C4			; kernal setup pointer high byte

LAB_C5	= $C5			; current key pressed
					;
					;  # key	 # key	 # key	 # key
					; -- ---	-- ---	-- ---	-- ---
					; 00 1	10 none	20 [SPACE]	30 Q
					; 01 3	11 A		21 Z		31 E
					; 02 5	12 D		22 C		32 T
					; 03 7	13 G		23 B		33 U
					; 04 9	14 J		24 M		34 O
					; 05 +	15 L		25 .		35 @
					; 06 [UKP]	16 ;		26 none	36 ^
					; 07 [DEL]	17 [CSR R]	27 [F1]	37 [F5]
					; 08 [<-]	18 [STOP]	28 none	38 2
					; 09 W	19 none	29 S		39 4
					; 0A R	1A X		2A F		3A 6
					; 0B Y	1B V		2B H		3B 8
					; 0C I	1C N		2C K		3C 0
					; 0D P	1D ,		2D :		3D -
					; 0E *	1E /		2E =		3E [HOME]
					; 0F [RET]	1F [CSR D]	2F [F3]	3F [F7]

LAB_C6	= $C6			; keyboard buffer length/index

; When the [CTRL][RVS-ON] characters are printed this flag is set to $12, and the print
; routines will add $80 to the screen code of each character which is printed, so that
; the caracter will appear on the screen with its colours reversed.

; Note that the contents of this location are cleared not only upon entry of a
; [CTRL][RVS-OFF] character but also at every carriage return.

LAB_C7	= $C7			; reverse flag $12 = reverse, $00 = normal

; This pointer indicates the column number of the last nonblank character on the logical
; line that is to be input. Since a logical line can be up to 88 characters long this
; number can range from 0-87.

LAB_C8	= $C8			; input [EOL] pointer

; These locations keep track of the logical line that the cursor is on and its column
; position on that logical line.

; Each logical line may contain up to four 22 column physical lines. So there may be as
; many as 23 logical lines, or as few as 6 at any one time. Therefore, the logical line
; number might be anywhere from 1-23. Depending on the length of the logical line, the
; cursor column may be from 1-22, 1-44, 1-66 or 1-88.

; For a more on logical lines, see the description of the screen line link table, $D9.

LAB_C9	= $C9			; input cursor row
LAB_CA	= $CA			; input cursor column

; The keyscan interrupt routine uses this location to indicate which key is currently
; being pressed. The value here is then used as an index into the appropriate keyboard
; table to determine which character to print when a key is struck.

; The correspondence between the key pressed and the number stored here is as follows:

; $00	1		$10	not used	$20	[SPACE]	$30	Q		$40	[NO KEY]
; $01	3		$11	A		$21	Z		$31	E		$xx	invalid
; $02	5		$12	D		$22	C		$32	T
; $03	7		$13	G		$23	B		$33	U
; $04	9		$14	J		$24	M		$34	O
; $05	+		$15	L		$25	.		$35	@
; $06	[POUND]	$16	;		$26	not used	$36	[U ARROW]
; $07	[DEL]		$17	[RIGHT]	$27	[F1]		$37	[F5]
; $08	[L ARROW]	$18	[STOP]	$28	not used	$38	2
; $09	W		$19	not used	$29	S		$39	4
; $0A	R		$1A	X		$2A	F		$3A	6
; $0B	Y		$1B	V		$2B	H		$3B	8
; $0C	I		$1C	N		$2C	K		$3C	0
; $0D	P		$1D	,		$2D	:		$3D	-
; $0E	*		$1E	/		$2E	=		$3E	[HOME]
; $0F	[RETURN]	$1F	[DOWN]	$2F	[F3]		$3F	[F7]

LAB_CB	= $CB			; which key

; When this flag is set to a nonzero value, it indicates to the routine that normally
; flashes the cursor not to do so. The cursor blink is turned off when there are
; characters in the keyboard buffer, or when the program is running.

LAB_CC	= $CC			; cursor enable, $00 = flash cursor

; The routine that blinks the cursor uses this location to tell when it's time for a
; blink. The number 20 is put here and decremented every jiffy until it reaches zero.
; Then the cursor state is changed, the number 20 is put back here, and the cycle starts
; all over again.

LAB_CD	= $CD			; cursor timing countdown

; The cursor is formed by printing the inverse of the character that occupies the cursor
; position. If that characters is the letter A, for example, the flashing cursor merely
; alternates between printing an A and a reverse-A. This location keeps track of the
; normal screen code of the character that is located at the cursor position, so that it
; may be restored when the cursor moves on.

LAB_CE	= $CE			; character under cursor

; This location keeps track of whether, during the current cursor blink, the character
; under the cursor was reversed, or was restored to normal. This location will contain
; $00 if the character is reversed, and $01 if the character is not reversed.

LAB_CF	= $CF			; cursor blink phase

LAB_D0	= $D0			; input from keyboard or screen, $xx = input is available
					; from the screen, $00 = input should be obtained from the
					; keyboard

; These locations point to the address in screen RAM of the first column of the logical
; line upon which the cursor is currently positioned.

LAB_D1	= $D1			; current screen line pointer low byte
LAB_D2	= $D2			; current screen line pointer high byte

; This holds the cursor column position within the logical line pointed to by LAB_D1.
; Since a logical line can comprise up to four physical lines, this value may be from
; $00 to $57.

LAB_D3	= $D3			; cursor column

; A nonzero value in this location indicates that the editor is in quote mode. Quote
; mode is toggled every time that you type in a quotation mark on a given line, the
; first quote mark turns it on, the second turns it off, the third turns it on, etc.

; If the editor is in this mode when a cursor control character or other nonprinting
; character is entered, a printed equivalent will appear on the screen instead of the
; cursor movement or other control operation taking place. Instead, that action is
; deferred until the string is sent to the string by a PRINT statement, at which time
; the cursor movement or other control operation will take place.

; The exception to this rule is the DELETE key, which will function normally within
; quote mode. The only way to print a character which is equivalent to the DELETE key
; is by entering insert mode. Quote mode may be exited by printing a closing quote or
; by hitting the RETURN or SHIFT-RETURN keys.

LAB_D4	= $D4			; cursor quote flag

; The line editor uses this location when the end of a line has been reached to determine
; whether another physical line can be added to the current logical line or if a new
; logical line must be started.

LAB_D5	= $D5			; current screen line length

; This location contains the current physical screen line position of the cursor, 0 to 22.

LAB_D6	= $D6			; cursor row

; The ASCII value of the last character printed to the screen is held here temporarily.

LAB_D7	= $D7			; checksum byte/temporary last character

; When the INST key is pressed, the screen editor shifts the line to the right, allocates
; another physical line to the logical line if necessary (and possible), updates the
; screen line length in $D5, and adjusts the screen line link table at $D9. This location
; is used to keep track of the number of spaces that has been opened up in this way.

; Until the spaces that have been opened up are filled, the editor acts as if in quote
; mode. See location $D4, the quote mode flag. This means that cursor control characters
; that are normally nonprinting will leave a printed equivalent on the screen when
; entered, instead of having their normal effect on cursor movement, etc. The only
; difference between insert and quote mode is that the DELETE key will leave a printed
; equivalent in insert mode, while the INSERT key will insert spaces as normal.

LAB_D8	= $D8			; insert count

; This table contains 25 entries, one for each row of the screen display. Each entry has
; two functions. Bits 0-3 indicate on which of the four pages of screen memory the first
; byte of memory for that row is located. This is used in calculating the pointer to the
; starting address of a screen line at LAB_D1.
;
; The high byte is calculated by adding the value of the starting page of screen memory
; held in $288 to the displacement page held here.
;
; The other function of this table is to establish the makeup of logical lines on the
; screen. While each screen line is only 40 characters long, BASIC allows the entry of
; program lines that contain up to 80 characters. Therefore, some method must be used
; to determine which physical lines are linked into a longer logical line, so that this
; longer logical line may be edited as a unit.
;
; The high bit of each byte here is used as a flag by the screen editor. That bit is set
; when a line is the first or only physical line in a logical line. The high bit is reset
; to 0 only when a line is an extension to this logical line.

LAB_D9	= $D9			; to LAB_D9 + $18 inclusive, screen line link table

LAB_F3	= $F3			; colour RAM pointer low byte
LAB_F4	= $F4			; colour RAM pointer high byte

; This pointer points to the address of the keyboard matrix lookup table currently being
; used. Although there are only 64 keys on the keyboard matrix, each key can be used to
; print up to four different characters, depending on whether it is struck by itself or
; in combination with the SHIFT, CTRL, or C= keys.

; These tables hold the ASCII value of each of the 64 keys for one of these possible
; combinations of keypresses. When it comes time to print the character, the table that
; is used determines which character is printed.

; The addresses of the tables are:

;	LAB_EB81			; unshifted
;	LAB_EBC2			; shifted
;	LAB_EC03			; commodore
;	LAB_EC78			; control

LAB_F5	= $F5			; keyboard pointer low byte
LAB_F6	= $F6			; keyboard pointer high byte

; When device the RS232 channel is opened two buffers of 256 bytes each are created at
; the top of memory. These locations point to the address of the one which is used to
; store characters as they are received.

LAB_F7	= $F7			; RS232 Rx pointer low byte
LAB_F8	= $F8			; RS232 Rx pointer high byte

; These locations point to the address of the 256 byte output buffer that is used for
; transmitting data to RS232 devices.

LAB_F9	= $F9			; RS232 Tx pointer low byte
LAB_FA	= $FA			; RS232 Tx pointer high byte

LAB_FF	= $FF			; string conversion address

LAB_0100	= $0100		;.
LAB_0101	= $0101		;.
LAB_0102	= $0102		;.
LAB_0103	= $0103		;.
LAB_0104	= $0104		;.
LAB_0109	= $0109		;.
LAB_010F	= $010F		;.
LAB_0110	= $0110		;.
LAB_0111	= $0111		;.
LAB_0112	= $0112		;.
LAB_01FC	= $01FC		; start of crunched line
LAB_01FD	= $01FD		;.
LAB_01FE	= $01FE		;.
LAB_01FF	= $01FF		; input buffer - 1

LAB_0200	= $0200		; input buffer. for some routines the byte before the input
					; buffer needs to be set to a specific value for the routine
					; to work correctly
LAB_0201	= $0201		; address for GET byte

LAB_0259	= $0259		; .. to LAB_0262 logical file table
LAB_0263	= $0263		; .. to LAB_026C device number table
LAB_026D	= $026D		; .. to LAB_0276 secondary address table
LAB_0277	= $0277		; .. to LAB_0280 keyboard buffer

LAB_0281	= $0281		; OS start of memory low byte
LAB_0282	= $0282		; OS start of memory high byte

LAB_0283	= $0283		; OS top of memory low byte
LAB_0284	= $0284		; OS top of memory high byte

LAB_0285	= $0285		; serial bus timeout flag

LAB_0286	= $0286		; current colour code
					; $00	black
					; $01	white
					; $02	red
					; $03	cyan
					; $04	magents
					; $05	green
					; $06	blue
					; $07	yellow
					; $08	orange
					; $09	brown
					; $0A	light red
					; $0B	dark grey
					; $0C	medium grey
					; $0D	light green
					; $0E	light blue
					; $0F	light grey
LAB_0287	= $0287		; colour under cursor
LAB_0288	= $0288		; screen memory page
LAB_0289	= $0289		; maximum keyboard buffer size
LAB_028A	= $028A		; key repeat. $80 = repeat all, $40 = repeat none,
					; $00 = repeat cursor movement keys, insert/delete
					; key and the space bar
LAB_028B	= $028B		; repeat speed counter
LAB_028C	= $028C		; repeat delay counter

; This flag signals which of the SHIFT, CTRL, or C= keys are currently being pressed.

; A value of $01 signifies that one of the SHIFT keys is being pressed, a $02 shows that
; the C= key is down, and $04 means that the CTRL key is being pressed. If more than one
; key is held down, these values will be added e.g $03 indicates that SHIFT and C= are
; both held down.

; Pressing the SHIFT and C= keys at the same time will toggle the character set that is
; presently being used between the uppercase/graphics set, and the lowercase/uppercase
; set.

; While this changes the appearance of all of the characters on the screen at once it
; has nothing whatever to do with the keyboard shift tables and should not be confused
; with the printing of SHIFTed characters, which affects only one character at a time.

LAB_028D	= $028D		; keyboard shift/control flag
					; bit	key(s) 1 = down
					; ---	---------------
					; 7-3	unused
					;  2	CTRL
					;  1	C=
					;  0	SHIFT

; This location, in combination with the one above, is used to debounce the special
; SHIFT keys. This will keep the SHIFT/C= combination from changing character sets
; back and forth during a single pressing of both keys.

LAB_028E	= $028E		; SHIFT/CTRL/C= keypress last pattern

; This location points to the address of the Operating System routine which actually
; determines which keyboard matrix lookup table will be used.

; The routine looks at the value of the SHIFT flag at $28D, and based on what value
; it finds there, stores the address of the correct table to use at location $F5.

LAB_028F	= $028F		; keyboard decode logic pointer low byte
LAB_0290	= $0290		; keyboard decode logic pointer high byte

; This flag is used to enable or disable the feature which lets you switch between the
; uppercase/graphics and upper/lowercase character sets by pressing the SHIFT and
; Commodore logo keys simultaneously.

LAB_0291	= $0291		; shift mode switch, $00 = enabled, $80 = locked

; This location is used to determine whether moving the cursor past the ??xx  column of
; a logical line will cause another physical line to be added to the logical line.

; A value of 0 enables the screen to scroll the following lines down in order to add
; that line; any nonzero value will disable the scroll.

; This flag is set to disable the scroll temporarily when there are characters waiting
; in the keyboard buffer, these may include cursor movement characters that would
; eliminate the need for a scroll.

LAB_0292	= $0292		; screen scrolling flag, $00 = enabled

LAB_0293	= $0293		; pseudo 6551 control register. the first character of
					; the OPEN RS232 filename will be stored here
					; bit	function
					; ---	--------
					;  7	2 stop bits/1 stop bit
					; 65	word length
					; ---	-----------
					; 00	8 bits
					; 01	7 bits
					; 10	6 bits
					; 11	5 bits
					;  4	unused
					; 3210	baud rate
					; ----	---------
					; 0000	user rate *
					; 0001	   50
					; 0010	   75
					; 0011	  110
					; 0100	  134.5
					; 0101	  150
					; 0110	  300
					; 0111	  600
					; 1000	 1200
					; 1001	 1800
					; 1010	 2400
					; 1011	 3600
					; 1100	 4800 *
					; 1101	 7200 *
					; 1110	 9600 *
					; 1111	19200 *	* = not implemented
LAB_0294	= $0294		; pseudo 6551 command register. the second character of
					; the OPEN RS232 filename will be stored here
					; bit	function
					; ---	--------
					; 7-5	parity
					;	xx0 = disabled
					;	001 = odd
					;	011 = even
					;	101 = mark
					;	111 = space
					;  4	duplex half/full
					;  3	unused
					;  2	unused
					;  1	unused
					;  0	handshake - X line/3 line
LAB_0295	= $0295		; nonstandard bit timing low byte. the third character
					; of the OPEN RS232 filename will be stored here
LAB_0296	= $0296		; nonstandard bit timing high byte. the fourth character
					; of the OPEN RS232 filename will be stored here
LAB_0297	= $0297		; RS-232 status register
					; bit	function
					; ---	--------
					;  7	break
					;  6	no DSR detected
					;  5	unused
					;  4	no CTS detected
					;  3	unused
					;  2	Rx buffer overrun
					;  1	framing error
					;  0	parity error
LAB_0298	= $0298		; number of bits to be sent/received

LAB_0299	= $0299		; bit time low byte
LAB_029A	= $029A		; bit time high byte


; Time Required to Send a Bit
;
; This location holds the prescaler value used by CIA #2 timers A and B.
; These timers cause an NMI interrupt to drive the RS-232 receive and transmit
; routines CLOCK/PRESCALER times per second each, where CLOCK is the system 02
; frequency of 1,022,730 Hz (985,250 if you are using the European PAL
; television standard rather than the American NTSC standard), and PRESCALER is
; the value stored at 56580-1 ($DD04-5) and 56582-3 ($DD06-7), in low-byte,
; high-byte order.  You can use the following formula to figure the correct
; prescaler value for a particular RS-232 baud rate:
;
; PRESCALER=((CLOCK/BAUDRATE)/2)-100
;
; The American (NTSC standard) prescaler values for the standard RS-232 baud
; rates which the control register at 659 ($293) makes available are stored in
; a table at 65218 ($FEC2), starting with the two-byte value used for 50 baud.
; The European (PAL standard) version of that table is located at 58604 ($E4EC).
;
; Location Range: 667-670 ($29B-$29E)
; Byte Indices to the Beginning and End of Receive and Transmit Buffers
;
; The two 256-byte First In, First Out (FIFO) buffers for RS-232 data reception
; and transmission are dynamic wraparound buffers.  This means that the starting
; point and the ending point of the buffer can change over time, and either
; point can be anywhere withing the buffer.  If, for example, the starting point
; is at byte 100, the buffer will fill towards byte 255, at which point it will
; wrap around to byte 0 again.  To maintain this system, the following four
; locations are used as indices to the starting and the ending point of each
; buffer.


LAB_029B	= $029B		; index to Rx buffer end
LAB_029C	= $029C		; index to Rx buffer start
LAB_029D	= $029D		; index to Tx buffer start
LAB_029E	= $029E		; index to Tx buffer end
LAB_029F	= $029F		; saved IRQ low byte
LAB_02A0	= $02A0		; saved IRQ high byte

; This location holds the active NMI interrupt flag byte from VIA 2 ICR, LAB_DD0D

LAB_02A1	= $02A1		; RS-232 interrupt enable byte
					; bit	function
					; ---	--------
					;  7	unused
					;  6	unused
					;  5	unused
					;  4	1 = waiting for Rx edge
					;  3	unused
					;  2	unused
					;  1	1 = Rx data timer
					;  0	1 = Tx data timer

LAB_02A2	= $02A2		; VIA 1 CRB shadow copy
LAB_02A3	= $02A3		; VIA 1 ICR shadow copy
LAB_02A4	= $02A4		; VIA 1 CRA shadow copy

LAB_02A5	= $02A5		; temp Index to the next line for scrolling
LAB_02A6	= $02A6		; PAL/NTSC flag
					; $00 = NTSC
					; $01 = PAL

; $02A7 to $02FF - unused

LAB_0300	= $0300		; vector to the print BASIC error message routine
LAB_0302	= $0302		; Vector to the main BASIC program Loop
LAB_0304	= $0304		; Vector to the the ASCII text to keywords routine
LAB_0306	= $0306		; Vector to the list BASIC program as ASCII routine
LAB_0308	= $0308		; Vector to the execute next BASIC command routine
LAB_030A	= $030A		; Vector to the get value from BASIC line routine

; Before every SYS command each of the registers is loaded with the value found in the
; corresponding storage address. Upon returning to BASIC with an RTS instruction, the
; new value of each register is stored in the appropriate storage address.

; This feature allows you to place the necessary values into the registers from BASIC
; before you SYS to a Kernal or BASIC ML routine. It also enables you to examine the
; resulting effect of the routine on the registers, and to preserve the condition of
; the registers on exit for subsequent SYS calls.

LAB_030C	= $030C		; A for SYS command
LAB_030D	= $030D		; X for SYS command
LAB_030E	= $030E		; Y for SYS command
LAB_030F	= $030F		; P for SYS command

LAB_0310	= $0310		; JMP instruction for user function
LAB_0311	= $0311		; user function vector low byte
LAB_0312	= $0312		; user function vector high byte

LAB_0314	= $0314		; IRQ vector low byte
LAB_0315	= $0315		; IRQ vector high byte
LAB_0316	= $0316		; BRK vector
LAB_0318	= $0318		; NMI vector

LAB_031A	= $031A		; kernal vector - open a logical file
LAB_031C	= $031C		; kernal vector - close a specified logical file
LAB_031E	= $031E		; kernal vector - open channel for input
LAB_0320	= $0320		; kernal vector - open channel for output
LAB_0322	= $0322		; kernal vector - close input and output channels
LAB_0324	= $0324		; kernal vector - input character from channel
LAB_0326	= $0326		; kernal vector - output character to channel
LAB_0328	= $0328		; kernal vector - scan stop key
LAB_032A	= $032A		; kernal vector - get character from keyboard queue
LAB_032C	= $032C		; kernal vector - close all channels and files

LAB_0330	= $0330		; kernal vector - load
LAB_0332	= $0332		; kernal vector - save

LAB_033C	= $033C		; cassette buffer

LAB_8000	= $8000		; autostart ROM initial entry vector
LAB_8002	= $8002		; autostart ROM break entry
LAB_8004	= $8004		; autostart ROM identifier string start

LAB_D000	= $D000		; vic ii chip base address
LAB_D011	= $D011		; vertical fine scroll and control
LAB_D012	= $D012		; raster compare register
LAB_D016	= $D016		; horizontal fine scroll and control
LAB_D018	= $D018		; memory control
LAB_D019	= $D019		; vic interrupt flag register
LAB_D418	= $D418		; volume and filter select

LAB_D800	= $D800		; 1K colour RAM base address

; VIA 1

LAB_DC00	= $DC00		; VIA 1 DRA, keyboard column drive
LAB_DC01	= $DC01		; VIA 1 DRB, keyboard row port
					;   keyboard matrix layout
					; keyboard matrix layout
					;	c7	c6	c5	c4	c3	c2	c1	c0
					;   +------------------------------------------------
					; r7|	[RUN]	/	,	N	V	X	[LSH]	[DN]
					; r6|	Q	[UP]	@	O	U	T	E	[F5]
					; r5|	[CBM]	=	:	K	H	F	S	[F3]
					; r4|	[SP]	[RSH]	.	M	B	C	Z	[F1]
					; r3|	2	[Home]-	0	8	6	4	[F7]
					; r2|	[CTL]	;	L	J	G	D	A	[RGT]
					; r1|	[LFT]	*	P	I	Y	R	W	[RET]
					; r0|	1	£	+	9	7	5	3	[DEL]
LAB_DC02	= $DC02		; VIA 1 DDRA, keyboard column
LAB_DC03	= $DC03		; VIA 1 DDRB, keyboard row
LAB_DC04	= $DC04		; VIA 1 timer A low byte
LAB_DC05	= $DC05		; VIA 1 timer A high byte
LAB_DC06	= $DC06		; VIA 1 timer B low byte
LAB_DC07	= $DC07		; VIA 1 timer B high byte
LAB_DC0D	= $DC0D		; VIA 1 ICR
					; bit	function
					; ---	--------
					;  7	interrupt
					;  6	unused
					;  5	unused
					;  4	FLAG
					;  3	shift register
					;  2	TOD alarm
					;  1	timer B
					;  0	timer A
LAB_DC0E	= $DC0E		; VIA 1 CRA
					; bit	function
					; ---	--------
					;  7	TOD clock, 1 = 50Hz, 0 = 60Hz
					;  6	serial port direction, 1 = out, 0 = in
					;  5	timer A input, 1 = phase2, 0 = CNT in
					;  4	1 = force load timer A
					;  3	timer A mode, 1 = single shot, 0 = continuous
					;  2	PB6 mode, 1 = toggle, 0 = single shot
					;  1	1 = timer A to PB6
					;  0	1 = start timer A
LAB_DC0F	= $DC0F		; VIA 1 CRB
					; bit	function
					; ---	--------
					;  7	TOD register select, 1 = clock, 0 = alarm
					; 6-5	timer B mode
      				;     11 = timer A with CNT enable
      				;     10 = timer A
      				;     01 = CNT in
      				;     00 = phase 2
					;  4	1 = force load timer B
					;  3	timer B mode, 1 = single shot, 0 = continuous
					;  2	PB7 mode, 1 = toggle, 0 = single shot
					;  1	1 = timer B to PB7
					;  0	1 = start timer B

; VIA 2

LAB_DD00	= $DD00		; VIA 2 DRA, serial port and video address
					; bit	function
					; ---	--------
					;  7	serial DATA in
					;  6	serial CLK in
					;  5	serial DATA out
					;  4	serial CLK out
					;  3	serial ATN out
					;  2	RS232 Tx DATA
					;  1	video address 15
					;  0	video address 14
LAB_DD01	= $DD01		; VIA 2 DRB, RS232 port
					; bit	function
					; ---	--------
					;  7	RS232 DSR
					;  6	RS232 CTS
					;  5	unused
					;  4	RS232 DCD
					;  3	RS232 RI
					;  2	RS232 DTR
					;  1	RS232 RTS
					;  0	RS232 Rx DATA
LAB_DD02	= $DD02		; VIA 2 DDRA, serial port and video address
LAB_DD03	= $DD03		; VIA 2 DDRB, RS232 port
LAB_DD04	= $DD04		; VIA 2 timer A low byte
LAB_DD05	= $DD05		; VIA 2 timer A high byte
LAB_DD06	= $DD06		; VIA 2 timer B low byte
LAB_DD07	= $DD07		; VIA 2 timer B high byte
LAB_DD0D	= $DD0D		; VIA 2 ICR
					; bit	function
					; ---	--------
					;  7	interrupt
					;  6	unused
					;  5	unused
					;  4	FLAG
					;  3	shift register
					;  2	TOD alarm
					;  1	timer B
					;  0	timer A
LAB_DD0E	= $DD0E		; VIA 2 CRA
					; bit	function
					; ---	--------
					;  7	TOD clock, 1 = 50Hz, 0 = 60Hz
					;  6	serial port direction, 1 = out, 0 = in
					;  5	timer A input, 1 = phase2, 0 = CNT in
					;  4	1 = force load timer A
					;  3	timer A mode, 1 = single shot, 0 = continuous
					;  2	PB6 mode, 1 = toggle, 0 = single shot
					;  1	1 = timer A to PB6
					;  0	1 = start timer A
LAB_DD0F	= $DD0F		; VIA 2 CRB
					; bit	function
					; ---	--------
					;  7	TOD register select, 1 = clock, 0 = alarm
					; 6-5	timer B mode
      				;     11 = timer A with CNT enable
      				;     10 = timer A
      				;     01 = CNT in
      				;     00 = phase 2
					;  4	1 = force load timer B
					;  3	timer B mode, 1 = single shot, 0 = continuous
					;  2	PB7 mode, 1 = toggle, 0 = single shot
					;  1	1 = timer B to PB7
					;  0	1 = start timer B


;************************************************************************************
;
; BASIC keyword token values. tokens not used in the source are included for
; completeness but commented out

; command tokens

;TK_END	= $80			; END token
TK_FOR	= $81			; FOR token
;TK_NEXT	= $82			; NEXT token
TK_DATA	= $83			; DATA token
;TK_INFL	= $84			; INPUT# token
;TK_INPUT	= $85			; INPUT token
;TK_DIM	= $86			; DIM token
;TK_READ	= $87			; READ token

;TK_LET	= $88			; LET token
TK_GOTO	= $89			; GOTO token
;TK_RUN	= $8A			; RUN token
;TK_IF	= $8B			; IF token
;TK_RESTORE	= $8C			; RESTORE token
TK_GOSUB	= $8D			; GOSUB token
;TK_RETURN	= $8E			; RETURN token
TK_REM	= $8F			; REM token

;TK_STOP	= $90			; STOP token
;TK_ON	= $91			; ON token
;TK_WAIT	= $92			; WAIT token
;TK_LOAD	= $93			; LOAD token
;TK_SAVE	= $94			; SAVE token
;TK_VERIFY	= $95			; VERIFY token
;TK_DEF	= $96			; DEF token
;TK_POKE	= $97			; POKE token

;TK_PRINFL	= $98			; PRINT# token
TK_PRINT	= $99			; PRINT token
;TK_CONT	= $9A			; CONT token
;TK_LIST	= $9B			; LIST token
;TK_CLR	= $9C			; CLR token
;TK_CMD	= $9D			; CMD token
;TK_SYS	= $9E			; SYS token
;TK_OPEN	= $9F			; OPEN token

;TK_CLOSE	= $A0			; CLOSE token
;TK_GET	= $A1			; GET token
;TK_NEW	= $A2			; NEW token

; secondary keyword tokens

TK_TAB	= $A3			; TAB( token
TK_TO		= $A4			; TO token
TK_FN		= $A5			; FN token
TK_SPC	= $A6			; SPC( token
TK_THEN	= $A7			; THEN token

TK_NOT	= $A8			; NOT token
TK_STEP	= $A9			; STEP token

; operator tokens

TK_PLUS	= $AA			; + token
TK_MINUS	= $AB			; - token
;TK_MUL	= $AC			; * token
;TK_DIV	= $AD			; / token
;TK_POWER	= $AE			; ^ token
;TK_AND	= $AF			; AND token

;TK_OR	= $B0			; OR token
TK_GT		= $B1			; > token
TK_EQUAL	= $B2			; = token
;TK_LT	= $B3			; < token

; function tokens

TK_SGN	= $B4			; SGN token
;TK_INT	= $B5			; INT token
;TK_ABS	= $B6			; ABS token
;TK_USR	= $B7			; USR token

;TK_FRE	= $B8			; FRE token
;TK_POS	= $B9			; POS token
;TK_SQR	= $BA			; SQR token
;TK_RND	= $BB			; RND token
;TK_LOG	= $BC			; LOG token
;TK_EXP	= $BD			; EXP token
;TK_COS	= $BE			; COS token
;TK_SIN	= $BF			; SIN token

;TK_TAN	= $C0			; TAN token
;TK_ATN	= $C1			; ATN token
;TK_PEEK	= $C2			; PEEK token
;TK_LEN	= $C3			; LEN token
;TK_STRS	= $C4			; STR$ token
;TK_VAL	= $C5			; VAL token
;TK_ASC	= $C6			; ASC token
;TK_CHRS	= $C7			; CHR$ token

;TK_LEFTS	= $C8			; LEFT$ token
;TK_RIGHTS	= $C9			; RIGHT$ token
;TK_MIDS	= $CA			; MID$ token
TK_GO		= $CB			; GO token

TK_PI		= $FF			; PI token


;************************************************************************************
;
; start of the BASIC ROM

	.ORG	$A000

LAB_A000
	.word	LAB_E394		; BASIC cold start entry point
LAB_A002
	.word	LAB_E37B		; BASIC warm start entry point

;LAB_A004
	.byte	"CBMBASIC"		; ROM name, unreferenced


;************************************************************************************
;
; action addresses for primary commands. these are called by pushing the address
; onto the stack and doing an RTS so the actual address -1 needs to be pushed

LAB_A00C
	.word	LAB_A831-1		; perform END		$80
	.word	LAB_A742-1		; perform FOR		$81
	.word	LAB_AD1E-1		; perform NEXT		$82
	.word	LAB_A8F8-1		; perform DATA		$83
	.word	LAB_ABA5-1		; perform INPUT#		$84
	.word	LAB_ABBF-1		; perform INPUT		$85
	.word	LAB_B081-1		; perform DIM		$86
	.word	LAB_AC06-1		; perform READ		$87

	.word	LAB_A9A5-1		; perform LET		$88
	.word	LAB_A8A0-1		; perform GOTO		$89
	.word	LAB_A871-1		; perform RUN		$8A
	.word	LAB_A928-1		; perform IF		$8B
	.word	LAB_A81D-1		; perform RESTORE		$8C
	.word	LAB_A883-1		; perform GOSUB		$8D
	.word	LAB_A8D2-1		; perform RETURN		$8E
	.word	LAB_A93B-1		; perform REM		$8F

	.word	LAB_A82F-1		; perform STOP		$90
	.word	LAB_A94B-1		; perform ON		$91
	.word	LAB_B82D-1		; perform WAIT		$92
	.word	LAB_E168-1		; perform LOAD		$93
	.word	LAB_E156-1		; perform SAVE		$94
	.word	LAB_E165-1		; perform VERIFY		$95
	.word	LAB_B3B3-1		; perform DEF		$96
	.word	LAB_B824-1		; perform POKE		$97

	.word	LAB_AA80-1		; perform PRINT#		$98
	.word	LAB_AAA0-1		; perform PRINT		$99
	.word	LAB_A857-1		; perform CONT		$9A
	.word	LAB_A69C-1		; perform LIST		$9B
	.word	LAB_A65E-1		; perform CLR		$9C
	.word	LAB_AA86-1		; perform CMD		$9D
	.word	LAB_E12A-1		; perform SYS		$9E
	.word	LAB_E1BE-1		; perform OPEN		$9F

	.word	LAB_E1C7-1		; perform CLOSE		$A0
	.word	LAB_AB7B-1		; perform GET		$A1
	.word	LAB_A642-1		; perform NEW		$A2


;************************************************************************************
;
; action addresses for functions

LAB_A052
	.word	LAB_BC39		; perform SGN()		$B4
	.word	LAB_BCCC		; perform INT()		$B5
	.word	LAB_BC58		; perform ABS()		$B6
	.word	LAB_0310		; perform USR()		$B7

	.word	LAB_B37D		; perform FRE()		$B8
	.word	LAB_B39E		; perform POS()		$B9
	.word	LAB_BF71		; perform SQR()		$BA
	.word	LAB_E097		; perform RND()		$BB
	.word	LAB_B9EA		; perform LOG()		$BC
	.word	LAB_BFED		; perform EXP()		$BD
	.word	LAB_E264		; perform COS()		$BE
	.word	LAB_E26B		; perform SIN()		$BF

	.word	LAB_E2B4		; perform TAN()		$C0
	.word	LAB_E30E		; perform ATN()		$C1
	.word	LAB_B80D		; perform PEEK()		$C2
	.word	LAB_B77C		; perform LEN()		$C3
	.word	LAB_B465		; perform STR$()		$C4
	.word	LAB_B7AD		; perform VAL()		$C5
	.word	LAB_B78B		; perform ASC()		$C6
	.word	LAB_B6EC		; perform CHR$()		$C7

	.word	LAB_B700		; perform LEFT$()		$C8
	.word	LAB_B72C		; perform RIGHT$()	$C9
	.word	LAB_B737		; perform MID$()		$CA


;************************************************************************************
;
; precedence byte and action addresses for operators. like the primarry commands
; these are called by pushing the address onto the stack and doing an RTS, so again
; the actual address -1 needs to be pushed

LAB_A080
	.byte	$79
	.word	LAB_B86A-1		; +
	.byte	$79
	.word	LAB_B853-1		; -
	.byte	$7B
	.word	LAB_BA2B-1		; *
	.byte	$7B
	.word	LAB_BB12-1		; /
	.byte	$7F
	.word	LAB_BF7B-1		; ^
	.byte	$50
	.word	LAB_AFE9-1		; AND
	.byte	$46
	.word	LAB_AFE6-1		; OR
	.byte	$7D
	.word	LAB_BFB4-1		; >
	.byte	$5A
	.word	LAB_AED4-1		; =
LAB_A09B
	.byte	$64
	.word	LAB_B016-1		; <


;************************************************************************************
;
; BASIC keywords. each word has b7 set in it's last character as an end marker, even
; the one character keywords such as "<" or "="

; first are the primary command keywords, only these can start a statement

LAB_A09E
	.byte	"EN",'D'+$80	; END		$80		128
	.byte	"FO",'R'+$80	; FOR		$81		129
	.byte	"NEX",'T'+$80	; NEXT	$82		130
	.byte	"DAT",'A'+$80	; DATA	$83		131
	.byte	"INPUT",'#'+$80	; INPUT#	$84		132
	.byte	"INPU",'T'+$80	; INPUT	$85		133
	.byte	"DI",'M'+$80	; DIM		$86		134
	.byte	"REA",'D'+$80	; READ	$87		135

	.byte	"LE",'T'+$80	; LET		$88		136
	.byte	"GOT",'O'+$80	; GOTO	$89		137
	.byte	"RU",'N'+$80	; RUN		$8A		138
	.byte	"I",'F'+$80		; IF		$8B		139
	.byte	"RESTOR",'E'+$80	; RESTORE	$8C		140
	.byte	"GOSU",'B'+$80	; GOSUB	$8D		141
	.byte	"RETUR",'N'+$80	; RETURN	$8E		142
	.byte	"RE",'M'+$80	; REM		$8F		143

	.byte	"STO",'P'+$80	; STOP	$90		144
	.byte	"O",'N'+$80		; ON		$91		145
	.byte	"WAI",'T'+$80	; WAIT	$92		146
	.byte	"LOA",'D'+$80	; LOAD	$93		147
	.byte	"SAV",'E'+$80	; SAVE	$94		148
	.byte	"VERIF",'Y'+$80	; VERIFY	$95		149
	.byte	"DE",'F'+$80	; DEF		$96		150
	.byte	"POK",'E'+$80	; POKE	$97		151

	.byte	"PRINT",'#'+$80	; PRINT#	$98		152
	.byte	"PRIN",'T'+$80	; PRINT	$99		153
	.byte	"CON",'T'+$80	; CONT	$9A		154
	.byte	"LIS",'T'+$80	; LIST	$9B		155
	.byte	"CL",'R'+$80	; CLR		$9C		156
	.byte	"CM",'D'+$80	; CMD		$9D		157
	.byte	"SY",'S'+$80	; SYS		$9E		158
	.byte	"OPE",'N'+$80	; OPEN	$9F		159

	.byte	"CLOS",'E'+$80	; CLOSE	$A0		160
	.byte	"GE",'T'+$80	; GET		$A1		161
	.byte	"NE",'W'+$80	; NEW		$A2		162

; next are the secondary command keywords, these can not start a statement

;LAB_A129
	.byte	"TAB",'('+$80	; TAB(	$A3		163
	.byte	"T",'O'+$80		; TO		$A4		164
	.byte	"F",'N'+$80		; FN		$A5		165
	.byte	"SPC",'('+$80	; SPC(	$A6		166
	.byte	"THE",'N'+$80	; THEN	$A7		167

	.byte	"NO",'T'+$80	; NOT		$A8		168
	.byte	"STE",'P'+$80	; STEP	$A9		169

; next are the operators

	.byte	'+'+$80		; +		$AA		170
	.byte	'-'+$80		; -		$AB		171
	.byte	'*'+$80		; *		$AC		172
	.byte	'/'+$80		; /		$AD		173
	.byte	'^'+$80		; ^		$AE		174
	.byte	"AN",'D'+$80	; AND		$AF		175

	.byte	"O",'R'+$80		; OR		$B0		176
	.byte	'>'+$80		; >		$B1		177
	.byte	'='+$80		; =		$B2		178
	.byte	'<'+$80		; <		$B3		179

; and finally the functions

	.byte	"SG",'N'+$80	; SGN		$B4		180
	.byte	"IN",'T'+$80	; INT		$B5		181
	.byte	"AB",'S'+$80	; ABS		$B6		182
	.byte	"US",'R'+$80	; USR		$B7		183

	.byte	"FR",'E'+$80	; FRE		$B8		184
	.byte	"PO",'S'+$80	; POS		$B9		185
	.byte	"SQ",'R'+$80	; SQR		$BA		186
	.byte	"RN",'D'+$80	; RND		$BB		187
	.byte	"LO",'G'+$80	; LOG		$BC		188
	.byte	"EX",'P'+$80	; EXP		$BD		189
	.byte	"CO",'S'+$80	; COS		$BE		190
	.byte	"SI",'N'+$80	; SIN		$BF		191

	.byte	"TA",'N'+$80	; TAN		$C0		192
	.byte	"AT",'N'+$80	; ATN		$C1		193
	.byte	"PEE",'K'+$80	; PEEK	$C2		194
	.byte	"LE",'N'+$80	; LEN		$C3		195
	.byte	"STR",'$'+$80	; STR$	$C4		196
	.byte	"VA",'L'+$80	; VAL		$C5		197
	.byte	"AS",'C'+$80	; ASC		$C6		198
	.byte	"CHR",'$'+$80	; CHR$	$C7		199

	.byte	"LEFT",'$'+$80	; LEFT$	$C8		200
	.byte	"RIGHT",'$'+$80	; RIGHT$	$C9		201
	.byte	"MID",'$'+$80	; MID$	$CA		202

; lastly is GO, this is an add on so that GO TO, as well as GOTO, will work

	.byte	"G",'O'+$80		; GO		$CB		203

	.byte	$00			; end marker


;************************************************************************************
;
; BASIC error messages

LAB_A19E
	.byte	"TOO MANY FILE",'S'+$80
LAB_A1AC
	.byte	"FILE OPE",'N'+$80
LAB_A1B5
	.byte	"FILE NOT OPE",'N'+$80
LAB_A1C2
	.byte	"FILE NOT FOUN",'D'+$80
LAB_A1D0
	.byte	"DEVICE NOT PRESEN",'T'+$80
LAB_A1E2
	.byte	"NOT INPUT FIL",'E'+$80
LAB_A1F0
	.byte	"NOT OUTPUT FIL",'E'+$80
LAB_A1FF
	.byte	"MISSING FILE NAM",'E'+$80
LAB_A210
	.byte	"ILLEGAL DEVICE NUMBE",'R'+$80
LAB_A225
	.byte	"NEXT WITHOUT FO",'R'+$80
LAB_A235
	.byte	"SYNTA",'X'+$80
LAB_A23B
	.byte	"RETURN WITHOUT GOSU",'B'+$80
LAB_A24F
	.byte	"OUT OF DAT",'A'+$80
LAB_A25A
	.byte	"ILLEGAL QUANTIT",'Y'+$80
LAB_A26A
	.byte	"OVERFLO",'W'+$80
LAB_A272
	.byte	"OUT OF MEMOR",'Y'+$80
LAB_A27F
	.byte	"UNDEF'D STATEMEN",'T'+$80
LAB_A290
	.byte	"BAD SUBSCRIP",'T'+$80
LAB_A29D
	.byte	"REDIM'D ARRA",'Y'+$80
LAB_A2AA
	.byte	"DIVISION BY ZER",'O'+$80
LAB_A2BA
	.byte	"ILLEGAL DIREC",'T'+$80
LAB_A2C8
	.byte	"TYPE MISMATC",'H'+$80
LAB_A2D5
	.byte	"STRING TOO LON",'G'+$80
LAB_A2E4
	.byte	"FILE DAT",'A'+$80
LAB_A2ED
	.byte	"FORMULA TOO COMPLE",'X'+$80
LAB_A300
	.byte	"CAN'T CONTINU",'E'+$80
LAB_A30E
	.byte	"UNDEF'D FUNCTIO",'N'+$80
LAB_A31E
	.byte	"VERIF",'Y'+$80
LAB_A324
	.byte	"LOA",'D'+$80

; error message pointer table

LAB_A328
	.word	LAB_A19E		; $01	TOO MANY FILES
	.word	LAB_A1AC		; $02	FILE OPEN
	.word	LAB_A1B5		; $03	FILE NOT OPEN
	.word	LAB_A1C2		; $04	FILE NOT FOUND
	.word	LAB_A1D0		; $05	DEVICE NOT PRESENT
	.word	LAB_A1E2		; $06	NOT INPUT FILE
	.word	LAB_A1F0		; $07	NOT OUTPUT FILE
	.word	LAB_A1FF		; $08	MISSING FILE NAME
	.word	LAB_A210		; $09	ILLEGAL DEVICE NUMBER
	.word	LAB_A225		; $0A	NEXT WITHOUT FOR
	.word	LAB_A235		; $0B	SYNTAX
	.word	LAB_A23B		; $0C	RETURN WITHOUT GOSUB
	.word	LAB_A24F		; $0D	OUT OF DATA
	.word	LAB_A25A		; $0E	ILLEGAL QUANTITY
	.word	LAB_A26A		; $0F	OVERFLOW
	.word	LAB_A272		; $10	OUT OF MEMORY
	.word	LAB_A27F		; $11	UNDEF'D STATEMENT
	.word	LAB_A290		; $12	BAD SUBSCRIPT
	.word	LAB_A29D		; $13	REDIM'D ARRAY
	.word	LAB_A2AA		; $14	DIVISION BY ZERO
	.word	LAB_A2BA		; $15	ILLEGAL DIRECT
	.word	LAB_A2C8		; $16	TYPE MISMATCH
	.word	LAB_A2D5		; $17	STRING TOO LONG
	.word	LAB_A2E4		; $18	FILE DATA
	.word	LAB_A2ED		; $19	FORMULA TOO COMPLEX
	.word	LAB_A300		; $1A	CAN'T CONTINUE
	.word	LAB_A30E		; $1B	UNDEF'D FUNCTION
	.word	LAB_A31E		; $1C	VERIFY
	.word	LAB_A324		; $1D	LOAD
	.word	LAB_A383		; $1E	BREAK


;************************************************************************************
;
; BASIC messages

LAB_A364
	.byte	$0D,"OK",$0D,$00
LAB_A369
	.byte	"  ERROR",$00
LAB_A371
	.byte	" IN ",$00
LAB_A376
	.byte	$0D,$0A,"READY.",$0D,$0A,$00
LAB_A381
	.byte	$0D,$0A
LAB_A383
	.byte	"BREAK",$00


;************************************************************************************
;
; spare byte, not referenced

;LAB_A389
	.byte	$A0			; unused


;************************************************************************************
;
; search the stack for FOR or GOSUB activity
; return Zb=1 if FOR variable found

LAB_A38A
	TSX				; copy stack pointer
	INX				; +1 pass return address
	INX				; +2 pass return address
	INX				; +3 pass calling routine return address
	INX				; +4 pass calling routine return address
LAB_A38F
	LDA	LAB_0100+1,X	; get the token byte from the stack
	CMP	#TK_FOR		; is it the FOR token
	BNE	LAB_A3B7		; if not FOR token just exit

; it was the FOR token

	LDA	LAB_4A		; get FOR/NEXT variable pointer high byte
	BNE	LAB_A3A4		; branch if not null

	LDA	LAB_0100+2,X	; get FOR variable pointer low byte
	STA	LAB_49		; save FOR/NEXT variable pointer low byte
	LDA	LAB_0100+3,X	; get FOR variable pointer high byte
	STA	LAB_4A		; save FOR/NEXT variable pointer high byte
LAB_A3A4
	CMP	LAB_0100+3,X	; compare variable pointer with stacked variable pointer
					; high byte
	BNE	LAB_A3B0		; branch if no match

	LDA	LAB_49		; get FOR/NEXT variable pointer low byte
	CMP	LAB_0100+2,X	; compare variable pointer with stacked variable pointer
					; low byte
	BEQ	LAB_A3B7		; exit if match found

LAB_A3B0
	TXA				; copy index
	CLC				; clear carry for add
	ADC	#$12			; add FOR stack use size
	TAX				; copy back to index
	BNE	LAB_A38F		; loop if not at start of stack

LAB_A3B7
	RTS


;************************************************************************************
;
; open up a space in the memory, set the end of arrays

LAB_A3B8
	JSR	LAB_A408		; check available memory, do out of memory error if no room
	STA	LAB_31		; set end of arrays low byte
	STY	LAB_32		; set end of arrays high byte

; open up a space in the memory, don't set the array end

LAB_A3BF
	SEC				; set carry for subtract
	LDA	LAB_5A		; get block end low byte
	SBC	LAB_5F		; subtract block start low byte
	STA	LAB_22		; save MOD(block length/$100) byte
	TAY				; copy MOD(block length/$100) byte to Y
	LDA	LAB_5B		; get block end high byte
	SBC	LAB_60		; subtract block start high byte
	TAX				; copy block length high byte to X
	INX				; +1 to allow for count=0 exit
	TYA				; copy block length low byte to A
	BEQ	LAB_A3F3		; branch if length low byte=0

					; block is (X-1)*256+Y bytes, do the Y bytes first
	LDA	LAB_5A		; get block end low byte
	SEC				; set carry for subtract
	SBC	LAB_22		; subtract MOD(block length/$100) byte
	STA	LAB_5A		; save corrected old block end low byte
	BCS	LAB_A3DC		; branch if no underflow

	DEC	LAB_5B		; else decrement block end high byte
	SEC				; set carry for subtract
LAB_A3DC
	LDA	LAB_58		; get destination end low byte
	SBC	LAB_22		; subtract MOD(block length/$100) byte
	STA	LAB_58		; save modified new block end low byte
	BCS	LAB_A3EC		; branch if no underflow

	DEC	LAB_59		; else decrement block end high byte
	BCC	LAB_A3EC		; branch always

LAB_A3E8
	LDA	(LAB_5A),Y		; get byte from source
	STA	(LAB_58),Y		; copy byte to destination
LAB_A3EC
	DEY				; decrement index
	BNE	LAB_A3E8		; loop until Y=0

					; now do Y=0 indexed byte
	LDA	(LAB_5A),Y		; get byte from source
	STA	(LAB_58),Y		; save byte to destination
LAB_A3F3
	DEC	LAB_5B		; decrement source pointer high byte
	DEC	LAB_59		; decrement destination pointer high byte
	DEX				; decrement block count
	BNE	LAB_A3EC		; loop until count = $0

	RTS


;************************************************************************************
;
; check room on stack for A bytes
; if stack too deep do out of memory error

LAB_A3FB
	ASL				; *2
	ADC	#$3E			; need at least $3E bytes free
	BCS	LAB_A435		; if overflow go do out of memory error then warm start

	STA	LAB_22		; save result in temp byte
	TSX				; copy stack
	CPX	LAB_22		; compare new limit with stack
	BCC	LAB_A435		; if stack < limit do out of memory error then warm start

	RTS


;************************************************************************************
;
; check available memory, do out of memory error if no room

LAB_A408
	CPY	LAB_34		; compare with bottom of string space high byte
	BCC	LAB_A434		; if less then exit (is ok)

	BNE	LAB_A412		; skip next test if greater (tested <)

					; high byte was =, now do low byte
	CMP	LAB_33		; compare with bottom of string space low byte
	BCC	LAB_A434		; if less then exit (is ok)

					; address is > string storage ptr (oops!)
LAB_A412
	PHA				; push address low byte
	LDX	#$09			; set index to save LAB_57 to LAB_60 inclusive
	TYA				; copy address high byte (to push on stack)

					; save misc numeric work area
LAB_A416
	PHA				; push byte
	LDA	LAB_57,X		; get byte from LAB_57 to LAB_60
	DEX				; decrement index
	BPL	LAB_A416		; loop until all done

	JSR	LAB_B526		; do garbage collection routine

					; restore misc numeric work area
	LDX	#$F7			; set index to restore bytes
LAB_A421
	PLA				; pop byte
	STA	LAB_60+1,X		; save byte to LAB_57 to LAB_60
	INX				; increment index
	BMI	LAB_A421		; loop while -ve

	PLA				; pop address high byte
	TAY				; copy back to Y
	PLA				; pop address low byte
	CPY	LAB_34		; compare with bottom of string space high byte
	BCC	LAB_A434		; if less then exit (is ok)

	BNE	LAB_A435		; if greater do out of memory error then warm start

					; high byte was =, now do low byte
	CMP	LAB_33		; compare with bottom of string space low byte
	BCS	LAB_A435		; if >= do out of memory error then warm start

					; ok exit, carry clear
LAB_A434
	RTS


;************************************************************************************
;
; do out of memory error then warm start

LAB_A435
	LDX	#$10			; error code $10, out of memory error

; do error #X then warm start

LAB_A437
	JMP	(LAB_0300)		; do error message


;************************************************************************************
;
; do error #X then warm start, the error message vector is initialised to point here

LAB_A43A
	TXA				; copy error number
	ASL				; *2
	TAX				; copy to index
	LDA	LAB_A328-2,X	; get error message pointer low byte
	STA	LAB_22		; save it
	LDA	LAB_A328-1,X	; get error message pointer high byte
	STA	LAB_23		; save it
	JSR	LAB_FFCC		; close input and output channels
	LDA	#$00			; clear A
	STA	LAB_13		; clear current I/O channel, flag default
	JSR	LAB_AAD7		; print CR/LF
	JSR	LAB_AB45		; print "?"
	LDY	#$00			; clear index
LAB_A456
	LDA	(LAB_22),Y		; get byte from message
	PHA				; save status
	AND	#$7F			; mask 0xxx xxxx, clear b7
	JSR	LAB_AB47		; output character
	INY				; increment index
	PLA				; restore status
	BPL	LAB_A456		; loop if character was not end marker

	JSR	LAB_A67A		; flush BASIC stack and clear continue pointer
	LDA	#<LAB_A369		; set " ERROR" pointer low byte
	LDY	#>LAB_A369		; set " ERROR" pointer high byte


;************************************************************************************
;
; print string and do warm start, break entry

LAB_A469
	JSR	LAB_AB1E		; print null terminated string
	LDY	LAB_3A		; get current line number high byte
	INY				; increment it
	BEQ	LAB_A474		; branch if was in immediate mode

	JSR	LAB_BDC2		; do " IN " line number message


;************************************************************************************
;
; do warm start

LAB_A474
	LDA	#<LAB_A376		; set "READY." pointer low byte
	LDY	#>LAB_A376		; set "READY." pointer high byte
	JSR	LAB_AB1E		; print null terminated string
	LDA	#$80			; set for control messages only
	JSR	LAB_FF90		; control kernal messages
LAB_A480
	JMP	(LAB_0302)		; do BASIC warm start


;************************************************************************************
;
; BASIC warm start, the warm start vector is initialised to point here

LAB_A483
	JSR	LAB_A560		; call for BASIC input
	STX	LAB_7A		; save BASIC execute pointer low byte
	STY	LAB_7B		; save BASIC execute pointer high byte
	JSR	LAB_0073		; increment and scan memory
	TAX				; copy byte to set flags
	BEQ	LAB_A480		; loop if no input

; got to interpret the input line now ....

	LDX	#$FF			; current line high byte to -1, indicates immediate mode
	STX	LAB_3A		; set current line number high byte
	BCC	LAB_A49C		; if numeric character go handle new BASIC line

					; no line number .. immediate mode
	JSR	LAB_A579		; crunch keywords into BASIC tokens
	JMP	LAB_A7E1		; go scan and interpret code


;************************************************************************************
;
; handle new BASIC line

LAB_A49C
	JSR	LAB_A96B		; get fixed-point number into temporary integer
	JSR	LAB_A579		; crunch keywords into BASIC tokens
	STY	LAB_0B		; save index pointer to end of crunched line
	JSR	LAB_A613		; search BASIC for temporary integer line number
	BCC	LAB_A4ED		; if not found skip the line delete

					; line # already exists so delete it
	LDY	#$01			; set index to next line pointer high byte
	LDA	(LAB_5F),Y		; get next line pointer high byte
	STA	LAB_23		; save it
	LDA	LAB_2D		; get start of variables low byte
	STA	LAB_22		; save it
	LDA	LAB_60		; get found line pointer high byte
	STA	LAB_25		; save it
	LDA	LAB_5F		; get found line pointer low byte
	DEY				; decrement index
	SBC	(LAB_5F),Y		; subtract next line pointer low byte
	CLC				; clear carry for add
	ADC	LAB_2D		; add start of variables low byte
	STA	LAB_2D		; set start of variables low byte
	STA	LAB_24		; save destination pointer low byte
	LDA	LAB_2E		; get start of variables high byte
	ADC	#$FF			; -1 + carry
	STA	LAB_2E		; set start of variables high byte
	SBC	LAB_60		; subtract found line pointer high byte
	TAX				; copy to block count
	SEC				; set carry for subtract
	LDA	LAB_5F		; get found line pointer low byte
	SBC	LAB_2D		; subtract start of variables low byte
	TAY				; copy to bytes in first block count
	BCS	LAB_A4D7		; branch if no underflow

	INX				; increment block count, correct for = 0 loop exit
	DEC	LAB_25		; decrement destination high byte
LAB_A4D7
	CLC				; clear carry for add
	ADC	LAB_22		; add source pointer low byte
	BCC	LAB_A4DF		; branch if no overflow

	DEC	LAB_23		; else decrement source pointer high byte
	CLC				; clear carry

					; close up memory to delete old line
LAB_A4DF
	LDA	(LAB_22),Y		; get byte from source
	STA	(LAB_24),Y		; copy to destination
	INY				; increment index
	BNE	LAB_A4DF		; while <> 0 do this block

	INC	LAB_23		; increment source pointer high byte
	INC	LAB_25		; increment destination pointer high byte
	DEX				; decrement block count
	BNE	LAB_A4DF		; loop until all done

					; got new line in buffer and no existing same #
LAB_A4ED
	JSR	LAB_A659		; reset execution to start, clear variables, flush stack
					; and return
	JSR	LAB_A533		; rebuild BASIC line chaining
	LDA	LAB_0200		; get first byte from buffer
	BEQ	LAB_A480		; if no line go do BASIC warm start

					; else insert line into memory
	CLC				; clear carry for add
	LDA	LAB_2D		; get start of variables low byte
	STA	LAB_5A		; save as source end pointer low byte
	ADC	LAB_0B		; add index pointer to end of crunched line
	STA	LAB_58		; save as destination end pointer low byte
	LDY	LAB_2E		; get start of variables high byte
	STY	LAB_5B		; save as source end pointer high byte
	BCC	LAB_A508		; branch if no carry to high byte

	INY				; else increment high byte
LAB_A508
	STY	LAB_59		; save as destination end pointer high byte
	JSR	LAB_A3B8		; open up space in memory

; most of what remains to do is copy the crunched line into the space opened up in memory,
; however, before the crunched line comes the next line pointer and the line number. the
; line number is retrieved from the temporary integer and stored in memory, this
; overwrites the bottom two bytes on the stack. next the line is copied and the next line
; pointer is filled with whatever was in two bytes above the line number in the stack.
; this is ok because the line pointer gets fixed in the line chain re-build.

	LDA	LAB_14		; get line number low byte
	LDY	LAB_15		; get line number high byte
	STA	LAB_01FE		; save line number low byte before crunched line
	STY	LAB_01FF		; save line number high byte before crunched line
	LDA	LAB_31		; get end of arrays low byte
	LDY	LAB_32		; get end of arrays high byte
	STA	LAB_2D		; set start of variables low byte
	STY	LAB_2E		; set start of variables high byte
	LDY	LAB_0B		; get index to end of crunched line
	DEY				; -1
LAB_A522
	LDA	LAB_01FC,Y		; get byte from crunched line
	STA	(LAB_5F),Y		; save byte to memory
	DEY				; decrement index
	BPL	LAB_A522		; loop while more to do

; reset execution, clear variables, flush stack, rebuild BASIC chain and do warm start

LAB_A52A
	JSR	LAB_A659		; reset execution to start, clear variables and flush stack
	JSR	LAB_A533		; rebuild BASIC line chaining
	JMP	LAB_A480		; go do BASIC warm start


;************************************************************************************
;
; rebuild BASIC line chaining

LAB_A533
	LDA	LAB_2B		; get start of memory low byte
	LDY	LAB_2C		; get start of memory high byte
	STA	LAB_22		; set line start pointer low byte
	STY	LAB_23		; set line start pointer high byte
	CLC				; clear carry for add
LAB_A53C
	LDY	#$01			; set index to pointer to next line high byte
	LDA	(LAB_22),Y		; get pointer to next line high byte
	BEQ	LAB_A55F		; exit if null, [EOT]

	LDY	#$04			; point to first code byte of line
					; there is always 1 byte + [EOL] as null entries are deleted
LAB_A544
	INY				; next code byte
	LDA	(LAB_22),Y		; get byte
	BNE	LAB_A544		; loop if not [EOL]

	INY				; point to byte past [EOL], start of next line
	TYA				; copy it
	ADC	LAB_22		; add line start pointer low byte
	TAX				; copy to X
	LDY	#$00			; clear index, point to this line's next line pointer
	STA	(LAB_22),Y		; set next line pointer low byte
	LDA	LAB_23		; get line start pointer high byte
	ADC	#$00			; add any overflow
	INY				; increment index to high byte
	STA	(LAB_22),Y		; set next line pointer high byte
	STX	LAB_22		; set line start pointer low byte
	STA	LAB_23		; set line start pointer high byte
	BCC	LAB_A53C		; go do next line, branch always

LAB_A55F
	RTS

; call for BASIC input

LAB_A560
	LDX	#$00			; set channel $00, keyboard
LAB_A562
	JSR	LAB_E112		; input character from channel with error check
	CMP	#$0D			; compare with [CR]
	BEQ	LAB_A576		; if [CR] set XY to LAB_200 - 1, print [CR] and exit

					; character was not [CR]
	STA	LAB_0200,X		; save character to buffer
	INX				; increment buffer index
	CPX	#$59			; compare with max+1
	BCC	LAB_A562		; branch if < max+1

	LDX	#$17			; error $17, string too long error
	JMP	LAB_A437		; do error #X then warm start

LAB_A576
	JMP	LAB_AACA		; set XY to LAB_200 - 1 and print [CR]


;************************************************************************************
;
; crunch BASIC tokens vector

LAB_A579
	JMP	(LAB_0304)		; do crunch BASIC tokens


;************************************************************************************
;
; crunch BASIC tokens, the crunch BASIC tokens vector is initialised to point here

LAB_A57C
	LDX	LAB_7A		; get BASIC execute pointer low byte
	LDY	#$04			; set save index
	STY	LAB_0F		; clear open quote/DATA flag
LAB_A582
	LDA	LAB_0200,X		; get a byte from the input buffer
	BPL	LAB_A58E		; if b7 clear go do crunching

	CMP	#TK_PI		; compare with the token for PI, this toke is input
					; directly from the keyboard as the PI character
	BEQ	LAB_A5C9		; if PI save byte then continue crunching

					; this is the bit of code that stops you being able to enter
					; some keywords as just single shifted characters. If this
					; dropped through you would be able to enter GOTO as just
					; [SHIFT]G

	INX				; increment read index
	BNE	LAB_A582		; loop if more to do, branch always

LAB_A58E
	CMP	#' '			; compare with [SPACE]
	BEQ	LAB_A5C9		; if [SPACE] save byte then continue crunching

	STA	LAB_08		; save buffer byte as search character
	CMP	#$22			; compare with quote character
	BEQ	LAB_A5EE		; if quote go copy quoted string

	BIT	LAB_0F		; get open quote/DATA token flag
	BVS	LAB_A5C9		; branch if b6 of Oquote set, was DATA
					; go save byte then continue crunching

	CMP	#'?'			; compare with "?" character
	BNE	LAB_A5A4		; if not "?" continue crunching

	LDA	#TK_PRINT		; else the keyword token is $99, PRINT
	BNE	LAB_A5C9		; go save byte then continue crunching, branch always

LAB_A5A4
	CMP	#'0'			; compare with "0"
	BCC	LAB_A5AC		; branch if <, continue crunching

	CMP	#'<'			; compare with "<"
	BCC	LAB_A5C9		; if <, 0123456789:; go save byte then continue crunching

					; gets here with next character not numeric, ";" or ":"
LAB_A5AC
	STY	LAB_71		; copy save index
	LDY	#$00			; clear table pointer
	STY	LAB_0B		; clear word index
	DEY				; adjust for pre increment loop
	STX	LAB_7A		; save BASIC execute pointer low byte, buffer index
	DEX				; adjust for pre increment loop
LAB_A5B6
	INY				; next table byte
	INX				; next buffer byte
LAB_A5B8
	LDA	LAB_0200,X		; get byte from input buffer
	SEC				; set carry for subtract
	SBC	LAB_A09E,Y		; subtract table byte
	BEQ	LAB_A5B6		; go compare next if match

	CMP	#$80			; was it end marker match ?
	BNE	LAB_A5F5		; branch if not, not found keyword

					; actually this works even if the input buffer byte is the
					; end marker, i.e. a shifted character. As you can't enter
					; any keywords as a single shifted character, see above,
					; you can enter keywords in shorthand by shifting any
					; character after the first. so RETURN can be entered as
					; R[SHIFT]E, RE[SHIFT]T, RET[SHIFT]U or RETU[SHIFT]R.
					; RETUR[SHIFT]N however will not work because the [SHIFT]N
					; will match the RETURN end marker so the routine will try
					; to match the next character.

					; else found keyword
	ORA	LAB_0B		; OR with word index, +$80 in A makes token
LAB_A5C7
	LDY	LAB_71		; restore save index

; save byte then continue crunching

LAB_A5C9
	INX				; increment buffer read index
	INY				; increment save index
	STA	LAB_0200-5,Y	; save byte to output
	LDA	LAB_0200-5,Y	; get byte from output, set flags
	BEQ	LAB_A609		; branch if was null [EOL]

					; A holds the token here
	SEC				; set carry for subtract
	SBC	#':'			; subtract ":"
	BEQ	LAB_A5DC		; branch if it was (is now $00)

					; A now holds token-':'
	CMP	#TK_DATA-':'	; compare with the token for DATA-':'
	BNE	LAB_A5DE		; if not DATA go try REM

; token was : or DATA

LAB_A5DC
	STA	LAB_0F		; save the token-$3A
LAB_A5DE
	SEC				; set carry for subtract
	SBC	#TK_REM-':'		; subtract the token for REM-':'
	BNE	LAB_A582		; if wasn't REM crunch next bit of line

	STA	LAB_08		; else was REM so set search for [EOL]

					; loop for "..." etc.
LAB_A5E5
	LDA	LAB_0200,X		; get byte from input buffer
	BEQ	LAB_A5C9		; if null [EOL] save byte then continue crunching

	CMP	LAB_08		; compare with stored character
	BEQ	LAB_A5C9		; if match save byte then continue crunching

LAB_A5EE
	INY				; increment save index
	STA	LAB_0200-5,Y	; save byte to output
	INX				; increment buffer index
	BNE	LAB_A5E5		; loop while <> 0, should never reach 0

					; not found keyword this go
LAB_A5F5
	LDX	LAB_7A		; restore BASIC execute pointer low byte
	INC	LAB_0B		; increment word index (next word)

					; now find end of this word in the table
LAB_A5F9
	INY				; increment table index
	LDA	LAB_A09E-1,Y	; get table byte
	BPL	LAB_A5F9		; loop if not end of word yet

	LDA	LAB_A09E,Y		; get byte from keyword table
	BNE	LAB_A5B8		; go test next word if not zero byte, end of table

					; reached end of table with no match
	LDA	LAB_0200,X		; restore byte from input buffer
	BPL	LAB_A5C7		; branch always, all unmatched bytes in the buffer are
					; $00 to $7F, go save byte in output and continue crunching

					; reached [EOL]
LAB_A609
	STA	LAB_01FD,Y		; save [EOL]
	DEC	LAB_7B		; decrement BASIC execute pointer high byte
	LDA	#$FF			; point to start of buffer-1
	STA	LAB_7A		; set BASIC execute pointer low byte
	RTS


;************************************************************************************
;
; search BASIC for temporary integer line number

LAB_A613
	LDA	LAB_2B		; get start of memory low byte
	LDX	LAB_2C		; get start of memory high byte


;************************************************************************************
;
; search Basic for temp integer line number from AX
; returns carry set if found

LAB_A617
	LDY	#$01			; set index to next line pointer high byte
	STA	LAB_5F		; save low byte as current
	STX	LAB_60		; save high byte as current
	LDA	(LAB_5F),Y		; get next line pointer high byte from address
	BEQ	LAB_A640		; pointer was zero so done, exit

	INY				; increment index ...
	INY				; ... to line # high byte
	LDA	LAB_15		; get temporary integer high byte
	CMP	(LAB_5F),Y		; compare with line # high byte
	BCC	LAB_A641		; exit if temp < this line, target line passed

	BEQ	LAB_A62E		; go check low byte if =

	DEY				; else decrement index
	BNE	LAB_A637		; branch always

LAB_A62E
	LDA	LAB_14		; get temporary integer low byte
	DEY				; decrement index to line # low byte
	CMP	(LAB_5F),Y		; compare with line # low byte
	BCC	LAB_A641		; exit if temp < this line, target line passed

	BEQ	LAB_A641		; exit if temp = (found line#)

					; not quite there yet
LAB_A637
	DEY				; decrement index to next line pointer high byte
	LDA	(LAB_5F),Y		; get next line pointer high byte
	TAX				; copy to X
	DEY				; decrement index to next line pointer low byte
	LDA	(LAB_5F),Y		; get next line pointer low byte
	BCS	LAB_A617		; go search for line # in temporary integer
					; from AX, carry always set

LAB_A640
	CLC				; clear found flag
LAB_A641
	RTS


;************************************************************************************
;
; perform NEW

LAB_A642
	BNE	LAB_A641		; exit if following byte to allow syntax error

LAB_A644
	LDA	#$00			; clear A
	TAY				; clear index
	STA	(LAB_2B),Y		; clear pointer to next line low byte
	INY				; increment index
	STA	(LAB_2B),Y		; clear pointer to next line high byte, erase program

	LDA	LAB_2B		; get start of memory low byte
	CLC				; clear carry for add
	ADC	#$02			; add null program length
	STA	LAB_2D		; set start of variables low byte
	LDA	LAB_2C		; get start of memory high byte
	ADC	#$00			; add carry
	STA	LAB_2E		; set start of variables high byte


;************************************************************************************
;
; reset execute pointer and do CLR

LAB_A659
	JSR	LAB_A68E		; set BASIC execute pointer to start of memory - 1
	LDA	#$00			; set Zb for CLR entry


;************************************************************************************
;
; perform CLR

LAB_A65E
	BNE	LAB_A68D		; exit if following byte to allow syntax error

LAB_A660
	JSR	LAB_FFE7		; close all channels and files
LAB_A663
	LDA	LAB_37		; get end of memory low byte
	LDY	LAB_38		; get end of memory high byte
	STA	LAB_33		; set bottom of string space low byte, clear strings
	STY	LAB_34		; set bottom of string space high byte
	LDA	LAB_2D		; get start of variables low byte
	LDY	LAB_2E		; get start of variables high byte
	STA	LAB_2F		; set end of variables low byte, clear variables
	STY	LAB_30		; set end of variables high byte
	STA	LAB_31		; set end of arrays low byte, clear arrays
	STY	LAB_32		; set end of arrays high byte


;************************************************************************************
;
; do RESTORE and clear stack

LAB_A677
	JSR	LAB_A81D		; perform RESTORE


;************************************************************************************
;
; flush BASIC stack and clear the continue pointer

LAB_A67A
	LDX	#LAB_19		; get the descriptor stack start
	STX	LAB_16		; set the descriptor stack pointer
	PLA				; pull the return address low byte
	TAY				; copy it
	PLA				; pull the return address high byte
	LDX	#$FA			; set the cleared stack pointer
	TXS				; set the stack
	PHA				; push the return address high byte
	TYA				; restore the return address low byte
	PHA				; push the return address low byte
	LDA	#$00			; clear A
	STA	LAB_3E		; clear the continue pointer high byte
	STA	LAB_10		; clear the subscript/FNX flag
LAB_A68D
	RTS


;************************************************************************************
;
; set BASIC execute pointer to start of memory - 1

LAB_A68E
	CLC				; clear carry for add
	LDA	LAB_2B		; get start of memory low byte
	ADC	#$FF			; add -1 low byte
	STA	LAB_7A		; set BASIC execute pointer low byte
	LDA	LAB_2C		; get start of memory high byte
	ADC	#$FF			; add -1 high byte
	STA	LAB_7B		; save BASIC execute pointer high byte
	RTS


;************************************************************************************
;
; perform LIST

LAB_A69C
	BCC	LAB_A6A4		; branch if next character not token (LIST n...)

	BEQ	LAB_A6A4		; branch if next character [NULL] (LIST)

	CMP	#TK_MINUS		; compare with token for -
	BNE	LAB_A68D		; exit if not - (LIST -m)

					; LIST [[n][-m]]
					; this bit sets the n , if present, as the start and end
LAB_A6A4
	JSR	LAB_A96B		; get fixed-point number into temporary integer
	JSR	LAB_A613		; search BASIC for temporary integer line number
	JSR	LAB_0079		; scan memory
	BEQ	LAB_A6BB		; branch if no more chrs

					; this bit checks the - is present
	CMP	#TK_MINUS		; compare with token for -
	BNE	LAB_A641		; return if not "-" (will be SN error)

					; LIST [n]-m
					; the - was there so set m as the end value
	JSR	LAB_0073		; increment and scan memory
	JSR	LAB_A96B		; get fixed-point number into temporary integer
	BNE	LAB_A641		; exit if not ok

LAB_A6BB
	PLA				; dump return address low byte, exit via warm start
	PLA				; dump return address high byte
	LDA	LAB_14		; get temporary integer low byte
	ORA	LAB_15		; OR temporary integer high byte
	BNE	LAB_A6C9		; branch if start set

	LDA	#$FF			; set for -1
	STA	LAB_14		; set temporary integer low byte
	STA	LAB_15		; set temporary integer high byte
LAB_A6C9
	LDY	#$01			; set index for line
	STY	LAB_0F		; clear open quote flag
	LDA	(LAB_5F),Y		; get next line pointer high byte
	BEQ	LAB_A714		; if null all done so exit

	JSR	LAB_A82C		; do CRTL-C check vector
	JSR	LAB_AAD7		; print CR/LF
	INY				; increment index for line
	LDA	(LAB_5F),Y		; get line number low byte
	TAX				; copy to X
	INY				; increment index
	LDA	(LAB_5F),Y		; get line number high byte
	CMP	LAB_15		; compare with temporary integer high byte
	BNE	LAB_A6E6		; branch if no high byte match

	CPX	LAB_14		; compare with temporary integer low byte
	BEQ	LAB_A6E8		; branch if = last line to do, < will pass next branch

LAB_A6E6				; else ...
	BCS	LAB_A714		; if greater all done so exit

LAB_A6E8
	STY	LAB_49		; save index for line
	JSR	LAB_BDCD		; print XA as unsigned integer
	LDA	#' '			; space is the next character
LAB_A6EF
	LDY	LAB_49		; get index for line
	AND	#$7F			; mask top out bit of character
LAB_A6F3
	JSR	LAB_AB47		; go print the character
	CMP	#$22			; was it " character
	BNE	LAB_A700		; if not skip the quote handle

					; we are either entering or leaving a pair of quotes
	LDA	LAB_0F		; get open quote flag
	EOR	#$FF			; toggle it
	STA	LAB_0F		; save it back
LAB_A700
	INY				; increment index
	BEQ	LAB_A714		; line too long so just bail out and do a warm start

	LDA	(LAB_5F),Y		; get next byte
	BNE	LAB_A717		; if not [EOL] (go print character)

					; was [EOL]
	TAY				; else clear index
	LDA	(LAB_5F),Y		; get next line pointer low byte
	TAX				; copy to X
	INY				; increment index
	LDA	(LAB_5F),Y		; get next line pointer high byte
	STX	LAB_5F		; set pointer to line low byte
	STA	LAB_60		; set pointer to line high byte
	BNE	LAB_A6C9		; go do next line if not [EOT]
					; else ...
LAB_A714
	JMP	LAB_E386		; do warm start

LAB_A717
	JMP	(LAB_0306)		; do uncrunch BASIC tokens


;************************************************************************************
;
; uncrunch BASIC tokens, the uncrunch BASIC tokens vector is initialised to point here

LAB_A71A
	BPL	LAB_A6F3		; just go print it if not token byte
					; else was token byte so uncrunch it

	CMP	#TK_PI		; compare with the token for PI. in this case the token
					; is the same as the PI character so it just needs printing
	BEQ	LAB_A6F3		; just print it if so

	BIT	LAB_0F		; test the open quote flag
	BMI	LAB_A6F3		; just go print character if open quote set

	SEC				; else set carry for subtract
	SBC	#$7F			; reduce token range to 1 to whatever
	TAX				; copy token # to X
	STY	LAB_49		; save index for line
	LDY	#$FF			; start from -1, adjust for pre increment
LAB_A72C
	DEX				; decrement token #
	BEQ	LAB_A737		; if now found go do printing

LAB_A72F
	INY				; else increment index
	LDA	LAB_A09E,Y		; get byte from keyword table
	BPL	LAB_A72F		; loop until keyword end marker

	BMI	LAB_A72C		; go test if this is required keyword, branch always

					; found keyword, it's the next one
LAB_A737
	INY				; increment keyword table index
	LDA	LAB_A09E,Y		; get byte from table
	BMI	LAB_A6EF		; go restore index, mask byte and print if
					; byte was end marker

	JSR	LAB_AB47		; else go print the character
	BNE	LAB_A737		; go get next character, branch always


;************************************************************************************
;
; perform FOR

LAB_A742
	LDA	#$80			; set FNX
	STA	LAB_10		; set subscript/FNX flag
	JSR	LAB_A9A5		; perform LET
	JSR	LAB_A38A		; search the stack for FOR or GOSUB activity
	BNE	LAB_A753		; branch if FOR, this variable, not found

					; FOR, this variable, was found so first we dump the old one
	TXA				; copy index
	ADC	#$0F			; add FOR structure size-2
	TAX				; copy to index
	TXS				; set stack (dump FOR structure (-2 bytes))
LAB_A753
	PLA				; pull return address
	PLA				; pull return address
	LDA	#$09			; we need 18d bytes !
	JSR	LAB_A3FB		; check room on stack for 2*A bytes
	JSR	LAB_A906		; scan for next BASIC statement ([:] or [EOL])
	CLC				; clear carry for add
	TYA				; copy index to A
	ADC	LAB_7A		; add BASIC execute pointer low byte
	PHA				; push onto stack
	LDA	LAB_7B		; get BASIC execute pointer high byte
	ADC	#$00			; add carry
	PHA				; push onto stack
	LDA	LAB_3A		; get current line number high byte
	PHA				; push onto stack
	LDA	LAB_39		; get current line number low byte
	PHA				; push onto stack
	LDA	#TK_TO		; set "TO" token
	JSR	LAB_AEFF		; scan for CHR$(A), else do syntax error then warm start
	JSR	LAB_AD8D		; check if source is numeric, else do type mismatch
	JSR	LAB_AD8A		; evaluate expression and check is numeric, else do
					; type mismatch
	LDA	LAB_66		; get FAC1 sign (b7)
	ORA	#$7F			; set all non sign bits
	AND	LAB_62		; and FAC1 mantissa 1
	STA	LAB_62		; save FAC1 mantissa 1
	LDA	#<LAB_A78B		; set return address low byte
	LDY	#>LAB_A78B		; set return address high byte
	STA	LAB_22		; save return address low byte
	STY	LAB_23		; save return address high byte
	JMP	LAB_AE43		; round FAC1 and put on stack, returns to next instruction

LAB_A78B
	LDA	#<LAB_B9BC		; set 1 pointer low address, default step size
	LDY	#>LAB_B9BC		; set 1 pointer high address
	JSR	LAB_BBA2		; unpack memory (AY) into FAC1
	JSR	LAB_0079		; scan memory
	CMP	#TK_STEP		; compare with STEP token
	BNE	LAB_A79F		; if not "STEP" continue

; was step so ....

	JSR	LAB_0073		; increment and scan memory
	JSR	LAB_AD8A		; evaluate expression and check is numeric, else do
					; type mismatch
LAB_A79F
	JSR	LAB_BC2B		; get FAC1 sign, return A = $FF -ve, A = $01 +ve
	JSR	LAB_AE38		; push sign, round FAC1 and put on stack
	LDA	LAB_4A		; get FOR/NEXT variable pointer high byte
	PHA				; push on stack
	LDA	LAB_49		; get FOR/NEXT variable pointer low byte
	PHA				; push on stack
	LDA	#TK_FOR		; get FOR token
	PHA				; push on stack


;************************************************************************************
;
; interpreter inner loop

LAB_A7AE
	JSR	LAB_A82C		; do CRTL-C check vector
	LDA	LAB_7A		; get the BASIC execute pointer low byte
	LDY	LAB_7B		; get the BASIC execute pointer high byte
	CPY	#$02			; compare the high byte with $02xx
	NOP				; unused byte							##
	BEQ	LAB_A7BE		; if immediate mode skip the continue pointer save

	STA	LAB_3D		; save the continue pointer low byte
	STY	LAB_3E		; save the continue pointer high byte
LAB_A7BE
	LDY	#$00			; clear the index
	LDA	(LAB_7A),Y		; get a BASIC byte
	BNE	LAB_A807		; if not [EOL] go test for ":"

	LDY	#$02			; else set the index
	LDA	(LAB_7A),Y		; get next line pointer high byte
	CLC				; clear carry for no "BREAK" message
	BNE	LAB_A7CE		; branch if not end of program

	JMP	LAB_A84B		; else go to immediate mode,was immediate or [EOT] marker

LAB_A7CE
	INY				; increment index
	LDA	(LAB_7A),Y		; get line number low byte
	STA	LAB_39		; save current line number low byte
	INY				; increment index
	LDA	(LAB_7A),Y		; get line # high byte
	STA	LAB_3A		; save current line number high byte
	TYA				; A now = 4
	ADC	LAB_7A		; add BASIC execute pointer low byte, now points to code
	STA	LAB_7A		; save BASIC execute pointer low byte
	BCC	LAB_A7E1		; branch if no overflow

	INC	LAB_7B		; else increment BASIC execute pointer high byte
LAB_A7E1
	JMP	(LAB_0308)		; do start new BASIC code


;************************************************************************************
;
; start new BASIC code, the start new BASIC code vector is initialised to point here

LAB_A7E4
	JSR	LAB_0073		; increment and scan memory
	JSR	LAB_A7ED		; go interpret BASIC code from BASIC execute pointer
	JMP	LAB_A7AE		; loop


;************************************************************************************
;
; go interpret BASIC code from BASIC execute pointer

LAB_A7ED
	BEQ	LAB_A82B		; if the first byte is null just exit

LAB_A7EF
	SBC	#$80			; normalise the token
	BCC	LAB_A804		; if wasn't token go do LET

	CMP	#TK_TAB-$80		; compare with token for TAB(-$80
	BCS	LAB_A80E		; branch if >= TAB(

	ASL				; *2 bytes per vector
	TAY				; copy to index
	LDA	LAB_A00C+1,Y	; get vector high byte
	PHA				; push on stack
	LDA	LAB_A00C,Y		; get vector low byte
	PHA				; push on stack
	JMP	LAB_0073		; increment and scan memory and return. the return in
					; this case calls the command code, the return from
					; that will eventually return to the interpreter inner
					; loop above

LAB_A804
	JMP	LAB_A9A5		; perform LET

					; was not [EOL]
LAB_A807
	CMP	#':'			; comapre with ":"
	BEQ	LAB_A7E1		; if ":" go execute new code

					; else ...
LAB_A80B
	JMP	LAB_AF08		; do syntax error then warm start

					; token was >= TAB(
LAB_A80E
	CMP	#TK_GO-$80		; compare with the token for GO
	BNE	LAB_A80B		; if not "GO" do syntax error then warm start

; else was "GO"

	JSR	LAB_0073		; increment and scan memory
	LDA	#TK_TO		; set "TO" token
	JSR	LAB_AEFF		; scan for CHR$(A), else do syntax error then warm start
	JMP	LAB_A8A0		; perform GOTO


;************************************************************************************
;
; perform RESTORE

LAB_A81D
	SEC				; set carry for subtract
	LDA	LAB_2B		; get start of memory low byte
	SBC	#$01			; -1
	LDY	LAB_2C		; get start of memory high byte
	BCS	LAB_A827		; branch if no rollunder

	DEY				; else decrement high byte
LAB_A827
	STA	LAB_41		; set DATA pointer low byte
	STY	LAB_42		; set DATA pointer high byte
LAB_A82B
	RTS


;************************************************************************************
;
; do CRTL-C check vector

LAB_A82C
	JSR	LAB_FFE1		; scan stop key


;************************************************************************************
;
; perform STOP

LAB_A82F
	BCS	LAB_A832		; if carry set do BREAK instead of just END


;************************************************************************************
;
; perform END

LAB_A831
	CLC				; clear carry
LAB_A832
	BNE	LAB_A870		; return if wasn't CTRL-C

	LDA	LAB_7A		; get BASIC execute pointer low byte
	LDY	LAB_7B		; get BASIC execute pointer high byte
	LDX	LAB_3A		; get current line number high byte
	INX				; increment it
	BEQ	LAB_A849		; branch if was immediate mode

	STA	LAB_3D		; save continue pointer low byte
	STY	LAB_3E		; save continue pointer high byte
	LDA	LAB_39		; get current line number low byte
	LDY	LAB_3A		; get current line number high byte
	STA	LAB_3B		; save break line number low byte
	STY	LAB_3C		; save break line number high byte
LAB_A849
	PLA				; dump return address low byte
	PLA				; dump return address high byte
LAB_A84B
	LDA	#<LAB_A381		; set [CR][LF]"BREAK" pointer low byte
	LDY	#>LAB_A381		; set [CR][LF]"BREAK" pointer high byte
	BCC	LAB_A854		; if was program end skip the print string

	JMP	LAB_A469		; print string and do warm start

LAB_A854
	JMP	LAB_E386		; do warm start


;************************************************************************************
;
; perform CONT

LAB_A857
	BNE	LAB_A870		; exit if following byte to allow syntax error

	LDX	#$1A			; error code $1A, can't continue error
	LDY	LAB_3E		; get continue pointer high byte
	BNE	LAB_A862		; go do continue if we can

	JMP	LAB_A437		; else do error #X then warm start

					; we can continue so ...
LAB_A862
	LDA	LAB_3D		; get continue pointer low byte
	STA	LAB_7A		; save BASIC execute pointer low byte
	STY	LAB_7B		; save BASIC execute pointer high byte
	LDA	LAB_3B		; get break line low byte
	LDY	LAB_3C		; get break line high byte
	STA	LAB_39		; set current line number low byte
	STY	LAB_3A		; set current line number high byte
LAB_A870
	RTS


;************************************************************************************
;
; perform RUN

LAB_A871
	PHP				; save status
	LDA	#$00			; no control or kernal messages
	JSR	LAB_FF90		; control kernal messages
	PLP				; restore status
	BNE	LAB_A87D		; branch if RUN n

	JMP	LAB_A659		; reset execution to start, clear variables, flush stack
					; and return
LAB_A87D
	JSR	LAB_A660		; go do "CLEAR"
	JMP	LAB_A897		; get n and do GOTO n


;************************************************************************************
;
; perform GOSUB

LAB_A883
	LDA	#$03			; need 6 bytes for GOSUB
	JSR	LAB_A3FB		; check room on stack for 2*A bytes
	LDA	LAB_7B		; get BASIC execute pointer high byte
	PHA				; save it
	LDA	LAB_7A		; get BASIC execute pointer low byte
	PHA				; save it
	LDA	LAB_3A		; get current line number high byte
	PHA				; save it
	LDA	LAB_39		; get current line number low byte
	PHA				; save it
	LDA	#TK_GOSUB		; token for GOSUB
	PHA				; save it
LAB_A897
	JSR	LAB_0079		; scan memory
	JSR	LAB_A8A0		; perform GOTO
	JMP	LAB_A7AE		; go do interpreter inner loop


;************************************************************************************
;
; perform GOTO

LAB_A8A0
	JSR	LAB_A96B		; get fixed-point number into temporary integer
	JSR	LAB_A909		; scan for next BASIC line
	SEC				; set carry for subtract
	LDA	LAB_39		; get current line number low byte
	SBC	LAB_14		; subtract temporary integer low byte
	LDA	LAB_3A		; get current line number high byte
	SBC	LAB_15		; subtract temporary integer high byte
	BCS	LAB_A8BC		; if current line number >= temporary integer, go search
					; from the start of memory

	TYA				; else copy line index to A
	SEC				; set carry (+1)
	ADC	LAB_7A		; add BASIC execute pointer low byte
	LDX	LAB_7B		; get BASIC execute pointer high byte
	BCC	LAB_A8C0		; branch if no overflow to high byte

	INX				; increment high byte
	BCS	LAB_A8C0		; branch always (can never be carry)


;************************************************************************************
;
; search for line number in temporary integer from start of memory pointer

LAB_A8BC
	LDA	LAB_2B		; get start of memory low byte
	LDX	LAB_2C		; get start of memory high byte


;************************************************************************************
;
; search for line # in temporary integer from (AX)

LAB_A8C0
	JSR	LAB_A617		; search Basic for temp integer line number from AX
	BCC	LAB_A8E3		; if carry clear go do unsdefined statement error

					; carry all ready set for subtract
	LDA	LAB_5F		; get pointer low byte
	SBC	#$01			; -1
	STA	LAB_7A		; save BASIC execute pointer low byte
	LDA	LAB_60		; get pointer high byte
	SBC	#$00			; subtract carry
	STA	LAB_7B		; save BASIC execute pointer high byte
LAB_A8D1
	RTS


;************************************************************************************
;
; perform RETURN

LAB_A8D2
	BNE	LAB_A8D1		; exit if following token to allow syntax error

	LDA	#$FF			; set byte so no match possible
	STA	LAB_4A		; save FOR/NEXT variable pointer high byte
	JSR	LAB_A38A		; search the stack for FOR or GOSUB activity,
					; get token off stack
	TXS				; correct the stack
	CMP	#TK_GOSUB		; compare with GOSUB token
	BEQ	LAB_A8EB		; if matching GOSUB go continue RETURN

	LDX	#$0C			; else error code $04, return without gosub error
	.byte	$2C			; makes next line BIT LAB_11A2
LAB_A8E3
	LDX	#$11			; error code $11, undefined statement error
	JMP	LAB_A437		; do error #X then warm start

LAB_A8E8
	JMP	LAB_AF08		; do syntax error then warm start

					; was matching GOSUB token
LAB_A8EB
	PLA				; dump token byte
	PLA				; pull return line low byte
	STA	LAB_39		; save current line number low byte
	PLA				; pull return line high byte
	STA	LAB_3A		; save current line number high byte
	PLA				; pull return address low byte
	STA	LAB_7A		; save BASIC execute pointer low byte
	PLA				; pull return address high byte
	STA	LAB_7B		; save BASIC execute pointer high byte


;************************************************************************************
;
; perform DATA

LAB_A8F8
	JSR	LAB_A906		; scan for next BASIC statement ([:] or [EOL])


;************************************************************************************
;
; add Y to the BASIC execute pointer

LAB_A8FB
	TYA				; copy index to A
	CLC				; clear carry for add
	ADC	LAB_7A		; add BASIC execute pointer low byte
	STA	LAB_7A		; save BASIC execute pointer low byte
	BCC	LAB_A905		; skip increment if no carry

	INC	LAB_7B		; else increment BASIC execute pointer high byte
LAB_A905
	RTS


;************************************************************************************
;
; scan for next BASIC statement ([:] or [EOL])
; returns Y as index to [:] or [EOL]

LAB_A906
	LDX	#':'			; set look for character = ":"
	.byte	$2C			; makes next line BIT LAB_00A2


;************************************************************************************
;
; scan for next BASIC line
; returns Y as index to [EOL]

LAB_A909
	LDX	#$00			; set alternate search character = [EOL]
	STX	LAB_07		; store alternate search character
	LDY	#$00			; set search character = [EOL]
	STY	LAB_08		; save the search character
LAB_A911
	LDA	LAB_08		; get search character
	LDX	LAB_07		; get alternate search character
	STA	LAB_07		; make search character = alternate search character
	STX	LAB_08		; make alternate search character = search character
LAB_A919
	LDA	(LAB_7A),Y		; get BASIC byte
	BEQ	LAB_A905		; exit if null [EOL]

	CMP	LAB_08		; compare with search character
	BEQ	LAB_A905		; exit if found

	INY				; else increment index
	CMP	#$22			; compare current character with open quote
	BNE	LAB_A919		; if found go swap search character for alternate search
					; character

	BEQ	LAB_A911		; loop for next character, branch always


;************************************************************************************
;
; perform IF

LAB_A928
	JSR	LAB_AD9E		; evaluate expression
	JSR	LAB_0079		; scan memory
	CMP	#TK_GOTO		; compare with "GOTO" token
	BEQ	LAB_A937		; if it was  the token for GOTO go do IF ... GOTO

					; wasn't IF ... GOTO so must be IF ... THEN
	LDA	#TK_THEN		; set "THEN" token
	JSR	LAB_AEFF		; scan for CHR$(A), else do syntax error then warm start
LAB_A937
	LDA	LAB_61		; get FAC1 exponent
	BNE	LAB_A940		; if result was non zero continue execution

					; else REM rest of line


;************************************************************************************
;
; perform REM

LAB_A93B
	JSR	LAB_A909		; scan for next BASIC line
	BEQ	LAB_A8FB		; add Y to the BASIC execute pointer and return, branch
					; always

					; result was non zero so do rest of line
LAB_A940
	JSR	LAB_0079		; scan memory
	BCS	LAB_A948		; branch if not numeric character, is variable or keyword

	JMP	LAB_A8A0		; else perform GOTO n

					; is variable or keyword
LAB_A948
	JMP	LAB_A7ED		; interpret BASIC code from BASIC execute pointer


;************************************************************************************
;
; perform ON

LAB_A94B
	JSR	LAB_B79E		; get byte parameter
	PHA				; push next character
	CMP	#TK_GOSUB		; compare with GOSUB token
	BEQ	LAB_A957		; if GOSUB go see if it should be executed

LAB_A953
	CMP	#TK_GOTO		; compare with GOTO token
	BNE	LAB_A8E8		; if not GOTO do syntax error then warm start

; next character was GOTO or GOSUB, see if it should be executed

LAB_A957
	DEC	LAB_65		; decrement the byte value
	BNE	LAB_A95F		; if not zero go see if another line number exists

	PLA				; pull keyword token
	JMP	LAB_A7EF		; go execute it

LAB_A95F
	JSR	LAB_0073		; increment and scan memory
	JSR	LAB_A96B		; get fixed-point number into temporary integer
					; skip this n
	CMP	#','			; compare next character with ","
	BEQ	LAB_A957		; loop if ","

	PLA				; else pull keyword token, ran out of options
LAB_A96A
	RTS


;************************************************************************************
;
; get fixed-point number into temporary integer

LAB_A96B
	LDX	#$00			; clear X
	STX	LAB_14		; clear temporary integer low byte
	STX	LAB_15		; clear temporary integer high byte
LAB_A971
	BCS	LAB_A96A		; return if carry set, end of scan, character was not 0-9

	SBC	#'0'-1		; subtract $30, $2F+carry, from byte
	STA	LAB_07		; store #
	LDA	LAB_15		; get temporary integer high byte
	STA	LAB_22		; save it for now
	CMP	#$19			; compare with $19
	BCS	LAB_A953		; branch if >= this makes the maximum line number 63999
					; because the next bit does $1900 * $0A = $FA00 = 64000
					; decimal. the branch target is really the SYNTAX error
					; at LAB_A8E8 but that is too far so an intermediate
					; compare and branch to that location is used. the problem
					; with this is that line number that gives a partial result
					; from $8900 to $89FF, 35072x to 35327x, will pass the new
					; target compare and will try to execute the remainder of
					; the ON n GOTO/GOSUB. a solution to this is to copy the
					; byte in A before the branch to X and then branch to
					; LAB_A955 skipping the second compare

	LDA	LAB_14		; get temporary integer low byte
	ASL				; *2 low byte
	ROL	LAB_22		; *2 high byte
	ASL				; *2 low byte
	ROL	LAB_22		; *2 high byte (*4)
	ADC	LAB_14		; + low byte (*5)
	STA	LAB_14		; save it
	LDA	LAB_22		; get high byte temp
	ADC	LAB_15		; + high byte (*5)
	STA	LAB_15		; save it
	ASL	LAB_14		; *2 low byte (*10d)
	ROL	LAB_15		; *2 high byte (*10d)
	LDA	LAB_14		; get low byte
	ADC	LAB_07		; add #
	STA	LAB_14		; save low byte
	BCC	LAB_A99F		; branch if no overflow to high byte

	INC	LAB_15		; else increment high byte
LAB_A99F
	JSR	LAB_0073		; increment and scan memory
	JMP	LAB_A971		; loop for next character


;************************************************************************************
;
; perform LET

LAB_A9A5
	JSR	LAB_B08B		; get variable address
	STA	LAB_49		; save variable address low byte
	STY	LAB_4A		; save variable address high byte
	LDA	#TK_EQUAL		; $B2 is "=" token
	JSR	LAB_AEFF		; scan for CHR$(A), else do syntax error then warm start
	LDA	LAB_0E		; get data type flag, $80 = integer, $00 = float
	PHA				; push data type flag
	LDA	LAB_0D		; get data type flag, $FF = string, $00 = numeric
	PHA				; push data type flag
	JSR	LAB_AD9E		; evaluate expression
	PLA				; pop data type flag
	ROL				; string bit into carry
	JSR	LAB_AD90		; do type match check
	BNE	LAB_A9D9		; branch if string

	PLA				; pop integer/float data type flag

; assign value to numeric variable

LAB_A9C2
	BPL	LAB_A9D6		; branch if float

					; expression is numeric integer
	JSR	LAB_BC1B		; round FAC1
	JSR	LAB_B1BF		; evaluate integer expression, no sign check
	LDY	#$00			; clear index
	LDA	LAB_64		; get FAC1 mantissa 3
	STA	(LAB_49),Y		; save as integer variable low byte
	INY				; increment index
	LDA	LAB_65		; get FAC1 mantissa 4
	STA	(LAB_49),Y		; save as integer variable high byte
	RTS

LAB_A9D6
	JMP	LAB_BBD0		; pack FAC1 into variable pointer and return

; assign value to numeric variable

LAB_A9D9
	PLA				; dump integer/float data type flag
LAB_A9DA
	LDY	LAB_4A		; get variable pointer high byte
	CPY	#>LAB_BF13		; was it TI$ pointer
	BNE	LAB_AA2C		; branch if not

					; else it's TI$ = <expr$>
	JSR	LAB_B6A6		; pop string off descriptor stack, or from top of string
					; space returns with A = length, X = pointer low byte,
					; Y = pointer high byte
	CMP	#$06			; compare length with 6
	BNE	LAB_AA24		; if length not 6 do illegal quantity error then warm start

	LDY	#$00			; clear index
	STY	LAB_61		; clear FAC1 exponent
	STY	LAB_66		; clear FAC1 sign (b7)
LAB_A9ED
	STY	LAB_71		; save index
	JSR	LAB_AA1D		; check and evaluate numeric digit
	JSR	LAB_BAE2		; multiply FAC1 by 10
	INC	LAB_71		; increment index
	LDY	LAB_71		; restore index
	JSR	LAB_AA1D		; check and evaluate numeric digit
	JSR	LAB_BC0C		; round and copy FAC1 to FAC2
	TAX				; copy FAC1 exponent
	BEQ	LAB_AA07		; branch if FAC1 zero

	INX				; increment index, * 2
	TXA				; copy back to A
	JSR	LAB_BAED		; FAC1 = (FAC1 + (FAC2 * 2)) * 2 = FAC1 * 6
LAB_AA07
	LDY	LAB_71		; get index
	INY				; increment index
	CPY	#$06			; compare index with 6
	BNE	LAB_A9ED		; loop if not 6

	JSR	LAB_BAE2		; multiply FAC1 by 10
	JSR	LAB_BC9B		; convert FAC1 floating to fixed
	LDX	LAB_64		; get FAC1 mantissa 3
	LDY	LAB_63		; get FAC1 mantissa 2
	LDA	LAB_65		; get FAC1 mantissa 4
	JMP	LAB_FFDB		; set real time clock and return


;************************************************************************************
;
; check and evaluate numeric digit

LAB_AA1D
	LDA	(LAB_22),Y		; get byte from string
	JSR	LAB_80		; clear Cb if numeric. this call should be to LAB_84
					; as the code from LAB_80 first comapres the byte with
					; [SPACE] and does a BASIC increment and get if it is
	BCC	LAB_AA27		; branch if numeric

LAB_AA24
	JMP	LAB_B248		; do illegal quantity error then warm start

LAB_AA27
	SBC	#'0'-1		; subtract $2F + carry to convert ASCII to binary
	JMP	LAB_BD7E		; evaluate new ASCII digit and return


;************************************************************************************
;
; assign value to numeric variable, but not TI$

LAB_AA2C
	LDY	#$02			; index to string pointer high byte
	LDA	(LAB_64),Y		; get string pointer high byte
	CMP	LAB_34		; compare with bottom of string space high byte
	BCC	LAB_AA4B		; branch if string pointer high byte is less than bottom
					; of string space high byte

	BNE	LAB_AA3D		; branch if string pointer high byte is greater than
					; bottom of string space high byte

					; else high bytes were equal
	DEY				; decrement index to string pointer low byte
	LDA	(LAB_64),Y		; get string pointer low byte
	CMP	LAB_33		; compare with bottom of string space low byte
	BCC	LAB_AA4B		; branch if string pointer low byte is less than bottom
					; of string space low byte

LAB_AA3D
	LDY	LAB_65		; get descriptor pointer high byte
	CPY	LAB_2E		; compare with start of variables high byte
	BCC	LAB_AA4B		; branch if less, is on string stack

	BNE	LAB_AA52		; if greater make space and copy string

					; else high bytes were equal
	LDA	LAB_64		; get descriptor pointer low byte
	CMP	LAB_2D		; compare with start of variables low byte
	BCS	LAB_AA52		; if greater or equal make space and copy string

LAB_AA4B
	LDA	LAB_64		; get descriptor pointer low byte
	LDY	LAB_65		; get descriptor pointer high byte
	JMP	LAB_AA68		; go copy descriptor to variable

LAB_AA52
	LDY	#$00			; clear index
	LDA	(LAB_64),Y		; get string length
	JSR	LAB_B475		; copy descriptor pointer and make string space A bytes long
	LDA	LAB_50		; copy old descriptor pointer low byte
	LDY	LAB_51		; copy old descriptor pointer high byte
	STA	LAB_6F		; save old descriptor pointer low byte
	STY	LAB_70		; save old descriptor pointer high byte
	JSR	LAB_B67A		; copy string from descriptor to utility pointer
	LDA	#<LAB_61		; get descriptor pointer low byte
	LDY	#>LAB_61		; get descriptor pointer high byte
LAB_AA68
	STA	LAB_50		; save descriptor pointer low byte
	STY	LAB_51		; save descriptor pointer high byte
	JSR	LAB_B6DB		; clean descriptor stack, YA = pointer
	LDY	#$00			; clear index
	LDA	(LAB_50),Y		; get string length from new descriptor
	STA	(LAB_49),Y		; copy string length to variable
	INY				; increment index
	LDA	(LAB_50),Y		; get string pointer low byte from new descriptor
	STA	(LAB_49),Y		; copy string pointer low byte to variable
	INY				; increment index
	LDA	(LAB_50),Y		; get string pointer high byte from new descriptor
	STA	(LAB_49),Y		; copy string pointer high byte to variable
	RTS


;************************************************************************************
;
; perform PRINT#

LAB_AA80
	JSR	LAB_AA86		; perform CMD
	JMP	LAB_ABB5		; close input and output channels and return


;************************************************************************************
;
; perform CMD

LAB_AA86
	JSR	LAB_B79E		; get byte parameter
	BEQ	LAB_AA90		; branch if following byte is ":" or [EOT]

	LDA	#','			; set ","
	JSR	LAB_AEFF		; scan for CHR$(A), else do syntax error then warm start
LAB_AA90
	PHP				; save status
	STX	LAB_13		; set current I/O channel
	JSR	LAB_E118		; open channel for output with error check
	PLP				; restore status
	JMP	LAB_AAA0		; perform PRINT

LAB_AA9A
	JSR	LAB_AB21		; print string from utility pointer
LAB_AA9D
	JSR	LAB_0079		; scan memory


;************************************************************************************
;
; perform PRINT

LAB_AAA0
	BEQ	LAB_AAD7		; if nothing following just print CR/LF

LAB_AAA2
	BEQ	LAB_AAE7		; exit if nothing following, end of PRINT branch

	CMP	#TK_TAB		; compare with token for TAB(
	BEQ	LAB_AAF8		; if TAB( go handle it

	CMP	#TK_SPC		; compare with token for SPC(
	CLC				; flag SPC(
	BEQ	LAB_AAF8		; if SPC( go handle it

	CMP	#','			; compare with ","
	BEQ	LAB_AAE8		; if "," go skip to the next TAB position

	CMP	#';'			; compare with ";"
	BEQ	LAB_AB13		; if ";" go continue the print loop

	JSR	LAB_AD9E		; evaluate expression
	BIT	LAB_0D		; test data type flag, $FF = string, $00 = numeric
	BMI	LAB_AA9A		; if string go print string, scan memory and continue PRINT

	JSR	LAB_BDDD		; convert FAC1 to ASCII string result in (AY)
	JSR	LAB_B487		; print " terminated string to utility pointer
	JSR	LAB_AB21		; print string from utility pointer
	JSR	LAB_AB3B		; print [SPACE] or [CURSOR RIGHT]
	BNE	LAB_AA9D		; go scan memory and continue PRINT, branch always


;************************************************************************************
;
; set XY to LAB_0200 - 1 and print [CR]

LAB_AACA
	LDA	#$00			; clear A
	STA	LAB_0200,X		; clear first byte of input buffer
	LDX	#<LAB_01FF		; LAB_0200 - 1 low byte
	LDY	#>LAB_01FF		; LAB_0200 - 1 high byte
	LDA	LAB_13		; get current I/O channel
	BNE	LAB_AAE7		; exit if not default channel


;************************************************************************************
;
; print CR/LF

LAB_AAD7
	LDA	#$0D			; set [CR]
	JSR	LAB_AB47		; print the character
	BIT	LAB_13		; test current I/O channel
	BPL	LAB_AAE5		; if ?? toggle A, EOR #$FF and return

	LDA	#$0A			; set [LF]
	JSR	LAB_AB47		; print the character

; toggle A

LAB_AAE5
	EOR	#$FF			; invert A
LAB_AAE7
	RTS

					; was ","
LAB_AAE8
	SEC				; set Cb for read cursor position
	JSR	LAB_FFF0		; read/set X,Y cursor position
	TYA				; copy cursor Y
	SEC				; set carry for subtract
LAB_AAEE
	SBC	#$0A			; subtract one TAB length
	BCS	LAB_AAEE		; loop if result was +ve

	EOR	#$FF			; complement it
	ADC	#$01			; +1, twos complement
	BNE	LAB_AB0E		; always print A spaces, result is never $00

LAB_AAF8
	PHP				; save TAB( or SPC( status
	SEC				; set Cb for read cursor position
	JSR	LAB_FFF0		; read/set X,Y cursor position
	STY	LAB_09		; save current cursor position
	JSR	LAB_B79B		; scan and get byte parameter
	CMP	#')'			; compare with ")"
	BNE	LAB_AB5F		; if not ")" do syntax error

	PLP				; restore TAB( or SPC( status
	BCC	LAB_AB0F		; branch if was SPC(

					; else was TAB(
	TXA				; copy TAB() byte to A
	SBC	LAB_09		; subtract current cursor position
	BCC	LAB_AB13		; go loop for next if already past requited position

LAB_AB0E
	TAX				; copy [SPACE] count to X
LAB_AB0F
	INX				; increment count
LAB_AB10
	DEX				; decrement count
	BNE	LAB_AB19		; branch if count was not zero

					; was ";" or [SPACES] printed
LAB_AB13
	JSR	LAB_0073		; increment and scan memory
	JMP	LAB_AAA2		; continue print loop

LAB_AB19
	JSR	LAB_AB3B		; print [SPACE] or [CURSOR RIGHT]
	BNE	LAB_AB10		; loop, branch always


;************************************************************************************
;
; print null terminated string

LAB_AB1E
	JSR	LAB_B487		; print " terminated string to utility pointer


;************************************************************************************
;
; print string from utility pointer

LAB_AB21
	JSR	LAB_B6A6		; pop string off descriptor stack, or from top of string
					; space returns with A = length, X = pointer low byte,
					; Y = pointer high byte
	TAX				; copy length
	LDY	#$00			; clear index
	INX				; increment length, for pre decrement loop
LAB_AB28
	DEX				; decrement length
	BEQ	LAB_AAE7		; exit if done

	LDA	(LAB_22),Y		; get byte from string
	JSR	LAB_AB47		; print the character
	INY				; increment index
	CMP	#$0D			; compare byte with [CR]
	BNE	LAB_AB28		; loop if not [CR]

	JSR	LAB_AAE5		; toggle A, EOR #$FF. what is the point of this ??
	JMP	LAB_AB28		; loop


;************************************************************************************
;
; print [SPACE] or [CURSOR RIGHT]

LAB_AB3B
	LDA	LAB_13		; get current I/O channel
	BEQ	LAB_AB42		; if default channel go output [CURSOR RIGHT]

	LDA	#' '			; else output [SPACE]
	.byte	$2C			; makes next line BIT LAB_1DA9
LAB_AB42
	LDA	#$1D			; set [CURSOR RIGHT]
	.byte	$2C			; makes next line BIT LAB_3FA9


;************************************************************************************
;
; print "?"

LAB_AB45
	LDA	#'?'			; set "?"


;************************************************************************************
;
; print character

LAB_AB47
	JSR	LAB_E10C		; output character to channel with error check
	AND	#$FF			; set the flags on A
	RTS


;************************************************************************************
;
; bad input routine

LAB_AB4D
	LDA	LAB_11		; get INPUT mode flag, $00 = INPUT, $40 = GET, $98 = READ
	BEQ	LAB_AB62		; branch if INPUT

	BMI	LAB_AB57		; branch if READ

					; else was GET
	LDY	#$FF			; set current line high byte to -1, indicate immediate mode
	BNE	LAB_AB5B		; branch always

LAB_AB57
	LDA	LAB_3F		; get current DATA line number low byte
	LDY	LAB_40		; get current DATA line number high byte
LAB_AB5B
	STA	LAB_39		; set current line number low byte
	STY	LAB_3A		; set current line number high byte
LAB_AB5F
	JMP	LAB_AF08		; do syntax error then warm start

					; was INPUT
LAB_AB62
	LDA	LAB_13		; get current I/O channel
	BEQ	LAB_AB6B		; branch if default channel

	LDX	#$18			; else error $18, file data error
	JMP	LAB_A437		; do error #X then warm start

LAB_AB6B
	LDA	#<LAB_AD0C		; set "?REDO FROM START" pointer low byte
	LDY	#>LAB_AD0C		; set "?REDO FROM START" pointer high byte
	JSR	LAB_AB1E		; print null terminated string
	LDA	LAB_3D		; get continue pointer low byte
	LDY	LAB_3E		; get continue pointer high byte
	STA	LAB_7A		; save BASIC execute pointer low byte
	STY	LAB_7B		; save BASIC execute pointer high byte
	RTS


;************************************************************************************
;
; perform GET

LAB_AB7B
	JSR	LAB_B3A6		; check not Direct, back here if ok
	CMP	#'#'			; compare with "#"
	BNE	LAB_AB92		; branch if not GET#

	JSR	LAB_0073		; increment and scan memory
	JSR	LAB_B79E		; get byte parameter
	LDA	#','			; set ","
	JSR	LAB_AEFF		; scan for CHR$(A), else do syntax error then warm start
	STX	LAB_13		; set current I/O channel
	JSR	LAB_E11E		; open channel for input with error check
LAB_AB92
	LDX	#<LAB_0201		; set pointer low byte
	LDY	#>LAB_0201		; set pointer high byte
	LDA	#$00			; clear A
	STA	LAB_0201		; ensure null terminator
	LDA	#$40			; input mode = GET
	JSR	LAB_AC0F		; perform the GET part of READ
	LDX	LAB_13		; get current I/O channel
	BNE	LAB_ABB7		; if not default channel go do channel close and return

	RTS


;************************************************************************************
;
; perform INPUT#

LAB_ABA5
	JSR	LAB_B79E		; get byte parameter
	LDA	#','			; set ","
	JSR	LAB_AEFF		; scan for CHR$(A), else do syntax error then warm start
	STX	LAB_13		; set current I/O channel
	JSR	LAB_E11E		; open channel for input with error check
	JSR	LAB_ABCE		; perform INPUT with no prompt string


;************************************************************************************
;
; close input and output channels

LAB_ABB5
	LDA	LAB_13		; get current I/O channel
LAB_ABB7
	JSR	LAB_FFCC		; close input and output channels
	LDX	#$00			; clear X
	STX	LAB_13		; clear current I/O channel, flag default
	RTS


;************************************************************************************
;
; perform INPUT

LAB_ABBF
	CMP	#$22			; compare next byte with open quote
	BNE	LAB_ABCE		; if no prompt string just do INPUT

	JSR	LAB_AEBD		; print "..." string
	LDA	#';'			; load A with ";"
	JSR	LAB_AEFF		; scan for CHR$(A), else do syntax error then warm start
	JSR	LAB_AB21		; print string from utility pointer

					; done with prompt, now get data
LAB_ABCE
	JSR	LAB_B3A6		; check not Direct, back here if ok
	LDA	#','			; set ","
	STA	LAB_01FF		; save to start of buffer - 1
LAB_ABD6
	JSR	LAB_ABF9		; print "? " and get BASIC input
	LDA	LAB_13		; get current I/O channel
	BEQ	LAB_ABEA		; branch if default I/O channel

	JSR	LAB_FFB7		; read I/O status word
	AND	#$02			; mask no DSR/timeout
	BEQ	LAB_ABEA		; branch if not error

	JSR	LAB_ABB5		; close input and output channels
	JMP	LAB_A8F8		; perform DATA

LAB_ABEA
	LDA	LAB_0200		; get first byte in input buffer
	BNE	LAB_AC0D		; branch if not null

					; else ..
	LDA	LAB_13		; get current I/O channel
	BNE	LAB_ABD6		; if not default channel go get BASIC input

	JSR	LAB_A906		; scan for next BASIC statement ([:] or [EOL])
	JMP	LAB_A8FB		; add Y to the BASIC execute pointer and return


;************************************************************************************
;
; print "? " and get BASIC input

LAB_ABF9
	LDA	LAB_13		; get current I/O channel
	BNE	LAB_AC03		; skip "?" prompt if not default channel

	JSR	LAB_AB45		; print "?"
	JSR	LAB_AB3B		; print [SPACE] or [CURSOR RIGHT]
LAB_AC03
	JMP	LAB_A560		; call for BASIC input and return


;************************************************************************************
;
; perform READ

LAB_AC06
	LDX	LAB_41		; get DATA pointer low byte
	LDY	LAB_42		; get DATA pointer high byte
	LDA	#$98			; set input mode = READ
	.byte	$2C			; makes next line BIT LAB_00A9
LAB_AC0D
	LDA	#$00			; set input mode = INPUT


;************************************************************************************
;
; perform GET

LAB_AC0F
	STA	LAB_11		; set input mode flag, $00 = INPUT, $40 = GET, $98 = READ
	STX	LAB_43		; save READ pointer low byte
	STY	LAB_44		; save READ pointer high byte

					; READ, GET or INPUT next variable from list
LAB_AC15
	JSR	LAB_B08B		; get variable address
	STA	LAB_49		; save address low byte
	STY	LAB_4A		; save address high byte
	LDA	LAB_7A		; get BASIC execute pointer low byte
	LDY	LAB_7B		; get BASIC execute pointer high byte
	STA	LAB_4B		; save BASIC execute pointer low byte
	STY	LAB_4C		; save BASIC execute pointer high byte
	LDX	LAB_43		; get READ pointer low byte
	LDY	LAB_44		; get READ pointer high byte
	STX	LAB_7A		; save as BASIC execute pointer low byte
	STY	LAB_7B		; save as BASIC execute pointer high byte
	JSR	LAB_0079		; scan memory
	BNE	LAB_AC51		; branch if not null

					; pointer was to null entry
	BIT	LAB_11		; test input mode flag, $00 = INPUT, $40 = GET, $98 = READ
	BVC	LAB_AC41		; branch if not GET

					; else was GET
	JSR	LAB_E124		; get character from input device with error check
	STA	LAB_0200		; save to buffer
	LDX	#<LAB_01FF		; set pointer low byte
	LDY	#>LAB_01FF		; set pointer high byte
	BNE	LAB_AC4D		; go interpret single character

LAB_AC41
	BMI	LAB_ACB8		; branch if READ

					; else was INPUT
	LDA	LAB_13		; get current I/O channel
	BNE	LAB_AC4A		; skip "?" prompt if not default channel

	JSR	LAB_AB45		; print "?"
LAB_AC4A
	JSR	LAB_ABF9		; print "? " and get BASIC input
LAB_AC4D
	STX	LAB_7A		; save BASIC execute pointer low byte
	STY	LAB_7B		; save BASIC execute pointer high byte
LAB_AC51
	JSR	LAB_0073		; increment and scan memory, execute pointer now points to
					; start of next data or null terminator
	BIT	LAB_0D		; test data type flag, $FF = string, $00 = numeric
	BPL	LAB_AC89		; branch if numeric

					; type is string
	BIT	LAB_11		; test INPUT mode flag, $00 = INPUT, $40 = GET, $98 = READ
	BVC	LAB_AC65		; branch if not GET

					; else do string GET
	INX				; clear X ??
	STX	LAB_7A		; save BASIC execute pointer low byte
	LDA	#$00			; clear A
	STA	LAB_07		; clear search character
	BEQ	LAB_AC71		; branch always

					; is string INPUT or string READ
LAB_AC65
	STA	LAB_07		; save search character
	CMP	#$22			; compare with "
	BEQ	LAB_AC72		; branch if quote

					; string is not in quotes so ":", "," or $00 are the
					; termination characters
	LDA	#':'			; set ":"
	STA	LAB_07		; set search character
	LDA	#','			; set ","
LAB_AC71
	CLC				; clear carry for add
LAB_AC72
	STA	LAB_08		; set scan quotes flag
	LDA	LAB_7A		; get BASIC execute pointer low byte
	LDY	LAB_7B		; get BASIC execute pointer high byte
	ADC	#$00			; add to pointer low byte. this add increments the pointer
					; if the mode is INPUT or READ and the data is a "..."
					; string
	BCC	LAB_AC7D		; branch if no rollover

	INY				; else increment pointer high byte
LAB_AC7D
	JSR	LAB_B48D		; print string to utility pointer
	JSR	LAB_B7E2		; restore BASIC execute pointer from temp
	JSR	LAB_A9DA		; perform string LET
	JMP	LAB_AC91		; continue processing command

					; GET, INPUT or READ is numeric
LAB_AC89
	JSR	LAB_BCF3		; get FAC1 from string
	LDA	LAB_0E		; get data type flag, $80 = integer, $00 = float
	JSR	LAB_A9C2		; assign value to numeric variable
LAB_AC91
	JSR	LAB_0079		; scan memory
	BEQ	LAB_AC9D		; branch if ":" or [EOL]

	CMP	#','			; comparte with ","
	BEQ	LAB_AC9D		; branch if ","

	JMP	LAB_AB4D		; else go do bad input routine

					; string terminated with ":", "," or $00
LAB_AC9D
	LDA	LAB_7A		; get BASIC execute pointer low byte
	LDY	LAB_7B		; get BASIC execute pointer high byte
	STA	LAB_43		; save READ pointer low byte
	STY	LAB_44		; save READ pointer high byte
	LDA	LAB_4B		; get saved BASIC execute pointer low byte
	LDY	LAB_4C		; get saved BASIC execute pointer high byte
	STA	LAB_7A		; restore BASIC execute pointer low byte
	STY	LAB_7B		; restore BASIC execute pointer high byte
	JSR	LAB_0079		; scan memory
	BEQ	LAB_ACDF		; branch if ":" or [EOL]

	JSR	LAB_AEFD		; scan for ",", else do syntax error then warm start
	JMP	LAB_AC15		; go READ or INPUT next variable from list

					; was READ
LAB_ACB8
	JSR	LAB_A906		; scan for next BASIC statement ([:] or [EOL])
	INY				; increment index to next byte
	TAX				; copy byte to X
	BNE	LAB_ACD1		; branch if ":"

	LDX	#$0D			; else set error $0D, out of data error
	INY				; increment index to next line pointer high byte
	LDA	(LAB_7A),Y		; get next line pointer high byte
	BEQ	LAB_AD32		; branch if program end, eventually does error X

	INY				; increment index
	LDA	(LAB_7A),Y		; get next line # low byte
	STA	LAB_3F		; save current DATA line low byte
	INY				; increment index
	LDA	(LAB_7A),Y		; get next line # high byte
	INY				; increment index
	STA	LAB_40		; save current DATA line high byte
LAB_ACD1
	JSR	LAB_A8FB		; add Y to the BASIC execute pointer
	JSR	LAB_0079		; scan memory
	TAX				; copy the byte
	CPX	#TK_DATA		; compare it with token for DATA
	BNE	LAB_ACB8		; loop if not DATA

	JMP	LAB_AC51		; continue evaluating READ

LAB_ACDF
	LDA	LAB_43		; get READ pointer low byte
	LDY	LAB_44		; get READ pointer high byte
	LDX	LAB_11		; get INPUT mode flag, $00 = INPUT, $40 = GET, $98 = READ
	BPL	LAB_ACEA		; branch if INPUT or GET

	JMP	LAB_A827		; else set data pointer and exit

LAB_ACEA
	LDY	#$00			; clear index
	LDA	(LAB_43),Y		; get READ byte
	BEQ	LAB_ACFB		; exit if [EOL]

	LDA	LAB_13		; get current I/O channel
	BNE	LAB_ACFB		; exit if not default channel

	LDA	#<LAB_ACFC		; set "?EXTRA IGNORED" pointer low byte
	LDY	#>LAB_ACFC		; set "?EXTRA IGNORED" pointer high byte
	JMP	LAB_AB1E		; print null terminated string

LAB_ACFB
	RTS


;************************************************************************************
;
; input error messages

LAB_ACFC
	.byte	"?EXTRA IGNORED",$0D,$00

LAB_AD0C
	.byte	"?REDO FROM START",$0D,$00


;************************************************************************************
;
; perform NEXT

LAB_AD1E
	BNE	LAB_AD24		; branch if NEXT variable

	LDY	#$00			; else clear Y
	BEQ	LAB_AD27		; branch always

; NEXT variable

LAB_AD24
	JSR	LAB_B08B		; get variable address
LAB_AD27
	STA	LAB_49		; save FOR/NEXT variable pointer low byte
	STY	LAB_4A		; save FOR/NEXT variable pointer high byte
					; (high byte cleared if no variable defined)
	JSR	LAB_A38A		; search the stack for FOR or GOSUB activity
	BEQ	LAB_AD35		; branch if FOR, this variable, found

	LDX	#$0A			; else set error $0A, next without for error
LAB_AD32
	JMP	LAB_A437		; do error #X then warm start

					; found this FOR variable
LAB_AD35
	TXS				; update stack pointer
	TXA				; copy stack pointer
	CLC				; clear carry for add
	ADC	#$04			; point to STEP value
	PHA				; save it
	ADC	#$06			; point to TO value
	STA	LAB_24		; save pointer to TO variable for compare
	PLA				; restore pointer to STEP value
	LDY	#$01			; point to stack page
	JSR	LAB_BBA2		; unpack memory (AY) into FAC1
	TSX				; get stack pointer back
	LDA	LAB_0100+9,X	; get step sign
	STA	LAB_66		; save FAC1 sign (b7)
	LDA	LAB_49		; get FOR/NEXT variable pointer low byte
	LDY	LAB_4A		; get FOR/NEXT variable pointer high byte
	JSR	LAB_B867		; add FOR variable to FAC1
	JSR	LAB_BBD0		; pack FAC1 into FOR variable
	LDY	#$01			; point to stack page
	JSR	LAB_BC5D		; compare FAC1 with TO value
	TSX				; get stack pointer back
	SEC				; set carry for subtract
	SBC	LAB_0100+9,X	; subtract step sign
	BEQ	LAB_AD78		; branch if =, loop complete

					; loop back and do it all again
	LDA	LAB_0100+$0F,X	; get FOR line low byte
	STA	LAB_39		; save current line number low byte
	LDA	LAB_0110,X		; get FOR line high byte
	STA	LAB_3A		; save current line number high byte
	LDA	LAB_0112,X		; get BASIC execute pointer low byte
	STA	LAB_7A		; save BASIC execute pointer low byte
	LDA	LAB_0111,X		; get BASIC execute pointer high byte
	STA	LAB_7B		; save BASIC execute pointer high byte
LAB_AD75
	JMP	LAB_A7AE		; go do interpreter inner loop

; NEXT loop comlete

LAB_AD78
	TXA				; stack copy to A
	ADC	#$11			; add $12, $11 + carry, to dump FOR structure
	TAX				; copy back to index
	TXS				; copy to stack pointer
	JSR	LAB_0079		; scan memory
	CMP	#','			; compare with ","
	BNE	LAB_AD75		; if not "," go do interpreter inner loop

					; was "," so another NEXT variable to do
	JSR	LAB_0073		; increment and scan memory
	JSR	LAB_AD24		; do NEXT variable


;************************************************************************************
;
; evaluate expression and check type mismatch

LAB_AD8A
	JSR	LAB_AD9E		; evaluate expression

; check if source and destination are numeric

LAB_AD8D
	CLC
	.byte	$24			; makes next line BIT LAB_38

; check if source and destination are string

LAB_AD8F
	SEC				; destination is string

; type match check, set C for string, clear C for numeric

LAB_AD90
	BIT	LAB_0D		; test data type flag, $FF = string, $00 = numeric
	BMI	LAB_AD97		; branch if string

	BCS	LAB_AD99		; if destiantion is numeric do type missmatch error
LAB_AD96
	RTS

LAB_AD97
	BCS	LAB_AD96		; exit if destination is string

; do type missmatch error

LAB_AD99
	LDX	#$16			; error code $16, type missmatch error
	JMP	LAB_A437		; do error #X then warm start


;************************************************************************************
;
; evaluate expression

LAB_AD9E
	LDX	LAB_7A		; get BASIC execute pointer low byte
	BNE	LAB_ADA4		; skip next if not zero

	DEC	LAB_7B		; else decrement BASIC execute pointer high byte
LAB_ADA4
	DEC	LAB_7A		; decrement BASIC execute pointer low byte
	LDX	#$00			; set null precedence, flag done
	.byte	$24			; makes next line BIT LAB_48
LAB_ADA9
	PHA				; push compare evaluation byte if branch to here
	TXA				; copy precedence byte
	PHA				; push precedence byte
	LDA	#$01			; 2 bytes
	JSR	LAB_A3FB		; check room on stack for A*2 bytes
	JSR	LAB_AE83		; get value from line
	LDA	#$00			; clear A
	STA	LAB_4D		; clear comparrison evaluation flag
LAB_ADB8
	JSR	LAB_0079		; scan memory
LAB_ADBB
	SEC				; set carry for subtract
	SBC	#TK_GT		; subtract the token for ">"
	BCC	LAB_ADD7		; branch if < ">"

	CMP	#$03			; compare with ">" to +3
	BCS	LAB_ADD7		; branch if >= 3

					; was token for ">" "=" or "<"
	CMP	#$01			; compare with token for =
	ROL				; *2, b0 = carry (=1 if token was = or <)
	EOR	#$01			; toggle b0
	EOR	LAB_4D		; EOR with comparrison evaluation flag
	CMP	LAB_4D		; compare with comparrison evaluation flag
	BCC	LAB_AE30		; if < saved flag do syntax error then warm start

	STA	LAB_4D		; save new comparrison evaluation flag
	JSR	LAB_0073		; increment and scan memory
	JMP	LAB_ADBB		; go do next character

LAB_ADD7
	LDX	LAB_4D		; get comparrison evaluation flag
	BNE	LAB_AE07		; branch if compare function

	BCS	LAB_AE58		; go do functions

					; else was < TK_GT so is operator or lower
	ADC	#$07			; add # of operators (+, -, *, /, ^, AND or OR)
	BCC	LAB_AE58		; branch if < + operator

					; carry was set so token was +, -, *, /, ^, AND or OR
	ADC	LAB_0D		; add data type flag, $FF = string, $00 = numeric
	BNE	LAB_ADE8		; branch if not string or not + token

					; will only be $00 if type is string and token was +
	JMP	LAB_B63D		; add strings, string 1 is in the descriptor, string 2
					; is in line, and return

LAB_ADE8
	ADC	#$FF			; -1 (corrects for carry add)
	STA	LAB_22		; save it
	ASL				; *2
	ADC	LAB_22		; *3
	TAY				; copy to index
LAB_ADF0
	PLA				; pull previous precedence
	CMP	LAB_A080,Y		; compare with precedence byte
	BCS	LAB_AE5D		; branch if A >=

	JSR	LAB_AD8D		; check if source is numeric, else do type mismatch
LAB_ADF9
	PHA				; save precedence
LAB_ADFA
	JSR	LAB_AE20		; get vector, execute function then continue evaluation
	PLA				; restore precedence
	LDY	LAB_4B		; get precedence stacked flag
	BPL	LAB_AE19		; branch if stacked values

	TAX				; copy precedence, set flags
	BEQ	LAB_AE5B		; exit if done

	BNE	LAB_AE66		; else pop FAC2 and return, branch always

LAB_AE07
	LSR	LAB_0D		; clear data type flag, $FF = string, $00 = numeric
	TXA				; copy compare function flag
	ROL				; <<1, shift data type flag into b0, 1 = string, 0 = num
	LDX	LAB_7A		; get BASIC execute pointer low byte
	BNE	LAB_AE11		; branch if no underflow

	DEC	LAB_7B		; else decrement BASIC execute pointer high byte
LAB_AE11
	DEC	LAB_7A		; decrement BASIC execute pointer low byte
	LDY	#LAB_A09B-LAB_A080
					; set offset to = operator precedence entry
	STA	LAB_4D		; save new comparrison evaluation flag
	BNE	LAB_ADF0		; branch always

LAB_AE19
	CMP	LAB_A080,Y		; compare with stacked function precedence
	BCS	LAB_AE66		; if A >=, pop FAC2 and return

	BCC	LAB_ADF9		; else go stack this one and continue, branch always


;************************************************************************************
;
; get vector, execute function then continue evaluation

LAB_AE20
	LDA	LAB_A080+2,Y	; get function vector high byte
	PHA				; onto stack
	LDA	LAB_A080+1,Y	; get function vector low byte
	PHA				; onto stack
					; now push sign, round FAC1 and put on stack
	JSR	LAB_AE33		; function will return here, then the next RTS will call
					; the function
	LDA	LAB_4D		; get comparrison evaluation flag
	JMP	LAB_ADA9		; continue evaluating expression

LAB_AE30
	JMP	LAB_AF08		; do syntax error then warm start

LAB_AE33
	LDA	LAB_66		; get FAC1 sign (b7)
	LDX	LAB_A080,Y		; get precedence byte


;************************************************************************************
;
; push sign, round FAC1 and put on stack

LAB_AE38
	TAY				; copy sign
	PLA				; get return address low byte
	STA	LAB_22		; save it
	INC	LAB_22		; increment it as return-1 is pushed
					; note, no check is made on the high byte so if the calling
					; routine ever assembles to a page edge then this all goes
					; horribly wrong!
	PLA				; get return address high byte
	STA	LAB_23		; save it
	TYA				; restore sign
	PHA				; push sign


;************************************************************************************
;
; round FAC1 and put on stack

LAB_AE43
	JSR	LAB_BC1B		; round FAC1
	LDA	LAB_65		; get FAC1 mantissa 4
	PHA				; save it
	LDA	LAB_64		; get FAC1 mantissa 3
	PHA				; save it
	LDA	LAB_63		; get FAC1 mantissa 2
	PHA				; save it
	LDA	LAB_62		; get FAC1 mantissa 1
	PHA				; save it
	LDA	LAB_61		; get FAC1 exponent
	PHA				; save it
	JMP	(LAB_22)		; return, sort of


;************************************************************************************
;
; do functions

LAB_AE58
	LDY	#$FF			; flag function
	PLA				; pull precedence byte
LAB_AE5B
	BEQ	LAB_AE80		; exit if done

LAB_AE5D
	CMP	#$64			; compare previous precedence with $64
	BEQ	LAB_AE64		; branch if was $64 (< function)

	JSR	LAB_AD8D		; check if source is numeric, else do type mismatch
LAB_AE64
	STY	LAB_4B		; save precedence stacked flag

					; pop FAC2 and return
LAB_AE66
	PLA				; pop byte
	LSR				; shift out comparison evaluation lowest bit
	STA	LAB_12		; save the comparison evaluation flag
	PLA				; pop exponent
	STA	LAB_69		; save FAC2 exponent
	PLA				; pop mantissa 1
	STA	LAB_6A		; save FAC2 mantissa 1
	PLA				; pop mantissa 2
	STA	LAB_6B		; save FAC2 mantissa 2
	PLA				; pop mantissa 3
	STA	LAB_6C		; save FAC2 mantissa 3
	PLA				; pop mantissa 4
	STA	LAB_6D		; save FAC2 mantissa 4
	PLA				; pop sign
	STA	LAB_6E		; save FAC2 sign (b7)
	EOR	LAB_66		; EOR FAC1 sign (b7)
	STA	LAB_6F		; save sign compare (FAC1 EOR FAC2)
LAB_AE80
	LDA	LAB_61		; get FAC1 exponent
	RTS


;************************************************************************************
;
; get value from line

LAB_AE83
	JMP	(LAB_030A)		; get arithmetic element


;************************************************************************************
;
; get arithmetic element, the get arithmetic element vector is initialised to point here

LAB_AE86
	LDA	#$00			; clear byte
	STA	LAB_0D		; clear data type flag, $FF = string, $00 = numeric
LAB_AE8A
	JSR	LAB_0073		; increment and scan memory
	BCS	LAB_AE92		; branch if not numeric character

					; else numeric string found (e.g. 123)
LAB_AE8F
	JMP	LAB_BCF3		; get FAC1 from string and return

; get value from line .. continued

					; wasn't a number so ...
LAB_AE92
	JSR	LAB_B113		; check byte, return Cb = 0 if<"A" or >"Z"
	BCC	LAB_AE9A		; branch if not variable name

	JMP	LAB_AF28		; variable name set-up and return

LAB_AE9A
	CMP	#TK_PI		; compare with token for PI
	BNE	LAB_AEAD		; branch if not PI

	LDA	#<LAB_AEA8		; get PI pointer low byte
	LDY	#>LAB_AEA8		; get PI pointer high byte
	JSR	LAB_BBA2		; unpack memory (AY) into FAC1
	JMP	LAB_0073		; increment and scan memory and return


;************************************************************************************
;
; PI as floating number

LAB_AEA8
	.byte	$82,$49,$0F,$DA,$A1
					; 3.141592653


;************************************************************************************
;
; get value from line .. continued

					; wasn't variable name so ...
LAB_AEAD
	CMP	#'.'			; compare with "."
	BEQ	LAB_AE8F		; if so get FAC1 from string and return, e.g. was .123

					; wasn't .123 so ...
	CMP	#TK_MINUS		; compare with token for -
	BEQ	LAB_AF0D		; branch if - token, do set-up for functions

					; wasn't -123 so ...
	CMP	#TK_PLUS		; compare with token for +
	BEQ	LAB_AE8A		; branch if + token, +1 = 1 so ignore leading +

					; it wasn't any sort of number so ...
	CMP	#$22			; compare with "
	BNE	LAB_AECC		; branch if not open quote

					; was open quote so get the enclosed string


;************************************************************************************
;
; print "..." string to string utility area

LAB_AEBD
	LDA	LAB_7A		; get BASIC execute pointer low byte
	LDY	LAB_7B		; get BASIC execute pointer high byte
	ADC	#$00			; add carry to low byte
	BCC	LAB_AEC6		; branch if no overflow

	INY				; increment high byte
LAB_AEC6
	JSR	LAB_B487		; print " terminated string to utility pointer
	JMP	LAB_B7E2		; restore BASIC execute pointer from temp and return

; get value from line .. continued

					; wasn't a string so ...
LAB_AECC
	CMP	#TK_NOT		; compare with token for NOT
	BNE	LAB_AEE3		; branch if not token for NOT

					; was NOT token
	LDY	#$18			; offset to NOT function
	BNE	LAB_AF0F		; do set-up for function then execute, branch always

; do = compare

LAB_AED4
	JSR	LAB_B1BF		; evaluate integer expression, no sign check
	LDA	LAB_65		; get FAC1 mantissa 4
	EOR	#$FF			; invert it
	TAY				; copy it
	LDA	LAB_64		; get FAC1 mantissa 3
	EOR	#$FF			; invert it
	JMP	LAB_B391		; convert fixed integer AY to float FAC1 and return

; get value from line .. continued

					; wasn't a string or NOT so ...
LAB_AEE3
	CMP	#TK_FN		; compare with token for FN
	BNE	LAB_AEEA		; branch if not token for FN

	JMP	LAB_B3F4		; else go evaluate FNx

; get value from line .. continued

					; wasn't a string, NOT or FN so ...
LAB_AEEA
	CMP	#TK_SGN		; compare with token for SGN
	BCC	LAB_AEF1		; if less than SGN token evaluate expression in parentheses

					; else was a function token
	JMP	LAB_AFA7		; go set up function references, branch always

; get value from line .. continued
; if here it can only be something in brackets so ....

; evaluate expression within parentheses

LAB_AEF1
	JSR	LAB_AEFA		; scan for "(", else do syntax error then warm start
	JSR	LAB_AD9E		; evaluate expression

; all the 'scan for' routines return the character after the sought character

; scan for ")", else do syntax error then warm start

LAB_AEF7
	LDA	#')'			; load A with ")"
	.byte	$2C			; makes next line BIT LAB_28A9

; scan for "(", else do syntax error then warm start

LAB_AEFA
	LDA	#'('			; load A with "("
	.byte	$2C			; makes next line BIT LAB_2CA9

; scan for ",", else do syntax error then warm start

LAB_AEFD
	LDA	#','			; load A with ","

; scan for CHR$(A), else do syntax error then warm start

LAB_AEFF
	LDY	#$00			; clear index
	CMP	(LAB_7A),Y		; compare with BASIC byte
	BNE	LAB_AF08		; if not expected byte do syntax error then warm start

	JMP	LAB_0073		; else increment and scan memory and return

; syntax error then warm start

LAB_AF08
	LDX	#$0B			; error code $0B, syntax error
	JMP	LAB_A437		; do error #X then warm start

LAB_AF0D
	LDY	#$15			; set offset from base to > operator
LAB_AF0F
	PLA				; dump return address low byte
	PLA				; dump return address high byte
	JMP	LAB_ADFA		; execute function then continue evaluation


;************************************************************************************
;
; check address range, return Cb = 1 if address in BASIC ROM

LAB_AF14
	SEC				; set carry for subtract
	LDA	LAB_64		; get variable address low byte
	SBC	#<LAB_A000		; subtract LAB_A000 low byte
	LDA	LAB_65		; get variable address high byte
	SBC	#>LAB_A000		; subtract LAB_A000 high byte
	BCC	LAB_AF27		; exit if address < LAB_A000

	LDA	#<LAB_E3A2		; get end of BASIC marker low byte
	SBC	LAB_64		; subtract variable address low byte
	LDA	#>LAB_E3A2		; get end of BASIC marker high byte
	SBC	LAB_65		; subtract variable address high byte
LAB_AF27
	RTS


;************************************************************************************
;
; variable name set-up

LAB_AF28
	JSR	LAB_B08B		; get variable address
	STA	LAB_64		; save variable pointer low byte
	STY	LAB_65		; save variable pointer high byte
	LDX	LAB_45		; get current variable name first character
	LDY	LAB_46		; get current variable name second character
	LDA	LAB_0D		; get data type flag, $FF = string, $00 = numeric
	BEQ	LAB_AF5D		; branch if numeric

					; variable is string
	LDA	#$00			; else clear A
	STA	LAB_70		; clear FAC1 rounding byte
	JSR	LAB_AF14		; check address range
	BCC	LAB_AF5C		; exit if not in BASIC ROM

	CPX	#'T'			; compare variable name first character with "T"
	BNE	LAB_AF5C		; exit if not "T"

	CPY	#'I'+$80		; compare variable name second character with "I$"
	BNE	LAB_AF5C		; exit if not "I$"

					; variable name was "TI$"
	JSR	LAB_AF84		; read real time clock into FAC1 mantissa, 0HML
	STY	LAB_5E		; clear exponent count adjust
	DEY				; Y = $FF
	STY	LAB_71		; set output string index, -1 to allow for pre increment
	LDY	#$06			; HH:MM:SS is six digits
	STY	LAB_5D		; set number of characters before the decimal point
	LDY	#LAB_BF3A-LAB_BF16
					; index to jiffy conversion table
	JSR	LAB_BE68		; convert jiffy count to string
	JMP	LAB_B46F		; exit via STR$() code tail

LAB_AF5C
	RTS

					; variable name set-up, variable is numeric
LAB_AF5D
	BIT	LAB_0E		; test data type flag, $80 = integer, $00 = float
	BPL	LAB_AF6E		; branch if float

	LDY	#$00			; clear index
	LDA	(LAB_64),Y		; get integer variable low byte
	TAX				; copy to X
	INY				; increment index
	LDA	(LAB_64),Y		; get integer variable high byte
	TAY				; copy to Y
	TXA				; copy loa byte to A
	JMP	LAB_B391		; convert fixed integer AY to float FAC1 and return

					; variable name set-up, variable is float
LAB_AF6E
	JSR	LAB_AF14		; check address range
	BCC	LAB_AFA0		; if not in BASIC ROM get pointer and unpack into FAC1

	CPX	#'T'			; compare variable name first character with "T"
	BNE	LAB_AF92		; branch if not "T"

	CPY	#'I'			; compare variable name second character with "I"
	BNE	LAB_AFA0		; branch if not "I"

					; variable name was "TI"
	JSR	LAB_AF84		; read real time clock into FAC1 mantissa, 0HML
	TYA				; clear A
	LDX	#$A0			; set exponent to 32 bit value
	JMP	LAB_BC4F		; set exponent = X and normalise FAC1


;************************************************************************************
;
; read real time clock into FAC1 mantissa, 0HML

LAB_AF84
	JSR	LAB_FFDE		; read real time clock
	STX	LAB_64		; save jiffy clock mid byte as  FAC1 mantissa 3
	STY	LAB_63		; save jiffy clock high byte as  FAC1 mantissa 2
	STA	LAB_65		; save jiffy clock low byte as  FAC1 mantissa 4
	LDY	#$00			; clear Y
	STY	LAB_62		; clear FAC1 mantissa 1
	RTS

					; variable name set-up, variable is float and not "Tx"
LAB_AF92
	CPX	#'S'			; compare variable name first character with "S"
	BNE	LAB_AFA0		; if not "S" go do normal floating variable

	CPY	#'T'			; compare variable name second character with "
	BNE	LAB_AFA0		; if not "T" go do normal floating variable

					; variable name was "ST"
	JSR	LAB_FFB7		; read I/O status word
	JMP	LAB_BC3C		; save A as integer byte and return

					; variable is float
LAB_AFA0
	LDA	LAB_64		; get variable pointer low byte
	LDY	LAB_65		; get variable pointer high byte
	JMP	LAB_BBA2		; unpack memory (AY) into FAC1


;************************************************************************************
;
; get value from line continued
; only functions left so ..

; set up function references

LAB_AFA7
	ASL				; *2 (2 bytes per function address)
	PHA				; save function offset
	TAX				; copy function offset
	JSR	LAB_0073		; increment and scan memory
	CPX	#$8F			; compare function offset to CHR$ token offset+1
	BCC	LAB_AFD1		; branch if < LEFT$ (can not be =)

; get value from line .. continued
; was LEFT$, RIGHT$ or MID$ so..

	JSR	LAB_AEFA		; scan for "(", else do syntax error then warm start
	JSR	LAB_AD9E		; evaluate, should be string, expression
	JSR	LAB_AEFD		; scan for ",", else do syntax error then warm start
	JSR	LAB_AD8F		; check if source is string, else do type mismatch
	PLA				; restore function offset
	TAX				; copy it
	LDA	LAB_65		; get descriptor pointer high byte
	PHA				; push string pointer high byte
	LDA	LAB_64		; get descriptor pointer low byte
	PHA				; push string pointer low byte
	TXA				; restore function offset
	PHA				; save function offset
	JSR	LAB_B79E		; get byte parameter
	PLA				; restore function offset
	TAY				; copy function offset
	TXA				; copy byte parameter to A
	PHA				; push byte parameter
	JMP	LAB_AFD6		; go call function

; get value from line .. continued
; was SGN() to CHR$() so..

LAB_AFD1
	JSR	LAB_AEF1		; evaluate expression within parentheses
	PLA				; restore function offset
	TAY				; copy to index
LAB_AFD6
	LDA	LAB_A052-$68,Y	; get function jump vector low byte
	STA	LAB_55		; save functions jump vector low byte
	LDA	LAB_A052-$67,Y	; get function jump vector high byte
	STA	LAB_56		; save functions jump vector high byte
	JSR	LAB_54		; do function call
	JMP	LAB_AD8D		; check if source is numeric and RTS, else do type mismatch
					; string functions avoid this by dumping the return address


;************************************************************************************
;
; perform OR
; this works because NOT(NOT(x) AND NOT(y)) = x OR y

LAB_AFE6
	LDY	#$FF			; set Y for OR
	.byte	$2C			; makes next line BIT LAB_00A0


;************************************************************************************
;
; perform AND

LAB_AFE9
	LDY	#$00			; clear Y for AND
	STY	LAB_0B		; set AND/OR invert value
	JSR	LAB_B1BF		; evaluate integer expression, no sign check
	LDA	LAB_64		; get FAC1 mantissa 3
	EOR	LAB_0B		; EOR low byte
	STA	LAB_07		; save it
	LDA	LAB_65		; get FAC1 mantissa 4
	EOR	LAB_0B		; EOR high byte
	STA	LAB_08		; save it
	JSR	LAB_BBFC		; copy FAC2 to FAC1, get 2nd value in expression
	JSR	LAB_B1BF		; evaluate integer expression, no sign check
	LDA	LAB_65		; get FAC1 mantissa 4
	EOR	LAB_0B		; EOR high byte
	AND	LAB_08		; AND with expression 1 high byte
	EOR	LAB_0B		; EOR result high byte
	TAY				; save in Y
	LDA	LAB_64		; get FAC1 mantissa 3
	EOR	LAB_0B		; EOR low byte
	AND	LAB_07		; AND with expression 1 low byte
	EOR	LAB_0B		; EOR result low byte
	JMP	LAB_B391		; convert fixed integer AY to float FAC1 and return


;************************************************************************************
;
; perform comparisons

; do < compare

LAB_B016
	JSR	LAB_AD90		; type match check, set C for string
	BCS	LAB_B02E		; branch if string

					; do numeric < compare
	LDA	LAB_6E		; get FAC2 sign (b7)
	ORA	#$7F			; set all non sign bits
	AND	LAB_6A		; and FAC2 mantissa 1 (AND in sign bit)
	STA	LAB_6A		; save FAC2 mantissa 1
	LDA	#<LAB_69		; set pointer low byte to FAC2
	LDY	#>LAB_69		; set pointer high byte to FAC2
	JSR	LAB_BC5B		; compare FAC1 with (AY)
	TAX				; copy the result
	JMP	LAB_B061		; go evaluate result

					; do string < compare
LAB_B02E
	LDA	#$00			; clear byte
	STA	LAB_0D		; clear data type flag, $FF = string, $00 = numeric
	DEC	LAB_4D		; clear < bit in comparrison evaluation flag
	JSR	LAB_B6A6		; pop string off descriptor stack, or from top of string
					; space returns with A = length, X = pointer low byte,
					; Y = pointer high byte
	STA	LAB_61		; save length
	STX	LAB_62		; save string pointer low byte
	STY	LAB_63		; save string pointer high byte
	LDA	LAB_6C		; get descriptor pointer low byte
	LDY	LAB_6D		; get descriptor pointer high byte
	JSR	LAB_B6AA		; pop (YA) descriptor off stack or from top of string space
					; returns with A = length, X = pointer low byte,
					; Y = pointer high byte
	STX	LAB_6C		; save string pointer low byte
	STY	LAB_6D		; save string pointer high byte
	TAX				; copy length
	SEC				; set carry for subtract
	SBC	LAB_61		; subtract string 1 length
	BEQ	LAB_B056		; branch if str 1 length = string 2 length

	LDA	#$01			; set str 1 length > string 2 length
	BCC	LAB_B056		; branch if so

	LDX	LAB_61		; get string 1 length
	LDA	#$FF			; set str 1 length < string 2 length
LAB_B056
	STA	LAB_66		; save length compare
	LDY	#$FF			; set index
	INX				; adjust for loop
LAB_B05B
	INY				; increment index
	DEX				; decrement count
	BNE	LAB_B066		; branch if still bytes to do

	LDX	LAB_66		; get length compare back
LAB_B061
	BMI	LAB_B072		; branch if str 1 < str 2

	CLC				; flag str 1 <= str 2
	BCC	LAB_B072		; go evaluate result

LAB_B066
	LDA	(LAB_6C),Y		; get string 2 byte
	CMP	(LAB_62),Y		; compare with string 1 byte
	BEQ	LAB_B05B		; loop if bytes =

	LDX	#$FF			; set str 1 < string 2
	BCS	LAB_B072		; branch if so

	LDX	#$01			; set str 1 > string 2
LAB_B072
	INX				; x = 0, 1 or 2
	TXA				; copy to A
	ROL				; * 2 (1, 2 or 4)
	AND	LAB_12		; AND with the comparison evaluation flag
	BEQ	LAB_B07B		; branch if 0 (compare is false)

	LDA	#$FF			; else set result true
LAB_B07B
	JMP	LAB_BC3C		; save A as integer byte and return

LAB_B07E
	JSR	LAB_AEFD		; scan for ",", else do syntax error then warm start


;************************************************************************************
;
; perform DIM

LAB_B081
	TAX				; copy "DIM" flag to X
	JSR	LAB_B090		; search for variable
	JSR	LAB_0079		; scan memory
	BNE	LAB_B07E		; scan for "," and loop if not null

	RTS


;************************************************************************************
;
; search for variable

LAB_B08B
	LDX	#$00			; set DIM flag = $00
	JSR	LAB_0079		; scan memory, 1st character
LAB_B090
	STX	LAB_0C		; save DIM flag
LAB_B092
	STA	LAB_45		; save 1st character
	JSR	LAB_0079		; scan memory
	JSR	LAB_B113		; check byte, return Cb = 0 if<"A" or >"Z"
	BCS	LAB_B09F		; branch if ok

LAB_B09C
	JMP	LAB_AF08		; else syntax error then warm start

					; was variable name so ...
LAB_B09F
	LDX	#$00			; clear 2nd character temp
	STX	LAB_0D		; clear data type flag, $FF = string, $00 = numeric
	STX	LAB_0E		; clear data type flag, $80 = integer, $00 = float
	JSR	LAB_0073		; increment and scan memory, 2nd character
	BCC	LAB_B0AF		; if character = "0"-"9" (ok) go save 2nd character

					; 2nd character wasn't "0" to "9" so ...
	JSR	LAB_B113		; check byte, return Cb = 0 if<"A" or >"Z"
	BCC	LAB_B0BA		; branch if <"A" or >"Z" (go check if string)

LAB_B0AF
	TAX				; copy 2nd character

					; ignore further (valid) characters in the variable name
LAB_B0B0
	JSR	LAB_0073		; increment and scan memory, 3rd character
	BCC	LAB_B0B0		; loop if character = "0"-"9" (ignore)

	JSR	LAB_B113		; check byte, return Cb = 0 if<"A" or >"Z"
	BCS	LAB_B0B0		; loop if character = "A"-"Z" (ignore)

					; check if string variable
LAB_B0BA
	CMP	#'$'			; compare with "$"
	BNE	LAB_B0C4		; branch if not string

					; type is string
	LDA	#$FF			; set data type = string
	STA	LAB_0D		; set data type flag, $FF = string, $00 = numeric
	BNE	LAB_B0D4		; branch always

LAB_B0C4
	CMP	#'%'			; compare with "%"
	BNE	LAB_B0DB		; branch if not integer

	LDA	LAB_10		; get subscript/FNX flag
	BNE	LAB_B09C		; if ?? do syntax error then warm start

	LDA	#$80			; set integer type
	STA	LAB_0E		; set data type = integer
	ORA	LAB_45		; OR current variable name first byte
	STA	LAB_45		; save current variable name first byte
LAB_B0D4
	TXA				; get 2nd character back
	ORA	#$80			; set top bit, indicate string or integer variable
	TAX				; copy back to 2nd character temp
	JSR	LAB_0073		; increment and scan memory
LAB_B0DB
	STX	LAB_46		; save 2nd character
	SEC				; set carry for subtract
	ORA	LAB_10		; or with subscript/FNX flag - or FN name
	SBC	#'('			; subtract "("
	BNE	LAB_B0E7		; branch if not "("

	JMP	LAB_B1D1		; go find, or make, array

; either find or create variable

					; variable name wasn't xx(.... so look for plain variable
LAB_B0E7
	LDY	#$00			; clear A
	STY	LAB_10		; clear subscript/FNX flag
	LDA	LAB_2D		; get start of variables low byte
	LDX	LAB_2E		; get start of variables high byte
LAB_B0EF
	STX	LAB_60		; save search address high byte
LAB_B0F1
	STA	LAB_5F		; save search address low byte
	CPX	LAB_30		; compare with end of variables high byte
	BNE	LAB_B0FB		; skip next compare if <>

					; high addresses were = so compare low addresses
	CMP	LAB_2F		; compare low address with end of variables low byte
	BEQ	LAB_B11D		; if not found go make new variable

LAB_B0FB
	LDA	LAB_45		; get 1st character of variable to find
	CMP	(LAB_5F),Y		; compare with variable name 1st character
	BNE	LAB_B109		; branch if no match

					; 1st characters match so compare 2nd character
	LDA	LAB_46		; get 2nd character of variable to find
	INY				; index to point to variable name 2nd character
	CMP	(LAB_5F),Y		; compare with variable name 2nd character
	BEQ	LAB_B185		; branch if match (found variable)

	DEY				; else decrement index (now = $00)
LAB_B109
	CLC				; clear carry for add
	LDA	LAB_5F		; get search address low byte
	ADC	#$07			; +7, offset to next variable name
	BCC	LAB_B0F1		; loop if no overflow to high byte

	INX				; else increment high byte
	BNE	LAB_B0EF		; loop always, RAM doesn't extend to $FFFF

; check byte, return Cb = 0 if<"A" or >"Z"

LAB_B113
	CMP	#$41			; compare with "A"
	BCC	LAB_B11C		; exit if less

					; carry is set
	SBC	#$5B			; subtract "Z"+1
	SEC				; set carry
	SBC	#$A5			; subtract $A5 (restore byte)
					; carry clear if byte > $5A
LAB_B11C
	RTS

					; reached end of variable memory without match
					; ... so create new variable
LAB_B11D
	PLA				; pop return address low byte
	PHA				; push return address low byte
LAB_AF28p2	= LAB_AF28+2
	CMP	#<LAB_AF28p2	; compare with expected calling routine return low byte
	BNE	LAB_B128		; if not get variable go create new variable

; this will only drop through if the call was from LAB_AF28 and is only called
; from there if it is searching for a variable from the right hand side of a LET a=b
; statement, it prevents the creation of variables not assigned a value.

; value returned by this is either numeric zero, exponent byte is $00, or null string,
; descriptor length byte is $00. in fact a pointer to any $00 byte would have done.

					; else return dummy null value
LAB_B123
	LDA	#<LAB_BF13		; set result pointer low byte
	LDY	#>LAB_BF13		; set result pointer high byte
	RTS

					; create new numeric variable
LAB_B128
	LDA	LAB_45		; get variable name first character
	LDY	LAB_46		; get variable name second character
	CMP	#'T'			; compare first character with "T"
	BNE	LAB_B13B		; branch if not "T"

	CPY	#'I'+$80		; compare second character with "I$"
	BEQ	LAB_B123		; if "I$" return null value

	CPY	#'I'			; compare second character with "I"
	BNE	LAB_B13B		; branch if not "I"

					; if name is "TI" do syntax error
LAB_B138
	JMP	LAB_AF08		; do syntax error then warm start

LAB_B13B
	CMP	#'S'			; compare first character with "S"
	BNE	LAB_B143		; branch if not "S"

	CPY	#'T'			; compare second character with "T"
	BEQ	LAB_B138		; if name is "ST" do syntax error

LAB_B143
	LDA	LAB_2F		; get end of variables low byte
	LDY	LAB_30		; get end of variables high byte
	STA	LAB_5F		; save old block start low byte
	STY	LAB_60		; save old block start high byte
	LDA	LAB_31		; get end of arrays low byte
	LDY	LAB_32		; get end of arrays high byte
	STA	LAB_5A		; save old block end low byte
	STY	LAB_5B		; save old block end high byte
	CLC				; clear carry for add
	ADC	#$07			; +7, space for one variable
	BCC	LAB_B159		; branch if no overflow to high byte

	INY				; else increment high byte
LAB_B159
	STA	LAB_58		; set new block end low byte
	STY	LAB_59		; set new block end high byte
	JSR	LAB_A3B8		; open up space in memory
	LDA	LAB_58		; get new start low byte
	LDY	LAB_59		; get new start high byte (-$100)
	INY				; correct high byte
	STA	LAB_2F		; set end of variables low byte
	STY	LAB_30		; set end of variables high byte
	LDY	#$00			; clear index
	LDA	LAB_45		; get variable name 1st character
	STA	(LAB_5F),Y		; save variable name 1st character
	INY				; increment index
	LDA	LAB_46		; get variable name 2nd character
	STA	(LAB_5F),Y		; save variable name 2nd character
	LDA	#$00			; clear A
	INY				; increment index
	STA	(LAB_5F),Y		; initialise variable byte
	INY				; increment index
	STA	(LAB_5F),Y		; initialise variable byte
	INY				; increment index
	STA	(LAB_5F),Y		; initialise variable byte
	INY				; increment index
	STA	(LAB_5F),Y		; initialise variable byte
	INY				; increment index
	STA	(LAB_5F),Y		; initialise variable byte

					; found a match for variable
LAB_B185
	LDA	LAB_5F		; get variable address low byte
	CLC				; clear carry for add
	ADC	#$02			; +2, offset past variable name bytes
	LDY	LAB_60		; get variable address high byte
	BCC	LAB_B18F		; branch if no overflow from add

	INY				; else increment high byte
LAB_B18F
	STA	LAB_47		; save current variable pointer low byte
	STY	LAB_48		; save current variable pointer high byte
	RTS

; set-up array pointer to first element in array

LAB_B194
	LDA	LAB_0B		; get # of dimensions (1, 2 or 3)
	ASL				; *2 (also clears the carry !)
	ADC	#$05			; +5 (result is 7, 9 or 11 here)
	ADC	LAB_5F		; add array start pointer low byte
	LDY	LAB_60		; get array pointer high byte
	BCC	LAB_B1A0		; branch if no overflow

	INY				; else increment high byte
LAB_B1A0
	STA	LAB_58		; save array data pointer low byte
	STY	LAB_59		; save array data pointer high byte
	RTS


;************************************************************************************
;
; -32768 as floating value

LAB_B1A5
	.byte	$90,$80,$00,$00,$00	; -32768


;************************************************************************************
;
; convert float to fixed

LAB_B1AA
	JSR	LAB_B1BF		; evaluate integer expression, no sign check
	LDA	LAB_64		; get result low byte
	LDY	LAB_65		; get result high byte
	RTS


;************************************************************************************
;
; evaluate integer expression

LAB_B1B2
	JSR	LAB_0073		; increment and scan memory
	JSR	LAB_AD9E		; evaluate expression

; evaluate integer expression, sign check

LAB_B1B8
	JSR	LAB_AD8D		; check if source is numeric, else do type mismatch
	LDA	LAB_66		; get FAC1 sign (b7)
	BMI	LAB_B1CC		; do illegal quantity error if -ve

; evaluate integer expression, no sign check

LAB_B1BF
	LDA	LAB_61		; get FAC1 exponent
	CMP	#$90			; compare with exponent = 2^16 (n>2^15)
	BCC	LAB_B1CE		; if n<2^16 go convert FAC1 floating to fixed and return

	LDA	#<LAB_B1A5		; set pointer low byte to -32768
	LDY	#>LAB_B1A5		; set pointer high byte to -32768
	JSR	LAB_BC5B		; compare FAC1 with (AY)
LAB_B1CC
	BNE	LAB_B248		; if <> do illegal quantity error then warm start

LAB_B1CE
	JMP	LAB_BC9B		; convert FAC1 floating to fixed and return


;************************************************************************************
;
; an array is stored as follows
;
; array name			; two bytes with the following patterns for different types
;					; 1st char	2nd char
;					;   b7	  b7		type			element size
;					; --------	--------	-----			------------
;					;   0		  0		floating point	 5
;					;   0		  1		string		 3
;					;   1		  1		integer		 2
; offset to next array		; word
; dimension count			; byte
; 1st dimension size		; word, this is the number of elements including 0
; 2nd dimension size		; word, only here if the array has a second dimension
; 2nd dimension size		; word, only here if the array has a third dimension
;					; note: the dimension size word is in high byte low byte
;					; format, not like most 6502 words
; then for each element the required number of bytes given as the element size above

; find or make array

LAB_B1D1
	LDA	LAB_0C		; get DIM flag
	ORA	LAB_0E		; OR with data type flag
	PHA				; push it
	LDA	LAB_0D		; get data type flag, $FF = string, $00 = numeric
	PHA				; push it
	LDY	#$00			; clear dimensions count

; now get the array dimension(s) and stack it (them) before the data type and DIM flag

LAB_B1DB
	TYA				; copy dimensions count
	PHA				; save it
	LDA	LAB_46		; get array name 2nd byte
	PHA				; save it
	LDA	LAB_45		; get array name 1st byte
	PHA				; save it
	JSR	LAB_B1B2		; evaluate integer expression
	PLA				; pull array name 1st byte
	STA	LAB_45		; restore array name 1st byte
	PLA				; pull array name 2nd byte
	STA	LAB_46		; restore array name 2nd byte
	PLA				; pull dimensions count
	TAY				; restore it
	TSX				; copy stack pointer
	LDA	LAB_0100+2,X	; get DIM flag
	PHA				; push it
	LDA	LAB_0100+1,X	; get data type flag
	PHA				; push it
	LDA	LAB_64		; get this dimension size high byte
	STA	LAB_0100+2,X	; stack before flag bytes
	LDA	LAB_65		; get this dimension size low byte
	STA	LAB_0100+1,X	; stack before flag bytes
	INY				; increment dimensions count
	JSR	LAB_0079		; scan memory
	CMP	#','			; compare with ","
	BEQ	LAB_B1DB		; if found go do next dimension

	STY	LAB_0B		; store dimensions count
	JSR	LAB_AEF7		; scan for ")", else do syntax error then warm start
	PLA				; pull data type flag
	STA	LAB_0D		; restore data type flag, $FF = string, $00 = numeric
	PLA				; pull data type flag
	STA	LAB_0E		; restore data type flag, $80 = integer, $00 = float
	AND	#$7F			; mask dim flag
	STA	LAB_0C		; restore DIM flag
	LDX	LAB_2F		; set end of variables low byte
					; (array memory start low byte)
	LDA	LAB_30		; set end of variables high byte
					; (array memory start high byte)

; now check to see if we are at the end of array memory, we would be if there were
; no arrays.

LAB_B21C
	STX	LAB_5F		; save as array start pointer low byte
	STA	LAB_60		; save as array start pointer high byte
	CMP	LAB_32		; compare with end of arrays high byte
	BNE	LAB_B228		; branch if not reached array memory end

	CPX	LAB_31		; else compare with end of arrays low byte
	BEQ	LAB_B261		; go build array if not found

					; search for array
LAB_B228
	LDY	#$00			; clear index
	LDA	(LAB_5F),Y		; get array name first byte
	INY				; increment index to second name byte
	CMP	LAB_45		; compare with this array name first byte
	BNE	LAB_B237		; branch if no match

	LDA	LAB_46		; else get this array name second byte
	CMP	(LAB_5F),Y		; compare with array name second byte
	BEQ	LAB_B24D		; array found so branch

					; no match
LAB_B237
	INY				; increment index
	LDA	(LAB_5F),Y		; get array size low byte
	CLC				; clear carry for add
	ADC	LAB_5F		; add array start pointer low byte
	TAX				; copy low byte to X
	INY				; increment index
	LDA	(LAB_5F),Y		; get array size high byte
	ADC	LAB_60		; add array memory pointer high byte
	BCC	LAB_B21C		; if no overflow go check next array


;************************************************************************************
;
; do bad subscript error

LAB_B245
	LDX	#$12			; error $12, bad subscript error
	.byte	$2C			; makes next line BIT LAB_0EA2


;************************************************************************************
;
; do illegal quantity error

LAB_B248
	LDX	#$0E			; error $0E, illegal quantity error
LAB_B24A
	JMP	LAB_A437		; do error #X then warm start


;************************************************************************************
;
; found the array

LAB_B24D
	LDX	#$13			; set error $13, double dimension error
	LDA	LAB_0C		; get DIM flag
	BNE	LAB_B24A		; if we are trying to dimension it do error #X then warm
					; start

; found the array and we're not dimensioning it so we must find an element in it

	JSR	LAB_B194		; set-up array pointer to first element in array
	LDA	LAB_0B		; get dimensions count
	LDY	#$04			; set index to array's # of dimensions
	CMP	(LAB_5F),Y		; compare with no of dimensions
	BNE	LAB_B245		; if wrong do bad subscript error

	JMP	LAB_B2EA		; found array so go get element

					; array not found, so build it
LAB_B261
	JSR	LAB_B194		; set-up array pointer to first element in array
	JSR	LAB_A408		; check available memory, do out of memory error if no room
	LDY	#$00			; clear Y
	STY	LAB_72		; clear array data size high byte
	LDX	#$05			; set default element size
	LDA	LAB_45		; get variable name 1st byte
	STA	(LAB_5F),Y		; save array name 1st byte
	BPL	LAB_B274		; branch if not string or floating point array

	DEX				; decrement element size, $04
LAB_B274
	INY				; increment index
	LDA	LAB_46		; get variable name 2nd byte
	STA	(LAB_5F),Y		; save array name 2nd byte
	BPL	LAB_B27D		; branch if not integer or string

	DEX				; decrement element size, $03
	DEX				; decrement element size, $02
LAB_B27D
	STX	LAB_71		; save element size
	LDA	LAB_0B		; get dimensions count
	INY				; increment index ..
	INY				; .. to array  ..
	INY				; .. dimension count
	STA	(LAB_5F),Y		; save array dimension count
LAB_B286
	LDX	#$0B			; set default dimension size low byte
	LDA	#$00			; set default dimension size high byte
	BIT	LAB_0C		; test DIM flag
	BVC	LAB_B296		; branch if default to be used

	PLA				; pull dimension size low byte
	CLC				; clear carry for add
	ADC	#$01			; add 1, allow for zeroeth element
	TAX				; copy low byte to X
	PLA				; pull dimension size high byte
	ADC	#$00			; add carry to high byte
LAB_B296
	INY				; incement index to dimension size high byte
	STA	(LAB_5F),Y		; save dimension size high byte
	INY				; incement index to dimension size low byte
	TXA				; copy dimension size low byte
	STA	(LAB_5F),Y		; save dimension size low byte
	JSR	LAB_B34C		; compute array size
	STX	LAB_71		; save result low byte
	STA	LAB_72		; save result high byte
	LDY	LAB_22		; restore index
	DEC	LAB_0B		; decrement dimensions count
	BNE	LAB_B286		; loop if not all done

	ADC	LAB_59		; add array data pointer high byte
	BCS	LAB_B30B		; if overflow do out of memory error then warm start

	STA	LAB_59		; save array data pointer high byte
	TAY				; copy array data pointer high byte
	TXA				; copy array size low byte
	ADC	LAB_58		; add array data pointer low byte
	BCC	LAB_B2B9		; branch if no rollover

	INY				; else increment next array pointer high byte
	BEQ	LAB_B30B		; if rolled over do out of memory error then warm start

LAB_B2B9
	JSR	LAB_A408		; check available memory, do out of memory error if no room
	STA	LAB_31		; set end of arrays low byte
	STY	LAB_32		; set end of arrays high byte

; now the aray is created we need to zero all the elements in it

	LDA	#$00			; clear A for array clear
	INC	LAB_72		; increment array size high byte, now block count
	LDY	LAB_71		; get array size low byte, now index to block
	BEQ	LAB_B2CD		; branch if $00
LAB_B2C8
	DEY				; decrement index, do 0 to n-1
	STA	(LAB_58),Y		; clear array element byte
	BNE	LAB_B2C8		; loop until this block done

LAB_B2CD
	DEC	LAB_59		; decrement array pointer high byte
	DEC	LAB_72		; decrement block count high byte
	BNE	LAB_B2C8		; loop until all blocks done

	INC	LAB_59		; correct for last loop
	SEC				; set carry for subtract
	LDA	LAB_31		; get end of arrays low byte
	SBC	LAB_5F		; subtract array start low byte
	LDY	#$02			; index to array size low byte
	STA	(LAB_5F),Y		; save array size low byte
	LDA	LAB_32		; get end of arrays high byte
	INY				; index to array size high byte
	SBC	LAB_60		; subtract array start high byte
	STA	(LAB_5F),Y		; save array size high byte
	LDA	LAB_0C		; get default DIM flag
	BNE	LAB_B34B		; exit if this was a DIM command

					; else, find element
	INY				; set index to # of dimensions, the dimension indeces
					; are on the stack and will be removed as the position
					; of the array element is calculated

LAB_B2EA
	LDA	(LAB_5F),Y		; get array's dimension count
	STA	LAB_0B		; save it
	LDA	#$00			; clear byte
	STA	LAB_71		; clear array data pointer low byte
LAB_B2F2
	STA	LAB_72		; save array data pointer high byte
	INY				; increment index, point to array bound high byte
	PLA				; pull array index low byte
	TAX				; copy to X
	STA	LAB_64		; save index low byte to FAC1 mantissa 3
	PLA				; pull array index high byte
	STA	LAB_65		; save index high byte to FAC1 mantissa 4
	CMP	(LAB_5F),Y		; compare with array bound high byte
	BCC	LAB_B30E		; branch if within bounds

	BNE	LAB_B308		; if outside bounds do bad subscript error

					; else high byte was = so test low bytes
	INY				; index to array bound low byte
	TXA				; get array index low byte
	CMP	(LAB_5F),Y		; compare with array bound low byte
	BCC	LAB_B30F		; branch if within bounds

LAB_B308
	JMP	LAB_B245		; do bad subscript error

LAB_B30B
	JMP	LAB_A435		; do out of memory error then warm start

LAB_B30E
	INY				; index to array bound low byte
LAB_B30F
	LDA	LAB_72		; get array data pointer high byte
	ORA	LAB_71		; OR with array data pointer low byte
	CLC				; clear carry for either add, carry always clear here ??
	BEQ	LAB_B320		; branch if array data pointer = null, skip multiply

	JSR	LAB_B34C		; compute array size
	TXA				; get result low byte
	ADC	LAB_64		; add index low byte from FAC1 mantissa 3
	TAX				; save result low byte
	TYA				; get result high byte
	LDY	LAB_22		; restore index
LAB_B320
	ADC	LAB_65		; add index high byte from FAC1 mantissa 4
	STX	LAB_71		; save array data pointer low byte
	DEC	LAB_0B		; decrement dimensions count
	BNE	LAB_B2F2		; loop if dimensions still to do

	STA	LAB_72		; save array data pointer high byte
	LDX	#$05			; set default element size
	LDA	LAB_45		; get variable name 1st byte
	BPL	LAB_B331		; branch if not string or floating point array

	DEX				; decrement element size, $04
LAB_B331
	LDA	LAB_46		; get variable name 2nd byte
	BPL	LAB_B337		; branch if not integer or string

	DEX				; decrement element size, $03
	DEX				; decrement element size, $02
LAB_B337
	STX	LAB_28		; save dimension size low byte
	LDA	#$00			; clear dimension size high byte
	JSR	LAB_B355		; compute array size
	TXA				; copy array size low byte
	ADC	LAB_58		; add array data start pointer low byte
	STA	LAB_47		; save as current variable pointer low byte
	TYA				; copy array size high byte
	ADC	LAB_59		; add array data start pointer high byte
	STA	LAB_48		; save as current variable pointer high byte
	TAY				; copy high byte to Y
	LDA	LAB_47		; get current variable pointer low byte
					; pointer to element is now in AY
LAB_B34B
	RTS

; compute array size, result in XY

LAB_B34C
	STY	LAB_22		; save index
	LDA	(LAB_5F),Y		; get dimension size low byte
	STA	LAB_28		; save dimension size low byte
	DEY				; decrement index
	LDA	(LAB_5F),Y		; get dimension size high byte
LAB_B355
	STA	LAB_29		; save dimension size high byte
	LDA	#$10			; count = $10 (16 bit multiply)
	STA	LAB_5D		; save bit count
	LDX	#$00			; clear result low byte
	LDY	#$00			; clear result high byte
LAB_B35F
	TXA				; get result low byte
	ASL				; *2
	TAX				; save result low byte
	TYA				; get result high byte
	ROL				; *2
	TAY				; save result high byte
	BCS	LAB_B30B		; if overflow go do "Out of memory" error

	ASL	LAB_71		; shift element size low byte
	ROL	LAB_72		; shift element size high byte
	BCC	LAB_B378		; skip add if no carry

	CLC				; else clear carry for add
	TXA				; get result low byte
	ADC	LAB_28		; add dimension size low byte
	TAX				; save result low byte
	TYA				; get result high byte
	ADC	LAB_29		; add dimension size high byte
	TAY				; save result high byte
	BCS	LAB_B30B		; if overflow go do "Out of memory" error

LAB_B378
	DEC	LAB_5D		; decrement bit count
	BNE	LAB_B35F		; loop until all done

	RTS

; perform FRE()

LAB_B37D
	LDA	LAB_0D		; get data type flag, $FF = string, $00 = numeric
	BEQ	LAB_B384		; branch if numeric

	JSR	LAB_B6A6		; pop string off descriptor stack, or from top of string
					; space returns with A = length, X=$71=pointer low byte,
					; Y=$72=pointer high byte

					; FRE(n) was numeric so do this
LAB_B384
	JSR	LAB_B526		; go do garbage collection
	SEC				; set carry for subtract
	LDA	LAB_33		; get bottom of string space low byte
	SBC	LAB_31		; subtract end of arrays low byte
	TAY				; copy result to Y
	LDA	LAB_34		; get bottom of string space high byte
	SBC	LAB_32		; subtract end of arrays high byte


;************************************************************************************
;
; convert fixed integer AY to float FAC1

LAB_B391
	LDX	#$00			; set type = numeric
	STX	LAB_0D		; clear data type flag, $FF = string, $00 = numeric
	STA	LAB_62		; save FAC1 mantissa 1
	STY	LAB_63		; save FAC1 mantissa 2
	LDX	#$90			; set exponent=2^16 (integer)
	JMP	LAB_BC44		; set exp = X, clear FAC1 3 and 4, normalise and return


;************************************************************************************
;
; perform POS()

LAB_B39E
	SEC				; set Cb for read cursor position
	JSR	LAB_FFF0		; read/set X,Y cursor position
LAB_B3A2
	LDA	#$00			; clear high byte
	BEQ	LAB_B391		; convert fixed integer AY to float FAC1, branch always

; check not Direct, used by DEF and INPUT

LAB_B3A6
	LDX	LAB_3A		; get current line number high byte
	INX				; increment it
	BNE	LAB_B34B		; return if not direct mode

					; else do illegal direct error
	LDX	#$15			; error $15, illegal direct error
	.byte	$2C			; makes next line BIT LAB_1BA2
LAB_B3AE
	LDX	#$1B			; error $1B, undefined function error
	JMP	LAB_A437		; do error #X then warm start


;************************************************************************************
;
; perform DEF

LAB_B3B3
	JSR	LAB_B3E1		; check FNx syntax
	JSR	LAB_B3A6		; check not direct, back here if ok
	JSR	LAB_AEFA		; scan for "(", else do syntax error then warm start
	LDA	#$80			; set flag for FNx
	STA	LAB_10		; save subscript/FNx flag
	JSR	LAB_B08B		; get variable address
	JSR	LAB_AD8D		; check if source is numeric, else do type mismatch
	JSR	LAB_AEF7		; scan for ")", else do syntax error then warm start
	LDA	#TK_EQUAL		; get = token
	JSR	LAB_AEFF		; scan for CHR$(A), else do syntax error then warm start
	PHA				; push next character
	LDA	LAB_48		; get current variable pointer high byte
	PHA				; push it
	LDA	LAB_47		; get current variable pointer low byte
	PHA				; push it
	LDA	LAB_7B		; get BASIC execute pointer high byte
	PHA				; push it
	LDA	LAB_7A		; get BASIC execute pointer low byte
	PHA				; push it
	JSR	LAB_A8F8		; perform DATA
	JMP	LAB_B44F		; put execute pointer and variable pointer into function
					; and return


;************************************************************************************
;
; check FNx syntax

LAB_B3E1
	LDA	#TK_FN		; set FN token
	JSR	LAB_AEFF		; scan for CHR$(A), else do syntax error then warm start
	ORA	#$80			; set FN flag bit
	STA	LAB_10		; save FN name
	JSR	LAB_B092		; search for FN variable
	STA	LAB_4E		; save function pointer low byte
	STY	LAB_4F		; save function pointer high byte
	JMP	LAB_AD8D		; check if source is numeric and return, else do type
					; mismatch


;************************************************************************************
;
; Evaluate FNx

LAB_B3F4
	JSR	LAB_B3E1		; check FNx syntax
	LDA	LAB_4F		; get function pointer high byte
	PHA				; push it
	LDA	LAB_4E		; get function pointer low byte
	PHA				; push it
	JSR	LAB_AEF1		; evaluate expression within parentheses
	JSR	LAB_AD8D		; check if source is numeric, else do type mismatch
	PLA				; pop function pointer low byte
	STA	LAB_4E		; restore it
	PLA				; pop function pointer high byte
	STA	LAB_4F		; restore it
	LDY	#$02			; index to variable pointer high byte
	LDA	(LAB_4E),Y		; get variable address low byte
	STA	LAB_47		; save current variable pointer low byte
	TAX				; copy address low byte
	INY				; index to variable address high byte
	LDA	(LAB_4E),Y		; get variable pointer high byte
	BEQ	LAB_B3AE		; branch if high byte zero

	STA	LAB_48		; save current variable pointer high byte
	INY				; index to mantissa 3

					; now stack the function variable value before use
LAB_B418
	LDA	(LAB_47),Y		; get byte from variable
	PHA				; stack it
	DEY				; decrement index
	BPL	LAB_B418		; loop until variable stacked

	LDY	LAB_48		; get current variable pointer high byte
	JSR	LAB_BBD4		; pack FAC1 into (XY)
	LDA	LAB_7B		; get BASIC execute pointer high byte
	PHA				; push it
	LDA	LAB_7A		; get BASIC execute pointer low byte
	PHA				; push it
	LDA	(LAB_4E),Y		; get function execute pointer low byte
	STA	LAB_7A		; save BASIC execute pointer low byte
	INY				; index to high byte
	LDA	(LAB_4E),Y		; get function execute pointer high byte
	STA	LAB_7B		; save BASIC execute pointer high byte
	LDA	LAB_48		; get current variable pointer high byte
	PHA				; push it
	LDA	LAB_47		; get current variable pointer low byte
	PHA				; push it
	JSR	LAB_AD8A		; evaluate expression and check is numeric, else do
					; type mismatch
	PLA				; pull variable address low byte
	STA	LAB_4E		; save variable address low byte
	PLA				; pull variable address high byte
	STA	LAB_4F		; save variable address high byte
	JSR	LAB_0079		; scan memory
	BEQ	LAB_B449		; branch if null (should be [EOL] marker)

	JMP	LAB_AF08		; else syntax error then warm start


;************************************************************************************
;
; restore BASIC execute pointer and function variable from stack

LAB_B449
	PLA				; pull BASIC execute pointer low byte
	STA	LAB_7A		; save BASIC execute pointer low byte
	PLA				; pull BASIC execute pointer high byte
	STA	LAB_7B		; save BASIC execute pointer high byte

; put execute pointer and variable pointer into function

LAB_B44F
	LDY	#$00			; clear index
	PLA				; pull BASIC execute pointer low byte
	STA	(LAB_4E),Y		; save to function
	PLA				; pull BASIC execute pointer high byte
	INY				; increment index
	STA	(LAB_4E),Y		; save to function
	PLA				; pull current variable address low byte
	INY				; increment index
	STA	(LAB_4E),Y		; save to function
	PLA				; pull current variable address high byte
	INY				; increment index
	STA	(LAB_4E),Y		; save to function
	PLA				; pull ??
	INY				; increment index
	STA	(LAB_4E),Y		; save to function
	RTS


;************************************************************************************
;
; perform STR$()

LAB_B465
	JSR	LAB_AD8D		; check if source is numeric, else do type mismatch
	LDY	#$00			; set string index
	JSR	LAB_BDDF		; convert FAC1 to string
	PLA				; dump return address (skip type check)
	PLA				; dump return address (skip type check)
LAB_B46F
	LDA	#<LAB_FF		; set result string low pointer
	LDY	#>LAB_FF		; set result string high pointer
	BEQ	LAB_B487		; print null terminated string to utility pointer


;************************************************************************************
;
; do string vector
; copy descriptor pointer and make string space A bytes long

LAB_B475
	LDX	LAB_64		; get descriptor pointer low byte
	LDY	LAB_65		; get descriptor pointer high byte
	STX	LAB_50		; save descriptor pointer low byte
	STY	LAB_51		; save descriptor pointer high byte


;************************************************************************************
;
; make string space A bytes long

LAB_B47D
	JSR	LAB_B4F4		; make space in string memory for string A long
	STX	LAB_62		; save string pointer low byte
	STY	LAB_63		; save string pointer high byte
	STA	LAB_61		; save length
	RTS


;************************************************************************************
;
; scan, set up string
; print " terminated string to utility pointer

LAB_B487
	LDX	#$22			; set terminator to "
	STX	LAB_07		; set search character, terminator 1
	STX	LAB_08		; set terminator 2

; print search or alternate terminated string to utility pointer
; source is AY

LAB_B48D
	STA	LAB_6F		; store string start low byte
	STY	LAB_70		; store string start high byte
	STA	LAB_62		; save string pointer low byte
	STY	LAB_63		; save string pointer high byte
	LDY	#$FF			; set length to -1
LAB_B497
	INY				; increment length
	LDA	(LAB_6F),Y		; get byte from string
	BEQ	LAB_B4A8		; exit loop if null byte [EOS]

	CMP	LAB_07		; compare with search character, terminator 1
	BEQ	LAB_B4A4		; branch if terminator

	CMP	LAB_08		; compare with terminator 2
	BNE	LAB_B497		; loop if not terminator 2

LAB_B4A4
	CMP	#$22			; compare with "
	BEQ	LAB_B4A9		; branch if " (carry set if = !)

LAB_B4A8
	CLC				; clear carry for add (only if [EOL] terminated string)
LAB_B4A9
	STY	LAB_61		; save length in FAC1 exponent
	TYA				; copy length to A
	ADC	LAB_6F		; add string start low byte
	STA	LAB_71		; save string end low byte
	LDX	LAB_70		; get string start high byte
	BCC	LAB_B4B5		; branch if no low byte overflow

	INX				; else increment high byte
LAB_B4B5
	STX	LAB_72		; save string end high byte
	LDA	LAB_70		; get string start high byte
	BEQ	LAB_B4BF		; branch if in utility area

	CMP	#$02			; compare with input buffer memory high byte
	BNE	LAB_B4CA		; branch if not in input buffer memory

					; string in input buffer or utility area, move to string
					; memory
LAB_B4BF
	TYA				; copy length to A
	JSR	LAB_B475		; copy descriptor pointer and make string space A bytes long
	LDX	LAB_6F		; get string start low byte
	LDY	LAB_70		; get string start high byte
	JSR	LAB_B688		; store string A bytes long from XY to utility pointer

; check for space on descriptor stack then ...
; put string address and length on descriptor stack and update stack pointers

LAB_B4CA
	LDX	LAB_16		; get the descriptor stack pointer
	CPX	#LAB_19+9		; compare it with the maximum + 1
	BNE	LAB_B4D5		; if there is space on the string stack continue

					; else do string too complex error
	LDX	#$19			; error $19, string too complex error
LAB_B4D2
	JMP	LAB_A437		; do error #X then warm start

; put string address and length on descriptor stack and update stack pointers

LAB_B4D5
	LDA	LAB_61		; get the string length
	STA	LAB_00,X		; put it on the string stack
	LDA	LAB_62		; get the string pointer low byte
	STA	LAB_00+1,X		; put it on the string stack
	LDA	LAB_63		; get the string pointer high byte
	STA	LAB_00+2,X		; put it on the string stack
	LDY	#$00			; clear Y
	STX	LAB_64		; save the string descriptor pointer low byte
	STY	LAB_65		; save the string descriptor pointer high byte, always $00
	STY	LAB_70		; clear FAC1 rounding byte
	DEY				; Y = $FF
	STY	LAB_0D		; save the data type flag, $FF = string
	STX	LAB_17		; save the current descriptor stack item pointer low byte
	INX				; update the stack pointer
	INX				; update the stack pointer
	INX				; update the stack pointer
	STX	LAB_16		; save the new descriptor stack pointer
	RTS


;************************************************************************************
;
; make space in string memory for string A long
; return X = pointer low byte, Y = pointer high byte

LAB_B4F4
	LSR	LAB_0F		; clear garbage collected flag (b7)

					; make space for string A long
LAB_B4F6
	PHA				; save string length
	EOR	#$FF			; complement it
	SEC				; set carry for subtract, two's complement add
	ADC	LAB_33		; add bottom of string space low byte, subtract length
	LDY	LAB_34		; get bottom of string space high byte
	BCS	LAB_B501		; skip decrement if no underflow

	DEY				; decrement bottom of string space high byte
LAB_B501
	CPY	LAB_32		; compare with end of arrays high byte
	BCC	LAB_B516		; do out of memory error if less

	BNE	LAB_B50B		; if not = skip next test

	CMP	LAB_31		; compare with end of arrays low byte
	BCC	LAB_B516		; do out of memory error if less

LAB_B50B
	STA	LAB_33		; save bottom of string space low byte
	STY	LAB_34		; save bottom of string space high byte
	STA	LAB_35		; save string utility ptr low byte
	STY	LAB_36		; save string utility ptr high byte
	TAX				; copy low byte to X
	PLA				; get string length back
	RTS

LAB_B516
	LDX	#$10			; error code $10, out of memory error
	LDA	LAB_0F		; get garbage collected flag
	BMI	LAB_B4D2		; if set then do error code X

	JSR	LAB_B526		; else go do garbage collection
	LDA	#$80			; flag for garbage collected
	STA	LAB_0F		; set garbage collected flag
	PLA				; pull length
	BNE	LAB_B4F6		; go try again (loop always, length should never be = $00)


;************************************************************************************
;
; garbage collection routine

LAB_B526
	LDX	LAB_37		; get end of memory low byte
	LDA	LAB_38		; get end of memory high byte

; re-run routine from last ending

LAB_B52A
	STX	LAB_33		; set bottom of string space low byte
	STA	LAB_34		; set bottom of string space high byte
	LDY	#$00			; clear index
	STY	LAB_4F		; clear working pointer high byte
	STY	LAB_4E		; clear working pointer low byte
	LDA	LAB_31		; get end of arrays low byte
	LDX	LAB_32		; get end of arrays high byte
	STA	LAB_5F		; save as highest uncollected string pointer low byte
	STX	LAB_60		; save as highest uncollected string pointer high byte
	LDA	#LAB_19		; set descriptor stack pointer
	LDX	#$00			; clear X
	STA	LAB_22		; save descriptor stack pointer low byte
	STX	LAB_23		; save descriptor stack pointer high byte ($00)
LAB_B544
	CMP	LAB_16		; compare with descriptor stack pointer
	BEQ	LAB_B54D		; branch if =

	JSR	LAB_B5C7		; check string salvageability
	BEQ	LAB_B544		; loop always

					; done stacked strings, now do string variables
LAB_B54D
	LDA	#$07			; set step size = $07, collecting variables
	STA	LAB_53		; save garbage collection step size
	LDA	LAB_2D		; get start of variables low byte
	LDX	LAB_2E		; get start of variables high byte
	STA	LAB_22		; save as pointer low byte
	STX	LAB_23		; save as pointer high byte
LAB_B559
	CPX	LAB_30		; compare end of variables high byte,
					; start of arrays high byte
	BNE	LAB_B561		; branch if no high byte match

	CMP	LAB_2F		; else compare end of variables low byte,
					; start of arrays low byte
	BEQ	LAB_B566		; branch if = variable memory end

LAB_B561
	JSR	LAB_B5BD		; check variable salvageability
	BEQ	LAB_B559		; loop always

					; done string variables, now do string arrays
LAB_B566
	STA	LAB_58		; save start of arrays low byte as working pointer
	STX	LAB_59		; save start of arrays high byte as working pointer
	LDA	#$03			; set step size, collecting descriptors
	STA	LAB_53		; save step size
LAB_B56E
	LDA	LAB_58		; get pointer low byte
	LDX	LAB_59		; get pointer high byte
LAB_B572
	CPX	LAB_32		; compare with end of arrays high byte
	BNE	LAB_B57D		; branch if not at end

	CMP	LAB_31		; else compare with end of arrays low byte
	BNE	LAB_B57D		; branch if not at end

	JMP	LAB_B606		; collect string, tidy up and exit if at end ??

LAB_B57D
	STA	LAB_22		; save pointer low byte
	STX	LAB_23		; save pointer high byte
	LDY	#$00			; set index
	LDA	(LAB_22),Y		; get array name first byte
	TAX				; copy it
	INY				; increment index
	LDA	(LAB_22),Y		; get array name second byte
	PHP				; push the flags
	INY				; increment index
	LDA	(LAB_22),Y		; get array size low byte
	ADC	LAB_58		; add start of this array low byte
	STA	LAB_58		; save start of next array low byte
	INY				; increment index
	LDA	(LAB_22),Y		; get array size high byte
	ADC	LAB_59		; add start of this array high byte
	STA	LAB_59		; save start of next array high byte
	PLP				; restore the flags
	BPL	LAB_B56E		; skip if not string array

; was possibly string array so ...

	TXA				; get name first byte back
	BMI	LAB_B56E		; skip if not string array

	INY				; increment index
	LDA	(LAB_22),Y		; get # of dimensions
	LDY	#$00			; clear index
	ASL				; *2
	ADC	#$05			; +5 (array header size)
	ADC	LAB_22		; add pointer low byte
	STA	LAB_22		; save pointer low byte
	BCC	LAB_B5AE		; branch if no rollover

	INC	LAB_23		; else increment pointer hgih byte
LAB_B5AE
	LDX	LAB_23		; get pointer high byte
LAB_B5B0
	CPX	LAB_59		; compare pointer high byte with end of this array high byte
	BNE	LAB_B5B8		; branch if not there yet

	CMP	LAB_58		; compare pointer low byte with end of this array low byte
	BEQ	LAB_B572		; if at end of this array go check next array

LAB_B5B8
	JSR	LAB_B5C7		; check string salvageability
	BEQ	LAB_B5B0		; loop

; check variable salvageability

LAB_B5BD
	LDA	(LAB_22),Y		; get variable name first byte
	BMI	LAB_B5F6		; add step and exit if not string

	INY				; increment index
	LDA	(LAB_22),Y		; get variable name second byte
	BPL	LAB_B5F6		; add step and exit if not string

	INY				; increment index

; check string salvageability

LAB_B5C7
	LDA	(LAB_22),Y		; get string length
	BEQ	LAB_B5F6		; add step and exit if null string

	INY				; increment index
	LDA	(LAB_22),Y		; get string pointer low byte
	TAX				; copy to X
	INY				; increment index
	LDA	(LAB_22),Y		; get string pointer high byte
	CMP	LAB_34		; compare string pointer high byte with bottom of string
					; space high byte
	BCC	LAB_B5DC		; if bottom of string space greater go test against highest
					; uncollected string

	BNE	LAB_B5F6		; if bottom of string space less string has been collected
					; so go update pointers, step to next and return

					; high bytes were equal so test low bytes
	CPX	LAB_33		; compare string pointer low byte with bottom of string
					; space low byte
	BCS	LAB_B5F6		; if bottom of string space less string has been collected
					; so go update pointers, step to next and return

					; else test string against highest uncollected string so far
LAB_B5DC
	CMP	LAB_60		; compare string pointer high byte with highest uncollected
					; string high byte
	BCC	LAB_B5F6		; if highest uncollected string is greater then go update
					; pointers, step to next and return

	BNE	LAB_B5E6		; if highest uncollected string is less then go set this
					; string as highest uncollected so far

					; high bytes were equal so test low bytes
	CPX	LAB_5F		; compare string pointer low byte with highest uncollected
					; string low byte
	BCC	LAB_B5F6		; if highest uncollected string is greater then go update
					; pointers, step to next and return

					; else set current string as highest uncollected string
LAB_B5E6
	STX	LAB_5F		; save string pointer low byte as highest uncollected string
					; low byte
	STA	LAB_60		; save string pointer high byte as highest uncollected
					; string high byte
	LDA	LAB_22		; get descriptor pointer low byte
	LDX	LAB_23		; get descriptor pointer high byte
	STA	LAB_4E		; save working pointer high byte
	STX	LAB_4F		; save working pointer low byte
	LDA	LAB_53		; get step size
	STA	LAB_55		; copy step size
LAB_B5F6
	LDA	LAB_53		; get step size
	CLC				; clear carry for add
	ADC	LAB_22		; add pointer low byte
	STA	LAB_22		; save pointer low byte
	BCC	LAB_B601		; branch if no rollover

	INC	LAB_23		; else increment pointer high byte
LAB_B601
	LDX	LAB_23		; get pointer high byte
	LDY	#$00			; flag not moved
	RTS

; collect string

LAB_B606
	LDA	LAB_4F		; get working pointer low byte
	ORA	LAB_4E		; OR working pointer high byte
	BEQ	LAB_B601		; exit if nothing to collect

	LDA	LAB_55		; get copied step size
	AND	#$04			; mask step size, $04 for variables, $00 for array or stack
	LSR				; >> 1
	TAY				; copy to index
	STA	LAB_55		; save offset to descriptor start
	LDA	(LAB_4E),Y		; get string length low byte
	ADC	LAB_5F		; add string start low byte
	STA	LAB_5A		; set block end low byte
	LDA	LAB_60		; get string start high byte
	ADC	#$00			; add carry
	STA	LAB_5B		; set block end high byte
	LDA	LAB_33		; get bottom of string space low byte
	LDX	LAB_34		; get bottom of string space high byte
	STA	LAB_58		; save destination end low byte
	STX	LAB_59		; save destination end high byte
	JSR	LAB_A3BF		; open up space in memory, don't set array end. this
					; copies the string from where it is to the end of the
					; uncollected string memory
	LDY	LAB_55		; restore offset to descriptor start
	INY				; increment index to string pointer low byte
	LDA	LAB_58		; get new string pointer low byte
	STA	(LAB_4E),Y		; save new string pointer low byte
	TAX				; copy string pointer low byte
	INC	LAB_59		; increment new string pointer high byte
	LDA	LAB_59		; get new string pointer high byte
	INY				; increment index to string pointer high byte
	STA	(LAB_4E),Y		; save new string pointer high byte
	JMP	LAB_B52A		; re-run routine from last ending, XA holds new bottom
					; of string memory pointer


;************************************************************************************
;
; concatenate
; add strings, the first string is in the descriptor, the second string is in line

LAB_B63D
	LDA	LAB_65		; get descriptor pointer high byte
	PHA				; put on stack
	LDA	LAB_64		; get descriptor pointer low byte
	PHA				; put on stack
	JSR	LAB_AE83		; get value from line
	JSR	LAB_AD8F		; check if source is string, else do type mismatch
	PLA				; get descriptor pointer low byte back
	STA	LAB_6F		; set pointer low byte
	PLA				; get descriptor pointer high byte back
	STA	LAB_70		; set pointer high byte
	LDY	#$00			; clear index
	LDA	(LAB_6F),Y		; get length of first string from descriptor
	CLC				; clear carry for add
	ADC	(LAB_64),Y		; add length of second string
	BCC	LAB_B65D		; branch if no overflow

	LDX	#$17			; else error $17, string too long error
	JMP	LAB_A437		; do error #X then warm start

LAB_B65D
	JSR	LAB_B475		; copy descriptor pointer and make string space A bytes long
	JSR	LAB_B67A		; copy string from descriptor to utility pointer
	LDA	LAB_50		; get descriptor pointer low byte
	LDY	LAB_51		; get descriptor pointer high byte
	JSR	LAB_B6AA		; pop (YA) descriptor off stack or from top of string space
					; returns with A = length, X = pointer low byte,
					; Y = pointer high byte
	JSR	LAB_B68C		; store string from pointer to utility pointer
	LDA	LAB_6F		; get descriptor pointer low byte
	LDY	LAB_70		; get descriptor pointer high byte
	JSR	LAB_B6AA		; pop (YA) descriptor off stack or from top of string space
					; returns with A = length, X = pointer low byte,
					; Y = pointer high byte
	JSR	LAB_B4CA		; check space on descriptor stack then put string address
					; and length on descriptor stack and update stack pointers
	JMP	LAB_ADB8		; continue evaluation


;************************************************************************************
;
; copy string from descriptor to utility pointer

LAB_B67A
	LDY	#$00			; clear index
	LDA	(LAB_6F),Y		; get string length
	PHA				; save it
	INY				; increment index
	LDA	(LAB_6F),Y		; get string pointer low byte
	TAX				; copy to X
	INY				; increment index
	LDA	(LAB_6F),Y		; get string pointer high byte
	TAY				; copy to Y
	PLA				; get length back
LAB_B688
	STX	LAB_22		; save string pointer low byte
	STY	LAB_23		; save string pointer high byte

; store string from pointer to utility pointer

LAB_B68C
	TAY				; copy length as index
	BEQ	LAB_B699		; branch if null string

	PHA				; save length
LAB_B690
	DEY				; decrement length/index
	LDA	(LAB_22),Y		; get byte from string
	STA	(LAB_35),Y		; save byte to destination
	TYA				; copy length/index
	BNE	LAB_B690		; loop if not all done yet

	PLA				; restore length
LAB_B699
	CLC				; clear carry for add
	ADC	LAB_35		; add string utility ptr low byte
	STA	LAB_35		; save string utility ptr low byte
	BCC	LAB_B6A2		; branch if no rollover

	INC	LAB_36		; increment string utility ptr high byte
LAB_B6A2
	RTS


;************************************************************************************
;
; evaluate string

LAB_B6A3
	JSR	LAB_AD8F		; check if source is string, else do type mismatch

; pop string off descriptor stack, or from top of string space
; returns with A = length, X = pointer low byte, Y = pointer high byte

LAB_B6A6
	LDA	LAB_64		; get descriptor pointer low byte
	LDY	LAB_65		; get descriptor pointer high byte

; pop (YA) descriptor off stack or from top of string space
; returns with A = length, X = pointer low byte, Y = pointer high byte

LAB_B6AA
	STA	LAB_22		; save string pointer low byte
	STY	LAB_23		; save string pointer high byte
	JSR	LAB_B6DB		; clean descriptor stack, YA = pointer
	PHP				; save status flags
	LDY	#$00			; clear index
	LDA	(LAB_22),Y		; get length from string descriptor
	PHA				; put on stack
	INY				; increment index
	LDA	(LAB_22),Y		; get string pointer low byte from descriptor
	TAX				; copy to X
	INY				; increment index
	LDA	(LAB_22),Y		; get string pointer high byte from descriptor
	TAY				; copy to Y
	PLA				; get string length back
	PLP				; restore status
	BNE	LAB_B6D6		; branch if pointer <> last_sl,last_sh

	CPY	LAB_34		; compare with bottom of string space high byte
	BNE	LAB_B6D6		; branch if <>

	CPX	LAB_33		; else compare with bottom of string space low byte
	BNE	LAB_B6D6		; branch if <>

	PHA				; save string length
	CLC				; clear carry for add
	ADC	LAB_33		; add bottom of string space low byte
	STA	LAB_33		; set bottom of string space low byte
	BCC	LAB_B6D5		; skip increment if no overflow

	INC	LAB_34		; increment bottom of string space high byte
LAB_B6D5
	PLA				; restore string length
LAB_B6D6
	STX	LAB_22		; save string pointer low byte
	STY	LAB_23		; save string pointer high byte
	RTS

; clean descriptor stack, YA = pointer
; checks if AY is on the descriptor stack, if so does a stack discard

LAB_B6DB
	CPY	LAB_18		; compare high byte with current descriptor stack item
					; pointer high byte
	BNE	LAB_B6EB		; exit if <>

	CMP	LAB_17		; compare low byte with current descriptor stack item
					; pointer low byte
	BNE	LAB_B6EB		; exit if <>

	STA	LAB_16		; set descriptor stack pointer
	SBC	#$03			; update last string pointer low byte
	STA	LAB_17		; save current descriptor stack item pointer low byte
	LDY	#$00			; clear high byte
LAB_B6EB
	RTS


;************************************************************************************
;
; perform CHR$()

LAB_B6EC
	JSR	LAB_B7A1		; evaluate byte expression, result in X
	TXA				; copy to A
	PHA				; save character
	LDA	#$01			; string is single byte
	JSR	LAB_B47D		; make string space A bytes long
	PLA				; get character back
	LDY	#$00			; clear index
	STA	(LAB_62),Y		; save byte in string - byte IS string!
	PLA				; dump return address (skip type check)
	PLA				; dump return address (skip type check)
	JMP	LAB_B4CA		; check space on descriptor stack then put string address
					; and length on descriptor stack and update stack pointers


;************************************************************************************
;
; perform LEFT$()

LAB_B700
	JSR	LAB_B761		; pull string data and byte parameter from stack
					; return pointer in descriptor, byte in A (and X), Y=0
	CMP	(LAB_50),Y		; compare byte parameter with string length
	TYA				; clear A
LAB_B706
	BCC	LAB_B70C		; branch if string length > byte parameter

	LDA	(LAB_50),Y		; else make parameter = length
	TAX				; copy to byte parameter copy
	TYA				; clear string start offset
LAB_B70C
	PHA				; save string start offset
LAB_B70D
	TXA				; copy byte parameter (or string length if <)
LAB_B70E
	PHA				; save string length
	JSR	LAB_B47D		; make string space A bytes long
	LDA	LAB_50		; get descriptor pointer low byte
	LDY	LAB_51		; get descriptor pointer high byte
	JSR	LAB_B6AA		; pop (YA) descriptor off stack or from top of string space
					; returns with A = length, X = pointer low byte,
					; Y = pointer high byte
	PLA				; get string length back
	TAY				; copy length to Y
	PLA				; get string start offset back
	CLC				; clear carry for add
	ADC	LAB_22		; add start offset to string start pointer low byte
	STA	LAB_22		; save string start pointer low byte
	BCC	LAB_B725		; branch if no overflow

	INC	LAB_23		; else increment string start pointer high byte
LAB_B725
	TYA				; copy length to A
	JSR	LAB_B68C		; store string from pointer to utility pointer
	JMP	LAB_B4CA		; check space on descriptor stack then put string address
					; and length on descriptor stack and update stack pointers


;************************************************************************************
;
; perform RIGHT$()

LAB_B72C
	JSR	LAB_B761		; pull string data and byte parameter from stack
					; return pointer in descriptor, byte in A (and X), Y=0
	CLC				; clear carry for add-1
	SBC	(LAB_50),Y		; subtract string length
	EOR	#$FF			; invert it (A=LEN(expression$)-l)
	JMP	LAB_B706		; go do rest of LEFT$()


;************************************************************************************
;
; perform MID$()

LAB_B737
	LDA	#$FF			; set default length = 255
	STA	LAB_65		; save default length
	JSR	LAB_0079		; scan memory
	CMP	#')'			; compare with ")"
	BEQ	LAB_B748		; branch if = ")" (skip second byte get)

	JSR	LAB_AEFD		; scan for ",", else do syntax error then warm start
	JSR	LAB_B79E		; get byte parameter
LAB_B748
	JSR	LAB_B761		; pull string data and byte parameter from stack
					; return pointer in descriptor, byte in A (and X), Y=0
	BEQ	LAB_B798		; if null do illegal quantity error then warm start

	DEX				; decrement start index
	TXA				; copy to A
	PHA				; save string start offset
	CLC				; clear carry for sub-1
	LDX	#$00			; clear output string length
	SBC	(LAB_50),Y		; subtract string length
	BCS	LAB_B70D		; if start>string length go do null string

	EOR	#$FF			; complement -length
	CMP	LAB_65		; compare byte parameter
	BCC	LAB_B70E		; if length>remaining string go do RIGHT$

	LDA	LAB_65		; get length byte
	BCS	LAB_B70E		; go do string copy, branch always


;************************************************************************************
;
; pull string data and byte parameter from stack
; return pointer in descriptor, byte in A (and X), Y=0

LAB_B761
	JSR	LAB_AEF7		; scan for ")", else do syntax error then warm start
	PLA				; pull return address low byte
	TAY				; save return address low byte
	PLA				; pull return address high byte
	STA	LAB_55		; save return address high byte
	PLA				; dump call to function vector low byte
	PLA				; dump call to function vector high byte
	PLA				; pull byte parameter
	TAX				; copy byte parameter to X
	PLA				; pull string pointer low byte
	STA	LAB_50		; save it
	PLA				; pull string pointer high byte
	STA	LAB_51		; save it
	LDA	LAB_55		; get return address high byte
	PHA				; back on stack
	TYA				; get return address low byte
	PHA				; back on stack
	LDY	#$00			; clear index
	TXA				; copy byte parameter
	RTS


;************************************************************************************
;
; perform LEN()

LAB_B77C
	JSR	LAB_B782		; evaluate string, get length in A (and Y)
	JMP	LAB_B3A2		; convert Y to byte in FAC1 and return


;************************************************************************************
;
; evaluate string, get length in Y

LAB_B782
	JSR	LAB_B6A3		; evaluate string
	LDX	#$00			; set data type = numeric
	STX	LAB_0D		; clear data type flag, $FF = string, $00 = numeric
	TAY				; copy length to Y
	RTS


;************************************************************************************
;
; perform ASC()

LAB_B78B
	JSR	LAB_B782		; evaluate string, get length in A (and Y)
	BEQ	LAB_B798		; if null do illegal quantity error then warm start

	LDY	#$00			; set index to first character
	LDA	(LAB_22),Y		; get byte
	TAY				; copy to Y
	JMP	LAB_B3A2		; convert Y to byte in FAC1 and return


;************************************************************************************
;
; do illegal quantity error then warm start

LAB_B798
	JMP	LAB_B248		; do illegal quantity error then warm start


;************************************************************************************
;
; scan and get byte parameter

LAB_B79B
	JSR	LAB_0073		; increment and scan memory


;************************************************************************************
;
; get byte parameter

LAB_B79E
	JSR	LAB_AD8A		; evaluate expression and check is numeric, else do
					; type mismatch


;************************************************************************************
;
; evaluate byte expression, result in X

LAB_B7A1
	JSR	LAB_B1B8		; evaluate integer expression, sign check

	LDX	LAB_64		; get FAC1 mantissa 3
	BNE	LAB_B798		; if not null do illegal quantity error then warm start

	LDX	LAB_65		; get FAC1 mantissa 4
	JMP	LAB_0079		; scan memory and return


;************************************************************************************
;
; perform VAL()

LAB_B7AD
	JSR	LAB_B782		; evaluate string, get length in A (and Y)
	BNE	LAB_B7B5		; branch if not null string

					; string was null so set result = $00
	JMP	LAB_B8F7		; clear FAC1 exponent and sign and return

LAB_B7B5
	LDX	LAB_7A		; get BASIC execute pointer low byte
	LDY	LAB_7B		; get BASIC execute pointer high byte
	STX	LAB_71		; save BASIC execute pointer low byte
	STY	LAB_72		; save BASIC execute pointer high byte
	LDX	LAB_22		; get string pointer low byte
	STX	LAB_7A		; save BASIC execute pointer low byte
	CLC				; clear carry for add
	ADC	LAB_22		; add string length
	STA	LAB_24		; save string end low byte
	LDX	LAB_23		; get string pointer high byte
	STX	LAB_7B		; save BASIC execute pointer high byte
	BCC	LAB_B7CD		; branch if no high byte increment

	INX				; increment string end high byte
LAB_B7CD
	STX	LAB_25		; save string end high byte
	LDY	#$00			; set index to $00
	LDA	(LAB_24),Y		; get string end byte
	PHA				; push it
	TYA				; clear A
	STA	(LAB_24),Y		; terminate string with $00
	JSR	LAB_0079		; scan memory
	JSR	LAB_BCF3		; get FAC1 from string
	PLA				; restore string end byte
	LDY	#$00			; clear index
	STA	(LAB_24),Y		; put string end byte back


;************************************************************************************
;
; restore BASIC execute pointer from temp

LAB_B7E2
	LDX	LAB_71		; get BASIC execute pointer low byte back
	LDY	LAB_72		; get BASIC execute pointer high byte back
	STX	LAB_7A		; save BASIC execute pointer low byte
	STY	LAB_7B		; save BASIC execute pointer high byte
	RTS


;************************************************************************************
;
; get parameters for POKE/WAIT

LAB_B7EB
	JSR	LAB_AD8A		; evaluate expression and check is numeric, else do
					; type mismatch
	JSR	LAB_B7F7		; convert FAC_1 to integer in temporary integer
LAB_B7F1
	JSR	LAB_AEFD		; scan for ",", else do syntax error then warm start
	JMP	LAB_B79E		; get byte parameter and return



;************************************************************************************
;
; convert FAC_1 to integer in temporary integer

LAB_B7F7
	LDA	LAB_66		; get FAC1 sign
	BMI	LAB_B798		; if -ve do illegal quantity error then warm start

	LDA	LAB_61		; get FAC1 exponent
	CMP	#$91			; compare with exponent = 2^16
	BCS	LAB_B798		; if >= do illegal quantity error then warm start

	JSR	LAB_BC9B		; convert FAC1 floating to fixed
	LDA	LAB_64		; get FAC1 mantissa 3
	LDY	LAB_65		; get FAC1 mantissa 4
	STY	LAB_14		; save temporary integer low byte
	STA	LAB_15		; save temporary integer high byte
	RTS


;************************************************************************************
;
; perform PEEK()

LAB_B80D
	LDA	LAB_15		; get line number high byte
	PHA				; save line number high byte
	LDA	LAB_14		; get line number low byte
	PHA				; save line number low byte
	JSR	LAB_B7F7		; convert FAC_1 to integer in temporary integer
	LDY	#$00			; clear index
	LDA	(LAB_14),Y		; read byte
	TAY				; copy byte to A
	PLA				; pull byte
	STA	LAB_14		; restore line number low byte
	PLA				; pull byte
	STA	LAB_15		; restore line number high byte
	JMP	LAB_B3A2		; convert Y to byte in FAC_1 and return



;************************************************************************************
;
; perform POKE

LAB_B824
	JSR	LAB_B7EB		; get parameters for POKE/WAIT
	TXA				; copy byte to A
	LDY	#$00			; clear index
	STA	(LAB_14),Y		; write byte
	RTS


;************************************************************************************
;
; perform WAIT

LAB_B82D
	JSR	LAB_B7EB		; get parameters for POKE/WAIT
	STX	LAB_49		; save byte
	LDX	#$00			; clear mask
	JSR	LAB_0079		; scan memory
	BEQ	LAB_B83C		; skip if no third argument

	JSR	LAB_B7F1		; scan for "," and get byte, else syntax error then
					; warm start
LAB_B83C
	STX	LAB_4A		; save EOR argument
	LDY	#$00			; clear index
LAB_B840
	LDA	(LAB_14),Y		; get byte via temporary integer	(address)
	EOR	LAB_4A		; EOR with second argument		(mask)
	AND	LAB_49		; AND with first argument		(byte)
	BEQ	LAB_B840		; loop if result is zero

LAB_B848
	RTS


;************************************************************************************
;
; add 0.5 to FAC1 (round FAC1)

LAB_B849
	LDA	#<LAB_BF11		; set 0.5 pointer low byte
	LDY	#>LAB_BF11		; set 0.5 pointer high byte
	JMP	LAB_B867		; add (AY) to FAC1


;************************************************************************************
;
; perform subtraction, FAC1 from (AY)

LAB_B850
	JSR	LAB_BA8C		; unpack memory (AY) into FAC2


;************************************************************************************
;
; perform subtraction, FAC1 from FAC2

LAB_B853
	LDA	LAB_66		; get FAC1 sign (b7)
	EOR	#$FF			; complement it
	STA	LAB_66		; save FAC1 sign (b7)
	EOR	LAB_6E		; EOR with FAC2 sign (b7)
	STA	LAB_6F		; save sign compare (FAC1 EOR FAC2)
	LDA	LAB_61		; get FAC1 exponent
	JMP	LAB_B86A		; add FAC2 to FAC1 and return

LAB_B862
	JSR	LAB_B999		; shift FACX A times right (>8 shifts)
	BCC	LAB_B8A3		;.go subtract mantissas


;************************************************************************************
;
; add (AY) to FAC1

LAB_B867
	JSR	LAB_BA8C		; unpack memory (AY) into FAC2


;************************************************************************************
;
; add FAC2 to FAC1

LAB_B86A
	BNE	LAB_B86F		; branch if FAC1 is not zero

	JMP	LAB_BBFC		; FAC1 was zero so copy FAC2 to FAC1 and return

					; FAC1 is non zero
LAB_B86F
	LDX	LAB_70		; get FAC1 rounding byte
	STX	LAB_56		; save as FAC2 rounding byte
	LDX	#LAB_69		; set index to FAC2 exponent address
	LDA	LAB_69		; get FAC2 exponent
LAB_B877
	TAY				; copy exponent
	BEQ	LAB_B848		; exit if zero

	SEC				; set carry for subtract
	SBC	LAB_61		; subtract FAC1 exponent
	BEQ	LAB_B8A3		; if equal go add mantissas

	BCC	LAB_B893		; if FAC2 < FAC1 then go shift FAC2 right

					; else FAC2 > FAC1
	STY	LAB_61		; save FAC1 exponent
	LDY	LAB_6E		; get FAC2 sign (b7)
	STY	LAB_66		; save FAC1 sign (b7)
	EOR	#$FF			; complement A
	ADC	#$00			; +1, twos complement, carry is set
	LDY	#$00			; clear Y
	STY	LAB_56		; clear FAC2 rounding byte
	LDX	#LAB_61		; set index to FAC1 exponent address
	BNE	LAB_B897		; branch always

					; FAC2 < FAC1
LAB_B893
	LDY	#$00			; clear Y
	STY	LAB_70		; clear FAC1 rounding byte
LAB_B897
	CMP	#$F9			; compare exponent diff with $F9
	BMI	LAB_B862		; branch if range $79-$F8

	TAY				; copy exponent difference to Y
	LDA	LAB_70		; get FAC1 rounding byte
	LSR	LAB_00+1,X		; shift FAC? mantissa 1
	JSR	LAB_B9B0		; shift FACX Y times right

					; exponents are equal now do mantissa subtract
LAB_B8A3
	BIT	LAB_6F		; test sign compare (FAC1 EOR FAC2)
	BPL	LAB_B8FE		; if = add FAC2 mantissa to FAC1 mantissa and return

	LDY	#LAB_61		; set the Y index to FAC1 exponent address
	CPX	#LAB_69		; compare X to FAC2 exponent address
	BEQ	LAB_B8AF		; if = continue, Y = FAC1, X = FAC2

	LDY	#LAB_69		; else set the Y index to FAC2 exponent address

					; subtract the smaller from the bigger (take the sign of
					; the bigger)
LAB_B8AF
	SEC				; set carry for subtract
	EOR	#$FF			; ones complement A
	ADC	LAB_56		; add FAC2 rounding byte
	STA	LAB_70		; save FAC1 rounding byte
	LDA	LAB_00+4,Y		; get FACY mantissa 4
	SBC	LAB_00+4,X		; subtract FACX mantissa 4
	STA	LAB_65		; save FAC1 mantissa 4
	LDA	LAB_00+3,Y		; get FACY mantissa 3
	SBC	LAB_00+3,X		; subtract FACX mantissa 3
	STA	LAB_64		; save FAC1 mantissa 3
	LDA	LAB_00+2,Y		; get FACY mantissa 2
	SBC	LAB_00+2,X		; subtract FACX mantissa 2
	STA	LAB_63		; save FAC1 mantissa 2
	LDA	LAB_00+1,Y		; get FACY mantissa 1
	SBC	LAB_00+1,X		; subtract FACX mantissa 1
	STA	LAB_62		; save FAC1 mantissa 1


;************************************************************************************
;
; do ABS and normalise FAC1

LAB_B8D2
	BCS	LAB_B8D7		; branch if number is +ve

	JSR	LAB_B947		; negate FAC1


;************************************************************************************
;
; normalise FAC1

LAB_B8D7
	LDY	#$00			; clear Y
	TYA				; clear A
	CLC				; clear carry for add
LAB_B8DB
	LDX	LAB_62		; get FAC1 mantissa 1
	BNE	LAB_B929		; if not zero normalise FAC1

	LDX	LAB_63		; get FAC1 mantissa 2
	STX	LAB_62		; save FAC1 mantissa 1
	LDX	LAB_64		; get FAC1 mantissa 3
	STX	LAB_63		; save FAC1 mantissa 2
	LDX	LAB_65		; get FAC1 mantissa 4
	STX	LAB_64		; save FAC1 mantissa 3
	LDX	LAB_70		; get FAC1 rounding byte
	STX	LAB_65		; save FAC1 mantissa 4
	STY	LAB_70		; clear FAC1 rounding byte
	ADC	#$08			; add x to exponent offset
	CMP	#$20			; compare with $20, max offset, all bits would be = 0
	BNE	LAB_B8DB		; loop if not max


;************************************************************************************
;
; clear FAC1 exponent and sign

LAB_B8F7
	LDA	#$00			; clear A
LAB_B8F9
	STA	LAB_61		; set FAC1 exponent


;************************************************************************************
;
; save FAC1 sign

LAB_B8FB
	STA	LAB_66		; save FAC1 sign (b7)
	RTS


;************************************************************************************
;
; add FAC2 mantissa to FAC1 mantissa

LAB_B8FE
	ADC	LAB_56		; add FAC2 rounding byte
	STA	LAB_70		; save FAC1 rounding byte
	LDA	LAB_65		; get FAC1 mantissa 4
	ADC	LAB_6D		; add FAC2 mantissa 4
	STA	LAB_65		; save FAC1 mantissa 4
	LDA	LAB_64		; get FAC1 mantissa 3
	ADC	LAB_6C		; add FAC2 mantissa 3
	STA	LAB_64		; save FAC1 mantissa 3
	LDA	LAB_63		; get FAC1 mantissa 2
	ADC	LAB_6B		; add FAC2 mantissa 2
	STA	LAB_63		; save FAC1 mantissa 2
	LDA	LAB_62		; get FAC1 mantissa 1
	ADC	LAB_6A		; add FAC2 mantissa 1
	STA	LAB_62		; save FAC1 mantissa 1
	JMP	LAB_B936		; test and normalise FAC1 for C=0/1

LAB_B91D
	ADC	#$01			; add 1 to exponent offset
	ASL	LAB_70		; shift FAC1 rounding byte
	ROL	LAB_65		; shift FAC1 mantissa 4
	ROL	LAB_64		; shift FAC1 mantissa 3
	ROL	LAB_63		; shift FAC1 mantissa 2
	ROL	LAB_62		; shift FAC1 mantissa 1

; normalise FAC1

LAB_B929
	BPL	LAB_B91D		; loop if not normalised

	SEC				; set carry for subtract
	SBC	LAB_61		; subtract FAC1 exponent
	BCS	LAB_B8F7		; branch if underflow (set result = $0)

	EOR	#$FF			; complement exponent
	ADC	#$01			; +1 (twos complement)
	STA	LAB_61		; save FAC1 exponent

; test and normalise FAC1 for C=0/1

LAB_B936
	BCC	LAB_B946		; exit if no overflow

; normalise FAC1 for C=1

LAB_B938
	INC	LAB_61		; increment FAC1 exponent
	BEQ	LAB_B97E		; if zero do overflow error then warm start

	ROR	LAB_62		; shift FAC1 mantissa 1
	ROR	LAB_63		; shift FAC1 mantissa 2
	ROR	LAB_64		; shift FAC1 mantissa 3
	ROR	LAB_65		; shift FAC1 mantissa 4
	ROR	LAB_70		; shift FAC1 rounding byte
LAB_B946
	RTS


;************************************************************************************
;
; negate FAC1

LAB_B947
	LDA	LAB_66		; get FAC1 sign (b7)
	EOR	#$FF			; complement it
	STA	LAB_66		; save FAC1 sign (b7)

; twos complement FAC1 mantissa

LAB_B94D
	LDA	LAB_62		; get FAC1 mantissa 1
	EOR	#$FF			; complement it
	STA	LAB_62		; save FAC1 mantissa 1
	LDA	LAB_63		; get FAC1 mantissa 2
	EOR	#$FF			; complement it
	STA	LAB_63		; save FAC1 mantissa 2
	LDA	LAB_64		; get FAC1 mantissa 3
	EOR	#$FF			; complement it
	STA	LAB_64		; save FAC1 mantissa 3
	LDA	LAB_65		; get FAC1 mantissa 4
	EOR	#$FF			; complement it
	STA	LAB_65		; save FAC1 mantissa 4
	LDA	LAB_70		; get FAC1 rounding byte
	EOR	#$FF			; complement it
	STA	LAB_70		; save FAC1 rounding byte
	INC	LAB_70		; increment FAC1 rounding byte
	BNE	LAB_B97D		; exit if no overflow

; increment FAC1 mantissa

LAB_B96F
	INC	LAB_65		; increment FAC1 mantissa 4
	BNE	LAB_B97D		; finished if no rollover

	INC	LAB_64		; increment FAC1 mantissa 3
	BNE	LAB_B97D		; finished if no rollover

	INC	LAB_63		; increment FAC1 mantissa 2
	BNE	LAB_B97D		; finished if no rollover

	INC	LAB_62		; increment FAC1 mantissa 1
LAB_B97D
	RTS


;************************************************************************************
;
; do overflow error then warm start

LAB_B97E
	LDX	#$0F			; error $0F, overflow error
	JMP	LAB_A437		; do error #X then warm start


;************************************************************************************
;
; shift FCAtemp << A+8 times

LAB_B983
	LDX	#LAB_26-1		; set the offset to FACtemp
LAB_B985
	LDY	LAB_00+4,X		; get FACX mantissa 4
	STY	LAB_70		; save as FAC1 rounding byte
	LDY	LAB_00+3,X		; get FACX mantissa 3
	STY	LAB_00+4,X		; save FACX mantissa 4
	LDY	LAB_00+2,X		; get FACX mantissa 2
	STY	LAB_00+3,X		; save FACX mantissa 3
	LDY	LAB_00+1,X		; get FACX mantissa 1
	STY	LAB_00+2,X		; save FACX mantissa 2
	LDY	LAB_68		; get FAC1 overflow byte
	STY	LAB_00+1,X		; save FACX mantissa 1

; shift FACX -A times right (> 8 shifts)

LAB_B999
	ADC	#$08			; add 8 to shift count
	BMI	LAB_B985		; go do 8 shift if still -ve

	BEQ	LAB_B985		; go do 8 shift if zero

	SBC	#$08			; else subtract 8 again
	TAY				; save count to Y
	LDA	LAB_70		; get FAC1 rounding byte
	BCS	LAB_B9BA		;.

LAB_B9A6
	ASL	LAB_00+1,X		; shift FACX mantissa 1
	BCC	LAB_B9AC		; branch if +ve

	INC	LAB_00+1,X		; this sets b7 eventually
LAB_B9AC
	ROR	LAB_00+1,X		; shift FACX mantissa 1 (correct for ASL)
	ROR	LAB_00+1,X		; shift FACX mantissa 1 (put carry in b7)

; shift FACX Y times right

LAB_B9B0
	ROR	LAB_00+2,X		; shift FACX mantissa 2
	ROR	LAB_00+3,X		; shift FACX mantissa 3
	ROR	LAB_00+4,X		; shift FACX mantissa 4
	ROR				; shift FACX rounding byte
	INY				; increment exponent diff
	BNE	LAB_B9A6		; branch if range adjust not complete

LAB_B9BA
	CLC				; just clear it
	RTS


;************************************************************************************
;
; constants and series for LOG(n)

LAB_B9BC
	.byte	$81,$00,$00,$00,$00	; 1

LAB_B9C1
	.byte	$03				; series counter
	.byte	$7F,$5E,$56,$CB,$79
	.byte	$80,$13,$9B,$0B,$64
	.byte	$80,$76,$38,$93,$16
	.byte	$82,$38,$AA,$3B,$20

LAB_B9D6
	.byte	$80,$35,$04,$F3,$34	; 0.70711	1/root 2
LAB_B9DB
	.byte	$81,$35,$04,$F3,$34	; 1.41421	root 2
LAB_B9E0
	.byte	$80,$80,$00,$00,$00	; -0.5	1/2
LAB_B9E5
	.byte	$80,$31,$72,$17,$F8	; 0.69315	LOG(2)


;************************************************************************************
;
; perform LOG()

LAB_B9EA
	JSR	LAB_BC2B		; test sign and zero
	BEQ	LAB_B9F1		; if zero do illegal quantity error then warm start

	BPL	LAB_B9F4		; skip error if +ve

LAB_B9F1
	JMP	LAB_B248		; do illegal quantity error then warm start

LAB_B9F4
	LDA	LAB_61		; get FAC1 exponent
	SBC	#$7F			; normalise it
	PHA				; save it
	LDA	#$80			; set exponent to zero
	STA	LAB_61		; save FAC1 exponent
	LDA	#<LAB_B9D6		; pointer to 1/root 2 low byte
	LDY	#>LAB_B9D6		; pointer to 1/root 2 high byte
	JSR	LAB_B867		; add (AY) to FAC1 (1/root2)
	LDA	#<LAB_B9DB		; pointer to root 2 low byte
	LDY	#>LAB_B9DB		; pointer to root 2 high byte
	JSR	LAB_BB0F		; convert AY and do (AY)/FAC1 (root2/(x+(1/root2)))
	LDA	#<LAB_B9BC		; pointer to 1 low byte
	LDY	#>LAB_B9BC		; pointer to 1 high byte
	JSR	LAB_B850		; subtract FAC1 ((root2/(x+(1/root2)))-1) from (AY)
	LDA	#<LAB_B9C1		; pointer to series for LOG(n) low byte
	LDY	#>LAB_B9C1		; pointer to series for LOG(n) high byte
	JSR	LAB_E043		; ^2 then series evaluation
	LDA	#<LAB_B9E0		; pointer to -0.5 low byte
	LDY	#>LAB_B9E0		; pointer to -0.5 high byte
	JSR	LAB_B867		; add (AY) to FAC1
	PLA				; restore FAC1 exponent
	JSR	LAB_BD7E		; evaluate new ASCII digit
	LDA	#<LAB_B9E5		; pointer to LOG(2) low byte
	LDY	#>LAB_B9E5		; pointer to LOG(2) high byte


;************************************************************************************
;
; do convert AY, FCA1*(AY)

LAB_BA28
	JSR	LAB_BA8C		; unpack memory (AY) into FAC2
LAB_BA2B
	BNE	LAB_BA30		; multiply FAC1 by FAC2 ??

	JMP	LAB_BA8B		; exit if zero

LAB_BA30
	JSR	LAB_BAB7		; test and adjust accumulators
	LDA	#$00			; clear A
	STA	LAB_26		; clear temp mantissa 1
	STA	LAB_27		; clear temp mantissa 2
	STA	LAB_28		; clear temp mantissa 3
	STA	LAB_29		; clear temp mantissa 4
	LDA	LAB_70		; get FAC1 rounding byte
	JSR	LAB_BA59		; go do shift/add FAC2
	LDA	LAB_65		; get FAC1 mantissa 4
	JSR	LAB_BA59		; go do shift/add FAC2
	LDA	LAB_64		; get FAC1 mantissa 3
	JSR	LAB_BA59		; go do shift/add FAC2
	LDA	LAB_63		; get FAC1 mantissa 2
	JSR	LAB_BA59		; go do shift/add FAC2
	LDA	LAB_62		; get FAC1 mantissa 1
	JSR	LAB_BA5E		; go do shift/add FAC2
	JMP	LAB_BB8F		; copy temp to FAC1, normalise and return

LAB_BA59
	BNE	LAB_BA5E		; branch if byte <> zero

	JMP	LAB_B983		; shift FCAtemp << A+8 times

					; else do shift and add
LAB_BA5E
	LSR				; shift byte
	ORA	#$80			; set top bit (mark for 8 times)
LAB_BA61
	TAY				; copy result
	BCC	LAB_BA7D		; skip next if bit was zero

	CLC				; clear carry for add
	LDA	LAB_29		; get temp mantissa 4
	ADC	LAB_6D		; add FAC2 mantissa 4
	STA	LAB_29		; save temp mantissa 4
	LDA	LAB_28		; get temp mantissa 3
	ADC	LAB_6C		; add FAC2 mantissa 3
	STA	LAB_28		; save temp mantissa 3
	LDA	LAB_27		; get temp mantissa 2
	ADC	LAB_6B		; add FAC2 mantissa 2
	STA	LAB_27		; save temp mantissa 2
	LDA	LAB_26		; get temp mantissa 1
	ADC	LAB_6A		; add FAC2 mantissa 1
	STA	LAB_26		; save temp mantissa 1
LAB_BA7D
	ROR	LAB_26		; shift temp mantissa 1
	ROR	LAB_27		; shift temp mantissa 2
	ROR	LAB_28		; shift temp mantissa 3
	ROR	LAB_29		; shift temp mantissa 4
	ROR	LAB_70		; shift temp rounding byte
	TYA				; get byte back
	LSR				; shift byte
	BNE	LAB_BA61		; loop if all bits not done

LAB_BA8B
	RTS


;************************************************************************************
;
; unpack memory (AY) into FAC2

LAB_BA8C
	STA	LAB_22		; save pointer low byte
	STY	LAB_23		; save pointer high byte
	LDY	#$04			; 5 bytes to get (0-4)
	LDA	(LAB_22),Y		; get mantissa 4
	STA	LAB_6D		; save FAC2 mantissa 4
	DEY				; decrement index
	LDA	(LAB_22),Y		; get mantissa 3
	STA	LAB_6C		; save FAC2 mantissa 3
	DEY				; decrement index
	LDA	(LAB_22),Y		; get mantissa 2
	STA	LAB_6B		; save FAC2 mantissa 2
	DEY				; decrement index
	LDA	(LAB_22),Y		; get mantissa 1 + sign
	STA	LAB_6E		; save FAC2 sign (b7)
	EOR	LAB_66		; EOR with FAC1 sign (b7)
	STA	LAB_6F		; save sign compare (FAC1 EOR FAC2)
	LDA	LAB_6E		; recover FAC2 sign (b7)
	ORA	#$80			; set 1xxx xxx (set normal bit)
	STA	LAB_6A		; save FAC2 mantissa 1
	DEY				; decrement index
	LDA	(LAB_22),Y		; get exponent byte
	STA	LAB_69		; save FAC2 exponent
	LDA	LAB_61		; get FAC1 exponent
	RTS


;************************************************************************************
;
; test and adjust accumulators

LAB_BAB7
	LDA	LAB_69		; get FAC2 exponent

LAB_BAB9
	BEQ	LAB_BADA		; branch if FAC2 = $00 (handle underflow)

	CLC				; clear carry for add
	ADC	LAB_61		; add FAC1 exponent
	BCC	LAB_BAC4		; branch if sum of exponents < $0100

	BMI	LAB_BADF		; do overflow error

	CLC				; clear carry for the add
	.byte	$2C			; makes next line BIT LAB_1410
LAB_BAC4
	BPL	LAB_BADA		; if +ve go handle underflow

	ADC	#$80			; adjust exponent
	STA	LAB_61		; save FAC1 exponent
	BNE	LAB_BACF		; branch if not zero

	JMP	LAB_B8FB		; save FAC1 sign and return


LAB_BACF
	LDA	LAB_6F		; get sign compare (FAC1 EOR FAC2)
	STA	LAB_66		; save FAC1 sign (b7)
	RTS

; handle overflow and underflow

LAB_BAD4
	LDA	LAB_66		; get FAC1 sign (b7)
	EOR	#$FF			; complement it
	BMI	LAB_BADF		; do overflow error

					; handle underflow
LAB_BADA
	PLA				; pop return address low byte
	PLA				; pop return address high byte
	JMP	LAB_B8F7		; clear FAC1 exponent and sign and return

LAB_BADF
	JMP	LAB_B97E		; do overflow error then warm start


;************************************************************************************
;
; multiply FAC1 by 10

LAB_BAE2
	JSR	LAB_BC0C		; round and copy FAC1 to FAC2
	TAX				; copy exponent (set the flags)
	BEQ	LAB_BAF8		; exit if zero

	CLC				; clear carry for add
	ADC	#$02			; add two to exponent (*4)
	BCS	LAB_BADF		; do overflow error if > $FF

; FAC1 = (FAC1 + FAC2) * 2

LAB_BAED
	LDX	#$00			; clear byte
	STX	LAB_6F		; clear sign compare (FAC1 EOR FAC2)
	JSR	LAB_B877		; add FAC2 to FAC1 (*5)
	INC	LAB_61		; increment FAC1 exponent (*10)
	BEQ	LAB_BADF		; if exponent now zero go do overflow error

LAB_BAF8
	RTS


;************************************************************************************
;
; 10 as a floating value

LAB_BAF9
	.byte	$84,$20,$00,$00,$00	; 10


;************************************************************************************
;
; divide FAC1 by 10

LAB_BAFE
	JSR	LAB_BC0C		; round and copy FAC1 to FAC2
	LDA	#<LAB_BAF9		; set 10 pointer low byte
	LDY	#>LAB_BAF9		; set 10 pointer high byte
	LDX	#$00			; clear sign


;************************************************************************************
;
; divide by (AY) (X=sign)

LAB_BB07
	STX	LAB_6F		; save sign compare (FAC1 EOR FAC2)
	JSR	LAB_BBA2		; unpack memory (AY) into FAC1
	JMP	LAB_BB12		; do FAC2/FAC1

					; Perform divide-by


;************************************************************************************
;
; convert AY and do (AY)/FAC1

LAB_BB0F
	JSR	LAB_BA8C		; unpack memory (AY) into FAC2
LAB_BB12
	BEQ	LAB_BB8A		; if zero go do /0 error

	JSR	LAB_BC1B		; round FAC1
	LDA	#$00			; clear A
	SEC				; set carry for subtract
	SBC	LAB_61		; subtract FAC1 exponent (2s complement)
	STA	LAB_61		; save FAC1 exponent
	JSR	LAB_BAB7		; test and adjust accumulators
	INC	LAB_61		; increment FAC1 exponent
	BEQ	LAB_BADF		; if zero do overflow error

	LDX	#$FC			; set index to FAC temp
	LDA	#$01			;.set byte
LAB_BB29
	LDY	LAB_6A		; get FAC2 mantissa 1
	CPY	LAB_62		; compare FAC1 mantissa 1
	BNE	LAB_BB3F		; branch if <>

	LDY	LAB_6B		; get FAC2 mantissa 2
	CPY	LAB_63		; compare FAC1 mantissa 2
	BNE	LAB_BB3F		; branch if <>

	LDY	LAB_6C		; get FAC2 mantissa 3
	CPY	LAB_64		; compare FAC1 mantissa 3
	BNE	LAB_BB3F		; branch if <>

	LDY	LAB_6D		; get FAC2 mantissa 4
	CPY	LAB_65		; compare FAC1 mantissa 4
LAB_BB3F
	PHP				; save FAC2-FAC1 compare status
	ROL				;.shift byte
	BCC	LAB_BB4C		; skip next if no carry

	INX				; increment index to FAC temp
	STA	LAB_29,X		;.
	BEQ	LAB_BB7A		;.

	BPL	LAB_BB7E		;.

	LDA	#$01			;.
LAB_BB4C
	PLP				; restore FAC2-FAC1 compare status
	BCS	LAB_BB5D		; if FAC2 >= FAC1 then do subtract

					; FAC2 = FAC2*2
LAB_BB4F
	ASL	LAB_6D		; shift FAC2 mantissa 4
	ROL	LAB_6C		; shift FAC2 mantissa 3
	ROL	LAB_6B		; shift FAC2 mantissa 2
	ROL	LAB_6A		; shift FAC2 mantissa 1
	BCS	LAB_BB3F		; loop with no compare

	BMI	LAB_BB29		; loop with compare

	BPL	LAB_BB3F		; loop with no compare, branch always

LAB_BB5D
	TAY				; save FAC2-FAC1 compare status
	LDA	LAB_6D		; get FAC2 mantissa 4
	SBC	LAB_65		; subtract FAC1 mantissa 4
	STA	LAB_6D		; save FAC2 mantissa 4
	LDA	LAB_6C		; get FAC2 mantissa 3
	SBC	LAB_64		; subtract FAC1 mantissa 3
	STA	LAB_6C		; save FAC2 mantissa 3
	LDA	LAB_6B		; get FAC2 mantissa 2
	SBC	LAB_63		; subtract FAC1 mantissa 2
	STA	LAB_6B		; save FAC2 mantissa 2
	LDA	LAB_6A		; get FAC2 mantissa 1
	SBC	LAB_62		; subtract FAC1 mantissa 1
	STA	LAB_6A		; save FAC2 mantissa 1
	TYA				; restore FAC2-FAC1 compare status
	JMP	LAB_BB4F		;.

LAB_BB7A
	LDA	#$40			;.
	BNE	LAB_BB4C		; branch always

; do A<<6, save as FAC1 rounding byte, normalise and return

LAB_BB7E
	ASL				;.
	ASL				;.
	ASL				;.
	ASL				;.
	ASL				;.
	ASL				;.
	STA	LAB_70		; save FAC1 rounding byte
	PLP				; dump FAC2-FAC1 compare status
	JMP	LAB_BB8F		; copy temp to FAC1, normalise and return

; do "Divide by zero" error

LAB_BB8A
	LDX	#$14			; error $14, divide by zero error
	JMP	LAB_A437		; do error #X then warm start

LAB_BB8F
	LDA	LAB_26		; get temp mantissa 1
	STA	LAB_62		; save FAC1 mantissa 1
	LDA	LAB_27		; get temp mantissa 2
	STA	LAB_63		; save FAC1 mantissa 2
	LDA	LAB_28		; get temp mantissa 3
	STA	LAB_64		; save FAC1 mantissa 3
	LDA	LAB_29		; get temp mantissa 4
	STA	LAB_65		; save FAC1 mantissa 4
	JMP	LAB_B8D7		; normalise FAC1 and return


;************************************************************************************
;
; unpack memory (AY) into FAC1

LAB_BBA2
	STA	LAB_22		; save pointer low byte
	STY	LAB_23		; save pointer high byte
	LDY	#$04			; 5 bytes to do
	LDA	(LAB_22),Y		; get fifth byte
	STA	LAB_65		; save FAC1 mantissa 4
	DEY				; decrement index
	LDA	(LAB_22),Y		; get fourth byte
	STA	LAB_64		; save FAC1 mantissa 3
	DEY				; decrement index
	LDA	(LAB_22),Y		; get third byte
	STA	LAB_63		; save FAC1 mantissa 2
	DEY				; decrement index
	LDA	(LAB_22),Y		; get second byte
	STA	LAB_66		; save FAC1 sign (b7)
	ORA	#$80			; set 1xxx xxxx (add normal bit)
	STA	LAB_62		; save FAC1 mantissa 1
	DEY				; decrement index
	LDA	(LAB_22),Y		; get first byte (exponent)
	STA	LAB_61		; save FAC1 exponent
	STY	LAB_70		; clear FAC1 rounding byte
	RTS


;************************************************************************************
;
; pack FAC1 into LAB_5C

LAB_BBC7
	LDX	#<LAB_5C		; set pointer low byte
	.byte	$2C			; makes next line BIT LAB_57A2


;************************************************************************************
;
; pack FAC1 into LAB_57

LAB_BBCA
	LDX	#<LAB_57		; set pointer low byte
	LDY	#>LAB_57		; set pointer high byte
	BEQ	LAB_BBD4		; pack FAC1 into (XY) and return, branch always


;************************************************************************************
;
; pack FAC1 into variable pointer

LAB_BBD0
	LDX	LAB_49		; get destination pointer low byte
	LDY	LAB_4A		; get destination pointer high byte


;************************************************************************************
;
; pack FAC1 into (XY)

LAB_BBD4
	JSR	LAB_BC1B		; round FAC1
	STX	LAB_22		; save pointer low byte
	STY	LAB_23		; save pointer high byte
	LDY	#$04			; set index
	LDA	LAB_65		; get FAC1 mantissa 4
	STA	(LAB_22),Y		; store in destination
	DEY				; decrement index
	LDA	LAB_64		; get FAC1 mantissa 3
	STA	(LAB_22),Y		; store in destination
	DEY				; decrement index
	LDA	LAB_63		; get FAC1 mantissa 2
	STA	(LAB_22),Y		; store in destination
	DEY				; decrement index
	LDA	LAB_66		; get FAC1 sign (b7)
	ORA	#$7F			; set bits x111 1111
	AND	LAB_62		; AND in FAC1 mantissa 1
	STA	(LAB_22),Y		; store in destination
	DEY				; decrement index
	LDA	LAB_61		; get FAC1 exponent
	STA	(LAB_22),Y		; store in destination
	STY	LAB_70		; clear FAC1 rounding byte
	RTS


;************************************************************************************
;
; copy FAC2 to FAC1

LAB_BBFC
	LDA	LAB_6E		; get FAC2 sign (b7)

; save FAC1 sign and copy ABS(FAC2) to FAC1

LAB_BBFE
	STA	LAB_66		; save FAC1 sign (b7)
	LDX	#$05			; 5 bytes to copy
LAB_BC02
	LDA	LAB_68,X		; get byte from FAC2,X
	STA	LAB_60,X		; save byte at FAC1,X
	DEX				; decrement count
	BNE	LAB_BC02		; loop if not all done

	STX	LAB_70		; clear FAC1 rounding byte
	RTS


;************************************************************************************
;
; round and copy FAC1 to FAC2

LAB_BC0C
	JSR	LAB_BC1B		; round FAC1

; copy FAC1 to FAC2

LAB_BC0F
	LDX	#$06			; 6 bytes to copy
LAB_BC11
	LDA	LAB_60,X		; get byte from FAC1,X
	STA	LAB_68,X		; save byte at FAC2,X
	DEX				; decrement count
	BNE	LAB_BC11		; loop if not all done

	STX	LAB_70		; clear FAC1 rounding byte
LAB_BC1A
	RTS


;************************************************************************************
;
; round FAC1

LAB_BC1B
	LDA	LAB_61		; get FAC1 exponent
	BEQ	LAB_BC1A		; exit if zero

	ASL	LAB_70		; shift FAC1 rounding byte
	BCC	LAB_BC1A		; exit if no overflow

; round FAC1 (no check)

LAB_BC23
	JSR	LAB_B96F		; increment FAC1 mantissa
	BNE	LAB_BC1A		; branch if no overflow

	JMP	LAB_B938		; nornalise FAC1 for C=1 and return


;************************************************************************************
;
; get FAC1 sign
; return A = $FF, Cb = 1/-ve A = $01, Cb = 0/+ve, A = $00, Cb = ?/0

LAB_BC2B
	LDA	LAB_61		; get FAC1 exponent
	BEQ	LAB_BC38		; exit if zero (allready correct SGN(0)=0)


;************************************************************************************
;
; return A = $FF, Cb = 1/-ve A = $01, Cb = 0/+ve
; no = 0 check

LAB_BC2F
	LDA	LAB_66		; else get FAC1 sign (b7)


;************************************************************************************
;
; return A = $FF, Cb = 1/-ve A = $01, Cb = 0/+ve
; no = 0 check, sign in A

LAB_BC31
	ROL				; move sign bit to carry
	LDA	#$FF			; set byte for -ve result
	BCS	LAB_BC38		; return if sign was set (-ve)

	LDA	#$01			; else set byte for +ve result
LAB_BC38
	RTS


;************************************************************************************
;
; perform SGN()

LAB_BC39
	JSR	LAB_BC2B		; get FAC1 sign, return A = $FF -ve, A = $01 +ve


;************************************************************************************
;
; save A as integer byte

LAB_BC3C
	STA	LAB_62		; save FAC1 mantissa 1
	LDA	#$00			; clear A
	STA	LAB_63		; clear FAC1 mantissa 2
	LDX	#$88			; set exponent

; set exponent = X, clear FAC1 3 and 4 and normalise

LAB_BC44
	LDA	LAB_62		; get FAC1 mantissa 1
	EOR	#$FF			; complement it
	ROL				; sign bit into carry

; set exponent = X, clear mantissa 4 and 3 and normalise FAC1

LAB_BC49
	LDA	#$00			; clear A
	STA	LAB_65		; clear FAC1 mantissa 4
	STA	LAB_64		; clear FAC1 mantissa 3

; set exponent = X and normalise FAC1

LAB_BC4F
	STX	LAB_61		; set FAC1 exponent
	STA	LAB_70		; clear FAC1 rounding byte
	STA	LAB_66		; clear FAC1 sign (b7)
	JMP	LAB_B8D2		; do ABS and normalise FAC1


;************************************************************************************
;
; perform ABS()

LAB_BC58
	LSR	LAB_66		; clear FAC1 sign, put zero in b7
	RTS


;************************************************************************************
;
; compare FAC1 with (AY)
; returns A=$00 if FAC1 = (AY)
; returns A=$01 if FAC1 > (AY)
; returns A=$FF if FAC1 < (AY)

LAB_BC5B
	STA	LAB_24		; save pointer low byte
LAB_BC5D
	STY	LAB_25		; save pointer high byte
	LDY	#$00			; clear index
	LDA	(LAB_24),Y		; get exponent
	INY				; increment index
	TAX				; copy (AY) exponent to X
	BEQ	LAB_BC2B		; branch if (AY) exponent=0 and get FAC1 sign
					; A = $FF, Cb = 1/-ve A = $01, Cb = 0/+ve

	LDA	(LAB_24),Y		; get (AY) mantissa 1, with sign
	EOR	LAB_66		; EOR FAC1 sign (b7)
	BMI	LAB_BC2F		; if signs <> do return A = $FF, Cb = 1/-ve
					; A = $01, Cb = 0/+ve and return

	CPX	LAB_61		; compare (AY) exponent with FAC1 exponent
	BNE	LAB_BC92		; branch if different

	LDA	(LAB_24),Y		; get (AY) mantissa 1, with sign
	ORA	#$80			; normalise top bit
	CMP	LAB_62		; compare with FAC1 mantissa 1
	BNE	LAB_BC92		; branch if different

	INY				; increment index
	LDA	(LAB_24),Y		; get mantissa 2
	CMP	LAB_63		; compare with FAC1 mantissa 2
	BNE	LAB_BC92		; branch if different

	INY				; increment index
	LDA	(LAB_24),Y		; get mantissa 3
	CMP	LAB_64		; compare with FAC1 mantissa 3
	BNE	LAB_BC92		; branch if different

	INY				; increment index
	LDA	#$7F			; set for 1/2 value rounding byte
	CMP	LAB_70		; compare with FAC1 rounding byte (set carry)
	LDA	(LAB_24),Y		; get mantissa 4
	SBC	LAB_65		; subtract FAC1 mantissa 4
	BEQ	LAB_BCBA		; exit if mantissa 4 equal

; gets here if number <> FAC1

LAB_BC92
	LDA	LAB_66		; get FAC1 sign (b7)
	BCC	LAB_BC98		; branch if FAC1 > (AY)

	EOR	#$FF			; else toggle FAC1 sign
LAB_BC98
	JMP	LAB_BC31		; return A = $FF, Cb = 1/-ve A = $01, Cb = 0/+ve


;************************************************************************************
;
; convert FAC1 floating to fixed

LAB_BC9B
	LDA	LAB_61		; get FAC1 exponent
	BEQ	LAB_BCE9		; if zero go clear FAC1 and return

	SEC				; set carry for subtract
	SBC	#$A0			; subtract maximum integer range exponent
	BIT	LAB_66		; test FAC1 sign (b7)
	BPL	LAB_BCAF		; branch if FAC1 +ve

					; FAC1 was -ve
	TAX				; copy subtracted exponent
	LDA	#$FF			; overflow for -ve number
	STA	LAB_68		; set FAC1 overflow byte
	JSR	LAB_B94D		; twos complement FAC1 mantissa
	TXA				; restore subtracted exponent
LAB_BCAF
	LDX	#$61			; set index to FAC1
	CMP	#$F9			; compare exponent result
	BPL	LAB_BCBB		; if < 8 shifts shift FAC1 A times right and return

	JSR	LAB_B999		; shift FAC1 A times right (> 8 shifts)
	STY	LAB_68		; clear FAC1 overflow byte
LAB_BCBA
	RTS


;************************************************************************************
;
; shift FAC1 A times right

LAB_BCBB
	TAY				; copy shift count
	LDA	LAB_66		; get FAC1 sign (b7)
	AND	#$80			; mask sign bit only (x000 0000)
	LSR	LAB_62		; shift FAC1 mantissa 1
	ORA	LAB_62		; OR sign in b7 FAC1 mantissa 1
	STA	LAB_62		; save FAC1 mantissa 1
	JSR	LAB_B9B0		; shift FAC1 Y times right
	STY	LAB_68		; clear FAC1 overflow byte
	RTS


;************************************************************************************
;
; perform INT()

LAB_BCCC
	LDA	LAB_61		; get FAC1 exponent
	CMP	#$A0			; compare with max int
	BCS	LAB_BCF2		; exit if >= (allready int, too big for fractional part!)

	JSR	LAB_BC9B		; convert FAC1 floating to fixed
	STY	LAB_70		; save FAC1 rounding byte
	LDA	LAB_66		; get FAC1 sign (b7)
	STY	LAB_66		; save FAC1 sign (b7)
	EOR	#$80			; toggle FAC1 sign
	ROL				; shift into carry
	LDA	#$A0			; set new exponent
	STA	LAB_61		; save FAC1 exponent
	LDA	LAB_65		; get FAC1 mantissa 4
	STA	LAB_07		; save FAC1 mantissa 4 for power function
	JMP	LAB_B8D2		; do ABS and normalise FAC1


;************************************************************************************
;
; clear FAC1 and return

LAB_BCE9
	STA	LAB_62		; clear FAC1 mantissa 1
	STA	LAB_63		; clear FAC1 mantissa 2
	STA	LAB_64		; clear FAC1 mantissa 3
	STA	LAB_65		; clear FAC1 mantissa 4
	TAY				; clear Y
LAB_BCF2
	RTS


;************************************************************************************
;
; get FAC1 from string

LAB_BCF3
	LDY	#$00			; clear Y
	LDX	#$0A			; set index
LAB_BCF7
	STY	LAB_5D,X		; clear byte
	DEX				; decrement index
	BPL	LAB_BCF7		; loop until numexp to negnum (and FAC1) = $00

	BCC	LAB_BD0D		; branch if first character is numeric

	CMP	#'-'			; else compare with "-"
	BNE	LAB_BD06		; branch if not "-"

	STX	LAB_67		; set flag for -ve n (negnum = $FF)
	BEQ	LAB_BD0A		; branch always

LAB_BD06
	CMP	#'+'			; else compare with "+"
	BNE	LAB_BD0F		; branch if not "+"

LAB_BD0A
	JSR	LAB_0073		; increment and scan memory
LAB_BD0D
	BCC	LAB_BD6A		; branch if numeric character

LAB_BD0F
	CMP	#'.'			; else compare with "."
	BEQ	LAB_BD41		; branch if "."

	CMP	#'E'			; else compare with "E"
	BNE	LAB_BD47		; branch if not "E"

					; was "E" so evaluate exponential part
	JSR	LAB_0073		; increment and scan memory
	BCC	LAB_BD33		; branch if numeric character

	CMP	#TK_MINUS		; else compare with token for -
	BEQ	LAB_BD2E		; branch if token for -

	CMP	#'-'			; else compare with "-"
	BEQ	LAB_BD2E		; branch if "-"

	CMP	#TK_PLUS		; else compare with token for +
	BEQ	LAB_BD30		; branch if token for +

	CMP	#'+'			; else compare with "+"
	BEQ	LAB_BD30		; branch if "+"

	BNE	LAB_BD35		; branch always

LAB_BD2E
	ROR	LAB_60		; set exponent -ve flag (C, which=1, into b7)
LAB_BD30
	JSR	LAB_0073		; increment and scan memory
LAB_BD33
	BCC	LAB_BD91		; branch if numeric character

LAB_BD35
	BIT	LAB_60		; test exponent -ve flag
	BPL	LAB_BD47		; if +ve go evaluate exponent

					; else do exponent = -exponent
	LDA	#$00			; clear result
	SEC				; set carry for subtract
	SBC	LAB_5E		; subtract exponent byte
	JMP	LAB_BD49		; go evaluate exponent

LAB_BD41
	ROR	LAB_5F		; set decimal point flag
	BIT	LAB_5F		; test decimal point flag
	BVC	LAB_BD0A		; branch if only one decimal point so far

					; evaluate exponent
LAB_BD47
	LDA	LAB_5E		; get exponent count byte
LAB_BD49
	SEC				; set carry for subtract
	SBC	LAB_5D		; subtract numerator exponent
	STA	LAB_5E		; save exponent count byte
	BEQ	LAB_BD62		; branch if no adjustment

	BPL	LAB_BD5B		; else if +ve go do FAC1*10^expcnt

					; else go do FAC1/10^(0-expcnt)
LAB_BD52
	JSR	LAB_BAFE		; divide FAC1 by 10
	INC	LAB_5E		; increment exponent count byte
	BNE	LAB_BD52		; loop until all done

	BEQ	LAB_BD62		; branch always

LAB_BD5B
	JSR	LAB_BAE2		; multiply FAC1 by 10
	DEC	LAB_5E		; decrement exponent count byte
	BNE	LAB_BD5B		; loop until all done

LAB_BD62
	LDA	LAB_67		; get -ve flag
	BMI	LAB_BD67		; if -ve do - FAC1 and return

	RTS


;************************************************************************************
;
; do - FAC1 and return

LAB_BD67
	JMP	LAB_BFB4		; do - FAC1

; do unsigned FAC1*10+number

LAB_BD6A
	PHA				; save character
	BIT	LAB_5F		; test decimal point flag
	BPL	LAB_BD71		; skip exponent increment if not set

	INC	LAB_5D		; else increment number exponent
LAB_BD71
	JSR	LAB_BAE2		; multiply FAC1 by 10
	PLA				; restore character
	SEC				; set carry for subtract
	SBC	#'0'			; convert to binary
	JSR	LAB_BD7E		; evaluate new ASCII digit
	JMP	LAB_BD0A		; go do next character

; evaluate new ASCII digit
; multiply FAC1 by 10 then (ABS) add in new digit

LAB_BD7E
	PHA				; save digit
	JSR	LAB_BC0C		; round and copy FAC1 to FAC2
	PLA				; restore digit
	JSR	LAB_BC3C		; save A as integer byte
	LDA	LAB_6E		; get FAC2 sign (b7)
	EOR	LAB_66		; toggle with FAC1 sign (b7)
	STA	LAB_6F		; save sign compare (FAC1 EOR FAC2)
	LDX	LAB_61		; get FAC1 exponent
	JMP	LAB_B86A		; add FAC2 to FAC1 and return

; evaluate next character of exponential part of number

LAB_BD91
	LDA	LAB_5E		; get exponent count byte
	CMP	#$0A			; compare with 10 decimal
	BCC	LAB_BDA0		; branch if less

	LDA	#$64			; make all -ve exponents = -100 decimal (causes underflow)
	BIT	LAB_60		; test exponent -ve flag
	BMI	LAB_BDAE		; branch if -ve

	JMP	LAB_B97E		; else do overflow error then warm start

LAB_BDA0
	ASL				; *2
	ASL				; *4
	CLC				; clear carry for add
	ADC	LAB_5E		; *5
	ASL				; *10
	CLC				; clear carry for add
	LDY	#$00			; set index
	ADC	(LAB_7A),Y		; add character (will be $30 too much!)
	SEC				; set carry for subtract
	SBC	#'0'			; convert character to binary
LAB_BDAE
	STA	LAB_5E		; save exponent count byte
	JMP	LAB_BD30		; go get next character


;************************************************************************************
;
; limits for scientific mode

LAB_BDB3
	.byte	$9B,$3E,$BC,$1F,$FD
					; 99999999.90625, maximum value with at least one decimal
LAB_BDB8
	.byte	$9E,$6E,$6B,$27,$FD
					; 999999999.25, maximum value before scientific notation
LAB_BDBD
	.byte	$9E,$6E,$6B,$28,$00
					; 1000000000


;************************************************************************************
;
; do " IN " line number message

LAB_BDC2
	LDA	#<LAB_A371		; set " IN " pointer low byte
	LDY	#>LAB_A371		; set " IN " pointer high byte
	JSR	LAB_BDDA		; print null terminated string
	LDA	LAB_3A		; get the current line number high byte
	LDX	LAB_39		; get the current line number low byte


;************************************************************************************
;
; print XA as unsigned integer

LAB_BDCD
	STA	LAB_62		; save high byte as FAC1 mantissa1
	STX	LAB_63		; save low byte as FAC1 mantissa2
	LDX	#$90			; set exponent to 16d bits
	SEC				; set integer is +ve flag
	JSR	LAB_BC49		; set exponent = X, clear mantissa 4 and 3 and normalise
					; FAC1
	JSR	LAB_BDDF		; convert FAC1 to string
LAB_BDDA
	JMP	LAB_AB1E		; print null terminated string


;************************************************************************************
;
; convert FAC1 to ASCII string result in (AY)

LAB_BDDD
	LDY	#$01			; set index = 1
LAB_BDDF
	LDA	#' '			; character = " " (assume +ve)
	BIT	LAB_66		; test FAC1 sign (b7)
	BPL	LAB_BDE7		; branch if +ve

	LDA	#'-'			; else character = "-"
LAB_BDE7
	STA	LAB_FF,Y		; save leading character (" " or "-")
	STA	LAB_66		; save FAC1 sign (b7)
	STY	LAB_71		; save index
	INY				; increment index
	LDA	#'0'			; set character = "0"
	LDX	LAB_61		; get FAC1 exponent
	BNE	LAB_BDF8		; branch if FAC1<>0

					; exponent was $00 so FAC1 is 0
	JMP	LAB_BF04		; save last character, [EOT] and exit

					; FAC1 is some non zero value
LAB_BDF8
	LDA	#$00			; clear (number exponent count)
	CPX	#$80			; compare FAC1 exponent with $80 (<1.00000)
LAB_BDFC
	BEQ	LAB_BE00		; branch if 0.5 <= FAC1 < 1.0

	BCS	LAB_BE09		; branch if FAC1=>1

LAB_BE00
	LDA	#<LAB_BDBD		; set 1000000000 pointer low byte
	LDY	#>LAB_BDBD		; set 1000000000 pointer high byte
	JSR	LAB_BA28		; do convert AY, FCA1*(AY)
	LDA	#$F7			; set number exponent count
LAB_BE09
	STA	LAB_5D		; save number exponent count
LAB_BE0B
	LDA	#<LAB_BDB8		; set 999999999.25 pointer low byte (max before sci note)
	LDY	#>LAB_BDB8		; set 999999999.25 pointer high byte
	JSR	LAB_BC5B		; compare FAC1 with (AY)
	BEQ	LAB_BE32		; exit if FAC1 = (AY)

	BPL	LAB_BE28		; go do /10 if FAC1 > (AY)

					; FAC1 < (AY)
LAB_BE16
	LDA	#<LAB_BDB3		; set 99999999.90625 pointer low byte
	LDY	#>LAB_BDB3		; set 99999999.90625 pointer high byte
	JSR	LAB_BC5B		; compare FAC1 with (AY)
	BEQ	LAB_BE21		; branch if FAC1 = (AY) (allow decimal places)

	BPL	LAB_BE2F		; branch if FAC1 > (AY) (no decimal places)

					; FAC1 <= (AY)
LAB_BE21
	JSR	LAB_BAE2		; multiply FAC1 by 10
	DEC	LAB_5D		; decrement number exponent count
	BNE	LAB_BE16		; go test again, branch always

LAB_BE28
	JSR	LAB_BAFE		; divide FAC1 by 10
	INC	LAB_5D		; increment number exponent count
	BNE	LAB_BE0B		; go test again, branch always

; now we have just the digits to do

LAB_BE2F
	JSR	LAB_B849		; add 0.5 to FAC1 (round FAC1)
LAB_BE32
	JSR	LAB_BC9B		; convert FAC1 floating to fixed
	LDX	#$01			; set default digits before dp = 1
	LDA	LAB_5D		; get number exponent count
	CLC				; clear carry for add
	ADC	#$0A			; up to 9 digits before point
	BMI	LAB_BE47		; if -ve then 1 digit before dp

	CMP	#$0B			; A>=$0B if n>=1E9
	BCS	LAB_BE48		; branch if >= $0B

					; carry is clear
	ADC	#$FF			; take 1 from digit count
	TAX				; copy to X
	LDA	#$02			;.set exponent adjust
LAB_BE47
	SEC				; set carry for subtract
LAB_BE48
	SBC	#$02			; -2
	STA	LAB_5E		;.save exponent adjust
	STX	LAB_5D		; save digits before dp count
	TXA				; copy to A
	BEQ	LAB_BE53		; branch if no digits before dp

	BPL	LAB_BE66		; branch if digits before dp

LAB_BE53
	LDY	LAB_71		; get output string index
	LDA	#'.'			; character "."
	INY				; increment index
	STA	LAB_FF,Y		; save to output string
	TXA				;.
	BEQ	LAB_BE64		;.

	LDA	#'0'			; character "0"
	INY				; increment index
	STA	LAB_FF,Y		; save to output string
LAB_BE64
	STY	LAB_71		; save output string index
LAB_BE66
	LDY	#$00			; clear index (point to 100,000)
LAB_BE68
	LDX	#$80			;.
LAB_BE6A
	LDA	LAB_65		; get FAC1 mantissa 4
	CLC				; clear carry for add
	ADC	LAB_BF16+3,Y	; add byte 4, least significant
	STA	LAB_65		; save FAC1 mantissa4
	LDA	LAB_64		; get FAC1 mantissa 3
	ADC	LAB_BF16+2,Y	; add byte 3
	STA	LAB_64		; save FAC1 mantissa3
	LDA	LAB_63		; get FAC1 mantissa 2
	ADC	LAB_BF16+1,Y	; add byte 2
	STA	LAB_63		; save FAC1 mantissa2
	LDA	LAB_62		; get FAC1 mantissa 1
	ADC	LAB_BF16+0,Y	; add byte 1, most significant
	STA	LAB_62		; save FAC1 mantissa1
	INX				; increment the digit, set the sign on the test sense bit
	BCS	LAB_BE8E		; if the carry is set go test if the result was positive

					; else the result needs to be negative
	BPL	LAB_BE6A		; not -ve so try again

	BMI	LAB_BE90		; else done so return the digit

LAB_BE8E
	BMI	LAB_BE6A		; not +ve so try again

; else done so return the digit

LAB_BE90
	TXA				; copy the digit
	BCC	LAB_BE97		; if Cb=0 just use it

	EOR	#$FF			; else make the 2's complement ..
	ADC	#$0A			; .. and subtract it from 10
LAB_BE97
	ADC	#'0'-1		; add "0"-1 to result
	INY				; increment ..
	INY				; .. index to..
	INY				; .. next less ..
	INY				; .. power of ten
	STY	LAB_47		; save current variable pointer low byte
	LDY	LAB_71		; get output string index
	INY				; increment output string index
	TAX				; copy character to X
	AND	#$7F			; mask out top bit
	STA	LAB_FF,Y		; save to output string
	DEC	LAB_5D		; decrement # of characters before the dp
	BNE	LAB_BEB2		; branch if still characters to do

					; else output the point
	LDA	#'.'			; character "."
	INY				; increment output string index
	STA	LAB_0100-1,Y	; save to output string
LAB_BEB2
	STY	LAB_71		; save output string index
	LDY	LAB_47		; get current variable pointer low byte
	TXA				; get character back
	EOR	#$FF			; toggle the test sense bit
	AND	#$80			; clear the digit
	TAX				; copy it to the new digit
	CPY	#LAB_BF3A-LAB_BF16
					; compare the table index with the max for decimal numbers
	BEQ	LAB_BEC4		; if at the max exit the digit loop

	CPY	#LAB_BF52-LAB_BF16
					; compare the table index with the max for time
	BNE	LAB_BE6A		; loop if not at the max

; now remove trailing zeroes

LAB_BEC4
	LDY	LAB_71		; restore the output string index
LAB_BEC6
	LDA	LAB_0100-1,Y	; get character from output string
	DEY				; decrement output string index
	CMP	#'0'			; compare with "0"
	BEQ	LAB_BEC6		; loop until non "0" character found

	CMP	#'.'			; compare with "."
	BEQ	LAB_BED3		; branch if was dp

					; restore last character
	INY				; increment output string index
LAB_BED3
	LDA	#'+'			; character "+"
	LDX	LAB_5E		; get exponent count
	BEQ	LAB_BF07		; if zero go set null terminator and exit

					; exponent isn't zero so write exponent
	BPL	LAB_BEE3		; branch if exponent count +ve

	LDA	#$00			; clear A
	SEC				; set carry for subtract
	SBC	LAB_5E		; subtract exponent count adjust (convert -ve to +ve)
	TAX				; copy exponent count to X
	LDA	#'-'			; character "-"
LAB_BEE3
	STA	LAB_0100+1,Y	; save to output string
	LDA	#'E'			; character "E"
	STA	LAB_0100,Y		; save exponent sign to output string
	TXA				; get exponent count back
	LDX	#'0'-1		; one less than "0" character
	SEC				; set carry for subtract
LAB_BEEF
	INX				; increment 10's character
	SBC	#$0A			;.subtract 10 from exponent count
	BCS	LAB_BEEF		; loop while still >= 0

	ADC	#':'			; add character ":" ($30+$0A, result is 10 less that value)
	STA	LAB_0100+3,Y	; save to output string
	TXA				; copy 10's character
	STA	LAB_0100+2,Y	; save to output string
	LDA	#$00			; set null terminator
	STA	LAB_0100+4,Y	; save to output string
	BEQ	LAB_BF0C		; go set string pointer (AY) and exit, branch always

					; save last character, [EOT] and exit
LAB_BF04
	STA	LAB_0100-1,Y	; save last character to output string

					; set null terminator and exit
LAB_BF07
	LDA	#$00			; set null terminator
	STA	LAB_0100,Y		; save after last character

					; set string pointer (AY) and exit
LAB_BF0C
	LDA	#<LAB_0100		; set result string pointer low byte
	LDY	#>LAB_0100		; set result string pointer high byte
	RTS


;************************************************************************************
;
; constants

LAB_BF11
	.byte	$80,$00		; 0.5, first two bytes
LAB_BF13
	.byte	$00,$00,$00		; null return for undefined variables

LAB_BF16
	.byte	$FA,$0A,$1F,$00	; -100000000
	.byte	$00,$98,$96,$80	;  +10000000
	.byte	$FF,$F0,$BD,$C0	;   -1000000
	.byte	$00,$01,$86,$A0	;    +100000
	.byte	$FF,$FF,$D8,$F0	;     -10000
	.byte	$00,$00,$03,$E8	;      +1000
	.byte	$FF,$FF,$FF,$9C	;       -100
	.byte	$00,$00,$00,$0A	;        +10
	.byte	$FF,$FF,$FF,$FF	;         -1

; jiffy counts

LAB_BF3A
	.byte	$FF,$DF,$0A,$80	; -2160000	10s hours
	.byte	$00,$03,$4B,$C0	;  +216000	    hours
	.byte	$FF,$FF,$73,$60	;   -36000	10s mins
	.byte	$00,$00,$0E,$10	;    +3600	    mins
	.byte	$FF,$FF,$FD,$A8	;     -600	10s secs
	.byte	$00,$00,$00,$3C	;      +60	    secs
LAB_BF52


;************************************************************************************
;
; not referenced

	.byte	$EC			; checksum byte


;************************************************************************************
;
; spare bytes, not referenced

	.byte	$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA
	.byte	$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA


;************************************************************************************
;
; perform SQR()

LAB_BF71
	JSR	LAB_BC0C		; round and copy FAC1 to FAC2
	LDA	#<LAB_BF11		; set 0.5 pointer low address
	LDY	#>LAB_BF11		; set 0.5 pointer high address
	JSR	LAB_BBA2		; unpack memory (AY) into FAC1


;************************************************************************************
;
; perform power function

LAB_BF7B
	BEQ	LAB_BFED		; perform EXP()

	LDA	LAB_69		; get FAC2 exponent
	BNE	LAB_BF84		; branch if FAC2<>0

	JMP	LAB_B8F9		; clear FAC1 exponent and sign and return

LAB_BF84
	LDX	#<LAB_4E		; set destination pointer low byte
	LDY	#>LAB_4E		; set destination pointer high byte
	JSR	LAB_BBD4		; pack FAC1 into (XY)
	LDA	LAB_6E		; get FAC2 sign (b7)
	BPL	LAB_BF9E		; branch if FAC2>0

					; else FAC2 is -ve and can only be raised to an
					; integer power which gives an x + j0 result
	JSR	LAB_BCCC		; perform INT()
	LDA	#<LAB_4E		; set source pointer low byte
	LDY	#>LAB_4E		; set source pointer high byte
	JSR	LAB_BC5B		; compare FAC1 with (AY)
	BNE	LAB_BF9E		; branch if FAC1 <> (AY) to allow Function Call error
					; this will leave FAC1 -ve and cause a Function Call
					; error when LOG() is called

	TYA				; clear sign b7
	LDY	LAB_07		; get FAC1 mantissa 4 from INT() function as sign in
					; Y for possible later negation, b0 only needed
LAB_BF9E
	JSR	LAB_BBFE		; save FAC1 sign and copy ABS(FAC2) to FAC1
	TYA				; copy sign back ..
	PHA				; .. and save it
	JSR	LAB_B9EA		; perform LOG()
	LDA	#<LAB_4E		; set pointer low byte
	LDY	#>LAB_4E		; set pointer high byte
	JSR	LAB_BA28		; do convert AY, FCA1*(AY)
	JSR	LAB_BFED		; perform EXP()
	PLA				; pull sign from stack
	LSR				; b0 is to be tested
	BCC	LAB_BFBE		; if no bit then exit

; do - FAC1

LAB_BFB4
	LDA	LAB_61		; get FAC1 exponent
	BEQ	LAB_BFBE		; exit if FAC1_e = $00

	LDA	LAB_66		; get FAC1 sign (b7)
	EOR	#$FF			; complement it
	STA	LAB_66		; save FAC1 sign (b7)
LAB_BFBE
	RTS


;************************************************************************************
;
; exp(n) constant and series

LAB_BFBF
	.byte	$81,$38,$AA,$3B,$29	; 1.443

LAB_BFC4
	.byte	$07				; series count
	.byte	$71,$34,$58,$3E,$56	; 2.14987637E-5
	.byte	$74,$16,$7E,$B3,$1B	; 1.43523140E-4
	.byte	$77,$2F,$EE,$E3,$85	; 1.34226348E-3
	.byte	$7A,$1D,$84,$1C,$2A	; 9.61401701E-3
	.byte	$7C,$63,$59,$58,$0A	; 5.55051269E-2
	.byte	$7E,$75,$FD,$E7,$C6	; 2.40226385E-1
	.byte	$80,$31,$72,$18,$10	; 6.93147186E-1
	.byte	$81,$00,$00,$00,$00	; 1.00000000


;************************************************************************************
;
; perform EXP()

LAB_BFED
	LDA	#<LAB_BFBF		; set 1.443 pointer low byte
	LDY	#>LAB_BFBF		; set 1.443 pointer high byte
	JSR	LAB_BA28		; do convert AY, FCA1*(AY)
	LDA	LAB_70		; get FAC1 rounding byte
	ADC	#$50			; +$50/$100
	BCC	LAB_BFFD		; skip rounding if no carry

	JSR	LAB_BC23		; round FAC1 (no check)
LAB_BFFD
	JMP	LAB_E000		; continue EXP()


;************************************************************************************
;
; start of the kernal ROM

	.ORG	$E000

; EXP() continued

LAB_E000
	STA	LAB_56		; save FAC2 rounding byte
	JSR	LAB_BC0F		; copy FAC1 to FAC2
	LDA	LAB_61		; get FAC1 exponent
	CMP	#$88			; compare with EXP limit (256d)
	BCC	LAB_E00E		; branch if less

LAB_E00B
	JSR	LAB_BAD4		; handle overflow and underflow
LAB_E00E
	JSR	LAB_BCCC		; perform INT()
	LDA	LAB_07		; get mantissa 4 from INT()
	CLC				; clear carry for add
	ADC	#$81			; normalise +1
	BEQ	LAB_E00B		; if $00 result has overflowed so go handle it

	SEC				; set carry for subtract
	SBC	#$01			; exponent now correct
	PHA				; save FAC2 exponent
					; swap FAC1 and FAC2
	LDX	#$05			; 4 bytes to do
LAB_E01E
	LDA	LAB_69,X		; get FAC2,X
	LDY	LAB_61,X		; get FAC1,X
	STA	LAB_61,X		; save FAC1,X
	STY	LAB_69,X		; save FAC2,X
	DEX				; decrement count/index
	BPL	LAB_E01E		; loop if not all done

	LDA	LAB_56		; get FAC2 rounding byte
	STA	LAB_70		; save as FAC1 rounding byte
	JSR	LAB_B853		; perform subtraction, FAC2 from FAC1
	JSR	LAB_BFB4		; do - FAC1
	LDA	#<LAB_BFC4		; set counter pointer low byte
	LDY	#>LAB_BFC4		; set counter pointer high byte
	JSR	LAB_E059		; go do series evaluation
	LDA	#$00			; clear A
	STA	LAB_6F		; clear sign compare (FAC1 EOR FAC2)
	PLA				;.get saved FAC2 exponent
	JSR	LAB_BAB9		; test and adjust accumulators
	RTS

; ^2 then series evaluation

LAB_E043
	STA	LAB_71		; save count pointer low byte
	STY	LAB_72		; save count pointer high byte
	JSR	LAB_BBCA		; pack FAC1 into LAB_57
	LDA	#<LAB_57		; set pointer low byte (Y already $00)
	JSR	LAB_BA28		; do convert AY, FCA1*(AY)
	JSR	LAB_E05D		; go do series evaluation
	LDA	#<LAB_57		; pointer to original # low byte
	LDY	#>LAB_57		; pointer to original # high byte
	JMP	LAB_BA28		; do convert AY, FCA1*(AY)

; do series evaluation

LAB_E059
	STA	LAB_71		; save count pointer low byte
	STY	LAB_72		; save count pointer high byte

; do series evaluation

LAB_E05D
	JSR	LAB_BBC7		; pack FAC1 into LAB_5C
	LDA	(LAB_71),Y		; get constants count
	STA	LAB_67		; save constants count
	LDY	LAB_71		; get count pointer low byte
	INY				; increment it (now constants pointer)
	TYA				; copy it
	BNE	LAB_E06C		; skip next if no overflow

	INC	LAB_72		; else increment high byte
LAB_E06C
	STA	LAB_71		; save low byte
	LDY	LAB_72		; get high byte
LAB_E070
	JSR	LAB_BA28		; do convert AY, FCA1*(AY)
	LDA	LAB_71		; get constants pointer low byte
	LDY	LAB_72		; get constants pointer high byte
	CLC				; clear carry for add
	ADC	#$05			; +5 to low pointer (5 bytes per constant)
	BCC	LAB_E07D		; skip next if no overflow

	INY				; increment high byte
LAB_E07D
	STA	LAB_71		; save pointer low byte
	STY	LAB_72		; save pointer high byte
	JSR	LAB_B867		; add (AY) to FAC1
	LDA	#<LAB_5C		; set pointer low byte to partial
	LDY	#>LAB_5C		; set pointer high byte to partial
	DEC	LAB_67		; decrement constants count
	BNE	LAB_E070		; loop until all done

	RTS


;************************************************************************************
;
; RND values

LAB_E08D
	.byte	$98,$35,$44,$7A,$00
					; 11879546			multiplier

LAB_E092
	.byte	$68,$28,$B1,$46,$00
					; 3.927677739E-8		offset


;************************************************************************************
;
; perform RND()

LAB_E097
	JSR	LAB_BC2B		; get FAC1 sign
					; return A = $FF -ve, A = $01 +ve
	BMI	LAB_E0D3		; if n<0 copy byte swapped FAC1 into RND() seed

	BNE	LAB_E0BE		; if n>0 get next number in RND() sequence

					; else n=0 so get the RND() number from VIA 1 timers
	JSR	LAB_FFF3		; return base address of I/O devices
	STX	LAB_22		; save pointer low byte
	STY	LAB_23		; save pointer high byte
	LDY	#$04			; set index to T1 low byte
	LDA	(LAB_22),Y		; get T1 low byte
	STA	LAB_62		; save FAC1 mantissa 1
	INY				; increment index
	LDA	(LAB_22),Y		; get T1 high byte
	STA	LAB_64		; save FAC1 mantissa 3
	LDY	#$08			; set index to T2 low byte
	LDA	(LAB_22),Y		; get T2 low byte
	STA	LAB_63		; save FAC1 mantissa 2
	INY				; increment index
	LDA	(LAB_22),Y		; get T2 high byte
	STA	LAB_65		; save FAC1 mantissa 4
	JMP	LAB_E0E3		; set exponent and exit

LAB_E0BE
	LDA	#<LAB_8B		; set seed pointer low address
	LDY	#>LAB_8B		; set seed pointer high address
	JSR	LAB_BBA2		; unpack memory (AY) into FAC1
	LDA	#<LAB_E08D		; set 11879546 pointer low byte
	LDY	#>LAB_E08D		; set 11879546 pointer high byte
	JSR	LAB_BA28		; do convert AY, FCA1*(AY)
	LDA	#<LAB_E092		; set 3.927677739E-8 pointer low byte
	LDY	#>LAB_E092		; set 3.927677739E-8 pointer high byte
	JSR	LAB_B867		; add (AY) to FAC1
LAB_E0D3
	LDX	LAB_65		; get FAC1 mantissa 4
	LDA	LAB_62		; get FAC1 mantissa 1
	STA	LAB_65		; save FAC1 mantissa 4
	STX	LAB_62		; save FAC1 mantissa 1
	LDX	LAB_63		; get FAC1 mantissa 2
	LDA	LAB_64		; get FAC1 mantissa 3
	STA	LAB_63		; save FAC1 mantissa 2
	STX	LAB_64		; save FAC1 mantissa 3
LAB_E0E3
	LDA	#$00			; clear byte
	STA	LAB_66		; clear FAC1 sign (always +ve)
	LDA	LAB_61		; get FAC1 exponent
	STA	LAB_70		; save FAC1 rounding byte
	LDA	#$80			; set exponent = $80
	STA	LAB_61		; save FAC1 exponent
	JSR	LAB_B8D7		; normalise FAC1
	LDX	#<LAB_8B		; set seed pointer low address
	LDY	#>LAB_8B		; set seed pointer high address


;************************************************************************************
;
; pack FAC1 into (XY)

LAB_E0F6
	JMP	LAB_BBD4		; pack FAC1 into (XY)


;************************************************************************************
;
; handle BASIC I/O error

LAB_E0F9
	CMP	#$F0			; compare error with $F0
	BNE	LAB_E104		; branch if not $F0

	STY	LAB_38		; set end of memory high byte
	STX	LAB_37		; set end of memory low byte
	JMP	LAB_A663		; clear from start to end and return

					; error was not $F0
LAB_E104
	TAX				; copy error #
	BNE	LAB_E109		; branch if not $00

	LDX	#$1E			; else error $1E, break error
LAB_E109
	JMP	LAB_A437		; do error #X then warm start


;************************************************************************************
;
; output character to channel with error check

LAB_E10C
	JSR	LAB_FFD2		; output character to channel
	BCS	LAB_E0F9		; if error go handle BASIC I/O error

	RTS


;************************************************************************************
;
; input character from channel with error check

LAB_E112
	JSR	LAB_FFCF		; input character from channel
	BCS	LAB_E0F9		; if error go handle BASIC I/O error

	RTS


;************************************************************************************
;
; open channel for output with error check

LAB_E118
	JSR	LAB_E4AD		; open channel for output
	BCS	LAB_E0F9		; if error go handle BASIC I/O error

	RTS


;************************************************************************************
;
; open channel for input with error check

LAB_E11E
	JSR	LAB_FFC6		; open channel for input
	BCS	LAB_E0F9		; if error go handle BASIC I/O error

	RTS


;************************************************************************************
;
; get character from input device with error check

LAB_E124
	JSR	LAB_FFE4		; get character from input device
	BCS	LAB_E0F9		; if error go handle BASIC I/O error

	RTS


;************************************************************************************
;
; perform SYS

LAB_E12A
	JSR	LAB_AD8A		; evaluate expression and check is numeric, else do
					; type mismatch
	JSR	LAB_B7F7		; convert FAC_1 to integer in temporary integer
	LDA	#>LAB_E146		; get return address high byte
	PHA				; push as return address
	LDA	#<LAB_E146		; get return address low byte
	PHA				; push as return address
	LDA	LAB_030F		; get saved status register
	PHA				; put on stack
	LDA	LAB_030C		; get saved A
	LDX	LAB_030D		; get saved X
	LDY	LAB_030E		; get saved Y
	PLP				; pull processor status
	JMP	(LAB_14)		; call SYS address

					; tail end of SYS code
LAB_E146	= *-1
;LAB_E147
	PHP				; save status
	STA	LAB_030C		; save returned A
	STX	LAB_030D		; save returned X
	STY	LAB_030E		; save returned Y
	PLA				; restore saved status
	STA	LAB_030F		; save status
	RTS


;************************************************************************************
;
; perform SAVE

LAB_E156
	JSR	LAB_E1D4		; get parameters for LOAD/SAVE
	LDX	LAB_2D		; get start of variables low byte
	LDY	LAB_2E		; get start of variables high byte
	LDA	#LAB_2B		; index to start of program memory
	JSR	LAB_FFD8		; save RAM to device, A = index to start address, XY = end
					; address low/high
	BCS	LAB_E0F9		; if error go handle BASIC I/O error

	RTS


;************************************************************************************
;
; perform VERIFY

LAB_E165
	LDA	#$01			; flag verify
	.byte	$2C			; makes next line BIT LAB_00A9


;************************************************************************************
;
; perform LOAD

LAB_E168
	LDA	#$00			; flag load
	STA	LAB_0A		; set load/verify flag
	JSR	LAB_E1D4		; get parameters for LOAD/SAVE
	LDA	LAB_0A		; get load/verify flag
	LDX	LAB_2B		; get start of memory low byte
	LDY	LAB_2C		; get start of memory high byte
	JSR	LAB_FFD5		; load RAM from a device
	BCS	LAB_E1D1		; if error go handle BASIC I/O error

	LDA	LAB_0A		; get load/verify flag
	BEQ	LAB_E195		; branch if load

	LDX	#$1C			; error $1C, verify error
	JSR	LAB_FFB7		; read I/O status word
	AND	#$10			; mask for tape read error
	BNE	LAB_E19E		; branch if no read error

	LDA	LAB_7A		; get the BASIC execute pointer low byte
					; is this correct ?? won't this mean the "OK" prompt
					; when doing a load from within a program ?
	CMP	#$02			;.
	BEQ	LAB_E194		; if ?? skip "OK" prompt

	LDA	#<LAB_A364		; set "OK" pointer low byte
	LDY	#>LAB_A364		; set "OK" pointer high byte
	JMP	LAB_AB1E		; print null terminated string

LAB_E194
	RTS


;************************************************************************************
;
; do READY return to BASIC

LAB_E195
	JSR	LAB_FFB7		; read I/O status word
	AND	#$BF			; mask x0xx xxxx, clear read error
	BEQ	LAB_E1A1		; branch if no errors

	LDX	#$1D			; error $1D, load error
LAB_E19E
	JMP	LAB_A437		; do error #X then warm start

LAB_E1A1
	LDA	LAB_7B		; get BASIC execute pointer high byte
	CMP	#$02			; compare with $02xx
	BNE	LAB_E1B5		; branch if not immediate mode

	STX	LAB_2D		; set start of variables low byte
	STY	LAB_2E		; set start of variables high byte
	LDA	#<LAB_A376		; set "READY." pointer low byte
	LDY	#>LAB_A376		; set "READY." pointer high byte
	JSR	LAB_AB1E		; print null terminated string
	JMP	LAB_A52A		; reset execution, clear variables, flush stack,
					; rebuild BASIC chain and do warm start

LAB_E1B5
	JSR	LAB_A68E		; set BASIC execute pointer to start of memory - 1
	JSR	LAB_A533		; rebuild BASIC line chaining
	JMP	LAB_A677		; rebuild BASIC line chaining, do RESTORE and return


;************************************************************************************
;
; perform OPEN

LAB_E1BE
	JSR	LAB_E219		; get parameters for OPEN/CLOSE
	JSR	LAB_FFC0		; open a logical file
	BCS	LAB_E1D1		; branch if error

	RTS


;************************************************************************************
;
; perform CLOSE

LAB_E1C7
	JSR	LAB_E219		; get parameters for OPEN/CLOSE
	LDA	LAB_49		; get logical file number
	JSR	LAB_FFC3		; close a specified logical file
	BCC	LAB_E194		; exit if no error

LAB_E1D1
	JMP	LAB_E0F9		; go handle BASIC I/O error


;************************************************************************************
;
; get parameters for LOAD/SAVE

LAB_E1D4
	LDA	#$00			; clear file name length
	JSR	LAB_FFBD		; clear the filename
	LDX	#$01			; set default device number, cassette
	LDY	#$00			; set default command
	JSR	LAB_FFBA		; set logical, first and second addresses
	JSR	LAB_E206		; exit function if [EOT] or ":"
	JSR	LAB_E257		; set filename
	JSR	LAB_E206		; exit function if [EOT] or ":"
	JSR	LAB_E200		; scan and get byte, else do syntax error then warm start
	LDY	#$00			; clear command
	STX	LAB_49		; save device number
	JSR	LAB_FFBA		; set logical, first and second addresses
	JSR	LAB_E206		; exit function if [EOT] or ":"
	JSR	LAB_E200		; scan and get byte, else do syntax error then warm start
	TXA				; copy command to A
	TAY				; copy command to Y
	LDX	LAB_49		; get device number back
	JMP	LAB_FFBA		; set logical, first and second addresses and return


;************************************************************************************
;
; scan and get byte, else do syntax error then warm start

LAB_E200
	JSR	LAB_E20E		; scan for ",byte", else do syntax error then warm start
	JMP	LAB_B79E		; get byte parameter and return

; exit function if [EOT] or ":"

LAB_E206
	JSR	LAB_0079		; scan memory
	BNE	LAB_E20D		; branch if not [EOL] or ":"

	PLA				; dump return address low byte
	PLA				; dump return address high byte
LAB_E20D
	RTS


;************************************************************************************
;
; scan for ",valid byte", else do syntax error then warm start

LAB_E20E
	JSR	LAB_AEFD		; scan for ",", else do syntax error then warm start


;************************************************************************************
;
; scan for valid byte, not [EOL] or ":", else do syntax error then warm start

LAB_E211
	JSR	LAB_0079		; scan memory
	BNE	LAB_E20D		; exit if following byte

	JMP	LAB_AF08		; else do syntax error then warm start


;************************************************************************************
;
; get parameters for OPEN/CLOSE

LAB_E219
	LDA	#$00			; clear the filename length
	JSR	LAB_FFBD		; clear the filename
	JSR	LAB_E211		; scan for valid byte, else do syntax error then warm start
	JSR	LAB_B79E		; get byte parameter, logical file number
	STX	LAB_49		; save logical file number
	TXA				; copy logical file number to A
	LDX	#$01			; set default device number, cassette
	LDY	#$00			; set default command
	JSR	LAB_FFBA		; set logical, first and second addresses
	JSR	LAB_E206		; exit function if [EOT] or ":"
	JSR	LAB_E200		; scan and get byte, else do syntax error then warm start
	STX	LAB_4A		; save device number
	LDY	#$00			; clear command
	LDA	LAB_49		; get logical file number
	CPX	#$03			; compare device number with screen
	BCC	LAB_E23F		; branch if less than screen

	DEY				; else decrement command
LAB_E23F
	JSR	LAB_FFBA		; set logical, first and second addresses
	JSR	LAB_E206		; exit function if [EOT] or ":"
	JSR	LAB_E200		; scan and get byte, else do syntax error then warm start
	TXA				; copy command to A
	TAY				; copy command to Y
	LDX	LAB_4A		; get device number
	LDA	LAB_49		; get logical file number
	JSR	LAB_FFBA		; set logical, first and second addresses
	JSR	LAB_E206		; exit function if [EOT] or ":"
	JSR	LAB_E20E		; scan for ",byte", else do syntax error then warm start


;************************************************************************************
;
; set filename

LAB_E257
	JSR	LAB_AD9E		; evaluate expression
	JSR	LAB_B6A3		; evaluate string
	LDX	LAB_22		; get string pointer low byte
	LDY	LAB_23		; get string pointer high byte
	JMP	LAB_FFBD		; set the filename and return


;************************************************************************************
;
; perform COS()

LAB_E264
	LDA	#<LAB_E2E0		; set pi/2 pointer low byte
	LDY	#>LAB_E2E0		; set pi/2 pointer high byte
	JSR	LAB_B867		; add (AY) to FAC1


;************************************************************************************
;
; perform SIN()

LAB_E26B
	JSR	LAB_BC0C		; round and copy FAC1 to FAC2
	LDA	#<LAB_E2E5		; set 2*pi pointer low byte
	LDY	#>LAB_E2E5		; set 2*pi pointer high byte
	LDX	LAB_6E		; get FAC2 sign (b7)
	JSR	LAB_BB07		; divide by (AY) (X=sign)
	JSR	LAB_BC0C		; round and copy FAC1 to FAC2
	JSR	LAB_BCCC		; perform INT()
	LDA	#$00			; clear byte
	STA	LAB_6F		; clear sign compare (FAC1 EOR FAC2)
	JSR	LAB_B853		; perform subtraction, FAC2 from FAC1
	LDA	#<LAB_E2EA		; set 0.25 pointer low byte
	LDY	#>LAB_E2EA		; set 0.25 pointer high byte
	JSR	LAB_B850		; perform subtraction, FAC1 from (AY)
	LDA	LAB_66		; get FAC1 sign (b7)
	PHA				; save FAC1 sign
	BPL	LAB_E29D		; branch if +ve

					; FAC1 sign was -ve
	JSR	LAB_B849		; add 0.5 to FAC1 (round FAC1)
	LDA	LAB_66		; get FAC1 sign (b7)
	BMI	LAB_E2A0		; branch if -ve

	LDA	LAB_12		; get the comparison evaluation flag
	EOR	#$FF			; toggle flag
	STA	LAB_12		; save the comparison evaluation flag
LAB_E29D
	JSR	LAB_BFB4		; do - FAC1
LAB_E2A0
	LDA	#<LAB_E2EA		; set 0.25 pointer low byte
	LDY	#>LAB_E2EA		; set 0.25 pointer high byte
	JSR	LAB_B867		; add (AY) to FAC1
	PLA				; restore FAC1 sign
	BPL	LAB_E2AD		; branch if was +ve

					; else correct FAC1
	JSR	LAB_BFB4		; do - FAC1
LAB_E2AD
	LDA	#<LAB_E2EF		; set pointer low byte to counter
	LDY	#>LAB_E2EF		; set pointer high byte to counter
	JMP	LAB_E043		; ^2 then series evaluation and return


;************************************************************************************
;
; perform TAN()

LAB_E2B4
	JSR	LAB_BBCA		; pack FAC1 into LAB_57
	LDA	#$00			; clear A
	STA	LAB_12		; clear the comparison evaluation flag
	JSR	LAB_E26B		; perform SIN()
	LDX	#<LAB_4E		; set sin(n) pointer low byte
	LDY	#>LAB_4E		; set sin(n) pointer high byte
	JSR	LAB_E0F6		; pack FAC1 into (XY)
	LDA	#<LAB_57		; set n pointer low byte
	LDY	#>LAB_57		; set n pointer high byte
	JSR	LAB_BBA2		; unpack memory (AY) into FAC1
	LDA	#$00			; clear byte
	STA	LAB_66		; clear FAC1 sign (b7)
	LDA	LAB_12		; get the comparison evaluation flag
	JSR	LAB_E2DC		; save flag and go do series evaluation
	LDA	#<LAB_4E		; set sin(n) pointer low byte
	LDY	#>LAB_4E		; set sin(n) pointer high byte
	JMP	LAB_BB0F		; convert AY and do (AY)/FAC1


;************************************************************************************
;
; save comparison flag and do series evaluation

LAB_E2DC
	PHA				; save comparison flag
	JMP	LAB_E29D		; add 0.25, ^2 then series evaluation


;************************************************************************************
;
; constants and series for SIN/COS(n)

LAB_E2E0
	.byte	$81,$49,$0F,$DA,$A2	; 1.570796371, pi/2, as floating number
LAB_E2E5
	.byte	$83,$49,$0F,$DA,$A2	; 6.28319, 2*pi, as floating number
LAB_E2EA
	.byte	$7F,$00,$00,$00,$00	; 0.25

LAB_E2EF
	.byte	$05				; series counter
	.byte	$84,$E6,$1A,$2D,$1B	; -14.3813907
	.byte	$86,$28,$07,$FB,$F8	;  42.0077971
	.byte	$87,$99,$68,$89,$01	; -76.7041703
	.byte	$87,$23,$35,$DF,$E1	;  81.6052237
	.byte	$86,$A5,$5D,$E7,$28	; -41.3417021
	.byte	$83,$49,$0F,$DA,$A2	;  6.28318531


;************************************************************************************
;
; perform ATN()

LAB_E30E
	LDA	LAB_66		; get FAC1 sign (b7)
	PHA				; save sign
	BPL	LAB_E316		; branch if +ve

	JSR	LAB_BFB4		; else do - FAC1
LAB_E316
	LDA	LAB_61		; get FAC1 exponent
	PHA				; push exponent
	CMP	#$81			; compare with 1
	BCC	LAB_E324		; branch if FAC1 < 1

	LDA	#<LAB_B9BC		; pointer to 1 low byte
	LDY	#>LAB_B9BC		; pointer to 1 high byte
	JSR	LAB_BB0F		; convert AY and do (AY)/FAC1
LAB_E324
	LDA	#<LAB_E33E		; pointer to series low byte
	LDY	#>LAB_E33E		; pointer to series high byte
	JSR	LAB_E043		; ^2 then series evaluation
	PLA				; restore old FAC1 exponent
	CMP	#$81			; compare with 1
	BCC	LAB_E337		; branch if FAC1 < 1

	LDA	#<LAB_E2E0		; pointer to (pi/2) low byte
	LDY	#>LAB_E2E0		; pointer to (pi/2) low byte
	JSR	LAB_B850		; perform subtraction, FAC1 from (AY)
LAB_E337
	PLA				; restore FAC1 sign
	BPL	LAB_E33D		; exit if was +ve

	JMP	LAB_BFB4		; else do - FAC1 and return

LAB_E33D
	RTS


;************************************************************************************
;
; series for ATN(n)

LAB_E33E
	.byte	$0B				; series counter
	.byte	$76,$B3,$83,$BD,$D3	;-6.84793912e-04
	.byte	$79,$1E,$F4,$A6,$F5	; 4.85094216e-03
	.byte	$7B,$83,$FC,$B0,$10	;-0.0161117015
	.byte	$7C,$0C,$1F,$67,$CA	; 0.034209638
	.byte	$7C,$DE,$53,$CB,$C1	;-0.054279133
	.byte	$7D,$14,$64,$70,$4C	; 0.0724571965
	.byte	$7D,$B7,$EA,$51,$7A	;-0.0898019185
	.byte	$7D,$63,$30,$88,$7E	; 0.110932413
	.byte	$7E,$92,$44,$99,$3A	;-0.142839808
	.byte	$7E,$4C,$CC,$91,$C7	; 0.19999912
	.byte	$7F,$AA,$AA,$AA,$13	;-0.333333316
	.byte	$81,$00,$00,$00,$00	; 1.000000000


;************************************************************************************
;
; BASIC warm start entry point

LAB_E37B
	JSR	LAB_FFCC		; close input and output channels
	LDA	#$00			; clear A
	STA	LAB_13		; set current I/O channel, flag default
	JSR	LAB_A67A		; flush BASIC stack and clear continue pointer
	CLI				; enable the interrupts
LAB_E386
	LDX	#$80			; set -ve error, just do warm start
	JMP	(LAB_0300)		; go handle error message, normally LAB_E38B

LAB_E38B
	TXA				; copy the error number
	BMI	LAB_E391		; if -ve go do warm start

	JMP	LAB_A43A		; else do error #X then warm start

LAB_E391
	JMP	LAB_A474		; do warm start


;************************************************************************************
;
; BASIC cold start entry point

LAB_E394
	JSR	LAB_E453		; initialise the BASIC vector table
	JSR	LAB_E3BF		; initialise the BASIC RAM locations
	JSR	LAB_E422		; print the start up message and initialise the memory
					; pointers
; not ok ??

	LDX	#$FB			; value for start stack
	TXS				; set stack pointer
	BNE	LAB_E386		; do "READY." warm start, branch always


;************************************************************************************
;
; character get subroutine for zero page

; the target address for the LDA $EA60 becomes the BASIC execute pointer once the
; block is copied to its destination, any non zero page address will do at assembly
; time, to assemble a three byte instruction. $EA60 is RTS, NOP.

; page 0 initialisation table from LAB_0073
; increment and scan memory

LAB_E3A2
	INC	LAB_7A		; increment BASIC execute pointer low byte
	BNE	LAB_E3A8		; branch if no carry
					; else
	INC	LAB_7B		; increment BASIC execute pointer high byte

; page 0 initialisation table from LAB_0079
; scan memory

LAB_E3A8
	LDA	$EA60			; get byte to scan, address set by call routine
	CMP	#':'			; compare with ":"
	BCS	LAB_E3B9		; exit if>=

; page 0 initialisation table from LAB_0080
; clear Cb if numeric

	CMP	#' '			; compare with " "
	BEQ	LAB_E3A2		; if " " go do next

	SEC				; set carry for SBC
	SBC	#'0'			; subtract "0"
	SEC				; set carry for SBC
	SBC	#$D0			; subtract -"0"
					; clear carry if byte = "0"-"9"
LAB_E3B9
	RTS


;************************************************************************************
;
; spare bytes, not referenced

;LAB_E3BA
	.byte	$80,$4F,$C7,$52,$58
					; 0.811635157


;************************************************************************************
;
; initialise BASIC RAM locations

LAB_E3BF
	LDA	#$4C			; opcode for JMP
	STA	LAB_54		; save for functions vector jump
	STA	LAB_0310		; save for USR() vector jump
					; set USR() vector to illegal quantity error
	LDA	#<LAB_B248		; set USR() vector low byte
	LDY	#>LAB_B248		; set USR() vector high byte
	STA	LAB_0311		; save USR() vector low byte
	STY	LAB_0312		; save USR() vector high byte
	LDA	#<LAB_B391		; set fixed to float vector low byte
	LDY	#>LAB_B391		; set fixed to float vector high byte
	STA	LAB_05		; save fixed to float vector low byte
	STY	LAB_06		; save fixed to float vector high byte
	LDA	#<LAB_B1AA		; set float to fixed vector low byte
	LDY	#>LAB_B1AA		; set float to fixed vector high byte
	STA	LAB_03		; save float to fixed vector low byte
	STY	LAB_04		; save float to fixed vector high byte

; copy the character get subroutine from LAB_E3A2 to LAB_0074

	LDX	#$1C			; set the byte count
LAB_E3E2
	LDA	LAB_E3A2,X		; get a byte from the table
	STA	LAB_0073,X		; save the byte in page zero
	DEX				; decrement the count
	BPL	LAB_E3E2		; loop if not all done

; clear descriptors, strings, program area and mamory pointers

	LDA	#$03			; set the step size, collecting descriptors
	STA	LAB_53		; save the garbage collection step size
	LDA	#$00			; clear A
	STA	LAB_68		; clear FAC1 overflow byte
	STA	LAB_13		; clear the current I/O channel, flag default
	STA	LAB_18		; clear the current descriptor stack item pointer high byte
	LDX	#$01			; set X
	STX	LAB_01FD		; set the chain link pointer low byte
	STX	LAB_01FC		; set the chain link pointer high byte
	LDX	#LAB_19		; initial the value for descriptor stack
	STX	LAB_16		; set descriptor stack pointer
	SEC				; set Cb = 1 to read the bottom of memory
	JSR	LAB_FF9C		; read/set the bottom of memory
	STX	LAB_2B		; save the start of memory low byte
	STY	LAB_2C		; save the start of memory high byte
	SEC				; set Cb = 1 to read the top of memory
	JSR	LAB_FF99		; read/set the top of memory
	STX	LAB_37		; save the end of memory low byte
	STY	LAB_38		; save the end of memory high byte
	STX	LAB_33		; set the bottom of string space low byte
	STY	LAB_34		; set the bottom of string space high byte
	LDY	#$00			; clear the index
	TYA				; clear the A
	STA	(LAB_2B),Y		; clear the the first byte of memory
	INC	LAB_2B		; increment the start of memory low byte
	BNE	LAB_E421		; if no rollover skip the high byte increment

	INC	LAB_2C		; increment start of memory high byte
LAB_E421
	RTS


;************************************************************************************
;
; print the start up message and initialise the memory pointers

LAB_E422
	LDA	LAB_2B		; get the start of memory low byte
	LDY	LAB_2C		; get the start of memory high byte
	JSR	LAB_A408		; check available memory, do out of memory error if no room

	LDA	#<LAB_E473		; set "**** COMMODORE 64 BASIC V2 ****" pointer low byte
	LDY	#>LAB_E473		; set "**** COMMODORE 64 BASIC V2 ****" pointer high byte
	JSR	LAB_AB1E		; print a null terminated string

	LDA	LAB_37		; get the end of memory low byte
	SEC				; set carry for subtract
	SBC	LAB_2B		; subtract the start of memory low byte
	TAX				; copy the result to X
	LDA	LAB_38		; get the end of memory high byte
	SBC	LAB_2C		; subtract the start of memory high byte
	JSR	LAB_BDCD		; print XA as unsigned integer
	LDA	#<LAB_E460		; set " BYTES FREE" pointer low byte
	LDY	#>LAB_E460		; set " BYTES FREE" pointer high byte
	JSR	LAB_AB1E		; print a null terminated string

	JMP	LAB_A644		; do NEW, CLEAR, RESTORE and return


;************************************************************************************
;
; BASIC vectors, these are copied to RAM from LAB_0300 onwards

LAB_E447
	.word	LAB_E38B		; error message				LAB_0300
	.word	LAB_A483		; BASIC warm start			LAB_0302
	.word	LAB_A57C		; crunch BASIC tokens			LAB_0304
	.word	LAB_A71A		; uncrunch BASIC tokens			LAB_0306
	.word	LAB_A7E4		; start new BASIC code			LAB_0308
	.word	LAB_AE86		; get arithmetic element		LAB_030A


;************************************************************************************
;
; initialise the BASIC vectors

LAB_E453
	LDX	#$0B			; set byte count
LAB_E455
	LDA	LAB_E447,X		; get byte from table
	STA	LAB_0300,X		; save byte to RAM
	DEX				; decrement index
	BPL	LAB_E455		; loop if more to do

	RTS


;************************************************************************************
;
;LAB_E45F
	.byte	$00			; unused byte ??


;************************************************************************************
;
; BASIC startup messages

LAB_E460
	.byte	" BASIC BYTES FREE",$0D,$00

LAB_E473
	.byte	$93,$0D
	.byte	"    **** COMMODORE 64 BASIC V2 ****",$0D
	.byte	$0D
	.byte	" 64K RAM SYSTEM  ",$00


;************************************************************************************
;
; unused

;LAB_E4AC
	.byte	$81			; unused byte ??


;************************************************************************************
;
; open channel for output

LAB_E4AD
	PHA				; save the flag byte
	JSR	LAB_FFC9		; open channel for output
	TAX				; copy the returned flag byte
	PLA				; restore the alling flag byte
	BCC	LAB_E4B6		; if there is no error skip copying the error flag

	TXA				; else copy the error flag
LAB_E4B6
	RTS


;************************************************************************************
;
; unused bytes

;LAB_E4B7
	.byte	$AA,$AA,$AA,$AA	; unused
	.byte	$AA,$AA,$AA,$AA	; unused
	.byte	$AA,$AA,$AA,$AA	; unused
	.byte	$AA,$AA,$AA,$AA	; unused
	.byte	$AA,$AA,$AA,$AA	; unused
	.byte	$AA,$AA,$AA,$AA	; unused
	.byte	$AA,$AA,$AA,$AA	; unused


;************************************************************************************
;
; flag the RS232 start bit and set the parity

LAB_E4D3
	STA	LAB_A9		; save the start bit check flag, set start bit received
	LDA	#$01			; set the initial parity state
	STA	LAB_AB		; save the receiver parity bit
	RTS


;************************************************************************************
;
; save the current colour to the colour RAM

LAB_E4DA
	LDA	LAB_0286		; get the current colour code
	STA	(LAB_F3),Y		; save it to the colour RAM
	RTS


;************************************************************************************
;
; wait ~8.5 seconds for any key from the STOP key column

LAB_E4E0
	ADC	#$02			; set the number of jiffies to wait
LAB_E4E2
	LDY	LAB_91		; read the stop key column
	INY				; test for $FF, no keys pressed
	BNE	LAB_E4EB		; if any keys were pressed just exit

	CMP	LAB_A1		; compare the wait time with the jiffy clock mid byte
	BNE	LAB_E4E2		; if not there yet go wait some more

LAB_E4EB
	RTS


;************************************************************************************
;
; baud rate word is calculated from ..
;
; (system clock / baud rate) / 2 - 100
;
;		system clock
;		------------
; PAL		  985248 Hz
; NTSC	 1022727 Hz

; baud rate tables for PAL C64

LAB_E4EC
	.word	$2619			;   50   baud	985300
	.word	$1944			;   75   baud	985200
	.word	$111A			;  110   baud	985160
	.word	$0DE8			;  134.5 baud	984540
	.word	$0C70			;  150   baud	985200
	.word	$0606			;  300   baud	985200
	.word	$02D1			;  600   baud	985200
	.word	$0137			; 1200   baud	986400
	.word	$00AE			; 1800   baud	986400
	.word	$0069			; 2400   baud	984000


;************************************************************************************
;
; return the base address of the I/O devices

LAB_E500
	LDX	#<LAB_DC00		; get the I/O base address low byte
	LDY	#>LAB_DC00		; get the I/O base address high byte
	RTS


;************************************************************************************
;
; return the x,y organization of the screen

LAB_E505
	LDX	#$28			; get the x size
	LDY	#$19			; get the y size
	RTS


;************************************************************************************
;
; read/set the x,y cursor position

LAB_E50A
	BCS	LAB_E513		; if read cursor go do read

	STX	LAB_D6		; save the cursor row
	STY	LAB_D3		; save the cursor column
	JSR	LAB_E56C		; set the screen pointers for the cursor row, column
LAB_E513
	LDX	LAB_D6		; get the cursor row
	LDY	LAB_D3		; get the cursor column
	RTS


;************************************************************************************
;
; initialise the screen and keyboard

LAB_E518
	JSR	LAB_E5A0		; initialise the vic chip
	LDA	#$00			; clear A
	STA	LAB_0291		; clear the shift mode switch
	STA	LAB_CF		; clear the cursor blink phase
	LDA	#<LAB_EB48		; get the keyboard decode logic pointer low byte
	STA	LAB_028F		; save the keyboard decode logic pointer low byte
	LDA	#>LAB_EB48		; get the keyboard decode logic pointer high byte
	STA	LAB_0290		; save the keyboard decode logic pointer high byte
	LDA	#$0A			; set the maximum size of the keyboard buffer
	STA	LAB_0289		; save the maximum size of the keyboard buffer
	STA	LAB_028C		; save the repeat delay counter
	LDA	#$0E			; set light blue
	STA	LAB_0286		; save the current colour code
	LDA	#$04			; speed 4
	STA	LAB_028B		; save the repeat speed counter
	LDA	#$0C			; set the cursor flash timing
	STA	LAB_CD		; save the cursor timing countdown
	STA	LAB_CC		; save the cursor enable, $00 = flash cursor


;************************************************************************************
;
; clear the screen

LAB_E544
	LDA	LAB_0288		; get the screen memory page
	ORA	#$80			; set the high bit, flag every line is a logical line start
	TAY				; copy to Y
	LDA	#$00			; clear the line start low byte
	TAX				; clear the index
LAB_E54D
	STY	LAB_D9,X		; save the start of line X pointer high byte
	CLC				; clear carry for add
	ADC	#$28			; add the line length to the low byte
	BCC	LAB_E555		; if no rollover skip the high byte increment

	INY				; else increment the high byte
LAB_E555
	INX				; increment the line index
	CPX	#$1A			; compare it with the number of lines + 1
	BNE	LAB_E54D		; loop if not all done

	LDA	#$FF			; set the end of table marker
	STA	LAB_D9,X		; mark the end of the table
	LDX	#$18			; set the line count, 25 lines to do, 0 to 24
LAB_E560
	JSR	LAB_E9FF		; clear screen line X
	DEX				; decrement the count
	BPL	LAB_E560		; loop if more to do


;************************************************************************************
;
; home the cursor

LAB_E566
	LDY	#$00			; clear Y
	STY	LAB_D3		; clear the cursor column
	STY	LAB_D6		; clear the cursor row


;************************************************************************************
;
; set screen pointers for cursor row, column

LAB_E56C
	LDX	LAB_D6		; get the cursor row
	LDA	LAB_D3		; get the cursor column
LAB_E570
	LDY	LAB_D9,X		; get start of line X pointer high byte
	BMI	LAB_E57C		; if it is the logical line start continue

	CLC				; else clear carry for add
	ADC	#$28			; add one line length
	STA	LAB_D3		; save the cursor column
	DEX				; decrement the cursor row
	BPL	LAB_E570		; loop, branch always

LAB_E57C
	JSR	LAB_E9F0		; fetch a screen address
	LDA	#$27			; set the line length
	INX				; increment the cursor row
LAB_E582
	LDY	LAB_D9,X		; get the start of line X pointer high byte
	BMI	LAB_E58C		; if logical line start exit

	CLC				; else clear carry for add
	ADC	#$28			; add one line length to the current line length
	INX				; increment the cursor row
	BPL	LAB_E582		; loop, branch always

LAB_E58C
	STA	LAB_D5		; save current screen line length
	JMP	LAB_EA24		; calculate the pointer to colour RAM and return

LAB_E591
	CPX	LAB_C9		; compare it with the input cursor row
	BEQ	LAB_E598		; if there just exit

	JMP	LAB_E6ED		; else go ??

LAB_E598
	RTS


;************************************************************************************
;
; orphan bytes ??

	NOP				; huh
	JSR	LAB_E5A0		; initialise the vic chip
	JMP	LAB_E566		; home the cursor and return


;************************************************************************************
;
; initialise the vic chip

LAB_E5A0
	LDA	#$03			; set the screen as the output device
	STA	LAB_9A		; save the output device number
	LDA	#$00			; set the keyboard as the input device
	STA	LAB_99		; save the input device number

	LDX	#$2F			; set the count/index
LAB_E5AA
	LDA	LAB_ECB9-1,X	; get a vic ii chip initialisation value
	STA	LAB_D000-1,X	; save it to the vic ii chip
	DEX				; decrement the count/index
	BNE	LAB_E5AA		; loop if more to do

	RTS


;************************************************************************************
;
; input from the keyboard buffer

LAB_E5B4
	LDY	LAB_0277		; get the current character from the buffer
	LDX	#$00			; clear the index
LAB_E5B9
	LDA	LAB_0277+1,X	; get the next character,X from the buffer
	STA	LAB_0277,X		; save it as the current character,X in the buffer
	INX				; increment the index
	CPX	LAB_C6		; compare it with the keyboard buffer index
	BNE	LAB_E5B9		; loop if more to do

	DEC	LAB_C6		; decrement keyboard buffer index
	TYA				; copy the key to A
	CLI				; enable the interrupts
	CLC				; flag got byte
	RTS


;************************************************************************************
;
; write character and wait for key

LAB_E5CA
	JSR	LAB_E716		; output character


;************************************************************************************
;
; wait for a key from the keyboard

LAB_E5CD
	LDA	LAB_C6		; get the keyboard buffer index
	STA	LAB_CC		; cursor enable, $00 = flash cursor, $xx = no flash
	STA	LAB_0292		; screen scrolling flag, $00 = scroll, $xx = no scroll
					; this disables both the cursor flash and the screen scroll
					; while there are characters in the keyboard buffer
	BEQ	LAB_E5CD		; loop if the buffer is empty

	SEI				; disable the interrupts
	LDA	LAB_CF		; get the cursor blink phase
	BEQ	LAB_E5E7		; if cursor phase skip the overwrite

					; else it is the character phase
	LDA	LAB_CE		; get the character under the cursor
	LDX	LAB_0287		; get the colour under the cursor
	LDY	#$00			; clear Y
	STY	LAB_CF		; clear the cursor blink phase
	JSR	LAB_EA13		; print character A and colour X
LAB_E5E7
	JSR	LAB_E5B4		; input from the keyboard buffer
	CMP	#$83			; compare with [SHIFT][RUN]
	BNE	LAB_E5FE		; if not [SHIFT][RUN] skip the buffer fill

					; keys are [SHIFT][RUN] so put "LOAD",$0D,"RUN",$0D into
					; the buffer
	LDX	#$09			; set the byte count
	SEI				; disable the interrupts
	STX	LAB_C6		; set the keyboard buffer index
LAB_E5F3
	LDA	LAB_ECE7-1,X	; get byte from the auto load/run table
	STA	LAB_0277-1,X	; save it to the keyboard buffer
	DEX				; decrement the count/index
	BNE	LAB_E5F3		; loop while more to do

	BEQ	LAB_E5CD		; loop for the next key, branch always

					; was not [SHIFT][RUN]
LAB_E5FE
	CMP	#$0D			; compare the key with [CR]
	BNE	LAB_E5CA		; if not [CR] print the character and get the next key

					; else it was [CR]
	LDY	LAB_D5		; get the current screen line length
	STY	LAB_D0		; input from keyboard or screen, $xx = screen,
					; $00 = keyboard
LAB_E606
	LDA	(LAB_D1),Y		; get the character from the current screen line
	CMP	#' '			; compare it with [SPACE]
	BNE	LAB_E60F		; if not [SPACE] continue

	DEY				; else eliminate the space, decrement end of input line
	BNE	LAB_E606		; loop, branch always

LAB_E60F
	INY				; increment past the last non space character on line
	STY	LAB_C8		; save the input [EOL] pointer
	LDY	#$00			; clear A
	STY	LAB_0292		; clear the screen scrolling flag, $00 = scroll
	STY	LAB_D3		; clear the cursor column
	STY	LAB_D4		; clear the cursor quote flag, $xx = quote, $00 = no quote
	LDA	LAB_C9		; get the input cursor row
	BMI	LAB_E63A		;.

	LDX	LAB_D6		; get the cursor row
	JSR	LAB_E591		; find and set the pointers for the start of logical line
	CPX	LAB_C9		; compare with input cursor row
	BNE	LAB_E63A		;.

	LDA	LAB_CA		; get the input cursor column
	STA	LAB_D3		; save the cursor column
	CMP	LAB_C8		; compare the cursor column with input [EOL] pointer
	BCC	LAB_E63A		; if less, cursor is in line, go ??

	BCS	LAB_E65D		; else the cursor is beyond the line end, branch always


;************************************************************************************
;
; input from screen or keyboard

LAB_E632
	TYA				; copy Y
	PHA				; save Y
	TXA				; copy X
	PHA				; save X
	LDA	LAB_D0		; input from keyboard or screen, $xx = screen,
					; $00 = keyboard
	BEQ	LAB_E5CD		; if keyboard go wait for key

LAB_E63A
	LDY	LAB_D3		; get the cursor column
	LDA	(LAB_D1),Y		; get character from the current screen line
	STA	LAB_D7		; save temporary last character
	AND	#$3F			; mask key bits
	ASL	LAB_D7		; << temporary last character
	BIT	LAB_D7		; test it
	BPL	LAB_E64A		; branch if not [NO KEY]

	ORA	#$80			;.
LAB_E64A
	BCC	LAB_E650		;.

	LDX	LAB_D4		; get the cursor quote flag, $xx = quote, $00 = no quote
	BNE	LAB_E654		; if in quote mode go ??

LAB_E650
	BVS	LAB_E654		;.

	ORA	#$40			;.
LAB_E654
	INC	LAB_D3		; increment the cursor column
	JSR	LAB_E684		; if open quote toggle the cursor quote flag
	CPY	LAB_C8		; compare ?? with input [EOL] pointer
	BNE	LAB_E674		; if not at line end go ??

LAB_E65D
	LDA	#$00			; clear A
	STA	LAB_D0		; clear input from keyboard or screen, $xx = screen,
					; $00 = keyboard
	LDA	#$0D			; set character [CR]
	LDX	LAB_99		; get the input device number
	CPX	#$03			; compare the input device with the screen
	BEQ	LAB_E66F		; if screen go ??

	LDX	LAB_9A		; get the output device number
	CPX	#$03			; compare the output device with the screen
	BEQ	LAB_E672		; if screen go ??

LAB_E66F
	JSR	LAB_E716		; output the character
LAB_E672
	LDA	#$0D			; set character [CR]
LAB_E674
	STA	LAB_D7		; save character
	PLA				; pull X
	TAX				; restore X
	PLA				; pull Y
	TAY				; restore Y
	LDA	LAB_D7		; restore character
	CMP	#$DE			;.
	BNE	LAB_E682		;.

	LDA	#$FF			;.
LAB_E682
	CLC				; flag ok
	RTS


;************************************************************************************
;
; if open quote toggle cursor quote flag

LAB_E684
	CMP	#$22			; comapre byte with "
	BNE	LAB_E690		; exit if not "

	LDA	LAB_D4		; get cursor quote flag, $xx = quote, $00 = no quote
	EOR	#$01			; toggle it
	STA	LAB_D4		; save cursor quote flag
	LDA	#$22			; restore the "
LAB_E690
	RTS


;************************************************************************************
;
; insert uppercase/graphic character

LAB_E691
	ORA	#$40			; change to uppercase/graphic
LAB_E693
	LDX	LAB_C7		; get the reverse flag
	BEQ	LAB_E699		; branch if not reverse

					; else ..
; insert reversed character

LAB_E697
	ORA	#$80			; reverse character
LAB_E699
	LDX	LAB_D8		; get the insert count
	BEQ	LAB_E69F		; branch if none

	DEC	LAB_D8		; else decrement the insert count
LAB_E69F
	LDX	LAB_0286		; get the current colour code
	JSR	LAB_EA13		; print character A and colour X
	JSR	LAB_E6B6		; advance the cursor

; restore the registers, set the quote flag and exit

LAB_E6A8
	PLA				; pull Y
	TAY				; restore Y
	LDA	LAB_D8		; get the insert count
	BEQ	LAB_E6B0		; skip quote flag clear if inserts to do

	LSR	LAB_D4		; clear cursor quote flag, $xx = quote, $00 = no quote
LAB_E6B0
	PLA				; pull X
	TAX				; restore X
	PLA				; restore A
	CLC				;.
	CLI				; enable the interrupts
	RTS


;************************************************************************************
;
; advance the cursor

LAB_E6B6
	JSR	LAB_E8B3		; test for line increment
	INC	LAB_D3		; increment the cursor column
	LDA	LAB_D5		; get current screen line length
	CMP	LAB_D3		; compare ?? with the cursor column
	BCS	LAB_E700		; exit if line length >= cursor column

	CMP	#$4F			; compare with max length
	BEQ	LAB_E6F7		; if at max clear column, back cursor up and do newline

	LDA	LAB_0292		; get the autoscroll flag
	BEQ	LAB_E6CD		; branch if autoscroll on

	JMP	LAB_E967		;.else open space on screen

LAB_E6CD
	LDX	LAB_D6		; get the cursor row
	CPX	#$19			; compare with max + 1
	BCC	LAB_E6DA		; if less than max + 1 go add this row to the current
					; logical line

	JSR	LAB_E8EA		; else scroll the screen
	DEC	LAB_D6		; decrement the cursor row
	LDX	LAB_D6		; get the cursor row

; add this row to the current logical line

LAB_E6DA
	ASL	LAB_D9,X		; shift start of line X pointer high byte
	LSR	LAB_D9,X		; shift start of line X pointer high byte back,

; make next screen line start of logical line, increment line length and set pointers

					; clear b7, start of logical line
	INX				; increment screen row
	LDA	LAB_D9,X		; get start of line X pointer high byte
	ORA	#$80			; mark as start of logical line
	STA	LAB_D9,X		; set start of line X pointer high byte
	DEX				; restore screen row
	LDA	LAB_D5		; get current screen line length

; add one line length and set the pointers for the start of the line

	CLC				; clear carry for add
	ADC	#$28			; add one line length
	STA	LAB_D5		; save current screen line length
LAB_E6ED
	LDA	LAB_D9,X		; get start of line X pointer high byte
	BMI	LAB_E6F4		; exit loop if start of logical line

	DEX				; else back up one line
	BNE	LAB_E6ED		; loop if not on first line

LAB_E6F4
	JMP	LAB_E9F0		; fetch a screen address
LAB_E6F7
	DEC	LAB_D6		; decrement the cursor row
	JSR	LAB_E87C		; do newline
	LDA	#$00			; clear A
	STA	LAB_D3		; clear the cursor column
LAB_E700
	RTS


;************************************************************************************
;
; back onto the previous line if possible

LAB_E701
	LDX	LAB_D6		; get the cursor row
	BNE	LAB_E70B		; branch if not top row

	STX	LAB_D3		; clear cursor column
	PLA				; dump return address low byte
	PLA				; dump return address high byte
	BNE	LAB_E6A8		; restore registers, set quote flag and exit, branch always

LAB_E70B
	DEX				; decrement the cursor row
	STX	LAB_D6		; save the cursor row
	JSR	LAB_E56C		; set the screen pointers for cursor row, column
	LDY	LAB_D5		; get current screen line length
	STY	LAB_D3		; save the cursor column
	RTS


;************************************************************************************
;
; output a character to the screen

LAB_E716
	PHA				; save character
	STA	LAB_D7		; save temporary last character
	TXA				; copy X
	PHA				; save X
	TYA				; copy Y
	PHA				; save Y
	LDA	#$00			; clear A
	STA	LAB_D0		; clear input from keyboard or screen, $xx = screen,
					; $00 = keyboard
	LDY	LAB_D3		; get cursor column
	LDA	LAB_D7		; restore last character
	BPL	LAB_E72A		; branch if unshifted

	JMP	LAB_E7D4		; do shifted characters and return

LAB_E72A
	CMP	#$0D			; compare with [CR]
	BNE	LAB_E731		; branch if not [CR]

	JMP	LAB_E891		; else output [CR] and return

LAB_E731
	CMP	#' '			; compare with [SPACE]
	BCC	LAB_E745		; branch if < [SPACE]

	CMP	#$60			;.
	BCC	LAB_E73D		; branch if $20 to $5F

					; character is $60 or greater
	AND	#$DF			;.
	BNE	LAB_E73F		;.

LAB_E73D
	AND	#$3F			;.
LAB_E73F
	JSR	LAB_E684		; if open quote toggle cursor direct/programmed flag
	JMP	LAB_E693		;.

					; character was < [SPACE] so is a control character
					; of some sort
LAB_E745
	LDX	LAB_D8		; get the insert count
	BEQ	LAB_E74C		; if no characters to insert continue

	JMP	LAB_E697		; insert reversed character

LAB_E74C
	CMP	#$14			; compare the character with [INSERT]/[DELETE]
	BNE	LAB_E77E		; if not [INSERT]/[DELETE] go ??

	TYA				;.
	BNE	LAB_E759		;.

	JSR	LAB_E701		; back onto the previous line if possible
	JMP	LAB_E773		;.

LAB_E759
	JSR	LAB_E8A1		; test for line decrement

					; now close up the line
	DEY				; decrement index to previous character
	STY	LAB_D3		; save the cursor column
	JSR	LAB_EA24		; calculate the pointer to colour RAM
LAB_E762
	INY				; increment index to next character
	LDA	(LAB_D1),Y		; get character from current screen line
	DEY				; decrement index to previous character
	STA	(LAB_D1),Y		; save character to current screen line
	INY				; increment index to next character
	LDA	(LAB_F3),Y		; get colour RAM byte
	DEY				; decrement index to previous character
	STA	(LAB_F3),Y		; save colour RAM byte
	INY				; increment index to next character
	CPY	LAB_D5		; compare with current screen line length
	BNE	LAB_E762		; loop if not there yet

LAB_E773
	LDA	#' '			; set [SPACE]
	STA	(LAB_D1),Y		; clear last character on current screen line
	LDA	LAB_0286		; get the current colour code
	STA	(LAB_F3),Y		; save to colour RAM
	BPL	LAB_E7CB		; branch always

LAB_E77E
	LDX	LAB_D4		; get cursor quote flag, $xx = quote, $00 = no quote
	BEQ	LAB_E785		; branch if not quote mode

	JMP	LAB_E697		; insert reversed character

LAB_E785
	CMP	#$12			; compare with [RVS ON]
	BNE	LAB_E78B		; if not [RVS ON] skip setting the reverse flag

	STA	LAB_C7		; else set the reverse flag
LAB_E78B
	CMP	#$13			; compare with [CLR HOME]
	BNE	LAB_E792		; if not [CLR HOME] continue

	JSR	LAB_E566		; home the cursor
LAB_E792
	CMP	#$1D			; compare with [CURSOR RIGHT]
	BNE	LAB_E7AD		; if not [CURSOR RIGHT] go ??

	INY				; increment the cursor column
	JSR	LAB_E8B3		; test for line increment
	STY	LAB_D3		; save the cursor column
	DEY				; decrement the cursor column
	CPY	LAB_D5		; compare cursor column with current screen line length
	BCC	LAB_E7AA		; exit if less

					; else the cursor column is >= the current screen line
					; length so back onto the current line and do a newline
	DEC	LAB_D6		; decrement the cursor row
	JSR	LAB_E87C		; do newline
	LDY	#$00			; clear cursor column
LAB_E7A8
	STY	LAB_D3		; save the cursor column
LAB_E7AA
	JMP	LAB_E6A8		; restore the registers, set the quote flag and exit

LAB_E7AD
	CMP	#$11			; compare with [CURSOR DOWN]
	BNE	LAB_E7CE		; if not [CURSOR DOWN] go ??

	CLC				; clear carry for add
	TYA				; copy the cursor column
	ADC	#$28			; add one line
	TAY				; copy back to Y
	INC	LAB_D6		; increment the cursor row
	CMP	LAB_D5		; compare cursor column with current screen line length
	BCC	LAB_E7A8		; if less go save cursor column and exit

	BEQ	LAB_E7A8		; if equal go save cursor column and exit

					; else the cursor has moved beyond the end of this line
					; so back it up until it's on the start of the logical line
	DEC	LAB_D6		; decrement the cursor row
LAB_E7C0
	SBC	#$28			; subtract one line
	BCC	LAB_E7C8		; if on previous line exit the loop

	STA	LAB_D3		; else save the cursor column
	BNE	LAB_E7C0		; loop if not at the start of the line

LAB_E7C8
	JSR	LAB_E87C		; do newline
LAB_E7CB
	JMP	LAB_E6A8		; restore the registers, set the quote flag and exit
LAB_E7CE
	JSR	LAB_E8CB		; set the colour code
	JMP	LAB_EC44		; go check for special character codes

LAB_E7D4
	AND	#$7F			; mask 0xxx xxxx, clear b7
	CMP	#$7F			; was it $FF before the mask
	BNE	LAB_E7DC		; branch if not

	LDA	#$5E			; else make it $5E
LAB_E7DC
	CMP	#' '			; compare the character with [SPACE]
	BCC	LAB_E7E3		; if < [SPACE] go ??

	JMP	LAB_E691		; insert uppercase/graphic character and return

					; character was $80 to $9F and is now $00 to $1F
LAB_E7E3
	CMP	#$0D			; compare with [CR]
	BNE	LAB_E7EA		; if not [CR] continue

	JMP	LAB_E891		; else output [CR] and return

					; was not [CR]
LAB_E7EA
	LDX	LAB_D4		; get the cursor quote flag, $xx = quote, $00 = no quote
	BNE	LAB_E82D		; branch if quote mode

	CMP	#$14			; compare with [INSERT DELETE]
	BNE	LAB_E829		; if not [INSERT DELETE] go ??

	LDY	LAB_D5		; get current screen line length
	LDA	(LAB_D1),Y		; get character from current screen line
	CMP	#' '			; compare the character with [SPACE]
	BNE	LAB_E7FE		; if not [SPACE] continue

	CPY	LAB_D3		; compare the current column with the cursor column
	BNE	LAB_E805		; if not cursor column go open up space on line

LAB_E7FE
	CPY	#$4F			; compare current column with max line length
	BEQ	LAB_E826		; if at line end just exit

	JSR	LAB_E965		; else open up a space on the screen
					; now open up space on the line to insert a character
LAB_E805
	LDY	LAB_D5		; get current screen line length
	JSR	LAB_EA24		; calculate the pointer to colour RAM
LAB_E80A
	DEY				; decrement the index to previous character
	LDA	(LAB_D1),Y		; get the character from the current screen line
	INY				; increment the index to next character
	STA	(LAB_D1),Y		; save the character to the current screen line
	DEY				; decrement the index to previous character
	LDA	(LAB_F3),Y		; get the current screen line colour RAM byte
	INY				; increment the index to next character
	STA	(LAB_F3),Y		; save the current screen line colour RAM byte
	DEY				; decrement the index to the previous character
	CPY	LAB_D3		; compare the index with the cursor column
	BNE	LAB_E80A		; loop if not there yet

	LDA	#' '			; set [SPACE]
	STA	(LAB_D1),Y		; clear character at cursor position on current screen line
	LDA	LAB_0286		; get current colour code
	STA	(LAB_F3),Y		; save to cursor position on current screen line colour RAM
	INC	LAB_D8		; increment insert count
LAB_E826
	JMP	LAB_E6A8		; restore the registers, set the quote flag and exit

LAB_E829
	LDX	LAB_D8		; get the insert count
	BEQ	LAB_E832		; branch if no insert space

LAB_E82D
	ORA	#$40			; change to uppercase/graphic
	JMP	LAB_E697		; insert reversed character

LAB_E832
	CMP	#$11			; compare with [CURSOR UP]
	BNE	LAB_E84C		; branch if not [CURSOR UP]

	LDX	LAB_D6		; get the cursor row
	BEQ	LAB_E871		; if on the top line go restore the registers, set the
					; quote flag and exit

	DEC	LAB_D6		; decrement the cursor row
	LDA	LAB_D3		; get the cursor column
	SEC				; set carry for subtract
	SBC	#$28			; subtract one line length
	BCC	LAB_E847		; branch if stepped back to previous line

	STA	LAB_D3		; else save the cursor column ..
	BPL	LAB_E871		; .. and exit, branch always

LAB_E847
	JSR	LAB_E56C		; set the screen pointers for cursor row, column ..
	BNE	LAB_E871		; .. and exit, branch always

LAB_E84C
	CMP	#$12			; compare with [RVS OFF]
	BNE	LAB_E854		; if not [RVS OFF] continue

	LDA	#$00			; else clear A
	STA	LAB_C7		; clear the reverse flag
LAB_E854
	CMP	#$1D			; compare with [CURSOR LEFT]
	BNE	LAB_E86A		; if not [CURSOR LEFT] go ??

	TYA				; copy the cursor column
	BEQ	LAB_E864		; if at start of line go back onto the previous line

	JSR	LAB_E8A1		; test for line decrement
	DEY				; decrement the cursor column
	STY	LAB_D3		; save the cursor column
	JMP	LAB_E6A8		; restore the registers, set the quote flag and exit

LAB_E864
	JSR	LAB_E701		; back onto the previous line if possible
	JMP	LAB_E6A8		; restore the registers, set the quote flag and exit

LAB_E86A
	CMP	#$13			; compare with [CLR]
	BNE	LAB_E874		; if not [CLR] continue

	JSR	LAB_E544		; clear the screen

LAB_E871
	JMP	LAB_E6A8		; restore the registers, set the quote flag and exit
LAB_E874
	ORA	#$80			; restore b7, colour can only be black, cyan, magenta
					; or yellow
	JSR	LAB_E8CB		; set the colour code
	JMP	LAB_EC4F		; go check for special character codes except fro switch
					; to lower case


;************************************************************************************
;
; do newline

LAB_E87C
	LSR	LAB_C9		; shift >> input cursor row
	LDX	LAB_D6		; get the cursor row
LAB_E880
	INX				; increment the row
	CPX	#$19			; compare it with last row + 1
	BNE	LAB_E888		; if not last row + 1 skip the screen scroll

	JSR	LAB_E8EA		; else scroll the screen
LAB_E888
	LDA	LAB_D9,X		; get start of line X pointer high byte
	BPL	LAB_E880		; loop if not start of logical line

	STX	LAB_D6		; save the cursor row
	JMP	LAB_E56C		; set the screen pointers for cursor row, column and return


;************************************************************************************
;
; output [CR]

LAB_E891
	LDX	#$00			; clear X
	STX	LAB_D8		; clear the insert count
	STX	LAB_C7		; clear the reverse flag
	STX	LAB_D4		; clear the cursor quote flag, $xx = quote, $00 = no quote
	STX	LAB_D3		; save the cursor column
	JSR	LAB_E87C		; do newline
	JMP	LAB_E6A8		; restore the registers, set the quote flag and exit


;************************************************************************************
;
; test for line decrement

LAB_E8A1
	LDX	#$02			; set the count
	LDA	#$00			; set the column
LAB_E8A5
	CMP	LAB_D3		; compare the column with the cursor column
	BEQ	LAB_E8B0		; if at the start of the line go decrement the cursor row
					; and exit

	CLC				; else clear carry for add
	ADC	#$28			; increment to next line
	DEX				; decrement loop count
	BNE	LAB_E8A5		; loop if more to test

	RTS

LAB_E8B0
	DEC	LAB_D6		; else decrement the cursor row
	RTS


;************************************************************************************
;
; test for line increment
;
; if at end of the line, but not at end of the last line, increment the cursor row

LAB_E8B3
	LDX	#$02			; set the count
	LDA	#$27			; set the column
LAB_E8B7
	CMP	LAB_D3		; compare the column with the cursor column
	BEQ	LAB_E8C2		; if at end of line test and possibly increment cursor row

	CLC				; else clear carry for add
	ADC	#$28			; increment to the next line
	DEX				; decrement the loop count
	BNE	LAB_E8B7		; loop if more to test

	RTS

					; cursor is at end of line
LAB_E8C2
	LDX	LAB_D6		; get the cursor row
	CPX	#$19			; compare it with the end of the screen
	BEQ	LAB_E8CA		; if at the end of screen just exit

	INC	LAB_D6		; else increment the cursor row
LAB_E8CA
	RTS


;************************************************************************************
;
; set the colour code. enter with the colour character in A. if A does not contain a
; colour character this routine exits without changing the colour

LAB_E8CB
	LDX	#LAB_E8E9-LAB_E8DA
					; set the colour code count
LAB_E8CD
	CMP	LAB_E8DA,X		; compare the character with a table code
	BEQ	LAB_E8D6		; if a match go save the colour and exit

	DEX				; else decrement the index
	BPL	LAB_E8CD		; loop if more to do

	RTS

LAB_E8D6
	STX	LAB_0286		; save the current colour code
	RTS


;************************************************************************************
;
; ASCII colour code table
					; CHR$()	colour
LAB_E8DA				; ------	------
	.byte	$90			;  144	black
	.byte	$05			;    5	white
	.byte	$1C			;   28	red
	.byte	$9F			;  159	cyan
	.byte	$9C			;  156	purple
	.byte	$1E			;   30	green
	.byte	$1F			;   31	Blue
	.byte	$9E			;  158	yellow
	.byte	$81			;  129	orange
	.byte	$95			;  149	brown
	.byte	$96			;  150	light red
	.byte	$97			;  151	dark grey
	.byte	$98			;  152	medium grey
	.byte	$99			;  153	light green
	.byte	$9A			;  154	light blue
LAB_E8E9
	.byte	$9B			;  155	light grey


;************************************************************************************
;
; scroll the screen

LAB_E8EA
	LDA	LAB_AC		; copy the tape buffer start pointer
	PHA				; save it
	LDA	LAB_AD		; copy the tape buffer start pointer
	PHA				; save it
	LDA	LAB_AE		; copy the tape buffer end pointer
	PHA				; save it
	LDA	LAB_AF		; copy the tape buffer end pointer
	PHA				; save it
LAB_E8F6
	LDX	#$FF			; set to -1 for pre increment loop
	DEC	LAB_D6		; decrement the cursor row
	DEC	LAB_C9		; decrement the input cursor row
	DEC	LAB_02A5		; decrement the screen row marker
LAB_E8FF
	INX				; increment the line number
	JSR	LAB_E9F0		; fetch a screen address, set the start of line X
	CPX	#$18			; compare with last line
	BCS	LAB_E913		; branch if >= $16

	LDA	LAB_ECF0+1,X	; get the start of the next line pointer low byte
	STA	LAB_AC		; save the next line pointer low byte
	LDA	LAB_D9+1,X		; get the start of the next line pointer high byte
	JSR	LAB_E9C8		; shift the screen line up
	BMI	LAB_E8FF		; loop, branch always

LAB_E913
	JSR	LAB_E9FF		; clear screen line X

					; now shift up the start of logical line bits
	LDX	#$00			; clear index
LAB_E918
	LDA	LAB_D9,X		; get the start of line X pointer high byte
	AND	#$7F			; clear the line X start of logical line bit
	LDY	LAB_D9+1,X		; get the start of the next line pointer high byte
	BPL	LAB_E922		; if next line is not a start of line skip the start set

	ORA	#$80			; set line X start of logical line bit
LAB_E922
	STA	LAB_D9,X		; set start of line X pointer high byte
	INX				; increment line number
	CPX	#$18			; compare with last line
	BNE	LAB_E918		; loop if not last line

	LDA	LAB_D9+$18		; get start of last line pointer high byte
	ORA	#$80			; mark as start of logical line
	STA	LAB_D9+$18		; set start of last line pointer high byte
	LDA	LAB_D9		; get start of first line pointer high byte
	BPL	LAB_E8F6		; if not start of logical line loop back and
					; scroll the screen up another line

	INC	LAB_D6		; increment the cursor row
	INC	LAB_02A5		; increment screen row marker
	LDA	#$7F			; set keyboard column c7
	STA	LAB_DC00		; save VIA 1 DRA, keyboard column drive
	LDA	LAB_DC01		; read VIA 1 DRB, keyboard row port
	CMP	#$FB			; compare with row r2 active, [CTL]
	PHP				; save status
	LDA	#$7F			; set keyboard column c7
	STA	LAB_DC00		; save VIA 1 DRA, keyboard column drive
	PLP				; restore status
	BNE	LAB_E956		; skip delay if ??

					; first time round the inner loop X will be $16
	LDY	#$00			; clear delay outer loop count, do this 256 times
LAB_E94D
	NOP				; waste cycles
	DEX				; decrement inner loop count
	BNE	LAB_E94D		; loop if not all done

	DEY				; decrement outer loop count
	BNE	LAB_E94D		; loop if not all done

	STY	LAB_C6		; clear the keyboard buffer index
LAB_E956
	LDX	LAB_D6		; get the cursor row

; restore the tape buffer pointers and exit

LAB_E958
	PLA				; pull tape buffer end pointer
	STA	LAB_AF		; restore it
	PLA				; pull tape buffer end pointer
	STA	LAB_AE		; restore it
	PLA				; pull tape buffer pointer
	STA	LAB_AD		; restore it
	PLA				; pull tape buffer pointer
	STA	LAB_AC		; restore it
	RTS


;************************************************************************************
;
; open up a space on the screen

LAB_E965
	LDX	LAB_D6		; get the cursor row
LAB_E967
	INX				; increment the row
	LDA	LAB_D9,X		; get the start of line X pointer high byte
	BPL	LAB_E967		; loop if not start of logical line

	STX	LAB_02A5		; save the screen row marker
	CPX	#$18			; compare it with the last line
	BEQ	LAB_E981		; if = last line go ??

	BCC	LAB_E981		; if < last line go ??

					; else it was > last line
	JSR	LAB_E8EA		; scroll the screen
	LDX	LAB_02A5		; get the screen row marker
	DEX				; decrement the screen row marker
	DEC	LAB_D6		; decrement the cursor row
	JMP	LAB_E6DA		; add this row to the current logical line and return

LAB_E981
	LDA	LAB_AC		; copy tape buffer pointer
	PHA				; save it
	LDA	LAB_AD		; copy tape buffer pointer
	PHA				; save it
	LDA	LAB_AE		; copy tape buffer end pointer
	PHA				; save it
	LDA	LAB_AF		; copy tape buffer end pointer
	PHA				; save it
	LDX	#$19			; set to end line + 1 for predecrement loop
LAB_E98F
	DEX				; decrement the line number
	JSR	LAB_E9F0		; fetch a screen address
	CPX	LAB_02A5		; compare it with the screen row marker
	BCC	LAB_E9A6		; if < screen row marker go ??

	BEQ	LAB_E9A6		; if = screen row marker go ??

	LDA	LAB_ECF0-1,X	; else get the start of the previous line low byte from the
					; ROM table
	STA	LAB_AC		; save previous line pointer low byte
	LDA	LAB_D9-1,X		; get the start of the previous line pointer high byte
	JSR	LAB_E9C8		; shift the screen line down
	BMI	LAB_E98F		; loop, branch always

LAB_E9A6
	JSR	LAB_E9FF		; clear screen line X
	LDX	#$17			;.
LAB_E9AB
	CPX	LAB_02A5		; compare it with the screen row marker
	BCC	LAB_E9BF		;.

	LDA	LAB_D9+1,X		;.
	AND	#$7F			;.
	LDY	LAB_D9,X		; get start of line X pointer high byte
	BPL	LAB_E9BA		;.

	ORA	#$80			;.
LAB_E9BA
	STA	LAB_D9+1,X		;.
	DEX				;.
	BNE	LAB_E9AB		;.

LAB_E9BF
	LDX	LAB_02A5		; get the screen row marker
	JSR	LAB_E6DA		; add this row to the current logical line
	JMP	LAB_E958		; restore the tape buffer pointers and exit


;************************************************************************************
;
; shift screen line up/down

LAB_E9C8
	AND	#$03			; mask 0000 00xx, line memory page
	ORA	LAB_0288		; OR with screen memory page
	STA	LAB_AD		; save next/previous line pointer high byte
	JSR	LAB_E9E0		; calculate pointers to screen lines colour RAM
	LDY	#$27			; set the column count
LAB_E9D4
	LDA	(LAB_AC),Y		; get character from next/previous screen line
	STA	(LAB_D1),Y		; save character to current screen line
	LDA	(LAB_AE),Y		; get colour from next/previous screen line colour RAM
	STA	(LAB_F3),Y		; save colour to current screen line colour RAM
	DEY				; decrement column index/count
	BPL	LAB_E9D4		; loop if more to do

	RTS


;************************************************************************************
;
; calculate pointers to screen lines colour RAM

LAB_E9E0
	JSR	LAB_EA24		; calculate the pointer to the current screen line colour
					; RAM
	LDA	LAB_AC		; get the next screen line pointer low byte
	STA	LAB_AE		; save the next screen line colour RAM pointer low byte
	LDA	LAB_AD		; get the next screen line pointer high byte
	AND	#$03			; mask 0000 00xx, line memory page
	ORA	#>LAB_D800		; set  1101 01xx, colour memory page
	STA	LAB_AF		; save the next screen line colour RAM pointer high byte
	RTS


;************************************************************************************
;
; fetch a screen address

LAB_E9F0
	LDA	LAB_ECF0,X		; get the start of line low byte from the ROM table
	STA	LAB_D1		; set the current screen line pointer low byte
	LDA	LAB_D9,X		; get the start of line high byte from the RAM table
	AND	#$03			; mask 0000 00xx, line memory page
	ORA	LAB_0288		; OR with the screen memory page
	STA	LAB_D2		; save the current screen line pointer high byte
	RTS


;************************************************************************************
;
; clear screen line X

LAB_E9FF
	LDY	#$27			; set number of columns to clear
	JSR	LAB_E9F0		; fetch a screen address
	JSR	LAB_EA24		; calculate the pointer to colour RAM
LAB_EA07
	JSR	LAB_E4DA		; save the current colour to the colour RAM
	LDA	#' '			; set [SPACE]
	STA	(LAB_D1),Y		; clear character in current screen line
	DEY				; decrement index
	BPL	LAB_EA07		; loop if more to do

	RTS


;************************************************************************************
;
; orphan byte

;LAB_EA12
	NOP				; unused


;************************************************************************************
;
; print character A and colour X

LAB_EA13
	TAY				; copy the character
	LDA	#$02			; set the count to $02, usually $14 ??
	STA	LAB_CD		; save the cursor countdown
	JSR	LAB_EA24		; calculate the pointer to colour RAM
	TYA				; get the character back


;************************************************************************************
;
; save the character and colour to the screen @ the cursor

LAB_EA1C
	LDY	LAB_D3		; get the cursor column
	STA	(LAB_D1),Y		; save the character from current screen line
	TXA				; copy the colour to A
	STA	(LAB_F3),Y		; save to colour RAM
	RTS


;************************************************************************************
;
; calculate the pointer to colour RAM

LAB_EA24
	LDA	LAB_D1		; get current screen line pointer low byte
	STA	LAB_F3		; save pointer to colour RAM low byte
	LDA	LAB_D2		; get current screen line pointer high byte
	AND	#$03			; mask 0000 00xx, line memory page
	ORA	#>LAB_D800		; set  1101 01xx, colour memory page
	STA	LAB_F4		; save pointer to colour RAM high byte
	RTS


;************************************************************************************
;
; IRQ vector

LAB_EA31
	JSR	LAB_FFEA		; increment the real time clock
	LDA	LAB_CC		; get the cursor enable, $00 = flash cursor
	BNE	LAB_EA61		; if flash not enabled skip the flash

	DEC	LAB_CD		; decrement the cursor timing countdown
	BNE	LAB_EA61		; if not counted out skip the flash

	LDA	#$14			; set the flash count
	STA	LAB_CD		; save the cursor timing countdown
	LDY	LAB_D3		; get the cursor column
	LSR	LAB_CF		; shift b0 cursor blink phase into carry
	LDX	LAB_0287		; get the colour under the cursor
	LDA	(LAB_D1),Y		; get the character from current screen line
	BCS	LAB_EA5C		; branch if cursor phase b0 was 1

	INC	LAB_CF		; set the cursor blink phase to 1
	STA	LAB_CE		; save the character under the cursor
	JSR	LAB_EA24		; calculate the pointer to colour RAM
	LDA	(LAB_F3),Y		; get the colour RAM byte
	STA	LAB_0287		; save the colour under the cursor
	LDX	LAB_0286		; get the current colour code
	LDA	LAB_CE		; get the character under the cursor
LAB_EA5C
	EOR	#$80			; toggle b7 of character under cursor
	JSR	LAB_EA1C		; save the character and colour to the screen @ the cursor
LAB_EA61
	LDA	LAB_01		; read the 6510 I/O port
	AND	#$10			; mask 000x 0000, the cassette switch sense
	BEQ	LAB_EA71		; if the cassette sense is low skip the motor stop

					; the cassette sense was high, the switch was open, so turn
					; off the motor and clear the interlock
	LDY	#$00			; clear Y
	STY	LAB_C0		; clear the tape motor interlock
	LDA	LAB_01		; read the 6510 I/O port
	ORA	#$20			; mask xxxx xx1x, turn off the motor
	BNE	LAB_EA79		; go save the port value, branch always

					; the cassette sense was low so turn the motor on, perhaps
LAB_EA71
	LDA	LAB_C0		; get the tape motor interlock
	BNE	LAB_EA7B		; if the cassette interlock <> 0 don't turn on motor

	LDA	LAB_01		; read the 6510 I/O port
	AND	#$1F			; mask xxxx xx0x, turn on the motor
LAB_EA79
	STA	LAB_01		; save the 6510 I/O port
LAB_EA7B
	JSR	LAB_EA87		; scan the keyboard
	LDA	LAB_DC0D		; read VIA 1 ICR, clear the timer interrupt flag
	PLA				; pull Y
	TAY				; restore Y
	PLA				; pull X
	TAX				; restore X
	PLA				; restore A
	RTI

;************************************************************************************
;
; scan keyboard performs the following ..
;
; 1)	check if key pressed, if not then exit the routine
;
; 2)	init I/O ports of VIA ?? for keyboard scan and set pointers to decode table 1.
;	clear the character counter
;
; 3)	set one line of port B low and test for a closed key on port A by shifting the
;	byte read from the port. if the carry is clear then a key is closed so save the
;	count which is incremented on each shift. check for shift/stop/cbm keys and
;	flag if closed
;
; 4)	repeat step 3 for the whole matrix
;
; 5)	evaluate the SHIFT/CTRL/C= keys, this may change the decode table selected
;
; 6)	use the key count saved in step 3 as an index into the table selected in step 5
;
; 7)	check for key repeat operation
;
; 8)	save the decoded key to the buffer if first press or repeat

; scan the keyboard

LAB_EA87
	LDA	#$00			; clear A
	STA	LAB_028D		; clear the keyboard shift/control/c= flag
	LDY	#$40			; set no key
	STY	LAB_CB		; save which key
	STA	LAB_DC00		; clear VIA 1 DRA, keyboard column drive
	LDX	LAB_DC01		; read VIA 1 DRB, keyboard row port
	CPX	#$FF			; compare with all bits set
	BEQ	LAB_EAFB		; if no key pressed clear current key and exit (does
					; further BEQ to LAB_EBBA)

	TAY				; clear the key count
	LDA	#<LAB_EB81		; get the decode table low byte
	STA	LAB_F5		; save the keyboard pointer low byte
	LDA	#>LAB_EB81		; get the decode table high byte
	STA	LAB_F6		; save the keyboard pointer high byte
	LDA	#$FE			; set column 0 low
	STA	LAB_DC00		; save VIA 1 DRA, keyboard column drive
LAB_EAA8
	LDX	#$08			; set the row count
	PHA				; save the column
LAB_EAAB
	LDA	LAB_DC01		; read VIA 1 DRB, keyboard row port
	CMP	LAB_DC01		; compare it with itself
	BNE	LAB_EAAB		; loop if changing

LAB_EAB3
	LSR				; shift row to Cb
	BCS	LAB_EACC		; if no key closed on this row go do next row

	PHA				; save row
	LDA	(LAB_F5),Y		; get character from decode table
	CMP	#$05			; compare with $05, there is no $05 key but the control
					; keys are all less than $05
	BCS	LAB_EAC9		; if not shift/control/c=/stop go save key count

					; else was shift/control/c=/stop key
	CMP	#$03			; compare with $03, stop
	BEQ	LAB_EAC9		; if stop go save key count and continue

					; character is $01 - shift, $02 - c= or $04 - control
	ORA	LAB_028D		; OR it with the keyboard shift/control/c= flag
	STA	LAB_028D		; save the keyboard shift/control/c= flag
	BPL	LAB_EACB		; skip save key, branch always

LAB_EAC9
	STY	LAB_CB		; save key count
LAB_EACB
	PLA				; restore row
LAB_EACC
	INY				; increment key count
	CPY	#$41			; compare with max+1
	BCS	LAB_EADC		; exit loop if >= max+1

					; else still in matrix
	DEX				; decrement row count
	BNE	LAB_EAB3		; loop if more rows to do

	SEC				; set carry for keyboard column shift
	PLA				; restore the column
	ROL				; shift the keyboard column
	STA	LAB_DC00		; save VIA 1 DRA, keyboard column drive
	BNE	LAB_EAA8		; loop for next column, branch always

LAB_EADC
	PLA				; dump the saved column
	JMP	(LAB_028F)		; evaluate the SHIFT/CTRL/C= keys, LAB_EBDC

; key decoding continues here after the SHIFT/CTRL/C= keys are evaluated

LAB_EAE0
	LDY	LAB_CB		; get saved key count
	LDA	(LAB_F5),Y		; get character from decode table
	TAX				; copy character to X
	CPY	LAB_C5		; compare key count with last key count
	BEQ	LAB_EAF0		; if this key = current key, key held, go test repeat

	LDY	#$10			; set the repeat delay count
	STY	LAB_028C		; save the repeat delay count
	BNE	LAB_EB26		; go save key to buffer and exit, branch always

LAB_EAF0
	AND	#$7F			; clear b7
	BIT	LAB_028A		; test key repeat
	BMI	LAB_EB0D		; if repeat all go ??

	BVS	LAB_EB42		; if repeat none go ??

	CMP	#$7F			; compare with end marker
LAB_EAFB
	BEQ	LAB_EB26		; if $00/end marker go save key to buffer and exit

	CMP	#$14			; compare with [INSERT]/[DELETE]
	BEQ	LAB_EB0D		; if [INSERT]/[DELETE] go test for repeat

	CMP	#' '			; compare with [SPACE]
	BEQ	LAB_EB0D		; if [SPACE] go test for repeat

	CMP	#$1D			; compare with [CURSOR RIGHT]
	BEQ	LAB_EB0D		; if [CURSOR RIGHT] go test for repeat

	CMP	#$11			; compare with [CURSOR DOWN]
	BNE	LAB_EB42		; if not [CURSOR DOWN] just exit

					; was one of the cursor movement keys, insert/delete
					; key or the space bar so always do repeat tests
LAB_EB0D
	LDY	LAB_028C		; get the repeat delay counter
	BEQ	LAB_EB17		; if delay expired go ??

	DEC	LAB_028C		; else decrement repeat delay counter
	BNE	LAB_EB42		; if delay not expired go ??

					; repeat delay counter has expired
LAB_EB17
	DEC	LAB_028B		; decrement the repeat speed counter
	BNE	LAB_EB42		; branch if repeat speed count not expired

	LDY	#$04			; set for 4/60ths of a second
	STY	LAB_028B		; save the repeat speed counter
	LDY	LAB_C6		; get the keyboard buffer index
	DEY				; decrement it
	BPL	LAB_EB42		; if the buffer isn't empty just exit

					; else repeat the key immediately

; possibly save the key to the keyboard buffer. if there was no key pressed or the key
; was not found during the scan (possibly due to key bounce) then X will be $FF here

LAB_EB26
	LDY	LAB_CB		; get the key count
	STY	LAB_C5		; save it as the current key count
	LDY	LAB_028D		; get the keyboard shift/control/c= flag
	STY	LAB_028E		; save it as last keyboard shift pattern
	CPX	#$FF			; compare the character with the table end marker or no key
	BEQ	LAB_EB42		; if it was the table end marker or no key just exit

	TXA				; copy the character to A
	LDX	LAB_C6		; get the keyboard buffer index
	CPX	LAB_0289		; compare it with the keyboard buffer size
	BCS	LAB_EB42		; if the buffer is full just exit

	STA	LAB_0277,X		; save the character to the keyboard buffer
	INX				; increment the index
	STX	LAB_C6		; save the keyboard buffer index
LAB_EB42
	LDA	#$7F			; enable column 7 for the stop key
	STA	LAB_DC00		; save VIA 1 DRA, keyboard column drive
	RTS


;************************************************************************************
;
; evaluate the SHIFT/CTRL/C= keys

LAB_EB48
	LDA	LAB_028D		; get the keyboard shift/control/c= flag
	CMP	#$03			; compare with [SHIFT][C=]
	BNE	LAB_EB64		; if not [SHIFT][C=] go ??

	CMP	LAB_028E		; compare with last
	BEQ	LAB_EB42		; exit if still the same

	LDA	LAB_0291		; get the shift mode switch $00 = enabled, $80 = locked
	BMI	LAB_EB76		; if locked continue keyboard decode

					; toggle text mode
	LDA	LAB_D018		; get the start of character memory address
	EOR	#$02			; toggle address b1
	STA	LAB_D018		; save the start of character memory address
	JMP	LAB_EB76		; continue the keyboard decode

; select keyboard table

LAB_EB64
	ASL				; << 1
	CMP	#$08			; compare with [CTRL]
	BCC	LAB_EB6B		; if [CTRL] is not pressed skip the index change

	LDA	#$06			; else [CTRL] was pressed so make the index = $06
LAB_EB6B
	TAX				; copy the index to X
	LDA	LAB_EB79,X		; get the decode table pointer low byte
	STA	LAB_F5		; save the decode table pointer low byte
	LDA	LAB_EB79+1,X	; get the decode table pointer high byte
	STA	LAB_F6		; save the decode table pointer high byte
LAB_EB76
	JMP	LAB_EAE0		; continue the keyboard decode


;************************************************************************************
;
; table addresses

LAB_EB79
	.word	LAB_EB81		; standard
	.word	LAB_EBC2		; shift
	.word	LAB_EC03		; commodore
	.word	LAB_EC78		; control


;************************************************************************************
;
; standard keyboard table

LAB_EB81
	.byte	$14,$0D,$1D,$88,$85,$86,$87,$11
	.byte	$33,$57,$41,$34,$5A,$53,$45,$01
	.byte	$35,$52,$44,$36,$43,$46,$54,$58
	.byte	$37,$59,$47,$38,$42,$48,$55,$56
	.byte	$39,$49,$4A,$30,$4D,$4B,$4F,$4E
	.byte	$2B,$50,$4C,$2D,$2E,$3A,$40,$2C
	.byte	$5C,$2A,$3B,$13,$01,$3D,$5E,$2F
	.byte	$31,$5F,$04,$32,$20,$02,$51,$03
	.byte	$FF

; shifted keyboard table

LAB_EBC2
	.byte	$94,$8D,$9D,$8C,$89,$8A,$8B,$91
	.byte	$23,$D7,$C1,$24,$DA,$D3,$C5,$01
	.byte	$25,$D2,$C4,$26,$C3,$C6,$D4,$D8
	.byte	$27,$D9,$C7,$28,$C2,$C8,$D5,$D6
	.byte	$29,$C9,$CA,$30,$CD,$CB,$CF,$CE
	.byte	$DB,$D0,$CC,$DD,$3E,$5B,$BA,$3C
	.byte	$A9,$C0,$5D,$93,$01,$3D,$DE,$3F
	.byte	$21,$5F,$04,$22,$A0,$02,$D1,$83
	.byte	$FF

; CBM key keyboard table

LAB_EC03
	.byte	$94,$8D,$9D,$8C,$89,$8A,$8B,$91
	.byte	$96,$B3,$B0,$97,$AD,$AE,$B1,$01
	.byte	$98,$B2,$AC,$99,$BC,$BB,$A3,$BD
	.byte	$9A,$B7,$A5,$9B,$BF,$B4,$B8,$BE
	.byte	$29,$A2,$B5,$30,$A7,$A1,$B9,$AA
	.byte	$A6,$AF,$B6,$DC,$3E,$5B,$A4,$3C
	.byte	$A8,$DF,$5D,$93,$01,$3D,$DE,$3F
	.byte	$81,$5F,$04,$95,$A0,$02,$AB,$83
	.byte	$FF


;************************************************************************************
;
; check for special character codes

LAB_EC44
	CMP	#$0E			; compare with [SWITCH TO LOWER CASE]
	BNE	LAB_EC4F		; if not [SWITCH TO LOWER CASE] skip the switch

	LDA	LAB_D018		; get the start of character memory address
	ORA	#$02			; mask xxxx xx1x, set lower case characters
	BNE	LAB_EC58		; go save the new value, branch always

; check for special character codes except fro switch to lower case

LAB_EC4F
	CMP	#$8E			; compare with [SWITCH TO UPPER CASE]
	BNE	LAB_EC5E		; if not [SWITCH TO UPPER CASE] go do the [SHIFT]+[C=] key
					; check

	LDA	LAB_D018		; get the start of character memory address
	AND	#$FD			; mask xxxx xx0x, set upper case characters
LAB_EC58
	STA	LAB_D018		; save the start of character memory address
LAB_EC5B
	JMP	LAB_E6A8		; restore the registers, set the quote flag and exit

; do the [SHIFT]+[C=] key check

LAB_EC5E
	CMP	#$08			; compare with disable [SHIFT][C=]
	BNE	LAB_EC69		; if not disable [SHIFT][C=] skip the set

	LDA	#$80			; set to lock shift mode switch
	ORA	LAB_0291		; OR it with the shift mode switch
	BMI	LAB_EC72		; go save the value, branch always

LAB_EC69
	CMP	#$09			; compare with enable [SHIFT][C=]
	BNE	LAB_EC5B		; exit if not enable [SHIFT][C=]

	LDA	#$7F			; set to unlock shift mode switch
	AND	LAB_0291		; AND it with the shift mode switch
LAB_EC72
	STA	LAB_0291		; save the shift mode switch $00 = enabled, $80 = locked
	JMP	LAB_E6A8		; restore the registers, set the quote flag and exit


;************************************************************************************
;
; control keyboard table

LAB_EC78
	.byte	$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF
	.byte	$1C,$17,$01,$9F,$1A,$13,$05,$FF
	.byte	$9C,$12,$04,$1E,$03,$06,$14,$18
	.byte	$1F,$19,$07,$9E,$02,$08,$15,$16
	.byte	$12,$09,$0A,$92,$0D,$0B,$0F,$0E
	.byte	$FF,$10,$0C,$FF,$FF,$1B,$00,$FF
	.byte	$1C,$FF,$1D,$FF,$FF,$1F,$1E,$FF
	.byte	$90,$06,$FF,$05,$FF,$FF,$11,$FF
	.byte	$FF


;************************************************************************************
;
; vic ii chip initialisation values

LAB_ECB9
	.byte	$00,$00		; sprite 0 x,y
	.byte	$00,$00		; sprite 1 x,y
	.byte	$00,$00		; sprite 2 x,y
	.byte	$00,$00		; sprite 3 x,y
	.byte	$00,$00		; sprite 4 x,y
	.byte	$00,$00		; sprite 5 x,y
	.byte	$00,$00		; sprite 6 x,y
	.byte	$00,$00		; sprite 7 x,y
;+$10
	.byte	$00			; sprites 0 to 7 x bit 8
	.byte	$9B			; enable screen, enable 25 rows
					; vertical fine scroll and control
					; bit	function
					; ---	-------
					;  7	raster compare bit 8
					;  6	1 = enable extended color text mode
					;  5	1 = enable bitmap graphics mode
					;  4	1 = enable screen, 0 = blank screen
					;  3	1 = 25 row display, 0 = 24 row display
					; 2-0	vertical scroll count
	.byte	$37			; raster compare
	.byte	$00			; light pen x
	.byte	$00			; light pen y
	.byte	$00			; sprite 0 to 7 enable
	.byte	$08			; enable 40 column display
					; horizontal fine scroll and control
					; bit	function
					; ---	-------
					; 7-6	unused
					;  5	1 = vic reset, 0 = vic on
					;  4	1 = enable multicolor mode
					;  3	1 = 40 column display, 0 = 38 column display
					; 2-0	horizontal scroll count
	.byte	$00			; sprite 0 to 7 y expand
	.byte	$14			; memory control
					; bit	function
					; ---	-------
					; 7-4	video matrix base address
					; 3-1	character data base address
					;  0	unused
	.byte	$0F			; clear all interrupts
					; interrupt flags
					;  7	1 = interrupt
					; 6-4	unused
					;  3	1 = light pen interrupt
					;  2	1 = sprite to sprite collision interrupt
					;  1	1 = sprite to foreground collision interrupt
					;  0	1 = raster compare interrupt
	.byte	$00			; all vic IRQs disabeld
					; IRQ enable
					; bit	function
					; ---	-------
					; 7-4	unused
					;  3	1 = enable light pen
					;  2	1 = enable sprite to sprite collision
					;  1	1 = enable sprite to foreground collision
					;  0	1 = enable raster compare
	.byte	$00			; sprite 0 to 7 foreground priority
	.byte	$00			; sprite 0 to 7 multicolour
	.byte	$00			; sprite 0 to 7 x expand
	.byte	$00			; sprite 0 to 7 sprite collision
	.byte	$00			; sprite 0 to 7 foreground collision
;+$20
	.byte	$0E			; border colour
	.byte	$06			; background colour 0
	.byte	$01			; background colour 1
	.byte	$02			; background colour 2
	.byte	$03			; background colour 3
	.byte	$04			; sprite multicolour 0
	.byte	$00			; sprite multicolour 1
	.byte	$01			; sprite 0 colour
	.byte	$02			; sprite 1 colour
	.byte	$03			; sprite 2 colour
	.byte	$04			; sprite 3 colour
	.byte	$05			; sprite 4 colour
	.byte	$06			; sprite 5 colour
	.byte	$07			; sprite 6 colour
;	.byte	$4C			; sprite 7 colour, actually the first character of "LOAD"


;************************************************************************************
;
; keyboard buffer for auto load/run

LAB_ECE7
	.byte	"LOAD",$0D,"RUN",$0D


;************************************************************************************
;
; low bytes of screen line addresses

LAB_ECF0
	.byte	$00,$28,$50,$78,$A0
	.byte	$C8,$F0,$18,$40,$68
	.byte	$90,$B8,$E0,$08,$30
	.byte	$58,$80,$A8,$D0,$F8
	.byte	$20,$48,$70,$98,$C0


;************************************************************************************
;
; command serial bus device to TALK

LAB_ED09
	ORA	#$40			; OR with the TALK command
	.byte	$2C			; makes next line BIT LAB_xxxx


;************************************************************************************
;
; command devices on the serial bus to LISTEN

LAB_ED0C
	ORA	#$20			; OR with the LISTEN command
	JSR	LAB_F0A4		; check RS232 bus idle


;************************************************************************************
;
; send a control character

LAB_ED11
	PHA				; save device address
	BIT	LAB_94		; test deferred character flag
	BPL	LAB_ED20		; if no defered character continue

	SEC				; else flag EOI
	ROR	LAB_A3		; rotate into EOI flag byte
	JSR	LAB_ED40		; Tx byte on serial bus
	LSR	LAB_94		; clear deferred character flag
	LSR	LAB_A3		; clear EOI flag
LAB_ED20
	PLA				; restore the device address


;************************************************************************************
;
; defer a command

;LAB_ED21
	STA	LAB_95		; save as serial defered character
	SEI				; disable the interrupts
	JSR	LAB_EE97		; set the serial data out high
	CMP	#$3F			; compare read byte with $3F
	BNE	LAB_ED2E		; branch if not $3F, this branch will always be taken as
					; after VIA 2's PCR is read it is ANDed with $DF, so the
					; result can never be $3F ??

	JSR	LAB_EE85		; set the serial clock out high
LAB_ED2E
	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	ORA	#$08			; mask xxxx 1xxx, set serial ATN low
	STA	LAB_DD00		; save VIA 2 DRA, serial port and video address

; if the code drops through to here the serial clock is low and the serial data has been
; released so the following code will have no effect apart from delaying the first byte
; by 1ms

; set the serial clk/data, wait and Tx byte on the serial bus

LAB_ED36
	SEI				; disable the interrupts
	JSR	LAB_EE8E		; set the serial clock out low
	JSR	LAB_EE97		; set the serial data out high
	JSR	LAB_EEB3		; 1ms delay


;************************************************************************************
;
; Tx byte on serial bus

LAB_ED40
	SEI				; disable the interrupts
	JSR	LAB_EE97		; set the serial data out high
	JSR	LAB_EEA9		; get the serial data status in Cb
	BCS	LAB_EDAD		; if the serial data is high go do 'device not present'

	JSR	LAB_EE85		; set the serial clock out high
	BIT	LAB_A3		; test the EOI flag
	BPL	LAB_ED5A		; if not EOI go ??

; I think this is the EOI sequence so the serial clock has been released and the serial
; data is being held low by the peripheral. first up wait for the serial data to rise

LAB_ED50
	JSR	LAB_EEA9		; get the serial data status in Cb
	BCC	LAB_ED50		; loop if the data is low

; now the data is high, EOI is signalled by waiting for at least 200us without pulling
; the serial clock line low again. the listener should respond by pulling the serial
; data line low

LAB_ED55
	JSR	LAB_EEA9		; get the serial data status in Cb
	BCS	LAB_ED55		; loop if the data is high

; the serial data has gone low ending the EOI sequence, now just wait for the serial
; data line to go high again or, if this isn't an EOI sequence, just wait for the serial
; data to go high the first time

LAB_ED5A
	JSR	LAB_EEA9		; get the serial data status in Cb
	BCC	LAB_ED5A		; loop if the data is low

; serial data is high now pull the clock low, preferably within 60us

	JSR	LAB_EE8E		; set the serial clock out low

; now the C64 has to send the eight bits, LSB first. first it sets the serial data line
; to reflect the bit in the byte, then it sets the serial clock to high. The serial
; clock is left high for 26 cycles, 23us on a PAL Vic, before it is again pulled low
; and the serial data is allowed high again

	LDA	#$08			; eight bits to do
	STA	LAB_A5		; set serial bus bit count
LAB_ED66
	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	CMP	LAB_DD00		; compare it with itself
	BNE	LAB_ED66		; if changed go try again

	ASL				; shift the serial data into Cb
	BCC	LAB_EDB0		; if the serial data is low go do serial bus timeout

	ROR	LAB_95		; rotate the transmit byte
	BCS	LAB_ED7A		; if the bit = 1 go set the serial data out high

	JSR	LAB_EEA0		; else set the serial data out low
	BNE	LAB_ED7D		; continue, branch always

LAB_ED7A
	JSR	LAB_EE97		; set the serial data out high
LAB_ED7D
	JSR	LAB_EE85		; set the serial clock out high
	NOP				; waste ..
	NOP				; .. a ..
	NOP				; .. cycle ..
	NOP				; .. or two
	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	AND	#$DF			; mask xx0x xxxx, set the serial data out high
	ORA	#$10			; mask xxx1 xxxx, set the serial clock out low
	STA	LAB_DD00		; save VIA 2 DRA, serial port and video address
	DEC	LAB_A5		; decrement the serial bus bit count
	BNE	LAB_ED66		; loop if not all done

; now all eight bits have been sent it's up to the peripheral to signal the byte was
; received by pulling the serial data low. this should be done within one milisecond

	LDA	#$04			; wait for up to about 1ms
	STA	LAB_DC07		; save VIA 1 timer B high byte
	LDA	#$19			; load timer B, timer B single shot, start timer B
	STA	LAB_DC0F		; save VIA 1 CRB
	LDA	LAB_DC0D		; read VIA 1 ICR
LAB_ED9F
	LDA	LAB_DC0D		; read VIA 1 ICR
	AND	#$02			; mask 0000 00x0, timer A interrupt
	BNE	LAB_EDB0		; if timer A interrupt go do serial bus timeout

	JSR	LAB_EEA9		; get the serial data status in Cb
	BCS	LAB_ED9F		; if the serial data is high go wait some more

	CLI				; enable the interrupts
	RTS

; device not present

LAB_EDAD
	LDA	#$80			; error $80, device not present
	.byte	$2C			; makes next line BIT LAB_xxxx

; timeout on serial bus

LAB_EDB0
	LDA	#$03			; error $03, read timeout, write timeout
LAB_EDB2
	JSR	LAB_FE1C		; OR into the serial status byte
	CLI				; enable the interrupts
	CLC				; clear for branch
	BCC	LAB_EE03		; ATN high, delay, clock high then data high, branch always


;************************************************************************************
;
; send secondary address after LISTEN

LAB_EDB9
	STA	LAB_95		; save the defered Tx byte
	JSR	LAB_ED36		; set the serial clk/data, wait and Tx the byte


;************************************************************************************
;
; set serial ATN high

LAB_EDBE
	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	AND	#$F7			; mask xxxx 0xxx, set serial ATN high
	STA	LAB_DD00		; save VIA 2 DRA, serial port and video address
	RTS


;************************************************************************************
;
; send secondary address after TALK

LAB_EDC7
	STA	LAB_95		; save the defered Tx byte
	JSR	LAB_ED36		; set the serial clk/data, wait and Tx the byte


;************************************************************************************
;
; wait for the serial bus end after send

LAB_EDCC				; return address from patch 6
	SEI				; disable the interrupts
	JSR	LAB_EEA0		; set the serial data out low
	JSR	LAB_EDBE		; set serial ATN high
	JSR	LAB_EE85		; set the serial clock out high
LAB_EDD6
	JSR	LAB_EEA9		; get the serial data status in Cb
	BMI	LAB_EDD6		; loop if the clock is high

	CLI				; enable the interrupts
	RTS


;************************************************************************************
;
; output a byte to the serial bus

LAB_EDDD
	BIT	LAB_94		; test the deferred character flag
	BMI	LAB_EDE6		; if there is a defered character go send it

	SEC				; set carry
	ROR	LAB_94		; shift into the deferred character flag
	BNE	LAB_EDEB		; save the byte and exit, branch always

LAB_EDE6
	PHA				; save the byte
	JSR	LAB_ED40		; Tx byte on serial bus
	PLA				; restore the byte
LAB_EDEB
	STA	LAB_95		; save the defered Tx byte
	CLC				; flag ok
	RTS


;************************************************************************************
;
; command serial bus to UNTALK

LAB_EDEF
	SEI				; disable the interrupts
	JSR	LAB_EE8E		; set the serial clock out low
	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	ORA	#$08			; mask xxxx 1xxx, set the serial ATN low
	STA	LAB_DD00		; save VIA 2 DRA, serial port and video address

	LDA	#$5F			; set the UNTALK command
	.byte	$2C			; makes next line BIT LAB_xxxx


;************************************************************************************
;
; command serial bus to UNLISTEN

LAB_EDFE
	LDA	#$3F			; set the UNLISTEN command
	JSR	LAB_ED11		; send a control character
LAB_EE03
	JSR	LAB_EDBE		; set serial ATN high

; 1ms delay, clock high then data high

LAB_EE06
	TXA				; save the device number
	LDX	#$0A			; short delay
LAB_EE09
	DEX				; decrement the count
	BNE	LAB_EE09		; loop if not all done

	TAX				; restore the device number
	JSR	LAB_EE85		; set the serial clock out high
	JMP	LAB_EE97		; set the serial data out high and return


;************************************************************************************
;
; input a byte from the serial bus

LAB_EE13
	SEI				; disable the interrupts
	LDA	#$00			; set 0 bits to do, will flag EOI on timeour
	STA	LAB_A5		; save the serial bus bit count
	JSR	LAB_EE85		; set the serial clock out high
LAB_EE1B
	JSR	LAB_EEA9		; get the serial data status in Cb
	BPL	LAB_EE1B		; loop if the serial clock is low

LAB_EE20
	LDA	#$01			; set the timeout count high byte
	STA	LAB_DC07		; save VIA 1 timer B high byte
	LDA	#$19			; load timer B, timer B single shot, start timer B
	STA	LAB_DC0F		; save VIA 1 CRB
	JSR	LAB_EE97		; set the serial data out high
	LDA	LAB_DC0D		; read VIA 1 ICR
LAB_EE30
	LDA	LAB_DC0D		; read VIA 1 ICR
	AND	#$02			; mask 0000 00x0, timer A interrupt
	BNE	LAB_EE3E		; if timer A interrupt go ??

	JSR	LAB_EEA9		; get the serial data status in Cb
	BMI	LAB_EE30		; loop if the serial clock is low

	BPL	LAB_EE56		; else go set 8 bits to do, branch always

					; timer A timed out
LAB_EE3E
	LDA	LAB_A5		; get the serial bus bit count
	BEQ	LAB_EE47		; if not already EOI then go flag EOI

	LDA	#$02			; else error $02, read timeour
	JMP	LAB_EDB2		; set the serial status and exit

LAB_EE47
	JSR	LAB_EEA0		; set the serial data out low
	JSR	LAB_EE85		; set the serial clock out high
	LDA	#$40			; set EOI
	JSR	LAB_FE1C		; OR into the serial status byte
	INC	LAB_A5		; increment the serial bus bit count, do error on the next
					; timeout
	BNE	LAB_EE20		; go try again, branch always

LAB_EE56
	LDA	#$08			; set 8 bits to do
	STA	LAB_A5		; save the serial bus bit count
LAB_EE5A
	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	CMP	LAB_DD00		; compare it with itself
	BNE	LAB_EE5A		; if changing go try again

	ASL				; shift the serial data into the carry
	BPL	LAB_EE5A		; loop while the serial clock is low

	ROR	LAB_A4		; shift the data bit into the receive byte
LAB_EE67
	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	CMP	LAB_DD00		; compare it with itself
	BNE	LAB_EE67		; if changing go try again

	ASL				; shift the serial data into the carry
	BMI	LAB_EE67		; loop while the serial clock is high

	DEC	LAB_A5		; decrement the serial bus bit count
	BNE	LAB_EE5A		; loop if not all done

	JSR	LAB_EEA0		; set the serial data out low
	BIT	LAB_90		; test the serial status byte
	BVC	LAB_EE80		; if EOI not set skip the bus end sequence

	JSR	LAB_EE06		; 1ms delay, clock high then data high
LAB_EE80
	LDA	LAB_A4		; get the receive byte
	CLI				; enable the interrupts
	CLC				; flag ok
	RTS


;************************************************************************************
;
; set the serial clock out high

LAB_EE85
	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	AND	#$EF			; mask xxx0 xxxx, set serial clock out high
	STA	LAB_DD00		; save VIA 2 DRA, serial port and video address
	RTS


;************************************************************************************
;
; set the serial clock out low

LAB_EE8E
	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	ORA	#$10			; mask xxx1 xxxx, set serial clock out low
	STA	LAB_DD00		; save VIA 2 DRA, serial port and video address
	RTS


;************************************************************************************
;
; set the serial data out high

LAB_EE97
	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	AND	#$DF			; mask xx0x xxxx, set serial data out high
	STA	LAB_DD00		; save VIA 2 DRA, serial port and video address
	RTS


;************************************************************************************
;
; set the serial data out low

LAB_EEA0
	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	ORA	#$20			; mask xx1x xxxx, set serial data out low
	STA	LAB_DD00		; save VIA 2 DRA, serial port and video address
	RTS


;************************************************************************************
;
; get the serial data status in Cb

LAB_EEA9
	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	CMP	LAB_DD00		; compare it with itself
	BNE	LAB_EEA9		; if changing got try again

	ASL				; shift the serial data into Cb
	RTS


;************************************************************************************
;
; 1ms delay

LAB_EEB3
	TXA				; save X
	LDX	#$B8			; set the loop count
LAB_EEB6
	DEX				; decrement the loop count
	BNE	LAB_EEB6		; loop if more to do

	TAX				; restore X
	RTS


;************************************************************************************
;
; RS232 Tx NMI routine

LAB_EEBB
	LDA	LAB_B4		; get RS232 bit count
	BEQ	LAB_EF06		; if zero go setup next RS232 Tx byte and return

	BMI	LAB_EF00		; if -ve go do stop bit(s)

					; else bit count is non zero and +ve
	LSR	LAB_B6		; shift RS232 output byte buffer
	LDX	#$00			; set $00 for bit = 0
	BCC	LAB_EEC8		; branch if bit was 0

	DEX				; set $FF for bit = 1
LAB_EEC8
	TXA				; copy bit to A
	EOR	LAB_BD		; EOR with RS232 parity byte
	STA	LAB_BD		; save RS232 parity byte
	DEC	LAB_B4		; decrement RS232 bit count
	BEQ	LAB_EED7		; if RS232 bit count now zero go do parity bit

; save bit and exit

LAB_EED1
	TXA				; copy bit to A
	AND	#$04			; mask 0000 0x00, RS232 Tx DATA bit
	STA	LAB_B5		; save the next RS232 data bit to send
	RTS


;************************************************************************************
;
; do RS232 parity bit, enters with RS232 bit count = 0

LAB_EED7
	LDA	#$20			; mask 00x0 0000, parity enable bit
	BIT	LAB_0294		; test the pseudo 6551 command register
	BEQ	LAB_EEF2		; if parity disabled go ??

	BMI	LAB_EEFC		; if fixed mark or space parity go ??

	BVS	LAB_EEF6		; if even parity go ??

					; else odd parity
	LDA	LAB_BD		; get RS232 parity byte
	BNE	LAB_EEE7		; if parity not zero leave parity bit = 0

LAB_EEE6
	DEX				; make parity bit = 1
LAB_EEE7
	DEC	LAB_B4		; decrement RS232 bit count, 1 stop bit
	LDA	LAB_0293		; get pseudo 6551 control register
	BPL	LAB_EED1		; if 1 stop bit save parity bit and exit

					; else two stop bits ..
	DEC	LAB_B4		; decrement RS232 bit count, 2 stop bits
	BNE	LAB_EED1		; save bit and exit, branch always

					; parity is disabled so the parity bit becomes the first,
					; and possibly only, stop bit. to do this increment the bit
					; count which effectively decrements the stop bit count.
LAB_EEF2
	INC	LAB_B4		; increment RS232 bit count, = -1 stop bit
	BNE	LAB_EEE6		; set stop bit = 1 and exit

					; do even parity
LAB_EEF6
	LDA	LAB_BD		; get RS232 parity byte
	BEQ	LAB_EEE7		; if parity zero leave parity bit = 0

	BNE	LAB_EEE6		; else make parity bit = 1, branch always

					; fixed mark or space parity
LAB_EEFC
	BVS	LAB_EEE7		; if fixed space parity leave parity bit = 0

	BVC	LAB_EEE6		; else fixed mark parity make parity bit = 1, branch always

; decrement stop bit count, set stop bit = 1 and exit. $FF is one stop bit, $FE is two
; stop bits

LAB_EF00
	INC	LAB_B4		; decrement RS232 bit count
	LDX	#$FF			; set stop bit = 1
	BNE	LAB_EED1		; save stop bit and exit, branch always


;************************************************************************************
;
; setup next RS232 Tx byte

LAB_EF06
	LDA	LAB_0294		; read the 6551 pseudo command register
	LSR				; handshake bit inot Cb
	BCC	LAB_EF13		; if 3 line interface go ??

	BIT	LAB_DD01		; test VIA 2 DRB, RS232 port

	BPL	LAB_EF2E		; if DSR = 0 set DSR signal not present and exit

	BVC	LAB_EF31		; if CTS = 0 set CTS signal not present and exit

					; was 3 line interface
LAB_EF13
	LDA	#$00			; clear A
	STA	LAB_BD		; clear the RS232 parity byte
	STA	LAB_B5		; clear the RS232 next bit to send
	LDX	LAB_0298		; get the number of bits to be sent/received
	STX	LAB_B4		; set the RS232 bit count
	LDY	LAB_029D		; get the index to the Tx buffer start
	CPY	LAB_029E		; compare it with the index to the Tx buffer end
	BEQ	LAB_EF39		; if all done go disable T?? interrupt and return

	LDA	(LAB_F9),Y		; else get a byte from the buffer
	STA	LAB_B6		; save it to the RS232 output byte buffer
	INC	LAB_029D		; increment the index to the Tx buffer start
	RTS


;************************************************************************************
;
; set DSR signal not present

LAB_EF2E
	LDA	#$40			; set DSR signal not present
	.byte	$2C			; makes next line BIT LAB_xxxx


;************************************************************************************
;
; set CTS signal not present

LAB_EF31
	LDA	#$10			; set CTS signal not present
	ORA	LAB_0297		; OR it with the RS232 status register
	STA	LAB_0297		; save the RS232 status register


;************************************************************************************
;
; disable timer A interrupt

LAB_EF39
	LDA	#$01			; disable timer A interrupt


;************************************************************************************
;
; set VIA 2 ICR from A

LAB_EF3B
	STA	LAB_DD0D		; save VIA 2 ICR
	EOR	LAB_02A1		; EOR with the RS-232 interrupt enable byte
	ORA	#$80			; set the interrupts enable bit
	STA	LAB_02A1		; save the RS-232 interrupt enable byte
	STA	LAB_DD0D		; save VIA 2 ICR
	RTS


;************************************************************************************
;
; compute bit count

LAB_EF4A
	LDX	#$09			; set bit count to 9, 8 data + 1 stop bit
	LDA	#$20			; mask for 8/7 data bits
	BIT	LAB_0293		; test pseudo 6551 control register
	BEQ	LAB_EF54		; branch if 8 bits

	DEX				; else decrement count for 7 data bits
LAB_EF54
	BVC	LAB_EF58		; branch if 7 bits

	DEX				; else decrement count ..
	DEX				; .. for 5 data bits
LAB_EF58
	RTS


;************************************************************************************
;
; RS232 Rx NMI

LAB_EF59
	LDX	LAB_A9		; get start bit check flag
	BNE	LAB_EF90		; if no start bit received go ??

	DEC	LAB_A8		; decrement receiver bit count in
	BEQ	LAB_EF97		; if the byte is complete go add it to the buffer

	BMI	LAB_EF70		;.

	LDA	LAB_A7		; get the RS232 received data bit
	EOR	LAB_AB		; EOR with the receiver parity bit
	STA	LAB_AB		; save the receiver parity bit
	LSR	LAB_A7		; shift the RS232 received data bit
	ROR	LAB_AA		;.
LAB_EF6D
	RTS

LAB_EF6E
	DEC	LAB_A8		; decrement receiver bit count in
LAB_EF70
	LDA	LAB_A7		; get the RS232 received data bit
	BEQ	LAB_EFDB		;.

	LDA	LAB_0293		; get pseudo 6551 control register
	ASL				; shift the stop bit flag to Cb
	LDA	#$01			; + 1
	ADC	LAB_A8		; add receiver bit count in
	BNE	LAB_EF6D		; exit, branch always


;************************************************************************************
;
; setup to receive an RS232 bit

LAB_EF7E
	LDA	#$90			; enable FLAG interrupt
	STA	LAB_DD0D		; save VIA 2 ICR
	ORA	LAB_02A1		; OR with the RS-232 interrupt enable byte
	STA	LAB_02A1		; save the RS-232 interrupt enable byte
	STA	LAB_A9		; set start bit check flag, set no start bit received
	LDA	#$02			; disable timer B interrupt
	JMP	LAB_EF3B		; set VIA 2 ICR from A and return


;************************************************************************************
;
; no RS232 start bit received

LAB_EF90
	LDA	LAB_A7		; get the RS232 received data bit
	BNE	LAB_EF7E		; if ?? go setup to receive an RS232 bit and return

	JMP	LAB_E4D3		; flag the RS232 start bit and set the parity


;************************************************************************************
;
; received a whole byte, add it to the buffer

LAB_EF97
	LDY	LAB_029B		; get index to Rx buffer end
	INY				; increment index
	CPY	LAB_029C		; compare with index to Rx buffer start
	BEQ	LAB_EFCA		; if buffer full go do Rx overrun error

	STY	LAB_029B		; save index to Rx buffer end
	DEY				; decrement index
	LDA	LAB_AA		; get assembled byte
	LDX	LAB_0298		; get bit count
LAB_EFA9
	CPX	#$09			; compare with byte + stop
	BEQ	LAB_EFB1		; branch if all nine bits received

	LSR				; else shift byte
	INX				; increment bit count
	BNE	LAB_EFA9		; loop, branch always

LAB_EFB1
	STA	(LAB_F7),Y		; save received byte to Rx buffer
	LDA	#$20			; mask 00x0 0000, parity enable bit
	BIT	LAB_0294		; test the pseudo 6551 command register
	BEQ	LAB_EF6E		; branch if parity disabled

	BMI	LAB_EF6D		; branch if mark or space parity

	LDA	LAB_A7		; get the RS232 received data bit
	EOR	LAB_AB		; EOR with the receiver parity bit
	BEQ	LAB_EFC5		;.

	BVS	LAB_EF6D		; if ?? just exit

	.byte	$2C			; makes next line BIT LAB_xxxx
LAB_EFC5
	BVC	$EF6D			; if ?? just exit

	LDA	#$01			; set Rx parity error
	.byte	$2C			; makes next line BIT LAB_xxxx

LAB_EFCA
	LDA	#$04			; set Rx overrun error
	.byte	$2C			; makes next line BIT LAB_80A9

LAB_EFCD
	LDA	#$80			; set Rx break error
	.byte	$2C			; makes next line BIT LAB_02A9

LAB_EFD0
	LDA	#$02			; set Rx frame error
	ORA	LAB_0297		; OR it with the RS232 status byte
	STA	LAB_0297		; save the RS232 status byte
	JMP	LAB_EF7E		; setup to receive an RS232 bit and return

LAB_EFDB
	LDA	LAB_AA		;.
	BNE	LAB_EFD0		; if ?? do frame error

	BEQ	LAB_EFCD		; else do break error, branch always


;************************************************************************************
;
; open RS232 channel for output

LAB_EFE1
	STA	LAB_9A		; save the output device number
	LDA	LAB_0294		; read the pseudo 6551 command register
	LSR				; shift handshake bit to carry
	BCC	LAB_F012		; if 3 line interface go ??

	LDA	#$02			; mask 0000 00x0, RTS out
	BIT	LAB_DD01		; test VIA 2 DRB, RS232 port
	BPL	LAB_F00D		; if DSR = 0 set DSR not present and exit

	BNE	LAB_F012		; if RTS = 1 just exit

LAB_EFF2
	LDA	LAB_02A1		; get the RS-232 interrupt enable byte
	AND	#$02			; mask 0000 00x0, timer B interrupt
	BNE	LAB_EFF2		; loop while the timer B interrupt is enebled

LAB_EFF9
	BIT	LAB_DD01		; test VIA 2 DRB, RS232 port
	BVS	LAB_EFF9		; loop while CTS high

	LDA	LAB_DD01		; read VIA 2 DRB, RS232 port
	ORA	#$02			; mask xxxx xx1x, set RTS high
	STA	LAB_DD01		; save VIA 2 DRB, RS232 port
LAB_F006
	BIT	LAB_DD01		; test VIA 2 DRB, RS232 port
	BVS	LAB_F012		; exit if CTS high

	BMI	LAB_F006		; loop while DSR high

; set no DSR and exit

LAB_F00D
	LDA	#$40			; set DSR signal not present
	STA	LAB_0297		; save the RS232 status register
LAB_F012
	CLC				; flag ok
	RTS


;************************************************************************************
;
; send byte to the RS232 buffer

LAB_F014
	JSR	LAB_F028		; setup for RS232 transmit

; send byte to the RS232 buffer, no setup

LAB_F017
	LDY	LAB_029E		; get index to Tx buffer end
	INY				; + 1
	CPY	LAB_029D		; compare with index to Tx buffer start
	BEQ	LAB_F014		; loop while buffer full

	STY	LAB_029E		; set index to Tx buffer end
	DEY				; index to available buffer byte
	LDA	LAB_9E		; read the RS232 character buffer
	STA	(LAB_F9),Y		; save the byte to the buffer


;************************************************************************************
;
; setup for RS232 transmit

LAB_F028
	LDA	LAB_02A1		; get the RS-232 interrupt enable byte
	LSR				; shift the enable bit to Cb
	BCS	LAB_F04C		; if interrupts are enabled just exit

	LDA	#$10			; start timer A
	STA	LAB_DD0E		; save VIA 2 CRA
	LDA	LAB_0299		; get the baud rate bit time low byte
	STA	LAB_DD04		; save VIA 2 timer A low byte
	LDA	LAB_029A		; get the baud rate bit time high byte
	STA	LAB_DD05		; save VIA 2 timer A high byte
	LDA	#$81			; enable timer A interrupt
	JSR	LAB_EF3B		; set VIA 2 ICR from A
	JSR	LAB_EF06		; setup next RS232 Tx byte
	LDA	#$11			; load timer A, start timer A
	STA	LAB_DD0E		; save VIA 2 CRA
LAB_F04C
	RTS


;************************************************************************************
;
; input from RS232 buffer

LAB_F04D
	STA	LAB_99		; save the input device number
	LDA	LAB_0294		; get pseudo 6551 command register
	LSR				; shift the handshake bit to Cb
	BCC	LAB_F07D		; if 3 line interface go ??

	AND	#$08			; mask the duplex bit, pseudo 6551 command is >> 1
	BEQ	LAB_F07D		; if full duplex go ??

	LDA	#$02			; mask 0000 00x0, RTS out
	BIT	LAB_DD01		; test VIA 2 DRB, RS232 port
	BPL	LAB_F00D		; if DSR = 0 set no DSR and exit

	BEQ	LAB_F084		; if RTS = 0 just exit

LAB_F062
	LDA	LAB_02A1		; get the RS-232 interrupt enable byte
	LSR				; shift the timer A interrupt enable bit to Cb
	BCS	LAB_F062		; loop while the timer A interrupt is enabled

	LDA	LAB_DD01		; read VIA 2 DRB, RS232 port
	AND	#$FD			; mask xxxx xx0x, clear RTS out
	STA	LAB_DD01		; save VIA 2 DRB, RS232 port
LAB_F070
	LDA	LAB_DD01		; read VIA 2 DRB, RS232 port
	AND	#$04			; mask xxxx x1xx, DTR in
	BEQ	LAB_F070		; loop while DTR low

LAB_F077
	LDA	#$90			; enable the FLAG interrupt
	CLC				; flag ok
	JMP	LAB_EF3B		; set VIA 2 ICR from A and return

LAB_F07D
	LDA	LAB_02A1		; get the RS-232 interrupt enable byte
	AND	#$12			; mask 000x 00x0
	BEQ	LAB_F077		; if FLAG or timer B bits set go enable the FLAG inetrrupt

LAB_F084
	CLC				; flag ok
	RTS


;************************************************************************************
;
; get byte from RS232 buffer

LAB_F086
	LDA	LAB_0297		; get the RS232 status register
	LDY	LAB_029C		; get index to Rx buffer start
	CPY	LAB_029B		; compare with index to Rx buffer end
	BEQ	LAB_F09C		; return null if buffer empty

	AND	#$F7			; clear the Rx buffer empty bit
	STA	LAB_0297		; save the RS232 status register
	LDA	(LAB_F7),Y		; get byte from Rx buffer
	INC	LAB_029C		; increment index to Rx buffer start
	RTS

LAB_F09C
	ORA	#$08			; set the Rx buffer empty bit
	STA	LAB_0297		; save the RS232 status register
	LDA	#$00			; return null
	RTS


;************************************************************************************
;
; check RS232 bus idle

LAB_F0A4
	PHA				; save A
	LDA	LAB_02A1		; get the RS-232 interrupt enable byte
	BEQ	LAB_F0BB		; if no interrupts enabled just exit

LAB_F0AA
	LDA	LAB_02A1		; get the RS-232 interrupt enable byte
	AND	#$03			; mask 0000 00xx, the error bits
	BNE	LAB_F0AA		; if there are errors loop

	LDA	#$10			; disable FLAG interrupt
	STA	LAB_DD0D		; save VIA 2 ICR
	LDA	#$00			; clear A
	STA	LAB_02A1		; clear the RS-232 interrupt enable byte
LAB_F0BB
	PLA				; restore A
	RTS


;************************************************************************************
;
; kernel I/O messages

LAB_F0BD
	.byte	$0D,"I/O ERROR ",'#'+$80
LAB_F0C9
	.byte	$0D,"SEARCHING",' '+$80
LAB_F0D4
	.byte	"FOR",' '+$80
LAB_F0D8
	.byte	$0D,"PRESS PLAY ON TAP",'E'+$80
LAB_F0EB
	.byte	"PRESS RECORD & PLAY ON TAP",'E'+$80
LAB_F106
	.byte	$0D,"LOADIN",'G'+$80
LAB_F10E
	.byte	$0D,"SAVING",' '+$80
LAB_F116
	.byte	$0D,"VERIFYIN",'G'+$80
LAB_F120
	.byte	$0D,"FOUND",' '+$80
LAB_F127
	.byte	$0D,"OK",$0D+$80


;************************************************************************************
;
; display control I/O message if in direct mode

LAB_F12B
	BIT	LAB_9D		; test message mode flag
	BPL	LAB_F13C		; exit if control messages off

; display kernel I/O message

LAB_F12F
	LDA	LAB_F0BD,Y		; get byte from message table
	PHP				; save status
	AND	#$7F			; clear b7
	JSR	LAB_FFD2		; output character to channel
	INY				; increment index
	PLP				; restore status
	BPL	LAB_F12F		; loop if not end of message

LAB_F13C
	CLC				;.
	RTS


;************************************************************************************
;
; get character from the input device

LAB_F13E
	LDA	LAB_99		; get the input device number
	BNE	LAB_F14A		; if not the keyboard go handle other devices

					; the input device was the keyboard
	LDA	LAB_C6		; get the keyboard buffer index
	BEQ	LAB_F155		; if the buffer is empty go flag no byte and return

	SEI				; disable the interrupts
	JMP	LAB_E5B4		; get input from the keyboard buffer and return

					; the input device was not the keyboard
LAB_F14A
	CMP	#$02			; compare the device with the RS232 device
	BNE	LAB_F166		; if not the RS232 device go ??

					; the input device is the RS232 device
LAB_F14E
	STY	LAB_97		; save Y
	JSR	LAB_F086		; get a byte from RS232 buffer
	LDY	LAB_97		; restore Y
LAB_F155
	CLC				; flag no error
	RTS


;************************************************************************************
;
; input a character from channel

LAB_F157
	LDA	LAB_99		; get the input device number
	BNE	LAB_F166		; if not the keyboard continue

; the input device was the keyboard

	LDA	LAB_D3		; get the cursor column
	STA	LAB_CA		; set the input cursor column
	LDA	LAB_D6		; get the cursor row
	STA	LAB_C9		; set the input cursor row
	JMP	LAB_E632		; input from screen or keyboard

; the input device was not the keyboard

LAB_F166
	CMP	#$03			; compare device number with screen
	BNE	LAB_F173		; if not screen continue

; the input device was the screen

	STA	LAB_D0		; input from keyboard or screen, $xx = screen,
					; $00 = keyboard
	LDA	LAB_D5		; get current screen line length
	STA	LAB_C8		; save input [EOL] pointer
	JMP	LAB_E632		; input from screen or keyboard

; the input device was not the screen

LAB_F173
	BCS	LAB_F1AD		; if input device > screen go do IEC devices

; the input device was < screen

	CMP	#$02			; compare the device with the RS232 device
	BEQ	LAB_F1B8		; if RS232 device go get a byte from the RS232 device

; only the tape device left ..

	STX	LAB_97		; save X
	JSR	LAB_F199		; get a byte from tape
	BCS	LAB_F196		; if error just exit

	PHA				; save the byte
	JSR	LAB_F199		; get the next byte from tape
	BCS	LAB_F193		; if error just exit

	BNE	LAB_F18D		; if end reached ??

	LDA	#$40			; set EOI
	JSR	LAB_FE1C		; OR into the serial status byte
LAB_F18D
	DEC	LAB_A6		; decrement tape buffer index
	LDX	LAB_97		; restore X
	PLA				; restore the saved byte
	RTS

LAB_F193
	TAX				; copy the error byte
	PLA				; dump the saved byte
	TXA				; restore error byte
LAB_F196
	LDX	LAB_97		; restore X
	RTS


;************************************************************************************
;
; get byte from tape

LAB_F199
	JSR	LAB_F80D		; bump tape pointer
	BNE	LAB_F1A9		; if not end get next byte and exit

	JSR	LAB_F841		; initiate tape read
	BCS	LAB_F1B4		; exit if error flagged

	LDA	#$00			; clear A
	STA	LAB_A6		; clear tape buffer index
	BEQ	LAB_F199		; loop, branch always

LAB_F1A9
	LDA	(LAB_B2),Y		; get next byte from buffer
	CLC				; flag no error
	RTS

					; input device was serial bus
LAB_F1AD
	LDA	LAB_90		; get the serial status byte
	BEQ	LAB_F1B5		; if no errors flagged go input byte and return

LAB_F1B1
	LDA	#$0D			; else return [EOL]
LAB_F1B3
	CLC				; flag no error
LAB_F1B4
	RTS

LAB_F1B5
	JMP	LAB_EE13		; input byte from serial bus and return

; input device was RS232 device

LAB_F1B8
	JSR	LAB_F14E		; get byte from RS232 device
	BCS	LAB_F1B4		; branch if error, this doesn't get taken as the last
					; instruction in the get byte from RS232 device routine
					; is CLC ??
	CMP	#$00			; compare with null
	BNE	LAB_F1B3		; exit if not null

	LDA	LAB_0297		; get the RS232 status register
	AND	#$60			; mask 0xx0 0000, DSR detected and ??
	BNE	LAB_F1B1		; if ?? return null

	BEQ	LAB_F1B8		; else loop, branch always


;************************************************************************************
;
; output character to channel

LAB_F1CA
	PHA				; save the character to output
	LDA	LAB_9A		; get the output device number
	CMP	#$03			; compare the output device with the screen
	BNE	LAB_F1D5		; if not the screen go ??

	PLA				; else restore the output character
	JMP	LAB_E716		; go output the character to the screen

LAB_F1D5
	BCC	LAB_F1DB		; if < screen go ??

	PLA				; else restore the output character
	JMP	LAB_EDDD		; go output the character to the serial bus

LAB_F1DB
	LSR				; shift b0 of the device into Cb
	PLA				; restore the output character


;************************************************************************************
;
; output the character to the cassette or RS232 device

LAB_F1DD
	STA	LAB_9E		; save the character to the character buffer
	TXA				; copy X
	PHA				; save X
	TYA				; copy Y
	PHA				; save Y
	BCC	LAB_F208		; if Cb is clear it must be the RS232 device

; output the character to the cassette

	JSR	LAB_F80D		; bump the tape pointer
	BNE	LAB_F1F8		; if not end save next byte and exit

	JSR	LAB_F864		; initiate tape write
	BCS	LAB_F1FD		; exit if error

	LDA	#$02			; set data block type ??
	LDY	#$00			; clear index
	STA	(LAB_B2),Y		; save type to buffer ??
	INY				; increment index
	STY	LAB_A6		; save tape buffer index
LAB_F1F8
	LDA	LAB_9E		; restore character from character buffer
	STA	(LAB_B2),Y		; save to buffer
LAB_F1FC
	CLC				; flag no error
LAB_F1FD
	PLA				; pull Y
	TAY				; restore Y
	PLA				; pull X
	TAX				; restore X
	LDA	LAB_9E		; get the character from the character buffer
	BCC	LAB_F207		; exit if no error

	LDA	#$00			; else clear A
LAB_F207
	RTS

; output the character to the RS232 device

LAB_F208
	JSR	LAB_F017		; send byte to the RS232 buffer, no setup
	JMP	LAB_F1FC		; do no error exit


;************************************************************************************
;
; open channel for input

LAB_F20E
	JSR	LAB_F30F		; find a file
	BEQ	LAB_F216		; if the file is open continue

	JMP	LAB_F701		; else do 'file not open' error and return

LAB_F216
	JSR	LAB_F31F		; set file details from table,X
	LDA	LAB_BA		; get the device number
	BEQ	LAB_F233		; if the device was the keyboard save the device #, flag
					; ok and exit

	CMP	#$03			; compare the device number with the screen
	BEQ	LAB_F233		; if the device was the screen save the device #, flag ok
					; and exit

	BCS	LAB_F237		; if the device was a serial bus device go ??

	CMP	#$02			; else compare the device with the RS232 device
	BNE	LAB_F22A		; if not the RS232 device continue

	JMP	LAB_F04D		; else go get input from the RS232 buffer and return

LAB_F22A
	LDX	LAB_B9		; get the secondary address
	CPX	#$60			;.
	BEQ	LAB_F233		;.

	JMP	LAB_F70A		; go do 'not input file' error and return

LAB_F233
	STA	LAB_99		; save the input device number
	CLC				; flag ok
	RTS

					; the device was a serial bus device
LAB_F237
	TAX				; copy device number to X
	JSR	LAB_ED09		; command serial bus device to TALK
	LDA	LAB_B9		; get the secondary address
	BPL	LAB_F245		;.

	JSR	LAB_EDCC		; wait for the serial bus end after send
	JMP	LAB_F248		;.

LAB_F245
	JSR	LAB_EDC7		; send secondary address after TALK
LAB_F248
	TXA				; copy device back to A
	BIT	LAB_90		; test the serial status byte
	BPL	LAB_F233		; if device present save device number and exit

	JMP	LAB_F707		; do 'device not present' error and return


;************************************************************************************
;
; open channel for output

LAB_F250
	JSR	LAB_F30F		; find a file
	BEQ	LAB_F258		; if file found continue

	JMP	LAB_F701		; else do 'file not open' error and return

LAB_F258
	JSR	LAB_F31F		; set file details from table,X
	LDA	LAB_BA		; get the device number
	BNE	LAB_F262		; if the device is not the keyboard go ??

LAB_F25F
	JMP	LAB_F70D		; go do 'not output file' error and return

LAB_F262
	CMP	#$03			; compare the device with the screen
	BEQ	LAB_F275		; if the device is the screen go save output the output
					; device number and exit

	BCS	LAB_F279		; if > screen then go handle a serial bus device

	CMP	#$02			; compare the device with the RS232 device
	BNE	LAB_F26F		; if not the RS232 device then it must be the tape device

	JMP	LAB_EFE1		; else go open RS232 channel for output

					; open a tape channel for output
LAB_F26F
	LDX	LAB_B9		; get the secondary address
	CPX	#$60			;.
	BEQ	LAB_F25F		; if ?? do not output file error and return

LAB_F275
	STA	LAB_9A		; save the output device number
	CLC				; flag ok
	RTS

LAB_F279
	TAX				; copy the device number
	JSR	LAB_ED0C		; command devices on the serial bus to LISTEN
	LDA	LAB_B9		; get the secondary address
	BPL	LAB_F286		; if address to send go ??

	JSR	LAB_EDBE		; else set serial ATN high
	BNE	LAB_F289		; go ??, branch always

LAB_F286
	JSR	LAB_EDB9		; send secondary address after LISTEN
LAB_F289
	TXA				; copy device number back to A
	BIT	LAB_90		; test the serial status byte
	BPL	LAB_F275		; if the device is present go save the output device number
					; and exit

	JMP	LAB_F707		; else do 'device not present error' and return


;************************************************************************************
;
; close a specified logical file

LAB_F291
	JSR	LAB_F314		; find file A
	BEQ	LAB_F298		; if file found go close it

	CLC				; else the file was closed so just flag ok
	RTS

					; file found so close it
LAB_F298
	JSR	LAB_F31F		; set file details from table,X
	TXA				; copy file index to A
	PHA				; save file index
	LDA	LAB_BA		; get the device number
	BEQ	LAB_F2F1		; if it is the keyboard go restore the index and close the
					; file

	CMP	#$03			; compare the device number with the screen
	BEQ	LAB_F2F1		; if it is the screen go restore the index and close the
					; file

	BCS	LAB_F2EE		; if > screen go do serial bus device close

	CMP	#$02			; compare the device with the RS232 device
	BNE	LAB_F2C8		; if not the RS232 device go ??

					; else close RS232 device
	PLA				; restore file index
	JSR	LAB_F2F2		; close file index X
	JSR	LAB_F483		; initialise RS232 output
	JSR	LAB_FE27		; read the top of memory
	LDA	LAB_F8		; get the RS232 input buffer pointer high byte
	BEQ	LAB_F2BA		; if no RS232 input buffer go ??

	INY				; else reclaim RS232 input buffer memory
LAB_F2BA
	LDA	LAB_FA		; get the RS232 output buffer pointer high byte
	BEQ	LAB_F2BF		; if no RS232 output buffer skip the reclaim

	INY				; else reclaim the RS232 output buffer memory
LAB_F2BF
	LDA	#$00			; clear A
	STA	LAB_F8		; clear the RS232 input buffer pointer high byte
	STA	LAB_FA		; clear the RS232 output buffer pointer high byte
	JMP	LAB_F47D		; go set the top of memory to F0xx

					; is not the RS232 device
LAB_F2C8
	LDA	LAB_B9		; get the secondary address
	AND	#$0F			; mask the device #
	BEQ	LAB_F2F1		; if ?? restore index and close file

	JSR	LAB_F7D0		; get tape buffer start pointer in XY
	LDA	#$00			; character $00
	SEC				; flag the tape device
	JSR	LAB_F1DD		; output the character to the cassette or RS232 device
	JSR	LAB_F864		; initiate tape write
	BCC	LAB_F2E0		;.

	PLA				;.
	LDA	#$00			;.
	RTS

LAB_F2E0
	LDA	LAB_B9		; get the secondary address
	CMP	#$62			;.
	BNE	LAB_F2F1		; if not ?? restore index and close file

	LDA	#$05			; set logical end of the tape
	JSR	LAB_F76A		; write tape header
	JMP	LAB_F2F1		; restore index and close file


;************************************************************************************
;
; serial bus device close

LAB_F2EE
	JSR	LAB_F642		; close serial bus device
LAB_F2F1
	PLA				; restore file index


;************************************************************************************
;
; close file index X

LAB_F2F2
	TAX				; copy index to file to close
	DEC	LAB_98		; decrement the open file count
	CPX	LAB_98		; compare the index with the open file count
	BEQ	LAB_F30D		; exit if equal, last entry was closing file

					; else entry was not last in list so copy last table entry
					; file details over the details of the closing one
	LDY	LAB_98		; get the open file count as index
	LDA	LAB_0259,Y		; get last+1 logical file number from logical file table
	STA	LAB_0259,X		; save logical file number over closed file
	LDA	LAB_0263,Y		; get last+1 device number from device number table
	STA	LAB_0263,X		; save device number over closed file
	LDA	LAB_026D,Y		; get last+1 secondary address from secondary address table
	STA	LAB_026D,X		; save secondary address over closed file
LAB_F30D
	CLC				; flag ok
	RTS


;************************************************************************************
;
; find a file

LAB_F30F
	LDA	#$00			; clear A
	STA	LAB_90		; clear the serial status byte
	TXA				; copy the logical file number to A


;************************************************************************************
;
; find file A

LAB_F314
	LDX	LAB_98		; get the open file count
LAB_F316
	DEX				; decrememnt the count to give the index
	BMI	LAB_F32E		; if no files just exit

	CMP	LAB_0259,X		; compare the logical file number with the table logical
					; file number
	BNE	LAB_F316		; if no match go try again

	RTS


;************************************************************************************
;
; set file details from table,X

LAB_F31F
	LDA	LAB_0259,X		; get logical file from logical file table
	STA	LAB_B8		; save the logical file
	LDA	LAB_0263,X		; get device number from device number table
	STA	LAB_BA		; save the device number
	LDA	LAB_026D,X		; get secondary address from secondary address table
	STA	LAB_B9		; save the secondary address
LAB_F32E
	RTS


;************************************************************************************
;
; close all channels and files

LAB_F32F
	LDA	#$00			; clear A
	STA	LAB_98		; clear the open file count


;************************************************************************************
;
; close input and output channels

LAB_F333
	LDX	#$03			; set the screen device
	CPX	LAB_9A		; compare the screen with the output device number
	BCS	LAB_F33C		; if <= screen skip the serial bus unlisten

	JSR	LAB_EDFE		; else command the serial bus to UNLISTEN
LAB_F33C
	CPX	LAB_99		; compare the screen with the input device number
	BCS	LAB_F343		; if <= screen skip the serial bus untalk

	JSR	LAB_EDEF		; else command the serial bus to UNTALK
LAB_F343
	STX	LAB_9A		; save the screen as the output device number
	LDA	#$00			; set the keyboard as the input device
	STA	LAB_99		; save the input device number
	RTS


;************************************************************************************
;
; open a logical file

LAB_F34A
	LDX	LAB_B8		; get the logical file
	BNE	LAB_F351		; if there is a file continue

	JMP	LAB_F70A		; else do 'not input file error' and return

LAB_F351
	JSR	LAB_F30F		; find a file
	BNE	LAB_F359		; if file not found continue

	JMP	LAB_F6FE		; else do 'file already open' error and return

LAB_F359
	LDX	LAB_98		; get the open file count
	CPX	#$0A			; compare it with the maximum + 1
	BCC	LAB_F362		; if less than maximum + 1 go open the file

	JMP	LAB_F6FB		; else do 'too many files error' and return

LAB_F362
	INC	LAB_98		; increment the open file count
	LDA	LAB_B8		; get the logical file
	STA	LAB_0259,X		; save it to the logical file table
	LDA	LAB_B9		; get the secondary address
	ORA	#$60			; OR with the OPEN CHANNEL command
	STA	LAB_B9		; save the secondary address
	STA	LAB_026D,X		; save it to the secondary address table
	LDA	LAB_BA		; get the device number
	STA	LAB_0263,X		; save it to the device number table
	BEQ	LAB_F3D3		; if it is the keyboard go do the ok exit

	CMP	#$03			; compare the device number with the screen
	BEQ	LAB_F3D3		; if it is the screen go do the ok exit

	BCC	LAB_F384		; if tape or RS232 device go ??

					; else it is a serial bus device
	JSR	LAB_F3D5		; send the secondary address and filename
	BCC	LAB_F3D3		; go do ok exit, branch always

LAB_F384
	CMP	#$02			;.
	BNE	LAB_F38B		;.

	JMP	LAB_F409		; go open RS232 device and return

LAB_F38B
	JSR	LAB_F7D0		; get tape buffer start pointer in XY
	BCS	LAB_F393		; if >= $0200 go ??

	JMP	LAB_F713		; else do 'illegal device number' and return

LAB_F393
	LDA	LAB_B9		; get the secondary address
	AND	#$0F			;.
	BNE	LAB_F3B8		;.

	JSR	LAB_F817		; wait for PLAY
	BCS	LAB_F3D4		; exit if STOP was pressed

	JSR	LAB_F5AF		; print "Searching..."
	LDA	LAB_B7		; get file name length
	BEQ	LAB_F3AF		; if null file name just go find header

	JSR	LAB_F7EA		; find specific tape header
	BCC	LAB_F3C2		; branch if no error

	BEQ	LAB_F3D4		; exit if ??

LAB_F3AC
	JMP	LAB_F704		; do file not found error and return

LAB_F3AF
	JSR	LAB_F72C		; find tape header, exit with header in buffer
	BEQ	LAB_F3D4		; exit if end of tape found
	BCC	LAB_F3C2		;.

	BCS	LAB_F3AC		;.

LAB_F3B8
	JSR	LAB_F838		; wait for PLAY/RECORD
	BCS	LAB_F3D4		; exit if STOP was pressed

	LDA	#$04			; set data file header
	JSR	LAB_F76A		; write tape header
LAB_F3C2
	LDA	#$BF			;.
	LDY	LAB_B9		; get the secondary address
	CPY	#$60			;.
	BEQ	LAB_F3D1		;.

	LDY	#$00			; clear index
	LDA	#$02			;.
	STA	(LAB_B2),Y		;.save to tape buffer
	TYA				;.clear A
LAB_F3D1
	STA	LAB_A6		;.save tape buffer index
LAB_F3D3
	CLC				; flag ok
LAB_F3D4
	RTS


;************************************************************************************
;
; send secondary address and filename

LAB_F3D5
	LDA	LAB_B9		; get the secondary address
	BMI	LAB_F3D3		; ok exit if -ve

	LDY	LAB_B7		; get file name length
	BEQ	LAB_F3D3		; ok exit if null

	LDA	#$00			; clear A
	STA	LAB_90		; clear the serial status byte
	LDA	LAB_BA		; get the device number
	JSR	LAB_ED0C		; command devices on the serial bus to LISTEN
	LDA	LAB_B9		; get the secondary address
	ORA	#$F0			; OR with the OPEN command
	JSR	LAB_EDB9		; send secondary address after LISTEN
	LDA	LAB_90		; get the serial status byte
	BPL	LAB_F3F6		; if device present skip the 'device not present' error

	PLA				; else dump calling address low byte
	PLA				; dump calling address high byte
	JMP	LAB_F707		; do 'device not present' error and return

LAB_F3F6
	LDA	LAB_B7		; get file name length
	BEQ	LAB_F406		; branch if null name

	LDY	#$00			; clear index
LAB_F3FC
	LDA	(LAB_BB),Y		; get file name byte
	JSR	LAB_EDDD		; output byte to serial bus
	INY				; increment index
	CPY	LAB_B7		; compare with file name length
	BNE	LAB_F3FC		; loop if not all done

LAB_F406
	JMP	LAB_F654		; command serial bus to UNLISTEN and return


;************************************************************************************
;
; open RS232 device

LAB_F409
	JSR	LAB_F483		; initialise RS232 output
	STY	LAB_0297		; save the RS232 status register
LAB_F40F
	CPY	LAB_B7		; compare with file name length
	BEQ	LAB_F41D		; exit loop if done

	LDA	(LAB_BB),Y		; get file name byte
	STA	LAB_0293,Y		; copy to 6551 register set
	INY				; increment index
	CPY	#$04			; compare with $04
	BNE	LAB_F40F		; loop if not to 4 yet

LAB_F41D
	JSR	LAB_EF4A		; compute bit count
	STX	LAB_0298		; save bit count
	LDA	LAB_0293		; get pseudo 6551 control register
	AND	#$0F			; mask 0000 xxxx, baud rate
	BEQ	LAB_F446		; if zero skip the baud rate setup

	ASL				; * 2 bytes per entry
	TAX				; copy to the index
	LDA	LAB_02A6		; get the PAL/NTSC flag
	BNE	LAB_F43A		; if PAL go set PAL timing

	LDY	LAB_FEC2-1,X	; get the NTSC baud rate value high byte
	LDA	LAB_FEC2-2,X	; get the NTSC baud rate value low byte
	JMP	LAB_F440		; go save the baud rate values

LAB_F43A
	LDY	LAB_E4EC-1,X	; get the PAL baud rate value high byte
	LDA	LAB_E4EC-2,X	; get the PAL baud rate value low byte
LAB_F440
	STY	LAB_0296		; save the nonstandard bit timing high byte
	STA	LAB_0295		; save the nonstandard bit timing low byte
LAB_F446
	LDA	LAB_0295		; get the nonstandard bit timing low byte
	ASL				; * 2
	JSR	LAB_FF2E		;.
	LDA	LAB_0294		; read the pseudo 6551 command register
	LSR				; shift the X line/3 line bit into Cb
	BCC	LAB_F45C		; if 3 line skip the DRS test

	LDA	LAB_DD01		; read VIA 2 DRB, RS232 port
	ASL				; shift DSR in into Cb
	BCS	LAB_F45C		; if DSR present skip the error set

	JSR	LAB_F00D		; set no DSR
LAB_F45C
	LDA	LAB_029B		; get index to Rx buffer end
	STA	LAB_029C		; set index to Rx buffer start, clear Rx buffer
	LDA	LAB_029E		; get index to Tx buffer end
	STA	LAB_029D		; set index to Tx buffer start, clear Tx buffer
	JSR	LAB_FE27		; read the top of memory
	LDA	LAB_F8		; get the RS232 input buffer pointer high byte
	BNE	LAB_F474		; if buffer already set skip the save

	DEY				; decrement top of memory high byte, 256 byte buffer
	STY	LAB_F8		; save the RS232 input buffer pointer high byte
	STX	LAB_F7		; save the RS232 input buffer pointer low byte
LAB_F474
	LDA	LAB_FA		; get the RS232 output buffer pointer high byte
	BNE	LAB_F47D		; if ?? go set the top of memory to F0xx

	DEY				;.
	STY	LAB_FA		; save the RS232 output buffer pointer high byte
	STX	LAB_F9		; save the RS232 output buffer pointer low byte


;************************************************************************************
;
; set the top of memory to F0xx

LAB_F47D
	SEC				; read the top of memory
	LDA	#$F0			; set $F000
	JMP	LAB_FE2D		; set the top of memory and return


;************************************************************************************
;
; initialise RS232 output

LAB_F483
	LDA	#$7F			; disable all interrupts
	STA	LAB_DD0D		; save VIA 2 ICR
	LDA	#$06			; set RS232 DTR output, RS232 RTS output
	STA	LAB_DD03		; save VIA 2 DDRB, RS232 port
	STA	LAB_DD01		; save VIA 2 DRB, RS232 port
	LDA	#$04			; mask xxxx x1xx, set RS232 Tx DATA high
	ORA	LAB_DD00		; OR it with VIA 2 DRA, serial port and video address
	STA	LAB_DD00		; save VIA 2 DRA, serial port and video address
	LDY	#$00			; clear Y
	STY	LAB_02A1		; clear the RS-232 interrupt enable byte
	RTS


;************************************************************************************
;
; load RAM from a device

LAB_F49E
	STX	LAB_C3		; set kernal setup pointer low byte
	STY	LAB_C4		; set kernal setup pointer high byte
	JMP	(LAB_0330)		; do LOAD vector, usually points to LAB_F4A5


;************************************************************************************
;
; load

LAB_F4A5
	STA	LAB_93		; save load/verify flag
	LDA	#$00			; clear A
	STA	LAB_90		; clear the serial status byte
	LDA	LAB_BA		; get the device number
	BNE	LAB_F4B2		; if not the keyboard continue

; do 'illegal device number'

LAB_F4AF
	JMP	LAB_F713		; else do 'illegal device number' and return

LAB_F4B2
	CMP	#$03			;.
	BEQ	LAB_F4AF		;.

	BCC	LAB_F533		;.

	LDY	LAB_B7		; get file name length
	BNE	LAB_F4BF		; if not null name go ??

	JMP	LAB_F710		; else do 'missing file name' error and return

LAB_F4BF
	LDX	LAB_B9		; get the secondary address
	JSR	LAB_F5AF		; print "Searching..."
	LDA	#$60			;.
	STA	LAB_B9		; save the secondary address
	JSR	LAB_F3D5		; send secondary address and filename
	LDA	LAB_BA		; get the device number
	JSR	LAB_ED09		; command serial bus device to TALK
	LDA	LAB_B9		; get the secondary address
	JSR	LAB_EDC7		; send secondary address after TALK
	JSR	LAB_EE13		; input byte from serial bus
	STA	LAB_AE		; save program start address low byte
	LDA	LAB_90		; get the serial status byte
	LSR				; shift time out read ..
	LSR				; .. into carry bit
	BCS	LAB_F530		; if timed out go do file not found error and return

	JSR	LAB_EE13		; input byte from serial bus
	STA	LAB_AF		; save program start address high byte
	TXA				; copy secondary address
	BNE	LAB_F4F0		; load location not set in LOAD call, so continue with the
					; load

	LDA	LAB_C3		; get the load address low byte
	STA	LAB_AE		; save the program start address low byte
	LDA	LAB_C4		; get the load address high byte
	STA	LAB_AF		; save the program start address high byte

LAB_F4F0
	JSR	LAB_F5D2		;.
LAB_F4F3
	LDA	#$FD			; mask xxxx xx0x, clear time out read bit
	AND	LAB_90		; mask the serial status byte
	STA	LAB_90		; set the serial status byte
	JSR	LAB_FFE1		; scan stop key, return Zb = 1 = [STOP]
	BNE	LAB_F501		; if not [STOP] go ??

	JMP	LAB_F633		; else close the serial bus device and flag stop

LAB_F501
	JSR	LAB_EE13		; input byte from serial bus
	TAX				; copy byte
	LDA	LAB_90		; get the serial status byte
	LSR				; shift time out read ..
	LSR				; .. into carry bit
	BCS	LAB_F4F3		; if timed out go try again

	TXA				; copy received byte back
	LDY	LAB_93		; get load/verify flag
	BEQ	LAB_F51C		; if load go load

					; else is verify
	LDY	#$00			; clear index
	CMP	(LAB_AE),Y		; compare byte with previously loaded byte
	BEQ	LAB_F51E		; if match go ??

	LDA	#$10			; flag read error
	JSR	LAB_FE1C		; OR into the serial status byte
	.byte	$2C			; makes next line BIT LAB_AE91
LAB_F51C
	STA	(LAB_AE),Y		; save byte to memory
LAB_F51E
	INC	LAB_AE		; increment save pointer low byte
	BNE	LAB_F524		; if no rollover go ??

	INC	LAB_AF		; else increment save pointer high byte
LAB_F524
	BIT	LAB_90		; test the serial status byte
	BVC	LAB_F4F3		; loop if not end of file

; close file and exit

;LAB_F528
	JSR	LAB_EDEF		; command serial bus to UNTALK
	JSR	LAB_F642		; close serial bus device
	BCC	LAB_F5A9		; if ?? go flag ok and exit

LAB_F530
	JMP	LAB_F704		; do file not found error and return


;************************************************************************************
;
; ??

LAB_F533
	LSR
	BCS	LAB_F539
	JMP	LAB_F713		; else do 'illegal device number' and return
LAB_F539
	JSR	LAB_F7D0		; get tape buffer start pointer in XY
	BCS	LAB_F541		; if ??

	JMP	LAB_F713		; else do 'illegal device number' and return

LAB_F541
	JSR	LAB_F817		; wait for PLAY
	BCS	LAB_F5AE		; exit if STOP was pressed

	JSR	LAB_F5AF		; print "Searching..."
LAB_F549
	LDA	LAB_B7		; get file name length
	BEQ	LAB_F556		;.

	JSR	LAB_F7EA		; find specific tape header
	BCC	LAB_F55D		; if no error continue

	BEQ	LAB_F5AE		; exit if ??

	BCS	LAB_F530		;., branch always

LAB_F556
	JSR	LAB_F72C		; find tape header, exit with header in buffer
	BEQ	LAB_F5AE		; exit if ??

	BCS	LAB_F530		;.

LAB_F55D
	LDA	LAB_90		; get the serial status byte
	AND	#$10			; mask 000x 0000, read error
	SEC				; flag fail
	BNE	LAB_F5AE		; if read error just exit

	CPX	#$01			;.
	BEQ	LAB_F579		;.

	CPX	#$03			;.
	BNE	LAB_F549		;.

LAB_F56C
	LDY	#$01			;.
	LDA	(LAB_B2),Y		;.
	STA	LAB_C3		;.
	INY				;.
	LDA	(LAB_B2),Y		;.
	STA	LAB_C4		;.
	BCS	LAB_F57D		;.

LAB_F579
	LDA	LAB_B9		; get the secondary address
	BNE	LAB_F56C		;.

LAB_F57D
	LDY	#$03			;.
	LDA	(LAB_B2),Y		;.
	LDY	#$01			;.
	SBC	(LAB_B2),Y		;.
	TAX				;.
	LDY	#$04			;.
	LDA	(LAB_B2),Y		;.
	LDY	#$02			;.
	SBC	(LAB_B2),Y		;.
	TAY				;.
	CLC				;.
	TXA				;.
	ADC	LAB_C3		;.
	STA	LAB_AE		;.
	TYA				;.
	ADC	LAB_C4		;.
	STA	LAB_AF		;.
	LDA	LAB_C3		;.
	STA	LAB_C1		; set I/O start addresses low byte
	LDA	LAB_C4		;.
	STA	LAB_C2		; set I/O start addresses high byte
	JSR	LAB_F5D2		; display "LOADING" or "VERIFYING"
	JSR	LAB_F84A		; do the tape read
	.byte	$24			; makes next line BIT LAB_xx, keep the error flag in Cb
LAB_F5A9
	CLC				; flag ok
	LDX	LAB_AE		; get the LOAD end pointer low byte
	LDY	LAB_AF		; get the LOAD end pointer high byte
LAB_F5AE
	RTS


;************************************************************************************
;
; print "Searching..."

LAB_F5AF
	LDA	LAB_9D		; get message mode flag
	BPL	LAB_F5D1		; exit if control messages off
	LDY	#LAB_F0C9-LAB_F0BD
					; index to "SEARCHING "
	JSR	LAB_F12F		; display kernel I/O message
	LDA	LAB_B7		; get file name length
	BEQ	LAB_F5D1		; exit if null name

	LDY	#LAB_F0D4-LAB_F0BD
					; else index to "FOR "
	JSR	LAB_F12F		; display kernel I/O message


;************************************************************************************
;
; print file name

LAB_F5C1
	LDY	LAB_B7		; get file name length
	BEQ	LAB_F5D1		; exit if null file name

	LDY	#$00			; clear index
LAB_F5C7
	LDA	(LAB_BB),Y		; get file name byte
	JSR	LAB_FFD2		; output character to channel
	INY				; increment index
	CPY	LAB_B7		; compare with file name length
	BNE	LAB_F5C7		; loop if more to do

LAB_F5D1
	RTS


;************************************************************************************
;
; display "LOADING" or "VERIFYING"

LAB_F5D2
	LDY	#LAB_F106-LAB_F0BD
					; point to "LOADING"
	LDA	LAB_93		; get load/verify flag
	BEQ	LAB_F5DA		; branch if load

	LDY	#LAB_F116-LAB_F0BD
					; point to "VERIFYING"
LAB_F5DA
	JMP	LAB_F12B		; display kernel I/O message if in direct mode and return


;************************************************************************************
;
; save RAM to device, A = index to start address, XY = end address low/high

LAB_F5DD
	STX	LAB_AE		; save end address low byte
	STY	LAB_AF		; save end address high byte
	TAX				; copy index to start pointer
	LDA	LAB_00+0,X		; get start address low byte
	STA	LAB_C1		; set I/O start addresses low byte
	LDA	LAB_00+1,X		; get start address high byte
	STA	LAB_C2		; set I/O start addresses high byte
	JMP	(LAB_0332)		; go save, usually points to LAB_F685


;************************************************************************************
;
; save

LAB_F5ED
	LDA	LAB_BA		; get the device number
	BNE	LAB_F5F4		; if not keyboard go ??

					; else ..
LAB_F5F1
	JMP	LAB_F713		; else do 'illegal device number' and return

LAB_F5F4
	CMP	#$03			; compare device number with screen
	BEQ	LAB_F5F1		; if screen do illegal device number and return

	BCC	LAB_F659		; branch if < screen

					; is greater than screen so is serial bus
	LDA	#$61			; set secondary address to $01
					; when a secondary address is to be sent to a device on
					; the serial bus the address must first be ORed with $60
	STA	LAB_B9		; save the secondary address
	LDY	LAB_B7		; get the file name length
	BNE	LAB_F605		; if filename not null continue

	JMP	LAB_F710		; else do 'missing file name' error and return

LAB_F605
	JSR	LAB_F3D5		; send secondary address and filename
	JSR	LAB_F68F		; print saving <file name>
	LDA	LAB_BA		; get the device number
	JSR	LAB_ED0C		; command devices on the serial bus to LISTEN
	LDA	LAB_B9		; get the secondary address
	JSR	LAB_EDB9		; send secondary address after LISTEN
	LDY	#$00			; clear index
	JSR	LAB_FB8E		; copy I/O start address to buffer address
	LDA	LAB_AC		; get buffer address low byte
	JSR	LAB_EDDD		; output byte to serial bus
	LDA	LAB_AD		; get buffer address high byte
	JSR	LAB_EDDD		; output byte to serial bus
LAB_F624
	JSR	LAB_FCD1		; check read/write pointer, return Cb = 1 if pointer >= end
	BCS	LAB_F63F		; go do UNLISTEN if at end

	LDA	(LAB_AC),Y		; get byte from buffer
	JSR	LAB_EDDD		; output byte to serial bus
	JSR	LAB_FFE1		; scan stop key
	BNE	LAB_F63A		; if stop not pressed go increment pointer and loop for next

					; else ..

; close the serial bus device and flag stop

LAB_F633
	JSR	LAB_F642		; close serial bus device
	LDA	#$00			;.
	SEC				; flag stop
	RTS

LAB_F63A
	JSR	LAB_FCDB		; increment read/write pointer
	BNE	LAB_F624		; loop, branch always

LAB_F63F
	JSR	LAB_EDFE		; command serial bus to UNLISTEN

; close serial bus device

LAB_F642
	BIT	LAB_B9		; test the secondary address
	BMI	LAB_F657		; if already closed just exit

	LDA	LAB_BA		; get the device number
	JSR	LAB_ED0C		; command devices on the serial bus to LISTEN
	LDA	LAB_B9		; get the secondary address
	AND	#$EF			; mask the channel number
	ORA	#$E0			; OR with the CLOSE command
	JSR	LAB_EDB9		; send secondary address after LISTEN
LAB_F654
	JSR	LAB_EDFE		; command serial bus to UNLISTEN
LAB_F657
	CLC				; flag ok
	RTS

LAB_F659
	LSR				;.
	BCS	LAB_F65F		; if not RS232 device ??

	JMP	LAB_F713		; else do 'illegal device number' and return

LAB_F65F
	JSR	LAB_F7D0		; get tape buffer start pointer in XY
	BCC	LAB_F5F1		; if < $0200 do illegal device number and return

	JSR	LAB_F838		; wait for PLAY/RECORD
	BCS	LAB_F68E		; exit if STOP was pressed

	JSR	LAB_F68F		; print saving <file name>
	LDX	#$03			; set header for a non relocatable program file
	LDA	LAB_B9		; get the secondary address
	AND	#$01			; mask non relocatable bit
	BNE	LAB_F676		; if non relocatable program go ??

	LDX	#$01			; else set header for a relocatable program file
LAB_F676
	TXA				; copy header type to A
	JSR	LAB_F76A		; write tape header
	BCS	LAB_F68E		; exit if error

	JSR	LAB_F867		; do tape write, 20 cycle count
	BCS	LAB_F68E		; exit if error

	LDA	LAB_B9		; get the secondary address
	AND	#$02			; mask end of tape flag
	BEQ	LAB_F68D		; if not end of tape go ??

	LDA	#$05			; else set logical end of the tape
	JSR	LAB_F76A		; write tape header
	.byte	$24			; makes next line BIT LAB_18 so Cb is not changed
LAB_F68D
	CLC				; flag ok
LAB_F68E
	RTS


;************************************************************************************
;
; print saving <file name>

LAB_F68F
	LDA	LAB_9D		; get message mode flag
	BPL	LAB_F68E		; exit if control messages off

	LDY	#LAB_F10E-LAB_F0BD
					; index to "SAVING "
	JSR	LAB_F12F		; display kernel I/O message
	JMP	LAB_F5C1		; print file name and return


;************************************************************************************
;
; increment the real time clock

LAB_F69B
	LDX	#$00			; clear X
	INC	LAB_A2		; increment the jiffy clock low byte
	BNE	LAB_F6A7		; if no rollover ??

	INC	LAB_A1		; increment the jiffy clock mid byte
	BNE	LAB_F6A7		; branch if no rollover

	INC	LAB_A0		; increment the jiffy clock high byte

					; now subtract a days worth of jiffies from current count
					; and remember only the Cb result
LAB_F6A7
	SEC				; set carry for subtract
	LDA	LAB_A2		; get the jiffy clock low byte
	SBC	#$01			; subtract $4F1A01 low byte
	LDA	LAB_A1		; get the jiffy clock mid byte
	SBC	#$1A			; subtract $4F1A01 mid byte
	LDA	LAB_A0		; get the jiffy clock high byte
	SBC	#$4F			; subtract $4F1A01 high byte
	BCC	LAB_F6BC		; if less than $4F1A01 jiffies skip the clock reset

					; else ..
	STX	LAB_A0		; clear the jiffy clock high byte
	STX	LAB_A1		; clear the jiffy clock mid byte
	STX	LAB_A2		; clear the jiffy clock low byte
					; this is wrong, there are $4F1A00 jiffies in a day so
					; the reset to zero should occur when the value reaches
					; $4F1A00 and not $4F1A01. this would give an extra jiffy
					; every day and a possible TI value of 24:00:00
LAB_F6BC
	LDA	LAB_DC01		; read VIA 1 DRB, keyboard row port
	CMP	LAB_DC01		; compare it with itself
	BNE	LAB_F6BC		; loop if changing

	TAX				;.
	BMI	LAB_F6DA		;.

	LDX	#$BD			; set c6
	STX	LAB_DC00		; save VIA 1 DRA, keyboard column drive

LAB_F6CC
	LDX	LAB_DC01		; read VIA 1 DRB, keyboard row port
	CPX	LAB_DC01		; compare it with itself
	BNE	LAB_F6CC		; loop if changing

	STA	LAB_DC00		; save VIA 1 DRA, keyboard column drive
	INX				;.
	BNE	LAB_F6DC		;.

LAB_F6DA
	STA	LAB_91		; save the stop key column
LAB_F6DC
	RTS


;************************************************************************************
;
; read the real time clock

LAB_F6DD
	SEI				; disable the interrupts
	LDA	LAB_A2		; get the jiffy clock low byte
	LDX	LAB_A1		; get the jiffy clock mid byte
	LDY	LAB_A0		; get the jiffy clock high byte


;************************************************************************************
;
; set the real time clock

LAB_F6E4
	SEI				; disable the interrupts
	STA	LAB_A2		; save the jiffy clock low byte
	STX	LAB_A1		; save the jiffy clock mid byte
	STY	LAB_A0		; save the jiffy clock high byte
	CLI				; enable the interrupts
	RTS


;************************************************************************************
;
; scan the stop key, return Zb = 1 = [STOP]

LAB_F6ED
	LDA	LAB_91		; read the stop key column
	CMP	#$7F			; compare with [STP] down
	BNE	LAB_F6FA		; if not [STP] or not just [STP] exit

					; just [STP] was pressed
	PHP				; save status
	JSR	LAB_FFCC		; close input and output channels
	STA	LAB_C6		; save the keyboard buffer index
	PLP				; restore status

LAB_F6FA
	RTS


;************************************************************************************
;
; file error messages

LAB_F6FB
	LDA	#$01			; 'too many files' error
	.byte	$2C			; makes next line BIT LAB_xxxx
LAB_F6FE
	LDA	#$02			; 'file already open' error
	.byte	$2C			; makes next line BIT LAB_xxxx
LAB_F701
	LDA	#$03			; 'file not open' error
	.byte	$2C			; makes next line BIT LAB_xxxx
LAB_F704
	LDA	#$04			; 'file not found' error
	.byte	$2C			; makes next line BIT LAB_xxxx
LAB_F707
	LDA	#$05			; 'device not present' error
	.byte	$2C			; makes next line BIT LAB_xxxx
LAB_F70A
	LDA	#$06			; 'not input file' error
	.byte	$2C			; makes next line BIT LAB_xxxx
LAB_F70D
	LDA	#$07			; 'not output file' error
	.byte	$2C			; makes next line BIT LAB_xxxx
LAB_F710
	LDA	#$08			; 'missing file name' error
	.byte	$2C			; makes next line BIT LAB_xxxx

LAB_F713
	LDA	#$09			; do 'illegal device number'

	PHA				; save the error #
	JSR	LAB_FFCC		; close input and output channels
	LDY	#LAB_F0BD-LAB_F0BD
					; index to "I/O ERROR #"
	BIT	LAB_9D		; test message mode flag
	BVC	LAB_F729		; exit if kernal messages off

	JSR	LAB_F12F		; display kernel I/O message
	PLA				; restore error #
	PHA				; copy error #
	ORA	#'0'			; convert to ASCII
	JSR	LAB_FFD2		; output character to channel
LAB_F729
	PLA				; pull error number
	SEC				; flag error
	RTS


;************************************************************************************
;
; find the tape header, exit with header in buffer

LAB_F72C
	LDA	LAB_93		; get load/verify flag
	PHA				; save load/verify flag
	JSR	LAB_F841		; initiate tape read
	PLA				; restore load/verify flag
	STA	LAB_93		; save load/verify flag
	BCS	LAB_F769		; exit if error

	LDY	#$00			; clear the index
	LDA	(LAB_B2),Y		; read first byte from tape buffer
	CMP	#$05			; compare with logical end of the tape
	BEQ	LAB_F769		; if end of the tape exit

	CMP	#$01			; compare with header for a relocatable program file
	BEQ	LAB_F74B		; if program file header go ??

	CMP	#$03			; compare with header for a non relocatable program file
	BEQ	LAB_F74B		; if program file header go  ??

	CMP	#$04			; compare with data file header
	BNE	LAB_F72C		; if data file loop to find the tape header

					; was a program file header
LAB_F74B
	TAX				; copy header type
	BIT	LAB_9D		; get message mode flag
	BPL	LAB_F767		; exit if control messages off

	LDY	#LAB_F120-LAB_F0BD
					; index to "FOUND "
	JSR	LAB_F12F		; display kernel I/O message
	LDY	#$05			; index to the tape filename
LAB_F757
	LDA	(LAB_B2),Y		; get byte from tape buffer
	JSR	LAB_FFD2		; output character to channel
	INY				; increment the index
	CPY	#$15			; compare it with end+1
	BNE	LAB_F757		; loop if more to do

	LDA	LAB_A1		; get the jiffy clock mid byte
	JSR	LAB_E4E0		; wait ~8.5 seconds for any key from the STOP key column
	NOP				; waste cycles
LAB_F767
	CLC				; flag no error
	DEY				; decrement the index
LAB_F769
	RTS


;************************************************************************************
;
; write the tape header

LAB_F76A
	STA	LAB_9E		; save header type
	JSR	LAB_F7D0		; get tape buffer start pointer in XY
	BCC	LAB_F7CF		; if < $0200 just exit ??

	LDA	LAB_C2		; get I/O start address high byte
	PHA				; save it
	LDA	LAB_C1		; get I/O start address low byte
	PHA				; save it
	LDA	LAB_AF		; get tape end address high byte
	PHA				; save it
	LDA	LAB_AE		; get tape end address low byte
	PHA				; save it

	LDY	#$BF			; index to header end
	LDA	#' '			; clear byte, [SPACE]
LAB_F781
	STA	(LAB_B2),Y		; clear header byte
	DEY				; decrement index
	BNE	LAB_F781		; loop if more to do

	LDA	LAB_9E		; get the header type back
	STA	(LAB_B2),Y		; write it to header
	INY				; increment the index
	LDA	LAB_C1		; get the I/O start address low byte
	STA	(LAB_B2),Y		; write it to header
	INY				; increment the index
	LDA	LAB_C2		; get the I/O start address high byte
	STA	(LAB_B2),Y		; write it to header
	INY				; increment the index
	LDA	LAB_AE		; get the tape end address low byte
	STA	(LAB_B2),Y		; write it to header
	INY				; increment the index
	LDA	LAB_AF		; get the tape end address high byte
	STA	(LAB_B2),Y		; write it to header
	INY				; increment the index
	STY	LAB_9F		; save the index
	LDY	#$00			; clear Y
	STY	LAB_9E		; clear the name index
LAB_F7A5
	LDY	LAB_9E		; get name index
	CPY	LAB_B7		; compare with file name length
	BEQ	LAB_F7B7		; if all done exit the loop

	LDA	(LAB_BB),Y		; get file name byte
	LDY	LAB_9F		; get buffer index
	STA	(LAB_B2),Y		; save file name byte to buffer
	INC	LAB_9E		; increment file name index
	INC	LAB_9F		; increment tape buffer index
	BNE	LAB_F7A5		; loop, branch always

LAB_F7B7
	JSR	LAB_F7D7		; set tape buffer start and end pointers
	LDA	#$69			; set write lead cycle count
	STA	LAB_AB		; save write lead cycle count
	JSR	LAB_F86B		; do tape write, no cycle count set
	TAY				;.
	PLA				; pull tape end address low byte
	STA	LAB_AE		; restore it
	PLA				; pull tape end address high byte
	STA	LAB_AF		; restore it
	PLA				; pull I/O start addresses low byte
	STA	LAB_C1		; restore it
	PLA				; pull I/O start addresses high byte
	STA	LAB_C2		; restore it
	TYA				;.
LAB_F7CF
	RTS


;************************************************************************************
;
; get the tape buffer start pointer

LAB_F7D0
	LDX	LAB_B2		; get tape buffer start pointer low byte
	LDY	LAB_B3		; get tape buffer start pointer high byte
	CPY	#$02			; compare high byte with $02xx
	RTS


;************************************************************************************
;
; set the tape buffer start and end pointers

LAB_F7D7
	JSR	LAB_F7D0		; get tape buffer start pointer in XY
	TXA				; copy tape buffer start pointer low byte
	STA	LAB_C1		; save as I/O address pointer low byte
	CLC				; clear carry for add
	ADC	#$C0			; add buffer length low byte
	STA	LAB_AE		; save tape buffer end pointer low byte
	TYA				; copy tape buffer start pointer high byte
	STA	LAB_C2		; save as I/O address pointer high byte
	ADC	#$00			; add buffer length high byte
	STA	LAB_AF		; save tape buffer end pointer high byte
	RTS


;************************************************************************************
;
; find specific tape header

LAB_F7EA
	JSR	LAB_F72C		; find tape header, exit with header in buffer
	BCS	LAB_F80C		; just exit if error

	LDY	#$05			; index to name
	STY	LAB_9F		; save as tape buffer index
	LDY	#$00			; clear Y
	STY	LAB_9E		; save as name buffer index
LAB_F7F7
	CPY	LAB_B7		; compare with file name length
	BEQ	LAB_F80B		; ok exit if match

	LDA	(LAB_BB),Y		; get file name byte
	LDY	LAB_9F		; get index to tape buffer
	CMP	(LAB_B2),Y		; compare with tape header name byte
	BNE	LAB_F7EA		; if no match go get next header

	INC	LAB_9E		; else increment name buffer index
	INC	LAB_9F		; increment tape buffer index
	LDY	LAB_9E		; get name buffer index
	BNE	LAB_F7F7		; loop, branch always

LAB_F80B
	CLC				; flag ok
LAB_F80C
	RTS


;************************************************************************************
;
; bump tape pointer

LAB_F80D
	JSR	LAB_F7D0		; get tape buffer start pointer in XY
	INC	LAB_A6		; increment tape buffer index
	LDY	LAB_A6		; get tape buffer index
	CPY	#$C0			; compare with buffer length
	RTS


;************************************************************************************
;
; wait for PLAY

LAB_F817
	JSR	LAB_F82E		; return cassette sense in Zb
	BEQ	LAB_F836		; if switch closed just exit

					; cassette switch was open
	LDY	#LAB_F0D8-LAB_F0BD
					; index to "PRESS PLAY ON TAPE"
LAB_F81E
	JSR	LAB_F12F		; display kernel I/O message
LAB_F821
	JSR	LAB_F8D0		; scan stop key and flag abort if pressed
					; note if STOP was pressed the return is to the
					; routine that called this one and not here
	JSR	LAB_F82E		; return cassette sense in Zb
	BNE	LAB_F821		; loop if the cassette switch is open

	LDY	#LAB_F127-LAB_F0BD
					; index to "OK"
	JMP	LAB_F12F		; display kernel I/O message and return


;************************************************************************************
;
; return cassette sense in Zb

LAB_F82E
	LDA	#$10			; set the mask for the cassette switch
	BIT	LAB_01		; test the 6510 I/O port
	BNE	LAB_F836		; branch if cassette sense high

	BIT	LAB_01		; test the 6510 I/O port
LAB_F836
	CLC				;.
	RTS


;************************************************************************************
;
; wait for PLAY/RECORD

LAB_F838
	JSR	LAB_F82E		; return the cassette sense in Zb
	BEQ	LAB_F836		; exit if switch closed

					; cassette switch was open
	LDY	#LAB_F0EB-LAB_F0BD
					; index to "PRESS RECORD & PLAY ON TAPE"
	BNE	LAB_F81E		; display message and wait for switch, branch always


;************************************************************************************
;
; initiate a tape read

LAB_F841
	LDA	#$00			; clear A
	STA	LAB_90		; clear serial status byte
	STA	LAB_93		; clear the load/verify flag
	JSR	LAB_F7D7		; set the tape buffer start and end pointers
LAB_F84A
	JSR	LAB_F817		; wait for PLAY
	BCS	LAB_F86E		; exit if STOP was pressed, uses a further BCS at the
					; target address to reach final target at LAB_F8DC

	SEI				; disable interrupts
	LDA	#$00			; clear A
	STA	LAB_AA		;.
	STA	LAB_B4		;.
	STA	LAB_B0		; clear tape timing constant min byte
	STA	LAB_9E		; clear tape pass 1 error log/char buffer
	STA	LAB_9F		; clear tape pass 2 error log corrected
	STA	LAB_9C		; clear byte received flag
	LDA	#$90			; enable CA1 interrupt ??
	LDX	#$0E			; set index for tape read vector
	BNE	LAB_F875		; go do tape read/write, branch always


;************************************************************************************
;
; initiate a tape write

LAB_F864
	JSR	LAB_F7D7		; set tape buffer start and end pointers

; do tape write, 20 cycle count

LAB_F867
	LDA	#$14			; set write lead cycle count
	STA	LAB_AB		; save write lead cycle count

; do tape write, no cycle count set

LAB_F86B
	JSR	LAB_F838		; wait for PLAY/RECORD
LAB_F86E
	BCS	LAB_F8DC		; if STOPped clear save IRQ address and exit

	SEI				; disable interrupts
	LDA	#$82			; enable ?? interrupt
	LDX	#$08			; set index for tape write tape leader vector


;************************************************************************************
;
; tape read/write

LAB_F875
	LDY	#$7F			; disable all interrupts
	STY	LAB_DC0D		; save VIA 1 ICR, disable all interrupts
	STA	LAB_DC0D		; save VIA 1 ICR, enable interrupts according to A

; check RS232 bus idle

	LDA	LAB_DC0E		; read VIA 1 CRA
	ORA	#$19			; load timer B, timer B single shot, start timer B
	STA	LAB_DC0F		; save VIA 1 CRB
	AND	#$91			; mask x00x 000x, TOD clock, load timer A, start timer A
	STA	LAB_02A2		; save VIA 1 CRB shadow copy
	JSR	LAB_F0A4		;.
	LDA	LAB_D011		; read the vertical fine scroll and control register
	AND	#$EF			; mask xxx0 xxxx, blank the screen
	STA	LAB_D011		; save the vertical fine scroll and control register
	LDA	LAB_0314		; get IRQ vector low byte
	STA	LAB_029F		; save IRQ vector low byte
	LDA	LAB_0315		; get IRQ vector high byte
	STA	LAB_02A0		; save IRQ vector high byte
	JSR	LAB_FCBD		; set the tape vector
	LDA	#$02			; set copies count. the first copy is the load copy, the
					; second copy is the verify copy
	STA	LAB_BE		; save copies count
	JSR	LAB_FB97		; new tape byte setup
	LDA	LAB_01		; read the 6510 I/O port
	AND	#$1F			; mask 000x xxxx, cassette motor on ??
	STA	LAB_01		; save the 6510 I/O port
	STA	LAB_C0		; set the tape motor interlock

					; 326656 cycle delay, allow tape motor speed to stabilise
	LDX	#$FF			; outer loop count
LAB_F8B5
	LDY	#$FF			; inner loop count
LAB_F8B7
	DEY				; decrement inner loop count
	BNE	LAB_F8B7		; loop if more to do

	DEX				; decrement outer loop count
	BNE	LAB_F8B5		; loop if more to do

	CLI				; enable tape interrupts
LAB_F8BE
	LDA	LAB_02A0		; get saved IRQ high byte
	CMP	LAB_0315		; compare with the current IRQ high byte
	CLC				; flag ok
	BEQ	LAB_F8DC		; if tape write done go clear saved IRQ address and exit

	JSR	LAB_F8D0		; scan stop key and flag abort if pressed
					; note if STOP was pressed the return is to the
					; routine that called this one and not here
	JSR	LAB_F6BC		; increment real time clock
	JMP	LAB_F8BE		; loop


;************************************************************************************
;
; scan stop key and flag abort if pressed

LAB_F8D0
	JSR	LAB_FFE1		; scan stop key
	CLC				; flag no stop
	BNE	LAB_F8E1		; exit if no stop

	JSR	LAB_FC93		; restore everything for STOP
	SEC				; flag stopped
	PLA				; dump return address low byte
	PLA				; dump return address high byte


;************************************************************************************
;
; clear saved IRQ address

LAB_F8DC
	LDA	#$00			; clear A
	STA	LAB_02A0		; clear saved IRQ address high byte
LAB_F8E1
	RTS


;************************************************************************************
;
;## set timing

LAB_F8E2
	STX	LAB_B1		; save tape timing constant max byte
	LDA	LAB_B0		; get tape timing constant min byte
	ASL				; *2
	ASL				; *4
	CLC				; clear carry for add
	ADC	LAB_B0		; add tape timing constant min byte *5
	CLC				; clear carry for add
	ADC	LAB_B1		; add tape timing constant max byte
	STA	LAB_B1		; save tape timing constant max byte
	LDA	#$00			;.
	BIT	LAB_B0		; test tape timing constant min byte
	BMI	LAB_F8F7		; branch if b7 set

	ROL				; else shift carry into ??
LAB_F8F7
	ASL	LAB_B1		; shift tape timing constant max byte
	ROL				;.
	ASL	LAB_B1		; shift tape timing constant max byte
	ROL				;.
	TAX				;.
LAB_F8FE
	LDA	LAB_DC06		; get VIA 1 timer B low byte
	CMP	#$16			;.compare with ??
	BCC	LAB_F8FE		; loop if less

	ADC	LAB_B1		; add tape timing constant max byte
	STA	LAB_DC04		; save VIA 1 timer A low byte
	TXA				;.
	ADC	LAB_DC07		; add VIA 1 timer B high byte
	STA	LAB_DC05		; save VIA 1 timer A high byte
	LDA	LAB_02A2		; read VIA 1 CRB shadow copy
	STA	LAB_DC0E		; save VIA 1 CRA
	STA	LAB_02A4		; save VIA 1 CRA shadow copy
	LDA	LAB_DC0D		; read VIA 1 ICR
	AND	#$10			; mask 000x 0000, FLAG interrupt
	BEQ	LAB_F92A		; if no FLAG interrupt just exit

					; else first call the IRQ routine
	LDA	#>LAB_F92A		; set the return address high byte
	PHA				; push the return address high byte
	LDA	#<LAB_F92A		; set the return address low byte
	PHA				; push the return address low byte
	JMP	LAB_FF43		; save the status and do the IRQ routine

LAB_F92A
	CLI				; enable interrupts
	RTS


;************************************************************************************
;
;	On Commodore computers, the streams consist of four kinds of symbols
;	that denote different kinds of low-to-high-to-low transitions on the
;	read or write signals of the Commodore cassette interface.
;
;	A	A break in the communications, or a pulse with very long cycle
;		time.
;
;	B	A short pulse, whose cycle time typically ranges from 296 to 424
;		microseconds, depending on the computer model.
;
;	C	A medium-length pulse, whose cycle time typically ranges from
;		440 to 576 microseconds, depending on the computer model.
;
;	D	A long pulse, whose cycle time typically ranges from 600 to 744
;		microseconds, depending on the computer model.
;
;  The actual interpretation of the serial data takes a little more work to explain.
; The typical ROM tape loader (and the turbo loaders) will initialize a timer with a
; specified value and start it counting down. If either the tape data changes or the
; timer runs out, an IRQ will occur. The loader will determine which condition caused
; the IRQ. If the tape data changed before the timer ran out, we have a short pulse,
; or a "0" bit. If the timer ran out first, we have a long pulse, or a "1" bit. Doing
; this continuously and we decode the entire file.

; read tape bits, IRQ routine

; read T2C which has been counting down from $FFFF. subtract this from $FFFF

LAB_F92C
	LDX	LAB_DC07		; read VIA 1 timer B high byte
	LDY	#$FF			;.set $FF
	TYA				;.A = $FF
	SBC	LAB_DC06		; subtract VIA 1 timer B low byte
	CPX	LAB_DC07		; compare it with VIA 1 timer B high byte
	BNE	LAB_F92C		; if timer low byte rolled over loop

	STX	LAB_B1		; save tape timing constant max byte
	TAX				;.copy $FF - T2C_l
	STY	LAB_DC06		; save VIA 1 timer B low byte
	STY	LAB_DC07		; save VIA 1 timer B high byte
	LDA	#$19			; load timer B, timer B single shot, start timer B
	STA	LAB_DC0F		; save VIA 1 CRB
	LDA	LAB_DC0D		; read VIA 1 ICR
	STA	LAB_02A3		; save VIA 1 ICR shadow copy
	TYA				; y = $FF
	SBC	LAB_B1		; subtract tape timing constant max byte
					; A = $FF - T2C_h
	STX	LAB_B1		; save tape timing constant max byte
					; LAB_B1 = $FF - T2C_l
	LSR				;.A = $FF - T2C_h >> 1
	ROR	LAB_B1		; shift tape timing constant max byte
					; LAB_B1 = $FF - T2C_l >> 1
	LSR				;.A = $FF - T2C_h >> 1
	ROR	LAB_B1		; shift tape timing constant max byte
					; LAB_B1 = $FF - T2C_l >> 1
	LDA	LAB_B0		; get tape timing constant min byte
	CLC				; clear carry for add
	ADC	#$3C			;.
	CMP	LAB_B1		; compare with tape timing constant max byte
					; compare with ($FFFF - T2C) >> 2
	BCS	LAB_F9AC		;.branch if min + $3C >= ($FFFF - T2C) >> 2

					;.min + $3C < ($FFFF - T2C) >> 2
	LDX	LAB_9C		;.get byte received flag
	BEQ	LAB_F969		;. if not byte received ??

	JMP	LAB_FA60		;.store the tape character

LAB_F969
	LDX	LAB_A3		;.get EOI flag byte
	BMI	LAB_F988		;.

	LDX	#$00			;.
	ADC	#$30			;.
	ADC	LAB_B0		; add tape timing constant min byte
	CMP	LAB_B1		; compare with tape timing constant max byte
	BCS	LAB_F993		;.

	INX				;.
	ADC	#$26			;.
	ADC	LAB_B0		; add tape timing constant min byte
	CMP	LAB_B1		; compare with tape timing constant max byte
	BCS	LAB_F997		;.

	ADC	#$2C			;.
	ADC	LAB_B0		; add tape timing constant min byte
	CMP	LAB_B1		; compare with tape timing constant max byte
	BCC	LAB_F98B		;.

LAB_F988
	JMP	LAB_FA10		;.

LAB_F98B
	LDA	LAB_B4		; get the bit count
	BEQ	LAB_F9AC		; if all done go ??

	STA	LAB_A8		; save receiver bit count in
	BNE	LAB_F9AC		; branch always

LAB_F993
	INC	LAB_A9		; increment ?? start bit check flag
	BCS	LAB_F999		;.

LAB_F997
	DEC	LAB_A9		; decrement ?? start bit check flag
LAB_F999
	SEC				;.
	SBC	#$13			;.
	SBC	LAB_B1		; subtract tape timing constant max byte
	ADC	LAB_92		; add timing constant for tape
	STA	LAB_92		; save timing constant for tape
	LDA	LAB_A4		;.get tape bit cycle phase
	EOR	#$01			;.
	STA	LAB_A4		;.save tape bit cycle phase
	BEQ	LAB_F9D5		;.

	STX	LAB_D7		;.
LAB_F9AC
	LDA	LAB_B4		; get the bit count
	BEQ	LAB_F9D2		; if all done go ??

	LDA	LAB_02A3		; read VIA 1 ICR shadow copy
	AND	#$01			; mask 0000 000x, timer A interrupt enabled
	BNE	LAB_F9BC		; if timer A is enabled go ??

	LDA	LAB_02A4		; read VIA 1 CRA shadow copy
	BNE	LAB_F9D2		; if ?? just exit

LAB_F9BC
	LDA	#$00			; clear A
	STA	LAB_A4		; clear the tape bit cycle phase
	STA	LAB_02A4		; save VIA 1 CRA shadow copy
	LDA	LAB_A3		;.get EOI flag byte
	BPL	LAB_F9F7		;.

	BMI	LAB_F988		;.

LAB_F9C9
	LDX	#$A6			; set timimg max byte
	JSR	LAB_F8E2		; set timing
	LDA	LAB_9B		;.
	BNE	LAB_F98B		;.

LAB_F9D2
	JMP	LAB_FEBC		; restore registers and exit interrupt

LAB_F9D5
	LDA	LAB_92		; get timing constant for tape
	BEQ	LAB_F9E0		;.

	BMI	LAB_F9DE		;.

	DEC	LAB_B0		; decrement tape timing constant min byte
	.byte	$2C			; makes next line BIT LAB_B0E6
LAB_F9DE
	INC	LAB_B0		; increment tape timing constant min byte
LAB_F9E0
	LDA	#$00			;.
	STA	LAB_92		; clear timing constant for tape
	CPX	LAB_D7		;.
	BNE	LAB_F9F7		;.

	TXA				;.
	BNE	LAB_F98B		;.

	LDA	LAB_A9		; get start bit check flag
	BMI	LAB_F9AC		;.

	CMP	#$10			;.
	BCC	LAB_F9AC		;.

	STA	LAB_96		;.save cassette block synchronization number
	BCS	LAB_F9AC		;.

LAB_F9F7
	TXA				;.
	EOR	LAB_9B		;.
	STA	LAB_9B		;.
	LDA	LAB_B4		;.
	BEQ	LAB_F9D2		;.

	DEC	LAB_A3		;.decrement EOI flag byte
	BMI	LAB_F9C9		;.

	LSR	LAB_D7		;.
	ROR	LAB_BF		;.parity count
	LDX	#$DA			; set timimg max byte
	JSR	LAB_F8E2		; set timing
	JMP	LAB_FEBC		; restore registers and exit interrupt

LAB_FA10
	LDA	LAB_96		;.get cassette block synchronization number
	BEQ	LAB_FA18		;.

	LDA	LAB_B4		;.
	BEQ	LAB_FA1F		;.

LAB_FA18
	LDA	LAB_A3		;.get EOI flag byte
	BMI	LAB_FA1F		;.

	JMP	LAB_F997		;.

LAB_FA1F
	LSR	LAB_B1		; shift tape timing constant max byte
	LDA	#$93			;.
	SEC				;.
	SBC	LAB_B1		; subtract tape timing constant max byte
	ADC	LAB_B0		; add tape timing constant min byte
	ASL				;.
	TAX				; copy timimg high byte
	JSR	LAB_F8E2		; set timing
	INC	LAB_9C		;.
	LDA	LAB_B4		;.
	BNE	LAB_FA44		;.

	LDA	LAB_96		;.get cassette block synchronization number
	BEQ	LAB_FA5D		;.

	STA	LAB_A8		; save receiver bit count in
	LDA	#$00			; clear A
	STA	LAB_96		;.clear cassette block synchronization number
	LDA	#$81			; enable timer A interrupt
	STA	LAB_DC0D		; save VIA 1 ICR
	STA	LAB_B4		;.
LAB_FA44
	LDA	LAB_96		;.get cassette block synchronization number
	STA	LAB_B5		;.
	BEQ	LAB_FA53		;.

	LDA	#$00			;.
	STA	LAB_B4		;.
	LDA	#$01			; disable timer A interrupt
	STA	LAB_DC0D		; save VIA 1 ICR
LAB_FA53
	LDA	LAB_BF		;.parity count
	STA	LAB_BD		;.save RS232 parity byte
	LDA	LAB_A8		; get receiver bit count in
	ORA	LAB_A9		; OR with start bit check flag
	STA	LAB_B6		;.
LAB_FA5D
	JMP	LAB_FEBC		; restore registers and exit interrupt


;************************************************************************************
;
;## store character

LAB_FA60
	JSR	LAB_FB97		; new tape byte setup
	STA	LAB_9C		; clear byte received flag
	LDX	#$DA			; set timimg max byte
	JSR	LAB_F8E2		; set timing
	LDA	LAB_BE		;.get copies count
	BEQ	LAB_FA70		;.

	STA	LAB_A7		; save receiver input bit temporary storage
LAB_FA70
	LDA	#$0F			;.
	BIT	LAB_AA		;.
	BPL	LAB_FA8D		;.

	LDA	LAB_B5		;.
	BNE	LAB_FA86		;.

	LDX	LAB_BE		;.get copies count
	DEX				;.
	BNE	LAB_FA8A		; if ?? restore registers and exit interrupt

	LDA	#$08			; set short block
	JSR	LAB_FE1C		; OR into serial status byte
	BNE	LAB_FA8A		; restore registers and exit interrupt, branch always

LAB_FA86
	LDA	#$00			;.
	STA	LAB_AA		;.
LAB_FA8A
	JMP	LAB_FEBC		; restore registers and exit interrupt

LAB_FA8D
	BVS	LAB_FAC0		;.

	BNE	LAB_FAA9		;.

	LDA	LAB_B5		;.
	BNE	LAB_FA8A		;.

	LDA	LAB_B6		;.
	BNE	LAB_FA8A		;.

	LDA	LAB_A7		; get receiver input bit temporary storage
	LSR				;.
	LDA	LAB_BD		;.get RS232 parity byte
	BMI	LAB_FAA3		;.

	BCC	LAB_FABA		;.

	CLC				;.
LAB_FAA3
	BCS	LAB_FABA		;.

	AND	#$0F			;.
	STA	LAB_AA		;.
LAB_FAA9
	DEC	LAB_AA		;.
	BNE	LAB_FA8A		;.

	LDA	#$40			;.
	STA	LAB_AA		;.
	JSR	LAB_FB8E		; copy I/O start address to buffer address
	LDA	#$00			;.
	STA	LAB_AB		;.
	BEQ	LAB_FA8A		;.

LAB_FABA
	LDA	#$80			;.
	STA	LAB_AA		;.
	BNE	LAB_FA8A		; restore registers and exit interrupt, branch always

LAB_FAC0
	LDA	LAB_B5		;.
	BEQ	LAB_FACE		;.

	LDA	#$04			;.
	JSR	LAB_FE1C		; OR into serial status byte
	LDA	#$00			;.
	JMP	LAB_FB4A		;.

LAB_FACE
	JSR	LAB_FCD1		; check read/write pointer, return Cb = 1 if pointer >= end
	BCC	LAB_FAD6		;.

	JMP	LAB_FB48		;.

LAB_FAD6
	LDX	LAB_A7		; get receiver input bit temporary storage
	DEX				;.
	BEQ	LAB_FB08		;.

	LDA	LAB_93		; get load/verify flag
	BEQ	LAB_FAEB		; if load go ??

	LDY	#$00			; clear index
	LDA	LAB_BD		;.get RS232 parity byte
	CMP	(LAB_AC),Y		;.
	BEQ	LAB_FAEB		;.

	LDA	#$01			;.
	STA	LAB_B6		;.
LAB_FAEB
	LDA	LAB_B6		;.
	BEQ	LAB_FB3A		;.

	LDX	#$3D			;.
	CPX	LAB_9E		;.
	BCC	LAB_FB33		;.

	LDX	LAB_9E		;.
	LDA	LAB_AD		;.
	STA	LAB_0100+1,X	;.
	LDA	LAB_AC		;.
	STA	LAB_0100,X		;.
	INX				;.
	INX				;.
	STX	LAB_9E		;.
	JMP	LAB_FB3A		;.

LAB_FB08
	LDX	LAB_9F		;.
	CPX	LAB_9E		;.
	BEQ	LAB_FB43		;.
	LDA	LAB_AC		;.
	CMP	LAB_0100,X		;.
	BNE	LAB_FB43		;.
	LDA	LAB_AD		;.
	CMP	LAB_0100+1,X	;.
	BNE	LAB_FB43		;.
	INC	LAB_9F		;.
	INC	LAB_9F		;.
	LDA	LAB_93		; get load/verify flag
	BEQ	LAB_FB2F		; if load ??

	LDA	LAB_BD		;.get RS232 parity byte
	LDY	#$00			;.
	CMP	(LAB_AC),Y		;.
	BEQ	LAB_FB43		;.

	INY				;.
	STY	LAB_B6		;.
LAB_FB2F
	LDA	LAB_B6		;.
	BEQ	LAB_FB3A		;.
LAB_FB33
	LDA	#$10			;.
	JSR	LAB_FE1C		; OR into serial status byte
	BNE	LAB_FB43		;.

LAB_FB3A
	LDA	LAB_93		; get load/verify flag
	BNE	LAB_FB43		; if verify go ??

	TAY				;.
	LDA	LAB_BD		;.get RS232 parity byte
	STA	(LAB_AC),Y		;.
LAB_FB43
	JSR	LAB_FCDB		; increment read/write pointer
	BNE	LAB_FB8B		; restore registers and exit interrupt, branch always

LAB_FB48
	LDA	#$80			;.
LAB_FB4A
	STA	LAB_AA		;.
	SEI				;.
	LDX	#$01			; disable timer A interrupt
	STX	LAB_DC0D		; save VIA 1 ICR
	LDX	LAB_DC0D		; read VIA 1 ICR
	LDX	LAB_BE		;.get copies count
	DEX				;.
	BMI	LAB_FB5C		;.

	STX	LAB_BE		;.save copies count
LAB_FB5C
	DEC	LAB_A7		; decrement receiver input bit temporary storage
	BEQ	LAB_FB68		;.

	LDA	LAB_9E		;.
	BNE	LAB_FB8B		; if ?? restore registers and exit interrupt

	STA	LAB_BE		;.save copies count
	BEQ	LAB_FB8B		; restore registers and exit interrupt, branch always

LAB_FB68
	JSR	LAB_FC93		; restore everything for STOP
	JSR	LAB_FB8E		; copy I/O start address to buffer address
	LDY	#$00			; clear index
	STY	LAB_AB		; clear checksum
LAB_FB72
	LDA	(LAB_AC),Y		; get byte from buffer
	EOR	LAB_AB		; XOR with checksum
	STA	LAB_AB		; save new checksum
	JSR	LAB_FCDB		; increment read/write pointer
	JSR	LAB_FCD1		; check read/write pointer, return Cb = 1 if pointer >= end
	BCC	LAB_FB72		; loop if not at end

	LDA	LAB_AB		; get computed checksum
	EOR	LAB_BD		; compare with stored checksum ??
	BEQ	LAB_FB8B		; if checksum ok restore registers and exit interrupt

	LDA	#$20			; else set checksum error
	JSR	LAB_FE1C		; OR into the serial status byte
LAB_FB8B
	JMP	LAB_FEBC		; restore registers and exit interrupt


;************************************************************************************
;
; copy I/O start address to buffer address

LAB_FB8E
	LDA	LAB_C2		; get I/O start address high byte
	STA	LAB_AD		; set buffer address high byte
	LDA	LAB_C1		; get I/O start address low byte
	STA	LAB_AC		; set buffer address low byte
	RTS


;************************************************************************************
;
; new tape byte setup

LAB_FB97
	LDA	#$08			; eight bits to do
	STA	LAB_A3		; set bit count
	LDA	#$00			; clear A
	STA	LAB_A4		; clear tape bit cycle phase
	STA	LAB_A8		; clear start bit first cycle done flag
	STA	LAB_9B		; clear byte parity
	STA	LAB_A9		; clear start bit check flag, set no start bit yet
	RTS


;************************************************************************************
;
; send lsb from tape write byte to tape

; this routine tests the least significant bit in the tape write byte and sets VIA 2 T2
; depending on the state of the bit. if the bit is a 1 a time of $00B0 cycles is set, if
; the bot is a 0 a time of $0060 cycles is set. note that this routine does not shift the
; bits of the tape write byte but uses a copy of that byte, the byte itself is shifted
; elsewhere

LAB_FBA6
	LDA	LAB_BD		; get tape write byte
	LSR				; shift lsb into Cb
	LDA	#$60			; set time constant low byte for bit = 0
	BCC	LAB_FBAF		; branch if bit was 0

; set time constant for bit = 1 and toggle tape

LAB_FBAD
	LDA	#$B0			; set time constant low byte for bit = 1

; write time constant and toggle tape

LAB_FBAF
	LDX	#$00			; set time constant high byte

; write time constant and toggle tape

LAB_FBB1
	STA	LAB_DC06		; save VIA 1 timer B low byte
	STX	LAB_DC07		; save VIA 1 timer B high byte
	LDA	LAB_DC0D		; read VIA 1 ICR
	LDA	#$19			; load timer B, timer B single shot, start timer B
	STA	LAB_DC0F		; save VIA 1 CRB
	LDA	LAB_01		; read the 6510 I/O port
	EOR	#$08			; toggle tape out bit
	STA	LAB_01		; save the 6510 I/O port
	AND	#$08			; mask tape out bit
	RTS


;************************************************************************************
;
; flag block done and exit interrupt

LAB_FBC8
	SEC				; set carry flag
	ROR	LAB_B6		; set buffer address high byte negative, flag all sync,
					; data and checksum bytes written
	BMI	LAB_FC09		; restore registers and exit interrupt, branch always


;************************************************************************************
;
; tape write IRQ routine

; this is the routine that writes the bits to the tape. it is called each time VIA 2 T2
; times out and checks if the start bit is done, if so checks if the data bits are done,
; if so it checks if the byte is done, if so it checks if the synchronisation bytes are
; done, if so it checks if the data bytes are done, if so it checks if the checksum byte
; is done, if so it checks if both the load and verify copies have been done, if so it
; stops the tape

LAB_FBCD
	LDA	LAB_A8		; get start bit first cycle done flag
	BNE	LAB_FBE3		; if first cycle done go do rest of byte

; each byte sent starts with two half cycles of $0110 ststem clocks and the whole block
; ends with two more such half cycles

	LDA	#$10			; set first start cycle time constant low byte
	LDX	#$01			; set first start cycle time constant high byte
	JSR	LAB_FBB1		; write time constant and toggle tape
	BNE	LAB_FC09		; if first half cycle go restore registers and exit
					; interrupt

	INC	LAB_A8		; set start bit first start cycle done flag
	LDA	LAB_B6		; get buffer address high byte
	BPL	LAB_FC09		; if block not complete go restore registers and exit
					; interrupt. the end of a block is indicated by the tape
					; buffer high byte b7 being set to 1

	JMP	LAB_FC57		; else do tape routine, block complete exit

; continue tape byte write. the first start cycle, both half cycles of it, is complete
; so the routine drops straight through to here

LAB_FBE3
	LDA	LAB_A9		; get start bit check flag
	BNE	LAB_FBF0		; if the start bit is complete go send the byte bits

; after the two half cycles of $0110 ststem clocks the start bit is completed with two
; half cycles of $00B0 system clocks. this is the same as the first part of a 1 bit

	JSR	LAB_FBAD		; set time constant for bit = 1 and toggle tape
	BNE	LAB_FC09		; if first half cycle go restore registers and exit
					; interrupt

	INC	LAB_A9		; set start bit check flag
	BNE	LAB_FC09		; restore registers and exit interrupt, branch always

; continue tape byte write. the start bit, both cycles of it, is complete so the routine
; drops straight through to here. now the cycle pairs for each bit, and the parity bit,
; are sent

LAB_FBF0
	JSR	LAB_FBA6		; send lsb from tape write byte to tape
	BNE	LAB_FC09		; if first half cycle go restore registers and exit
					; interrupt

					; else two half cycles have been done
	LDA	LAB_A4		; get tape bit cycle phase
	EOR	#$01			; toggle b0
	STA	LAB_A4		; save tape bit cycle phase
	BEQ	LAB_FC0C		; if bit cycle phase complete go setup for next bit

; each bit is written as two full cycles. a 1 is sent as a full cycle of $0160 system
; clocks then a full cycle of $00C0 system clocks. a 0 is sent as a full cycle of $00C0
; system clocks then a full cycle of $0160 system clocks. to do this each bit from the
; write byte is inverted during the second bit cycle phase. as the bit is inverted it
; is also added to the, one bit, parity count for this byte

	LDA	LAB_BD		; get tape write byte
	EOR	#$01			; invert bit being sent
	STA	LAB_BD		; save tape write byte
	AND	#$01			; mask b0
	EOR	LAB_9B		; EOR with tape write byte parity bit
	STA	LAB_9B		; save tape write byte parity bit
LAB_FC09
	JMP	LAB_FEBC		; restore registers and exit interrupt

; the bit cycle phase is complete so shift out the just written bit and test for byte
; end

LAB_FC0C
	LSR	LAB_BD		; shift bit out of tape write byte
	DEC	LAB_A3		; decrement tape write bit count
	LDA	LAB_A3		; get tape write bit count
	BEQ	LAB_FC4E		; if all the data bits have been written go setup for
					; sending the parity bit next and exit the interrupt

	BPL	LAB_FC09		; if all the data bits are not yet sent just restore the
					; registers and exit the interrupt

; do next tape byte

; the byte is complete. the start bit, data bits and parity bit have been written to
; the tape so setup for the next byte

LAB_FC16
	JSR	LAB_FB97		; new tape byte setup
	CLI				; enable the interrupts
	LDA	LAB_A5		; get cassette synchronization character count
	BEQ	LAB_FC30		; if synchronisation characters done go do block data

; at the start of each block sent to tape there are a number of synchronisation bytes
; that count down to the actual data. the commodore tape system saves two copies of all
; the tape data, the first is loaded and is indicated by the synchronisation bytes
; having b7 set, and the second copy is indicated by the synchronisation bytes having b7
; clear. the sequence goes $09, $08, ..... $02, $01, data bytes

	LDX	#$00			; clear X
	STX	LAB_D7		; clear checksum byte
	DEC	LAB_A5		; decrement cassette synchronization byte count
	LDX	LAB_BE		; get cassette copies count
	CPX	#$02			; compare with load block indicator
	BNE	LAB_FC2C		; branch if not the load block

	ORA	#$80			; this is the load block so make the synchronisation count
					; go $89, $88, ..... $82, $81
LAB_FC2C
	STA	LAB_BD		; save the synchronisation byte as the tape write byte
	BNE	LAB_FC09		; restore registers and exit interrupt, branch always

; the synchronization bytes have been done so now check and do the actual block data

LAB_FC30
	JSR	LAB_FCD1		; check read/write pointer, return Cb = 1 if pointer >= end
	BCC	LAB_FC3F		; if not all done yet go get the byte to send

	BNE	LAB_FBC8		; if pointer > end go flag block done and exit interrupt

					; else the block is complete, it only remains to write the
					; checksum byte to the tape so setup for that
	INC	LAB_AD		; increment buffer pointer high byte, this means the block
					; done branch will always be taken next time without having
					; to worry about the low byte wrapping to zero
	LDA	LAB_D7		; get checksum byte
	STA	LAB_BD		; save checksum as tape write byte
	BCS	LAB_FC09		; restore registers and exit interrupt, branch always

; the block isn't finished so get the next byte to write to tape

LAB_FC3F
	LDY	#$00			; clear index
	LDA	(LAB_AC),Y		; get byte from buffer
	STA	LAB_BD		; save as tape write byte
	EOR	LAB_D7		; XOR with checksum byte
	STA	LAB_D7		; save new checksum byte
	JSR	LAB_FCDB		; increment read/write pointer
	BNE	LAB_FC09		; restore registers and exit interrupt, branch always

; set parity as next bit and exit interrupt

LAB_FC4E
	LDA	LAB_9B		; get parity bit
	EOR	#$01			; toggle it
	STA	LAB_BD		; save as tape write byte
LAB_FC54
	JMP	LAB_FEBC		; restore registers and exit interrupt

; tape routine, block complete exit

LAB_FC57
	DEC	LAB_BE		; decrement copies remaining to read/write
	BNE	LAB_FC5E		; branch if more to do

	JSR	LAB_FCCA		; stop the cassette motor
LAB_FC5E
	LDA	#$50			; set tape write leader count
	STA	LAB_A7		; save tape write leader count
	LDX	#$08			; set index for write tape leader vector
	SEI				; disable the interrupts
	JSR	LAB_FCBD		; set the tape vector
	BNE	LAB_FC54		; restore registers and exit interrupt, branch always


;************************************************************************************
;
; write tape leader IRQ routine

LAB_FC6A
	LDA	#$78			; set time constant low byte for bit = leader
	JSR	LAB_FBAF		; write time constant and toggle tape
	BNE	LAB_FC54		; if tape bit high restore registers and exit interrupt

	DEC	LAB_A7		; decrement cycle count
	BNE	LAB_FC54		; if not all done restore registers and exit interrupt

	JSR	LAB_FB97		; new tape byte setup
	DEC	LAB_AB		; decrement cassette leader count
	BPL	LAB_FC54		; if not all done restore registers and exit interrupt

	LDX	#$0A			; set index for tape write vector
	JSR	LAB_FCBD		; set the tape vector
	CLI				; enable the interrupts
	INC	LAB_AB		; clear cassette leader counter, was $FF
	LDA	LAB_BE		; get cassette block count
	BEQ	LAB_FCB8		; if all done restore everything for STOP and exit the
					; interrupt

	JSR	LAB_FB8E		; copy I/O start address to buffer address
	LDX	#$09			; set nine synchronisation bytes
	STX	LAB_A5		; save cassette synchronization byte count
	STX	LAB_B6		;.
	BNE	LAB_FC16		; go do the next tape byte, branch always


;************************************************************************************
;
; restore everything for STOP

LAB_FC93
	PHP				; save status
	SEI				; disable the interrupts
	LDA	LAB_D011		; read the vertical fine scroll and control register
	ORA	#$10			; mask xxx1 xxxx, unblank the screen
	STA	LAB_D011		; save the vertical fine scroll and control register
	JSR	LAB_FCCA		; stop the cassette motor
	LDA	#$7F			; disable all interrupts
	STA	LAB_DC0D		; save VIA 1 ICR
	JSR	LAB_FDDD		;.
	LDA	LAB_02A0		; get saved IRQ vector high byte
	BEQ	LAB_FCB6		; branch if null

	STA	LAB_0315		; restore IRQ vector high byte
	LDA	LAB_029F		; get saved IRQ vector low byte
	STA	LAB_0314		; restore IRQ vector low byte
LAB_FCB6
	PLP				; restore status
	RTS


;************************************************************************************
;
; reset vector

LAB_FCB8
	JSR	LAB_FC93		; restore everything for STOP
	BEQ	LAB_FC54		; restore registers and exit interrupt, branch always


;************************************************************************************
;
; set tape vector

LAB_FCBD
	LDA	LAB_FD9B-8,X	; get tape IRQ vector low byte
	STA	LAB_0314		; set IRQ vector low byte
	LDA	LAB_FD9B-7,X	; get tape IRQ vector high byte
	STA	LAB_0315		; set IRQ vector high byte
	RTS


;************************************************************************************
;
; stop the cassette motor

LAB_FCCA
	LDA	LAB_01		; read the 6510 I/O port
	ORA	#$20			; mask xxxx xx1x, turn the cassette motor off
	STA	LAB_01		; save the 6510 I/O port
	RTS


;************************************************************************************
;
; check read/write pointer
; return Cb = 1 if pointer >= end

LAB_FCD1
	SEC				; set carry for subtract
	LDA	LAB_AC		; get buffer address low byte
	SBC	LAB_AE		; subtract buffer end low byte
	LDA	LAB_AD		; get buffer address high byte
	SBC	LAB_AF		; subtract buffer end high byte
	RTS


;************************************************************************************
;
; increment read/write pointer

LAB_FCDB
	INC	LAB_AC		; increment buffer address low byte
	BNE	LAB_FCE1		; branch if no overflow

	INC	LAB_AD		; increment buffer address low byte
LAB_FCE1
	RTS


;************************************************************************************
;
; RESET, hardware reset starts here

LAB_FCE2
	LDX	#$FF			; set X for stack
	SEI				; disable the interrupts
	TXS				; clear stack
	CLD				; clear decimal mode
	JSR	LAB_FD02		; scan for autostart ROM at $8000
	BNE	LAB_FCEF		; if not there continue startup

	JMP	(LAB_8000)		; else call ROM start code

LAB_FCEF
	STX	LAB_D016		; read the horizontal fine scroll and control register
	JSR	LAB_FDA3		; initialise SID, CIA and IRQ
	JSR	LAB_FD50		; RAM test and find RAM end
	JSR	LAB_FD15		; restore default I/O vectors
	JSR	LAB_FF5B		; initialise VIC and screen editor
	CLI				; enable the interrupts
	JMP	(LAB_A000)		; execute BASIC


;************************************************************************************
;
; scan for autostart ROM at $8000, returns Zb=1 if ROM found

LAB_FD02
	LDX	#$05			; five characters to test
LAB_FD04
	LDA	LAB_FD10-1,X	; get test character
	CMP	LAB_8004-1,X	; compare wiith byte in ROM space
	BNE	LAB_FD0F		; exit if no match

	DEX				; decrement index
	BNE	LAB_FD04		; loop if not all done

LAB_FD0F
	RTS

; autostart ROM signature

LAB_FD10
	.byte	$C3,$C2,$CD,$38,$30
					; CBM80


;************************************************************************************
;
; restore default I/O vectors

LAB_FD15
	LDX	#<LAB_FD30		; pointer to vector table low byte
	LDY	#>LAB_FD30		; pointer to vector table high byte
	CLC				; flag set vectors


;************************************************************************************
;
; set/read vectored I/O from (XY), Cb = 1 to read, Cb = 0 to set

LAB_FD1A
	STX	LAB_C3		; save pointer low byte
	STY	LAB_C4		; save pointer high byte
	LDY	#$1F			; set byte count
LAB_FD20
	LDA	LAB_0314,Y		; read vector byte from vectors
	BCS	LAB_FD27		; branch if read vectors

	LDA	(LAB_C3),Y		; read vector byte from (XY)
LAB_FD27
	STA	(LAB_C3),Y		; save byte to (XY)
	STA	LAB_0314,Y		; save byte to vector
	DEY				; decrement index
	BPL	LAB_FD20		; loop if more to do

	RTS

;; The above code works but it tries to write to the ROM. while this is usually harmless
;; systems that use flash ROM may suffer. Here is a version that makes the extra write
;; to RAM instead but is otherwise identical in function. ##
;
;; set/read vectored I/O from (XY), Cb = 1 to read, Cb = 0 to set
;
;LAB_FD1A
;	STX	LAB_C3		; save pointer low byte
;	STY	LAB_C4		; save pointer high byte
;	LDY	#$1F			; set byte count
;LAB_FD20
;	LDA	(LAB_C3),Y		; read vector byte from (XY)
;	BCC	LAB_FD29		; branch if set vectors
;
;	LDA	LAB_0314,Y		; else read vector byte from vectors
;	STA	(LAB_C3),Y		; save byte to (XY)
;LAB_FD29
;	STA	LAB_0314,Y		; save byte to vector
;	DEY				; decrement index
;	BPL	LAB_FD20		; loop if more to do
;
;	RTS


;************************************************************************************
;
; kernal vectors

LAB_FD30
	.word	LAB_EA31		; LAB_0314	IRQ vector
	.word	LAB_FE66		; LAB_0316	BRK vector
	.word	LAB_FE47		; LAB_0318	NMI vector
	.word	LAB_F34A		; LAB_031A	open a logical file
	.word	LAB_F291		; LAB_031C	close a specified logical file
	.word	LAB_F20E		; LAB_031E	open channel for input
	.word	LAB_F250		; LAB_0320	open channel for output
	.word	LAB_F333		; LAB_0322	close input and output channels
	.word	LAB_F157		; LAB_0324	input character from channel
	.word	LAB_F1CA		; LAB_0326	output character to channel
	.word	LAB_F6ED		; LAB_0328	scan stop key
	.word	LAB_F13E		; LAB_032A	get character from the input device
	.word	LAB_F32F		; LAB_032C	close all channels and files
	.word	LAB_FE66		; LAB_032E	user function

; Vector to user defined command, currently points to BRK.

; This appears to be a holdover from PET days, when the built-in machine language monitor
; would jump through the LAB_032E vector when it encountered a command that it did not
; understand, allowing the user to add new commands to the monitor.

; Although this vector is initialized to point to the routine called by STOP/RESTORE and
; the BRK interrupt, and is updated by the kernal vector routine at $FD57, it no longer
; has any function.

	.word	LAB_F4A5		; LAB_0330	load
	.word	LAB_F5ED		; LAB_0332	save


;************************************************************************************
;
; test RAM and find RAM end

LAB_FD50
	LDA	#$00			; clear A
	TAY				; clear index
LAB_FD53
	STA	LAB_00+2,Y		; clear page 0, don't do $0000 or $0001
	STA	LAB_0200,Y		; clear page 2
	STA	LAB_0300,Y		; clear page 3
	INY				; increment index
	BNE	LAB_FD53		; loop if more to do

	LDX	#<LAB_033C		; set cassette buffer pointer low byte
	LDY	#>LAB_033C		; set cassette buffer pointer high byte
	STX	LAB_B2		; save tape buffer start pointer low byte
	STY	LAB_B3		; save tape buffer start pointer high byte
	TAY				; clear Y
	LDA	#$03			; set RAM test pointer high byte
	STA	LAB_C2		; save RAM test pointer high byte
LAB_FD6C
	INC	LAB_C2		; increment RAM test pointer high byte
LAB_FD6E
	LDA	(LAB_C1),Y		;.
	TAX				;.
	LDA	#$55			;.
	STA	(LAB_C1),Y		;.
	CMP	(LAB_C1),Y		;.
	BNE	LAB_FD88		;.
	ROL				;.
	STA	(LAB_C1),Y		;.
	CMP	(LAB_C1),Y		;.
	BNE	LAB_FD88		;.
	TXA				;.
	STA	(LAB_C1),Y		;.
	INY				;.
	BNE	LAB_FD6E		;.
	BEQ	LAB_FD6C		;.
LAB_FD88
	TYA				;.
	TAX				;.
	LDY	LAB_C2		;.
	CLC				;.
	JSR	LAB_FE2D		; set the top of memory
	LDA	#$08			;.
	STA	LAB_0282		; save the OS start of memory high byte
	LDA	#$04			;.
	STA	LAB_0288		; save the screen memory page
	RTS


;************************************************************************************
;
; tape IRQ vectors

LAB_FD9B
	.word	LAB_FC6A		; $08	write tape leader IRQ routine
	.word	LAB_FBCD		; $0A	tape write IRQ routine
	.word	LAB_EA31		; $0C	normal IRQ vector
	.word	LAB_F92C		; $0E	read tape bits IRQ routine


;************************************************************************************
;
; initialise SID, CIA and IRQ

LAB_FDA3
	LDA	#$7F			; disable all interrupts
	STA	LAB_DC0D		; save VIA 1 ICR
	STA	LAB_DD0D		; save VIA 2 ICR
	STA	LAB_DC00		; save VIA 1 DRA, keyboard column drive
	LDA	#$08			; set timer single shot
	STA	LAB_DC0E		; save VIA 1 CRA
	STA	LAB_DD0E		; save VIA 2 CRA
	STA	LAB_DC0F		; save VIA 1 CRB
	STA	LAB_DD0F		; save VIA 2 CRB
	LDX	#$00			; set all inputs
	STX	LAB_DC03		; save VIA 1 DDRB, keyboard row
	STX	LAB_DD03		; save VIA 2 DDRB, RS232 port
	STX	LAB_D418		; clear the volume and filter select register
	DEX				; set X = $FF
	STX	LAB_DC02		; save VIA 1 DDRA, keyboard column
	LDA	#$07			; DATA out high, CLK out high, ATN out high, RE232 Tx DATA
					; high, video address 15 = 1,	video address 14 = 1
	STA	LAB_DD00		; save VIA 2 DRA, serial port and video address
	LDA	#$3F			; set serial DATA input, serial CLK input
	STA	LAB_DD02		; save VIA 2 DDRA, serial port and video address
	LDA	#$E7			; set 1110 0111, motor off, enable I/O, enable KERNAL,
					; enable BASIC
	STA	LAB_01		; save the 6510 I/O port
	LDA	#$2F			; set 0010 1111, 0 = input, 1 = output
	STA	LAB_00		; save the 6510 I/O port direction register
LAB_FDDD
	LDA	LAB_02A6		; get the PAL/NTSC flag
	BEQ	LAB_FDEC		; if NTSC go set NTSC timing

					; else set PAL timing
	LDA	#$25			;.
	STA	LAB_DC04		; save VIA 1 timer A low byte
	LDA	#$40			;.
	JMP	LAB_FDF3		;.

LAB_FDEC
	LDA	#$95			;.
	STA	LAB_DC04		; save VIA 1 timer A low byte
	LDA	#$42			;.
LAB_FDF3
	STA	LAB_DC05		; save VIA 1 timer A high byte
	JMP	LAB_FF6E		;.


;************************************************************************************
;
; set filename

LAB_FDF9
	STA	LAB_B7		; set file name length
	STX	LAB_BB		; set file name pointer low byte
	STY	LAB_BC		; set file name pointer high byte
	RTS


;************************************************************************************
;
; set logical, first and second addresses

LAB_FE00
	STA	LAB_B8		; save the logical file
	STX	LAB_BA		; save the device number
	STY	LAB_B9		; save the secondary address
	RTS


;************************************************************************************
;
; read I/O status word

LAB_FE07
	LDA	LAB_BA		; get the device number
	CMP	#$02			; compare device with RS232 device
	BNE	LAB_FE1A		; if not RS232 device go ??

					; get RS232 device status
	LDA	LAB_0297		; get the RS232 status register
	PHA				; save the RS232 status value
	LDA	#$00			; clear A
	STA	LAB_0297		; clear the RS232 status register
	PLA				; restore the RS232 status value
	RTS


;************************************************************************************
;
; control kernal messages

LAB_FE18
	STA	LAB_9D		; set message mode flag
LAB_FE1A
	LDA	LAB_90		; read the serial status byte


;************************************************************************************
;
; OR into the serial status byte

LAB_FE1C
	ORA	LAB_90		; OR with the serial status byte
	STA	LAB_90		; save the serial status byte
	RTS


;************************************************************************************
;
; set timeout on serial bus

LAB_FE21
	STA	LAB_0285		; save serial bus timeout flag
	RTS


;************************************************************************************
;
; read/set the top of memory, Cb = 1 to read, Cb = 0 to set

LAB_FE25
	BCC	LAB_FE2D		; if Cb clear go set the top of memory


;************************************************************************************
;
; read the top of memory

LAB_FE27
	LDX	LAB_0283		; get memory top low byte
	LDY	LAB_0284		; get memory top high byte


;************************************************************************************
;
; set the top of memory

LAB_FE2D
	STX	LAB_0283		; set memory top low byte
	STY	LAB_0284		; set memory top high byte
	RTS


;************************************************************************************
;
; read/set the bottom of memory, Cb = 1 to read, Cb = 0 to set

LAB_FE34
	BCC	LAB_FE3C		; if Cb clear go set the bottom of memory

	LDX	LAB_0281		; get the OS start of memory low byte
	LDY	LAB_0282		; get the OS start of memory high byte
LAB_FE3C
	STX	LAB_0281		; save the OS start of memory low byte
	STY	LAB_0282		; save the OS start of memory high byte
	RTS


;************************************************************************************
;
; NMI vector

LAB_FE43
	SEI				; disable the interrupts
	JMP	(LAB_0318)		; do NMI vector


;************************************************************************************
;
; NMI handler

LAB_FE47
	PHA				; save A
	TXA				; copy X
	PHA				; save X
	TYA				; copy Y
	PHA				; save Y
	LDA	#$7F			; disable all interrupts
	STA	LAB_DD0D		; save VIA 2 ICR
	LDY	LAB_DD0D		; save VIA 2 ICR
	BMI	LAB_FE72		;.

	JSR	LAB_FD02		; scan for autostart ROM at $8000
	BNE	LAB_FE5E		; branch if no autostart ROM

	JMP	(LAB_8002)		; else do autostart ROM break entry

LAB_FE5E
	JSR	LAB_F6BC		; increment real time clock
	JSR	LAB_FFE1		; scan stop key
	BNE	LAB_FE72		; if not [STOP] restore registers and exit interrupt


;************************************************************************************
;
; user function default vector
; BRK handler

LAB_FE66
	JSR	LAB_FD15		; restore default I/O vectors
	JSR	LAB_FDA3		; initialise SID, CIA and IRQ
	JSR	LAB_E518		; initialise the screen and keyboard
	JMP	(LAB_A002)		; do BASIC break entry


;************************************************************************************
;
; RS232 NMI routine

LAB_FE72
	TYA				;.
	AND	LAB_02A1		; AND with the RS-232 interrupt enable byte
	TAX				;.
	AND	#$01			;.
	BEQ	LAB_FEA3		;.

	LDA	LAB_DD00		; read VIA 2 DRA, serial port and video address
	AND	#$FB			; mask xxxx x0xx, clear RS232 Tx DATA
	ORA	LAB_B5		; OR in the RS232 transmit data bit
	STA	LAB_DD00		; save VIA 2 DRA, serial port and video address
	LDA	LAB_02A1		; get the RS-232 interrupt enable byte
	STA	LAB_DD0D		; save VIA 2 ICR
	TXA				;.
	AND	#$12			;.
	BEQ	LAB_FE9D		;.

	AND	#$02			;.
	BEQ	LAB_FE9A		;.
	JSR	LAB_FED6		;.
	JMP	LAB_FE9D		;.
LAB_FE9A
	JSR	LAB_FF07		;.
LAB_FE9D
	JSR	LAB_EEBB		;.
	JMP	LAB_FEB6		;.
LAB_FEA3
	TXA				; get active interrupts back
	AND	#$02			; mask ?? interrupt
	BEQ	LAB_FEAE		; branch if not ?? interrupt

					; was ?? interrupt
	JSR	LAB_FED6		;.
	JMP	LAB_FEB6		;.
LAB_FEAE
	TXA				; get active interrupts back
	AND	#$10			; mask CB1 interrupt, Rx data bit transition
	BEQ	LAB_FEB6		; if no bit restore registers and exit interrupt

	JSR	LAB_FF07		;.
LAB_FEB6
	LDA	LAB_02A1		; get the RS-232 interrupt enable byte
	STA	LAB_DD0D		; save VIA 2 ICR
LAB_FEBC
	PLA				; pull Y
	TAY				; restore Y
	PLA				; pull X
	TAX				; restore X
	PLA				; restore A
	RTI


;************************************************************************************
;
; baud rate word is calculated from ..
;
; (system clock / baud rate) / 2 - 100
;
;		system clock
;		------------
; PAL		  985248 Hz
; NTSC	 1022727 Hz

; baud rate tables for NTSC C64

LAB_FEC2
	.word	$27C1			;   50   baud	1027700
	.word	$1A3E			;   75   baud	1022700
	.word	$11C5			;  110   baud	1022780
	.word	$0E74			;  134.5 baud	1022200
	.word	$0CED			;  150   baud	1022700
	.word	$0645			;  300   baud	1023000
	.word	$02F0			;  600   baud	1022400
	.word	$0146			; 1200   baud	1022400
	.word	$00B8			; 1800   baud	1022400
	.word	$0071			; 2400   baud	1022400


;************************************************************************************
;
; ??

LAB_FED6
	LDA	LAB_DD01		; read VIA 2 DRB, RS232 port
	AND	#$01			; mask 0000 000x, RS232 Rx DATA
	STA	LAB_A7		; save the RS232 received data bit
	LDA	LAB_DD06		; get VIA 2 timer B low byte
	SBC	#$1C			;.
	ADC	LAB_0299		;.
	STA	LAB_DD06		; save VIA 2 timer B low byte
	LDA	LAB_DD07		; get VIA 2 timer B high byte
	ADC	LAB_029A		;.
	STA	LAB_DD07		; save VIA 2 timer B high byte
	LDA	#$11			; set timer B single shot, start timer B
	STA	LAB_DD0F		; save VIA 2 CRB
	LDA	LAB_02A1		; get the RS-232 interrupt enable byte
	STA	LAB_DD0D		; save VIA 2 ICR
	LDA	#$FF			;.
	STA	LAB_DD06		; save VIA 2 timer B low byte
	STA	LAB_DD07		; save VIA 2 timer B high byte
	JMP	LAB_EF59		;.
LAB_FF07
	LDA	LAB_0295		; nonstandard bit timing low byte
	STA	LAB_DD06		; save VIA 2 timer B low byte
	LDA	LAB_0296		; nonstandard bit timing high byte
	STA	LAB_DD07		; save VIA 2 timer B high byte
	LDA	#$11			; set timer B single shot, start timer B
	STA	LAB_DD0F		; save VIA 2 CRB
	LDA	#$12			;.
	EOR	LAB_02A1		; EOR with the RS-232 interrupt enable byte
	STA	LAB_02A1		; save the RS-232 interrupt enable byte
	LDA	#$FF			;.
	STA	LAB_DD06		; save VIA 2 timer B low byte
	STA	LAB_DD07		; save VIA 2 timer B high byte
	LDX	LAB_0298		;.
	STX	LAB_A8		;.
	RTS


;************************************************************************************
;
; ??

LAB_FF2E
	TAX				;.
	LDA	LAB_0296		; nonstandard bit timing high byte
	ROL				;.
	TAY				;.
	TXA				;.
	ADC	#$C8			;.
	STA	LAB_0299		;.
	TYA				;.
	ADC	#$00			; add any carry
	STA	LAB_029A		;.
	RTS


;************************************************************************************
;
; unused bytes

;LAB_FF41
	NOP				; waste cycles
	NOP				; waste cycles


;************************************************************************************
;
; save the status and do the IRQ routine

LAB_FF43
	PHP				; save the processor status
	PLA				; pull the processor status
	AND	#$EF			; mask xxx0 xxxx, clear the break bit
	PHA				; save the modified processor status


;************************************************************************************
;
; IRQ vector

LAB_FF48
	PHA				; save A
	TXA				; copy X
	PHA				; save X
	TYA				; copy Y
	PHA				; save Y
	TSX				; copy stack pointer
	LDA	LAB_0100+4,X	; get stacked status register
	AND	#$10			; mask BRK flag
	BEQ	LAB_FF58		; branch if not BRK

	JMP	(LAB_0316)		; else do BRK vector (iBRK)

LAB_FF58
	JMP	(LAB_0314)		; do IRQ vector (iIRQ)


;************************************************************************************
;
; initialise VIC and screen editor

LAB_FF5B
	JSR	LAB_E518		; initialise the screen and keyboard
LAB_FF5E
	LDA	LAB_D012		; read the raster compare register
	BNE	LAB_FF5E		; loop if not raster line $00

	LDA	LAB_D019		; read the vic interrupt flag register
	AND	#$01			; mask the raster compare flag
	STA	LAB_02A6		; save the PAL/NTSC flag
	JMP	LAB_FDDD		;.


;************************************************************************************
;
; ??

LAB_FF6E
	LDA	#$81			; enable timer A interrupt
	STA	LAB_DC0D		; save VIA 1 ICR
	LDA	LAB_DC0E		; read VIA 1 CRA
	AND	#$80			; mask x000 0000, TOD clock
	ORA	#$11			; mask xxx1 xxx1, load timer A, start timer A
	STA	LAB_DC0E		; save VIA 1 CRA
	JMP	LAB_EE8E		; set the serial clock out low and return


;************************************************************************************
;
; unused

;LAB_FF80
	.byte	$03			;.


;************************************************************************************
;
; initialise VIC and screen editor

;LAB_FF81
	JMP	LAB_FF5B		; initialise VIC and screen editor


;************************************************************************************
;
; initialise SID, CIA and IRQ, unused

;LAB_FF84
	JMP	LAB_FDA3		; initialise SID, CIA and IRQ


;************************************************************************************
;
; RAM test and find RAM end

;LAB_FF87
	JMP	LAB_FD50		; RAM test and find RAM end


;************************************************************************************
;
; restore default I/O vectors

; this routine restores the default values of all system vectors used in KERNAL and
; BASIC routines and interrupts.

;LAB_FF8A
	JMP	LAB_FD15		; restore default I/O vectors


;************************************************************************************
;
; read/set vectored I/O

; this routine manages all system vector jump addresses stored in RAM. Calling this
; routine with the carry bit set will store the current contents of the RAM vectors
; in a list pointed to by the X and Y registers. When this routine is called with
; the carry bit clear, the user list pointed to by the X and Y registers is copied
; to the system RAM vectors.

; NOTE: This routine requires caution in its use. The best way to use it is to first
; read the entire vector contents into the user area, alter the desired vectors and
; then copy the contents back to the system vectors.

;LAB_FF8D
	JMP	LAB_FD1A		; read/set vectored I/O


;************************************************************************************
;
; control kernal messages

; this routine controls the printing of error and control messages by the KERNAL.
; Either print error messages or print control messages can be selected by setting
; the accumulator when the routine is called.

; FILE NOT FOUND is an example of an error message. PRESS PLAY ON CASSETTE is an
; example of a control message.

; bits 6 and 7 of this value determine where the message will come from. If bit 7
; is set one of the error messages from the KERNAL will be printed. If bit 6 is set
; a control message will be printed.

LAB_FF90
	JMP	LAB_FE18		; control kernal messages


;************************************************************************************
;
; send secondary address after LISTEN

; this routine is used to send a secondary address to an I/O device after a call to
; the LISTEN routine is made and the device commanded to LISTEN. The routine cannot
; be used to send a secondary address after a call to the TALK routine.

; A secondary address is usually used to give set-up information to a device before
; I/O operations begin.

; When a secondary address is to be sent to a device on the serial bus the address
; must first be ORed with $60.

;LAB_FF93
	JMP	LAB_EDB9		; send secondary address after LISTEN


;************************************************************************************
;
; send secondary address after TALK

; this routine transmits a secondary address on the serial bus for a TALK device.
; This routine must be called with a number between 4 and 31 in the accumulator.
; The routine will send this number as a secondary address command over the serial
; bus. This routine can only be called after a call to the TALK routine. It will
; not work after a LISTEN.

;LAB_FF96
	JMP	LAB_EDC7		; send secondary address after TALK


;************************************************************************************
;
; read/set the top of memory

; this routine is used to read and set the top of RAM. When this routine is called
; with the carry bit set the pointer to the top of RAM will be loaded into XY. When
; this routine is called with the carry bit clear XY will be saved as the top of
; memory pointer changing the top of memory.

LAB_FF99
	JMP	LAB_FE25		; read/set the top of memory


;************************************************************************************
;
; read/set the bottom of memory

; this routine is used to read and set the bottom of RAM. When this routine is
; called with the carry bit set the pointer to the bottom of RAM will be loaded
; into XY. When this routine is called with the carry bit clear XY will be saved as
; the bottom of memory pointer changing the bottom of memory.

LAB_FF9C
	JMP	LAB_FE34		; read/set the bottom of memory


;************************************************************************************
;
; scan the keyboard

; this routine will scan the keyboard and check for pressed keys. It is the same
; routine called by the interrupt handler. If a key is down, its ASCII value is
; placed in the keyboard queue.

;LAB_FF9F
	JMP	LAB_EA87		; scan keyboard


;************************************************************************************
;
; set timeout on serial bus

; this routine sets the timeout flag for the serial bus. When the timeout flag is
; set, the computer will wait for a device on the serial port for 64 milliseconds.
; If the device does not respond to the computer's DAV signal within that time the
; computer will recognize an error condition and leave the handshake sequence. When
; this routine is called and the accumulator contains a 0 in bit 7, timeouts are
; enabled. A 1 in bit 7 will disable the timeouts.

; NOTE: The the timeout feature is used to communicate that a disk file is not found
; on an attempt to OPEN a file.

;LAB_FFA2
	JMP	LAB_FE21		; set timeout on serial bus


;************************************************************************************
;
; input byte from serial bus
;
; this routine reads a byte of data from the serial bus using full handshaking. the
; data is returned in the accumulator. before using this routine the TALK routine,
; LAB_FFB4, must have been called first to command the device on the serial bus to
; send data on the bus. if the input device needs a secondary command it must be sent
; by using the TKSA routine, LAB_FF96, before calling this routine.
;
; errors are returned in the status word which can be read by calling the READST
; routine, LAB_FFB7.

;LAB_FFA5
	JMP	LAB_EE13		; input byte from serial bus


;************************************************************************************
;
; output a byte to serial bus

; this routine is used to send information to devices on the serial bus. A call to
; this routine will put a data byte onto the serial bus using full handshaking.
; Before this routine is called the LISTEN routine, LAB_FFB1, must be used to
; command a device on the serial bus to get ready to receive data.

; the accumulator is loaded with a byte to output as data on the serial bus. A
; device must be listening or the status word will return a timeout. This routine
; always buffers one character. So when a call to the UNLISTEN routine, LAB_FFAE,
; is made to end the data transmission, the buffered character is sent with EOI
; set. Then the UNLISTEN command is sent to the device.

;LAB_FFA8
	JMP	LAB_EDDD		; output byte to serial bus


;************************************************************************************
;
; command serial bus to UNTALK

; this routine will transmit an UNTALK command on the serial bus. All devices
; previously set to TALK will stop sending data when this command is received.

;LAB_FFAB
	JMP	LAB_EDEF		; command serial bus to UNTALK


;************************************************************************************
;
; command serial bus to UNLISTEN

; this routine commands all devices on the serial bus to stop receiving data from
; the computer. Calling this routine results in an UNLISTEN command being transmitted
; on the serial bus. Only devices previously commanded to listen will be affected.

; This routine is normally used after the computer is finished sending data to
; external devices. Sending the UNLISTEN will command the listening devices to get
; off the serial bus so it can be used for other purposes.

;LAB_FFAE
	JMP	LAB_EDFE		; command serial bus to UNLISTEN


;************************************************************************************
;
; command devices on the serial bus to LISTEN

; this routine will command a device on the serial bus to receive data. The
; accumulator must be loaded with a device number between 4 and 31 before calling
; this routine. LISTEN convert this to a listen address then transmit this data as
; a command on the serial bus. The specified device will then go into listen mode
; and be ready to accept information.

;LAB_FFB1
	JMP	LAB_ED0C		; command devices on the serial bus to LISTEN


;************************************************************************************
;
; command serial bus device to TALK

; to use this routine the accumulator must first be loaded with a device number
; between 4 and 30. When called this routine converts this device number to a talk
; address. Then this data is transmitted as a command on the Serial bus.

;LAB_FFB4
	JMP	LAB_ED09		; command serial bus device to TALK


;************************************************************************************
;
; read I/O status word

; this routine returns the current status of the I/O device in the accumulator. The
; routine is usually called after new communication to an I/O device. The routine
; will give information about device status, or errors that have occurred during the
; I/O operation.

LAB_FFB7
	JMP	LAB_FE07		; read I/O status word


;************************************************************************************
;
; set logical, first and second addresses

; this routine will set the logical file number, device address, and secondary
; address, command number, for other KERNAL routines.

; the logical file number is used by the system as a key to the file table created
; by the OPEN file routine. Device addresses can range from 0 to 30. The following
; codes are used by the computer to stand for the following CBM devices:

; ADDRESS	DEVICE
; =======	======
;  0		Keyboard
;  1		Cassette #1
;  2		RS-232C device
;  3		CRT display
;  4		Serial bus printer
;  8		CBM Serial bus disk drive

; device numbers of four or greater automatically refer to devices on the serial
; bus.

; a command to the device is sent as a secondary address on the serial bus after
; the device number is sent during the serial attention handshaking sequence. If
; no secondary address is to be sent Y should be set to $FF.

LAB_FFBA
	JMP	LAB_FE00		; set logical, first and second addresses


;************************************************************************************
;
; set the filename

; this routine is used to set up the file name for the OPEN, SAVE, or LOAD routines.
; The accumulator must be loaded with the length of the file and XY with the pointer
; to file name, X being th low byte. The address can be any valid memory address in
; the system where a string of characters for the file name is stored. If no file
; name desired the accumulator must be set to 0, representing a zero file length,
; in that case  XY may be set to any memory address.

LAB_FFBD
	JMP	LAB_FDF9		; set the filename


;************************************************************************************
;
; open a logical file

; this routine is used to open a logical file. Once the logical file is set up it
; can be used for input/output operations. Most of the I/O KERNAL routines call on
; this routine to create the logical files to operate on. No arguments need to be
; set up to use this routine, but both the SETLFS, LAB_FFBA, and SETNAM, LAB_FFBD,
; KERNAL routines must be called before using this routine.


LAB_FFC0
	JMP	(LAB_031A)		; do open a logical file


;************************************************************************************
;
; close a specified logical file

; this routine is used to close a logical file after all I/O operations have been
; completed on that file. This routine is called after the accumulator is loaded
; with the logical file number to be closed, the same number used when the file was
; opened using the OPEN routine.

LAB_FFC3
	JMP	(LAB_031C)		; do close a specified logical file


;************************************************************************************
;
; open channel for input

; any logical file that has already been opened by the OPEN routine, LAB_FFC0, can be
; defined as an input channel by this routine. the device on the channel must be an
; input device or an error will occur and the routine will abort.
;
; if you are getting data from anywhere other than the keyboard, this routine must be
; called before using either the CHRIN routine, LAB_FFCF, or the GETIN routine,
; LAB_FFE4. if you are getting data from the keyboard and no other input channels are
; open then the calls to this routine and to the OPEN routine, LAB_FFC0, are not needed.
;
; when used with a device on the serial bus this routine will automatically send the
; listen address specified by the OPEN routine, LAB_FFC0, and any secondary address.
;
; possible errors are:
;
;	3 : file not open
;	5 : device not present
;	6 : file is not an input file

LAB_FFC6
	JMP	(LAB_031E)		; do open channel for input


;************************************************************************************
;
; open channel for output

; any logical file that has already been opened by the OPEN routine, LAB_FFC0, can be
; defined as an output channel by this routine the device on the channel must be an
; output device or an error will occur and the routine will abort.
;
; if you are sending data to anywhere other than the screen this routine must be
; called before using the CHROUT routine, LAB_FFD2. if you are sending data to the
; screen and no other output channels are open then the calls to this routine and to
; the OPEN routine, LAB_FFC0, are not needed.
;
; when used with a device on the serial bus this routine will automatically send the
; listen address specified by the OPEN routine, LAB_FFC0, and any secondary address.
;
; possible errors are:
;
;	3 : file not open
;	5 : device not present
;	7 : file is not an output file

LAB_FFC9
	JMP	(LAB_0320)		; do open channel for output


;************************************************************************************
;
; close input and output channels

; this routine is called to clear all open channels and restore the I/O channels to
; their original default values. It is usually called after opening other I/O
; channels and using them for input/output operations. The default input device is
; 0, the keyboard. The default output device is 3, the screen.

; If one of the channels to be closed is to the serial port, an UNTALK signal is sent
; first to clear the input channel or an UNLISTEN is sent to clear the output channel.
; By not calling this routine and leaving listener(s) active on the serial bus,
; several devices can receive the same data from the VIC at the same time. One way to
; take advantage of this would be to command the printer to TALK and the disk to
; LISTEN. This would allow direct printing of a disk file.

LAB_FFCC
	JMP	(LAB_0322)		; do close input and output channels


;************************************************************************************
;
; input character from channel

; this routine will get a byte of data from the channel already set up as the input
; channel by the CHKIN routine, LAB_FFC6.
;
; If CHKIN, LAB_FFC6, has not been used to define another input channel the data is
; expected to be from the keyboard. the data byte is returned in the accumulator. the
; channel remains open after the call.
;
; input from the keyboard is handled in a special way. first, the cursor is turned on
; and it will blink until a carriage return is typed on the keyboard. all characters
; on the logical line, up to 80 characters, will be stored in the BASIC input buffer.
; then the characters can be returned one at a time by calling this routine once for
; each character. when the carriage return is returned the entire line has been
; processed. the next time this routine is called the whole process begins again.

LAB_FFCF
	JMP	(LAB_0324)		; do input character from channel


;************************************************************************************
;
; output character to channel

; this routine will output a character to an already opened channel. Use the OPEN
; routine, LAB_FFC0, and the CHKOUT routine, LAB_FFC9, to set up the output channel
; before calling this routine. If these calls are omitted, data will be sent to the
; default output device, device 3, the screen. The data byte to be output is loaded
; into the accumulator, and this routine is called. The data is then sent to the
; specified output device. The channel is left open after the call.

; NOTE: Care must be taken when using routine to send data to a serial device since
; data will be sent to all open output channels on the bus. Unless this is desired,
; all open output channels on the serial bus other than the actually intended
; destination channel must be closed by a call to the KERNAL close channel routine.

LAB_FFD2
	JMP	(LAB_0326)		; do output character to channel


;************************************************************************************
;
; load RAM from a device

; this routine will load data bytes from any input device directly into the memory
; of the computer. It can also be used for a verify operation comparing data from a
; device with the data already in memory, leaving the data stored in RAM unchanged.

; The accumulator must be set to 0 for a load operation or 1 for a verify. If the
; input device was OPENed with a secondary address of 0 the header information from
; device will be ignored. In this case XY must contain the starting address for the
; load. If the device was addressed with a secondary address of 1 or 2 the data will
; load into memory starting at the location specified by the header. This routine
; returns the address of the highest RAM location which was loaded.

; Before this routine can be called, the SETLFS, LAB_FFBA, and SETNAM, LAB_FFBD,
; routines must be called.

LAB_FFD5
	JMP	LAB_F49E		; load RAM from a device


;************************************************************************************
;
; save RAM to a device

; this routine saves a section of memory. Memory is saved from an indirect address
; on page 0 specified by A, to the address stored in XY, to a logical file. The
; SETLFS, LAB_FFBA, and SETNAM, LAB_FFBD, routines must be used before calling this
; routine. However, a file name is not required to SAVE to device 1, the cassette.
; Any attempt to save to other devices without using a file name results in an error.

; NOTE: device 0, the keyboard, and device 3, the screen, cannot be SAVEd to. If
; the attempt is made, an error will occur, and the SAVE stopped.

LAB_FFD8
	JMP	LAB_F5DD		; save RAM to device


;************************************************************************************
;
; set the real time clock

; the system clock is maintained by an interrupt routine that updates the clock
; every 1/60th of a second. The clock is three bytes long which gives the capability
; to count from zero up to 5,184,000 jiffies - 24 hours plus one jiffy. At that point
; the clock resets to zero. Before calling this routine to set the clock the new time,
; in jiffies, should be in YXA, the accumulator containing the most significant byte.

LAB_FFDB
	JMP	LAB_F6E4		; set real time clock


;************************************************************************************
;
; read the real time clock

; this routine returns the time, in jiffies, in AXY. The accumulator contains the
; most significant byte.

LAB_FFDE
	JMP	LAB_F6DD		; read real time clock


;************************************************************************************
;
; scan the stop key

; if the STOP key on the keyboard is pressed when this routine is called the Z flag
; will be set. All other flags remain unchanged. If the STOP key is not pressed then
; the accumulator will contain a byte representing the last row of the keyboard scan.

; The user can also check for certain other keys this way.

LAB_FFE1
	JMP	(LAB_0328)		; do scan stop key


;************************************************************************************
;
; get character from input device

; in practice this routine operates identically to the CHRIN routine, LAB_FFCF,
; for all devices except for the keyboard. If the keyboard is the current input
; device this routine will get one character from the keyboard buffer. It depends
; on the IRQ routine to read the keyboard and put characters into the buffer.

; If the keyboard buffer is empty the value returned in the accumulator will be zero.

LAB_FFE4
	JMP	(LAB_032A)		; do get character from input device


;************************************************************************************
;
; close all channels and files

; this routine closes all open files. When this routine is called, the pointers into
; the open file table are reset, closing all files. Also the routine automatically
; resets the I/O channels.

LAB_FFE7
	JMP	(LAB_032C)		; do close all channels and files


;************************************************************************************
;
; increment real time clock

; this routine updates the system clock. Normally this routine is called by the
; normal KERNAL interrupt routine every 1/60th of a second. If the user program
; processes its own interrupts this routine must be called to update the time. Also,
; the STOP key routine must be called if the stop key is to remain functional.

LAB_FFEA
	JMP	LAB_F69B		; increment real time clock


;************************************************************************************
;
; return X,Y organization of screen

; this routine returns the x,y organisation of the screen in X,Y

;LAB_FFED
	JMP	LAB_E505		; return X,Y organization of screen


;************************************************************************************
;
; read/set X,Y cursor position

; this routine, when called with the carry flag set, loads the current position of
; the cursor on the screen into the X and Y registers. X is the column number of
; the cursor location and Y is the row number of the cursor. A call with the carry
; bit clear moves the cursor to the position determined by the X and Y registers.

LAB_FFF0
	JMP	LAB_E50A		; read/set X,Y cursor position


;************************************************************************************
;
; return the base address of the I/O devices

; this routine will set XY to the address of the memory section where the memory
; mapped I/O devices are located. This address can then be used with an offset to
; access the memory mapped I/O devices in the computer.

LAB_FFF3
	JMP	LAB_E500		; return the base address of the I/O devices


;************************************************************************************
;

;LAB_FFF6
	.byte	"RRBY"

; hardware vectors

;LAB_FFFA
	.word	LAB_FE43		; NMI vector
	.word	LAB_FCE2		; RESET vector
	.word	LAB_FF48		; IRQ vector

	.END


;************************************************************************************
