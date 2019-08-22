// A simple test to communicate with a ENC28J60 and SPI protocol

//#include <fonts/font6x8.h>
//const u8 spilcd = SPI1;
const u8 spieth = SPI2;

// Olimex PIC32-Pinguino have USERLED and SCK2 multiplexed
//const led = USERLED // (or LED1 for 2-LEDs Pinguinos)
const u8 led = LED2;

void setup()
{
    pinMode (led, OUTPUT); 

    /*
    // Init ST7735 display
    ST7735.init(spilcd, 14); // DC=TX1 for Pinguino torda UEXT1
    //ST7735.init(spilcd, 24); // DC=SCL2 for Pinguino torda UEXT2
    //ST7735.init(spilcd, 19); // DC=SCL1 for Olimex PIC32 Pinguino UEXT
    ST7735.setFont(spilcd, font6x8);
    ST7735.setColor(spilcd, ST7735_YELLOW);
    ST7735.setBackgroundColor(spilcd, ST7735_BLACK);
    //ST7735.setOrientation(spilcd, 90);
    ST7735.clearScreen(spilcd);
    */

    // Init SPI module
    SPI.deselect(spieth);
    SPI.setMode(spieth, SPI_MASTER);
    // ENC28J60 supports SPI mode 0,0 only (datasheet p25)
    SPI.setDataMode(spieth, SPI_MODE0);
    // ENC28J60 supports SPI clock speeds up to 20 MHz
    // but not under 8 MHz (Rev. B4 Silicon Errata).
    // P8 : maximum baud rate possible = FPB = FOSC/4 = 12 MHz @ 48MHz
    // P32: maximum baud rate possible = FCPU/4 = 20 MHz @ 80 MHz
    SPI.setClockDivider(spieth, SPI_PBCLOCK_DIV4);
    //SPI.setClockDivider(spieth, SPI_CLOCK_DIV4);
    SPI.begin(spieth);
}

void loop()
{
    u8 i;
 
    // Reset ENC28J60
    // A Reset is generated by holding the RESET pin low.
    TRISDCLR = 1<<9;
    LATDCLR  = 1<<9;
    delay(50);
    LATDSET  = 1<<9;
    //ENC28J60.writeOp(spieth, ENC28J60_SOFT_RESET, 0, ENC28J60_SOFT_RESET);
    //
    SPI.select(spieth);
    SPI.write(spieth, ENC28J60_SOFT_RESET);
    SPI.deselect(spieth);
    //

    // Check CLKRDY bit to see if reset is complete
    // The CLKRDY does not work. See Rev. B4 Silicon Errata point.
    // Work around : wait for at least 1 ms for the device to be ready
    //while(!(ENC28J60.read(ESTAT) & ESTAT_CLKRDY));
    delay(50);

    // Let's make LEDs blinking
    for (i=0; i<10; i++)
    {
        toggle(led);

        // 0x880 is PHLCON LEDB=on, LEDA=on
        // 0b1000<<8 | 0b1000<<4 = 0x880
        ENC28J60.phyWrite(spieth, PHLCON, 0x880);
    /*
            // set the PHY register address
            //ENC28J60.write(spieth, MIREGADR, PHLCON);
               // set the bank
               //ENC28J60.setBank(spieth, MIREGADR);
                   //ENC28J60.writeOp(spieth, ENC28J60_BIT_FIELD_CLR, ECON1, (ECON1_BSEL1|ECON1_BSEL0));
                       SPI.select(spieth);
                       SPI.write(spieth, ENC28J60_BIT_FIELD_CLR|(ECON1 & ADDR_MASK));
                       SPI.write(spieth, (ECON1_BSEL1|ECON1_BSEL0));
                       SPI.deselect(spieth);
                   //ENC28J60.writeOp(spieth, ENC28J60_BIT_FIELD_SET, ECON1, (MIREGADR & BANK_MASK)>>5);
                       SPI.select(spieth);
                       SPI.write(spieth, ENC28J60_BIT_FIELD_SET|(ECON1 & ADDR_MASK));
                       SPI.write(spieth, (MIREGADR & BANK_MASK)>>5);
                       SPI.deselect(spieth);
               // do the write
               //ENC28J60.writeOp(spieth, ENC28J60_WRITE_CTRL_REG, MIREGADR, PHLCON);
                   SPI.select(spieth);
                   SPI.write(spieth, ENC28J60_WRITE_CTRL_REG|(MIREGADR & ADDR_MASK));
                   SPI.write(spieth, PHLCON);
                   SPI.deselect(spieth);
            // write the PHY data
            //ENC28J60.write(spieth, MIWRL,  low8(0x0880));
            //ENC28J60.write(spieth, MIWRH, high8(0x0880));
            // wait until the PHY write completes
            //while(ENC28J60.read(spieth, MISTAT) & MISTAT_BUSY);
    */
        delay(500);
        // 0x990 is PHLCON LEDB=off, LEDA=off
        // 0b1001<<8 | 0b1001<<4 = 0x990
        ENC28J60.phyWrite(spieth, PHLCON, 0x990);
        delay(500);
    }

    // 0x476 is PHLCON LEDA=links status, LEDB=receive/transmit,
    //ENC28J60.phyWrite(spieth, PHLCON, 0x470);
    // Stretch LED events by TMSTRCH and 
    // Stretchable LED events will cause lengthened LED pulses based on LFRQ1:LFRQ0 configuration
    // 0b0100<<8 | 0b0111<<4 + 6 = 0x476
    ENC28J60.phyWrite(spieth, PHLCON, 0x476);
    Delayms(500);

    //u8 rev, i;

    //rev = ENC28J60.getrev(spieth);
    //ST7735.printf(spilcd, "%03d - Rev. %d\r\n", i++, rev);
    //toggle(led);
    //delay(1000);
}