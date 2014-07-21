/*
    6500Dump - AVR code to dump MOS 6500 ROM contents
    Copyright Jim Brain 2014

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    Notes:

    There are two versions of code in this file:

    Version #1 (the original working code)

    The code takes a brute force approach to pulling memory contents from the
    6500/1.  Based on a plan by Greg King to simply pull data directly from
    the ROM, with no need to create a program that runs in the 6500/1, the
    code holds RESET low for a suitable time, puts the CPU into TEST mode, and
    tries to synchronize the opcode stream using a set of opcodes provided by
    Gerrit Heitsch, modified based on empirical testing.  Once synchronization
    happens, it instructs the internal CPU to load one memory location into the
    .A register, dropping out of TEST during the cycle when the load from ROM
    occurs. It then stores the data to PORTA, JAMS the CPU, and the AVR reads
    the data from PORTA, sends it out via the AVR UART, and then repeats the
    process for the next memory location. The code does not always synchronize,
    so a few resets of the AVR MEGA32 are sometimes required.  Also, though I
    tried setting up the code to read multiple pages of memory in one run, that
    pushed the code out of synchronization, so you must recompile and
    re-download the code into the AVR for each page.

    Truly, this is truly a hack of a codebase.  It was a
    quick (and evidently successful) attempt to dump ROM contents.  The code is
    brittle, in that there's still much we do not know about startup timing
    and synchronization.  As well, the 16MHz AVR seems just barely capable of
    keeping things in sync at that speed.  I tried to implement the send_data
    as part of an OCR ISR triggered on clock state change, but the overhead
    was too much.  Thus, the horrid busy-wait loops.  I expect most robust
    implementation would be to rewrite into AVR ASM, simply count cycles,
    and manually drive the clock signal changes.

    The number of NOP instructions is truly overkill.  I added them until I
    found a reasonably stable setup.

    Also, the uart data send has no failsafe.  I rely on the fact that the
    reset + code execution path on the 6500/1 takes enough time to send at
    least one byte at 57600

    You can define "IMMEDIATE" in the codebase to test out immediate mode.

    Version #2 (proving that the original description in the 6500/1 datasheet 
    is also workable)

    The code stuffs a small program into the first few RAM locations that
    increments through each ROM address, reading the value in ROM and then 
    storing on PORTA.  It also strobes PORTC to signal that a new piece
    of data is valid.  As with the rest of the code herein, I am sure there
    are lots of more elegant ways to write this little program, but I was 
    more interested in getting it running, so it morphed from reading a single
    location into reading a 256 byte range and then reading the entire 2kB
    ROM.  I also was able to reduce the "startup" code to a bare minimum, which
    suggests that the 6502 needs 4 cycles to start executing code.  This code is
    much less brittle than the original attempt, so I would use it to read ROM
    contents.  

    The AVR resets the 6500/1 for 4 cycles, then lets it run for 4 cycles before
    sending code to store the program into RAM.  It then sets up a JuMP to $0000
    and turns off TEST mode, allowing the 6502 to run code from RAM, and the 6502
    code then reads data and delivers it to the PORTA, where the AVR picks it
    up after seeing the STROBE signal.  The received data is then sent to the UART.

*/

#include <inttypes.h>
#include <avr/io.h>
#include <util/atomic.h>
#include <util/delay.h>

static uint8_t i = 255;

#define F_CPU 16000000
#define UART0_BAUDRATE 57600

#define CALC_BPS(x) (int)((double)F_CPU/(16.0*x)-1)
#define RESET _BV(PD6)
#define TEST _BV(PD5)
#define CLK _BV(PD7)

#define RESET_OFF()  PORTD &= ~RESET
#define RESET_ON()  PORTD = (PORTD & ~TEST) | RESET
#define TEST_ON()   PORTD = (PORTD & ~RESET) | TEST
#define TEST_OFF()  PORTD &= ~TEST

static inline __attribute__((always_inline)) void send_data(uint8_t data) {
  PORTC = data;

  while(!(TIFR & _BV(OCF2))); // went high
  TIFR |= _BV(OCF2);
  while(!(TIFR & _BV(OCF2))); // went lo
  TIFR |= _BV(OCF2);
  while(!(TIFR & _BV(OCF2))); // went hi
  TIFR |= _BV(OCF2);
  while(!(TIFR & _BV(OCF2))); // went lo
  TIFR |= _BV(OCF2);
}

#define VER2
#ifdef VER2
int main(void) {
  UCSRC = _BV(URSEL) | _BV(UCSZ1) | _BV(UCSZ0);
  UBRRH = CALC_BPS(UART0_BAUDRATE) >> 8;
  UBRRL = CALC_BPS(UART0_BAUDRATE) & 0xff;
  UCSRB = (_BV(TXEN));
  uint8_t code[] = { 0xA9 ,0x00       // lda #0
                    ,0x85 ,0x82       // sta $82
                    ,0xA2 ,0x00       // ldx #0
                    ,0xBD ,0x00 ,0x08 //lda $800,x
                    ,0x85 ,0x80       // sta $80
                    ,0xA9 ,0xFF       // lda #$ff
                    ,0x85 ,0x82       // sta $82
                    ,0xA9 ,0x00       // lda #00
                    ,0x85 ,0x82       // sta $82
                    ,0xE8             // inx
                    ,0xD0 ,0xF0       // bne loop
                    ,0xe6 ,0x08       // inc $08
                    ,0xa5, 0x08       // lda $08
                    ,0xc9, 0x10       // cmp $10
                    ,0xd0 ,0xE6       // bne loop2
                    ,0xf0, 0xfe       // beq loop3 (this);
                   };


  DDRD = CLK | TEST | RESET;
  DDRC = 0xff;
  RESET_ON();
  DDRA = 0;
  PORTA = 0xff;
  OCR2 = 32;
  TCCR2 = _BV(WGM21) | _BV(COM20) | _BV(CS20); // /16MHz, CTC mode

  while(1) {
    RESET_ON();
    send_data(0xEA);
    send_data(0xEA);  // it'll work without the remaining 3 of these, but it's better with all 4
    send_data(0xEA);
    send_data(0xEA);
    TEST_ON();

    send_data(0xEA);
    send_data(0xEA);

    send_data(0xEA);
    send_data(0xEA);

    for(i = 0; i< sizeof(code);i++) {
      send_data(0xA9);
      send_data(code[i]);
      send_data(0x85);
      send_data(0x00 + i);
      TEST_OFF();
      send_data(0);  // extra cycle
      TEST_ON();
    }
    send_data(0x4c);
    send_data(0);
    send_data(0);
    TEST_OFF();
    PORTC = 0;
    DDRC = 0;
    //while(PINC);
    while(1) {
      while(!PINC);
      UDR = PINA;  // uart output
      while(PINC);
    }
  }
}
#else
int main(void) {
  UCSRC = _BV(URSEL) | _BV(UCSZ1) | _BV(UCSZ0);
  UBRRH = CALC_BPS(UART0_BAUDRATE) >> 8;
  UBRRL = CALC_BPS(UART0_BAUDRATE) & 0xff;
  UCSRB = (_BV(TXEN));


  DDRD = CLK | TEST | RESET;
  DDRC = 0xff;
  RESET_ON();
  DDRA = 0;
  PORTA = 0xff;
  OCR2 = 32;
  TCCR2 = _BV(WGM21) | _BV(COM20) | _BV(CS20); // /16MHz, CTC mode

  while(1) {
    send_data(0xEA); // just wasting some time...
    RESET_ON();
    send_data(0xEA);
    i++;
    send_data(0xEA);
    send_data(0xEA);

    send_data(0xEA);
    send_data(0xEA);
    send_data(0xEA);
    send_data(0xEA);

    send_data(0xEA);
    send_data(0xEA);
    send_data(0xEA);
    send_data(0xEA);

    send_data(0xEA);
    send_data(0xEA);
    send_data(0xEA);
    send_data(0xEA);

    send_data(0xEA);
    send_data(0xEA);
    send_data(0xEA);
    send_data(0xEA);
    TEST_ON();

    send_data(0xEA);  // these 4 can be removed and the code still
    send_data(0xEA);  // seems to work most of the time.
    send_data(0xEA);
    send_data(0xEA);

    send_data(0xEA); // but, these seem to be needed.
    send_data(0xEA); //keep
    send_data(0xEA); //keep

    send_data(0x2C);
    send_data(0x24);
    send_data(0xEA);
    send_data(0xEA);
    send_data(0x78);
    send_data(0x78);
//#define IMMEDIATE
#ifdef IMMEDIATE
    send_data(0xA9);
    send_data(i);
#else
    send_data(0xad);
    send_data(i);
    send_data(0xff);
    TEST_OFF();
    send_data(0);
    TEST_ON();

#endif
    send_data(0x85);
    send_data(0x80);

    send_data(0x80);
    //send_data(0x02);
    UDR = PINA;  // uart output
  }
}
#endif
