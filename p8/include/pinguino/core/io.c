/*	----------------------------------------------------------------------------
    FILE:           io.c
    PROJECT:        pinguino
    PURPOSE:        Peripheral Remappage and IOs Configuration
    PROGRAMER:      Régis Blanchot <rblanchot@gmail.com>
    FIRST RELEASE:  20 Jun. 2012
    LAST RELEASE:   28 Feb 2013
    ----------------------------------------------------------------------------
    CHANGELOG:
    23 Nov. 2012 - Régis Blanchot - added PIC18F1220,1320,2455,4455,46j50 support
    07 Dec. 2012 - Régis Blanchot - added PIC18F25K50 and PIC18F45K50 support
    05 Oct. 2013 - Régis Blanchot - replaced SystemUnlock/SystemLock
                                    with EECON2 = 0x55; EECON2 = 0xAA;]
    28 Feb. 2013 - Régis Blanchot - renamed functions
                                    added IO_init()
    01 Oct. 2015 - Régis Blanchot - added SPI2 pins in IO_remap()
    09 Sep. 2015 - Régis Blanchot - added PIC16F1459 support
    27 Jan. 2016 - Régis Blanchot - added PIC16F1708 support
    ----------------------------------------------------------------------------
    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
    --------------------------------------------------------------------------*/

#ifndef __IO_C
#define __IO_C

#include <compiler.h>
#include <typedef.h>
#include <const.h>
#include <macro.h>
//#include <system.c>

void IO_init(void)
{
    // Initialize everything as an output
    
    // Set everything low

    #if defined(__16F1459) || defined(__16F1708) || \
        defined(__18f13k50) || defined(__18f14k50)
    LATA  = 0x00;
    LATB  = 0x80;       // Except UART TX bit (maintain high state to not emit extra low state) 
    LATC  = 0x00;
    #else
    LATA  = 0x00;
    LATB  = 0x00;
    #endif
    
    #if defined(__18f26j50) || defined(__18f46j50) || \
        defined(__18f27j53) || defined(__18f47j53)
        #ifdef __SERIAL__
        LATC  = 0x44;   // Except UART TX,TX2 bit (maintain high state to not emit extra low state) 
        #else
        LATC  = 0x00;
        #endif
    #endif
    
    #if  defined(__18f2455)  || defined(__18f4455)  || \
         defined(__18f2550)  || defined(__18f4550)  || \
         defined(__18f25k50) || defined(__18f45k50)
        #ifdef __SERIAL__
        LATC  = 0x40;   // Except UART TX bit (maintain high state to not emit extra low state) 
        #else
        LATC  = 0x00;
        #endif
    #endif

    #if defined(__18f4455)  || defined(__18f4550)  || \
        defined(__18f45k50) || defined(__18f46j50) || \
        defined(__18f47j53)
    LATD  = 0x00; 
    LATE  = 0x00; 
    #endif

    TRISA = 0x00;
    #ifndef I2CINT
        TRISB = 0x00;
        #if defined(__SERIAL__) && defined(__16F1459)
        TRISBbits.TRISB5 = 1; // Clear all bits except RB5 (Serial INPUT)
        #endif
    #endif
    
    #if defined(__16F1459) || defined(__16F1708) || \
        defined(__18f13k50) || defined(__18f14k50)
    TRISC = 0x00;
    #else
    TRISCbits.TRISC0 = 0x00;
    TRISCbits.TRISC1 = 0x00;
    TRISCbits.TRISC2 = 0x00;
    TRISCbits.TRISC6 = 0x00;
    TRISCbits.TRISC7 = 0x00;
    #endif

    #if defined(__18f4455)  || defined(__18f4550)  || \
        defined(__18f45k50) || defined(__18f46j50) || \
        defined(__18f47j53)
    TRISD = 0x00; 
    TRISE = 0x00; 
    #endif

    // Set everything low to avoid current leakage in low-power mode
    PORTA  = 0x00;
    PORTB  = 0x00;
    PORTC  = 0x00;
    #if defined(__18f4455)  || defined(__18f4550)  || \
        defined(__18f45k50) || defined(__18f46j50) || \
        defined(__18f47j53)
    PORTD  = 0x00; 
    PORTE  = 0x00; 
    #endif
}

// All Analog Pins as Digital IOs
void IO_digital(void)
{
    #if defined(__18f2455) || defined(__18f4455) || \
        defined(__18f2550) || defined(__18f4550)

        ADCON1 = 0x0F;              // AN0 to AN12 Digital I/O
        CMCON  = 0x07;              // Comparators as Digital I/O

    #elif defined(__18f13k50) || defined(__18f14k50)

        // Initialize all Analog pins as Digital I/O
        ANSEL  = 0;                 // AN3 to AN7  Digital I/O
        ANSELH = 0;                 // AN8 to AN11 Digital I/O

    #elif defined(__16F1459)  || defined(__16F1708)  || \
          defined(__18f25k50) || defined(__18f45k50)

        // Initialize all Analog pins as Digital I/O
        ANSELA = 0;
        ANSELB = 0;
        ANSELC = 0;
        #if defined(__18f45k50)
        ANSELD = 0;
        ANSELE = 0;
        #endif

    #elif defined(__18f26j50) || defined(__18f46j50)

        // Initialize all Analog pins as Digital I/O
        ANCON0 = 0xFF;              // AN0 to AN7  Digital I/O
        ANCON1 = 0x1F;              // AN8 to AN12 Digital I/O

        // Turn off all comparators 
        CM1CON = 0x00;
        CM2CON = 0x00; 
        CVRCON = 0x00;

    #elif defined(__18f27j53) || defined(__18f47j53)

        // Initialize all Analog pins as Digital I/O
        ANCON0 = 0xFF;              // AN0 to AN7  Digital I/O
        ANCON1 = 0x1F;              // AN8 to AN12 Digital I/O

    #endif
}

/**
 * PIC  PINGUINO    PPS
 * 0    RB0         RP3
 * 1    RB1         RP4
 * 2    RB2         RP5
 * 3    RB3         RP6
 * 4    RB4         RP7
 * 5    RB5         RP8
 * 6    RB6         RP9
 * 7    RB7         RP10
 * 8    RC6         RP17
 * 9    RC7         RP18
 * 10   RC0         RP11
 * 11   RC1         RP12
 * 12   RC2         RP13
 * 13   RA0         RP0
 * 14   RA1         RP1
 * 15   RA2         -
 * 16   RA3         -
 * 17   RA5         RP2
 **/
 
// Peripheral Remappage
// NB1 : the Config. bit IOL1WAY is set to OFF (cf. bootloader's code)
// NB2 : pins must be explicitly reconfigured as digital I/O when used
//       with a PPS

#if defined(__16F1459)  || defined(__16F1708)  || \
    defined(__18f26j50) || defined(__18f46j50) || \
    defined(__18f27j53) || defined(__18f47j53)
    
void IO_remap(void)
{
    #if defined(__16F1459)

        //bit 7 CLKRSEL: Pin Selection bit
        //1 = CLKR function is on RC3
        //0 = CLKR function is on RA4
        //APFCONbits.CLKRSEL = 1;                         // RC3

        //bit 5 SSSEL: Pin Selection bit
        //1 = SS function is on RA4
        //0 = SS function is on RC2
        //APFCONbits.SDOSEL = 0;                          // RC2

        //bit 5 SSSEL: Pin Selection bit
        //1 = SS function is on RA3
        //0 = SS function is on RC6
        //APFCONbits.SSSEL = 0;                           // RC6

        //bit 3 T1GSEL: Pin Selection bit
        //1 = T1G function is on RA3
        //0 = T1G function is on RA4
        //APFCONbits.T1GSEL = 1;                          // RA3

    #elif defined(__16F1708)

        // TODO

    #elif defined(__18f26j50) || defined(__18f46j50)

        //SystemUnlock();
        EECON2 = 0x55;
        EECON2 = 0xAA;
        PPSCONbits.IOLOCK = 0;			// Turn off PPS Write Protect
        //SystemLock();

        //#ifdef __SERIAL2__
        RPINR16 = 4;                    // RP4 (RB1) <- RX2
        RPOR3 = 5;                      // RP3 (RB0) -> TX2 (func. num. 5)
        //RPINR17 = ;                     // EUSART2 Clock Input (CKR2)
        //#endif

        //#ifdef __SPI2__
        /**
         * datasheet 18f26j50 p274
         * When MSSP2 is used in SPI Master mode, the SCK2 function must be
         * configured as both an output and an input in the PPS module.
         * SCK2 must be initialized as an output pin (by writing 0x0A to one
         * of the RPORx registers).
         * Additionally, SCK2IN must also be mapped to the same pin by
         * initializing the RPINR22 register.
         * Failure to initialize SCK2/SCK2IN as both output and input will
         * prevent the module from receiving data on the SDI2 pin, as the
         * module uses the SCK2IN signal to latch the received data.
        **/
        
        //RPINR23 = 3;                    // RP3 (RB0) <- SS2 (Slave mode)
        RPINR22 = 5;                    // RP5 (RB2) <- SCK2 [2014-20-03 - AG - fixed (see above)]
        RPOR5 = 10;                     // RP5 (RB2) -> SCK2
        RPINR21 = 6;                    // RP6 (RB3) <- SDI2
        RPOR4 = 9;                      // RP4 (RB1) -> SDO2 (func. num. 9)
        //RPOR3 = 12;                     // RP3 (RB0) -> SS2 (SPI DMA Slave Select)
        //#endif

        //#ifdef __PWM__
        RPOR11 = 14;                    // RP11 (RC0) <- CCP1
                //P1B      - 15 - ECCP1 Enhanced PWM Output, Channel B
                //P1C      - 16 - ECCP1 Enhanced PWM Output, Channel C
                //P1D      - 17 - ECCP1 Enhanced PWM Output, Channel D
        RPOR12 = 18;                    // RP12 (RC1) <- CCP2
                //P2B      - 19 - ECCP2 Enhanced PWM Output, Channel B
                //P2C      - 20 - ECCP2 Enhanced PWM Output, Channel C
                //P2D      - 21 - ECCP2 Enhanced PWM Output, Channel D
        // RPINR24 = ;                     // PWM Fault Input (FLT0)
        
        //#endif

        //SystemUnlock();
        EECON2 = 0x55;
        EECON2 = 0xAA;
        PPSCONbits.IOLOCK = 1;			// Turn on PPS Write Protect
        //SystemLock();

    #elif defined(__18f27j53) || defined(__18f47j53)

        //SystemUnlock();
        EECON2 = 0x55;
        EECON2 = 0xAA;
        PPSCONbits.IOLOCK = 0;          // Turn on PPS Write Protect

        /**
         * datasheet 18f47j53 p296
         * When MSSP2 is used in SPI Master mode, the SCK2 function must be
         * configured as both an output and an input in the PPS module.
         * SCK2 must be initialized as an output pin (by writing 0x0A to one
         * of the RPORx registers).
         * Additionally, SCK2IN must also be mapped to the same pin by
         * initializing the RPINR22 register.
         * Failure to initialize SCK2/SCK2IN as both output and input will
         * prevent the module from receiving data on the SDI2 pin, as the
         * module uses the SCK2IN signal to latch the received data.
        **/
        
        //RPINR23 = 3;                    // RP3 (RB0) <- SS2 (Slave mode)
        RPINR22 = 5;                    // RP5 (RB2) <- SCK2 [2014-20-03 - AG - fixed (see above)]
        RPOR5 = 11;                     // RP5 (RB2) -> SCK2 (func. num. 11)
        RPINR21 = 6;                    // RP6 (RB3) <- SDI2
        RPOR4 = 10;                     // RP4 (RB1) -> SDO2 (func. num. 10)

        #if defined(SERIALUSEPORT2)
        RPINR16 = 4;                    // RP4 (RB1) <- RX2
        RPOR3 = 6;                      // RP3 (RB0) -> TX2 (func. num. 6)
        //RPINR17 = ;                     // EUSART2 Clock Input (CKR2)
        #endif
    
        //SystemLock();
        EECON2 = 0x55;
        EECON2 = 0xAA;
        PPSCONbits.IOLOCK = 1;          // Turn on PPS Write Protect

    #endif
}
#endif // defined(__18f26j50) || defined(__18f46j50) ...

#endif /* __IO_C */
