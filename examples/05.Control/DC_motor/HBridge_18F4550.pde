/*----------------------------------------------------- 
Author:  --<>
Date: Sun Jan 25 15:00:00 2015
Description: Enhanced PWM - Full Bridge
Boards : 44-pin PIC18F only
Function:
PWM_setEnhancedOutput(config, mode)

Pin:
P1A = 12 (RC2)
P1B = 26 (RD5)
P1C = 27 (RD6)
P1D = 28 (RD7)

Supported Config:
SINGLE_OUT      Single output: P1A modulated; P1B, P1C, P1D assigned as port pins
FULL_OUT_FWD    Full-bridge output forward: P1D modulated; P1A active; P1B, P1C inactive
HALF_OUT        Half-bridge output: P1A, P1B modulated with dead-band control; P1C, P1D assigned as port pins
FULL_OUT_REV    Full-bridge output reverse: P1B modulated; P1C active; P1A, P1D inactive

Supported Mode:
PWM_MODE_1    P1A,P1C active high, P1B,P1D active high
PWM_MODE_2    P1A,P1C active high, P1B,P1D active low
PWM_MODE_3    P1A,P1C active low, P1B,P1D active high
PWM_MODE_4    P1A,P1C active low, P1B,P1D active low
-----------------------------------------------------*/

// Pin Definitions
#define PWM1A     12   // (RC2)
#define PWM1B     26   // (RD5)
#define PWM1C     27   // (RD6)
#define PWM1D     28   // (RD7)
#define FLT0      0    // INT0

// Variables
u8 led_handle = 0;
int i = 512;

// Functions
void TMR0_Tick() {
    led_handle = (led_handle ^ 1);
    digitalWrite(USERLED,led_handle);
} 

void setup() {

    // I/O Settings 
    pinMode(USERLED, OUTPUT);
    pinMode(PWM1A, OUTPUT);
    pinMode(PWM1B, OUTPUT);
    pinMode(PWM1C, OUTPUT);
    pinMode(PWM1D, OUTPUT);
    pinMode(FLT0,  INPUT);                    //FLT0 as input
    
    digitalWrite(USERLED, LOW);
    digitalWrite(PWM1A, LOW);
    digitalWrite(PWM1B, LOW);
    digitalWrite(PWM1C, LOW);
    digitalWrite(PWM1D, LOW);   
    OnTimer0(TMR0_Tick, INT_MILLISEC, 500);
    
    // Quick Output test
    digitalWrite(PWM1A, HIGH);
    delay(500);
    digitalWrite(PWM1A, LOW);
    digitalWrite(PWM1B, HIGH);
    delay(500);
    digitalWrite(PWM1B, LOW);
    digitalWrite(PWM1C, HIGH);
    delay(500);
    digitalWrite(PWM1C, LOW);
    digitalWrite(PWM1D, HIGH);
    delay(500);
    digitalWrite(PWM1D, LOW);
    delay(500);

    PWM.setAutoShutdown(TRUE);            // This set ECCP1AS = 0b01000000
    PWM.setASautoRestart(TRUE);
    
    PWM.setFrequency(4000);                // 4KHz
    PWM.setDutyCycle(PWM1, 512);
 
}

void loop()
{
    PWM.setEnhancedOutput(FULL_OUT_FWD, PWM_MODE_1);    // 2 sec FORWARD
    delay(2000);
    PWM.setEnhancedOutput(FULL_OUT_REV, PWM_MODE_1);    // 2 sec REVERSE
    delay(2000);
    
    // Duty Cycle Test
    i += 100;    
    if (i >= 1023)
        i = 0;
    PWM.setDutyCycle(PWM1, i);
}
