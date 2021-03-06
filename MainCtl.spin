''*******************************************************************
''*  File       : MainCtl                                           *
''*  Purpose    : Main code to start and manage all operations      *
''*               of the HTP1                                       *
''*  Author     : John R. Leeman                                    *
''*  E-mail     : kd5wxb@gmail.com                                  *
''*  Notes      : 3/3/14                                            *
''*******************************************************************
{{

CLK - Pin 15
DAT - Pin 14
Gnd - 0 V
VDD - +3.3 V
}}
CON
  _CLKMODE = XTAL1+ PLL16X 
  _XINFREQ = 5_000_000

  
  RS_pin   = 5                                           '  RS  - low for commands, high for text 
  RW_pin   = 6                                           '  R/W - low for write, high for read    
  E_pin    = 7                                           '  E   - clocks the data lines           
  D4_pin   = 8 

VAR

byte ACK, checksum, msb, lsb
long temperature, humidity, pressure

DAT                     org
Prod_Name                byte      "      HTP1      ",0
Prod_Version             byte      "   Ver: 1.0.0   ",0
Org_Top                  byte      "     Leeman     ",0 
Org_Bottom               byte      "   Geophysical  ",0
OBJ
  F     : "FloatMath"
  FS    : "FloatString"
  LCD   : "LCDDriver"
  MPL115A1    : "MPL115A1"
  HTU21D : "HTU21D"
  PST   : "Parallax Serial Terminal"  

PUB Main
  
  
  Startup ' Display welcome messages
  PST.Start(115200)                                        ' Start the Parallax Serial Terminal cog                
  PST.Str(String("DEBUG SERIAL TERMINAL:"))       ' Heading
  
  'MPL115A1.StartSensor
  HTU21D.StartSensor

  dira[16] := 1
  PST.str(String("Top of loop (before)."))
  repeat
    PST.str(String("Top of loop (inside)."))
    outa[16] := 1
    'pressure := \MPL115A1.GetReading
    temperature := \HTU21D.ReadTemp
    humidity := \HTU21D.ReadHumid

    'FS.SetPrecision(4)
    'LCD.move(1,12)
    'LCD.str(FS.FloatToString(pressure))
    LCD.Move(1,4)
    FS.SetPrecision(3)
    LCD.str(FS.FloatToString(temperature))
    PST.str(FS.FloatToString(humidity))
    LCD.Move(2,4)
    LCD.str(FS.FloatToString(humidity))
    'PST.Str(String(13,"Main (hPa): "))
    'PST.Str(FS.FloatToString(pressure))
    Pause_MS(1000)
    outa[16] := 0
    Pause_MS(1000)

PRI Pause_MS(mS)
  waitcnt(clkfreq/1000 * mS + cnt)

PRI Startup
  ' Start LCD and Display Messages
  LCD.start(E_pin,RW_pin,RS_pin,D4_pin)
  LCD.clear
  LCD.scroll_ind(@Prod_Name,1)                           
  LCD.scroll_ind(@Prod_Version,2)                      
  Pause_MS(2000)
  LCD.Move(1,1)
  LCD.str(@Org_Top)
  LCD.Move(2,1)
  LCD.str(@Org_Bottom)
  Pause_MS(2000)
  LCD.clear
  LCD.Move(1,1)
  'LCD.str(String("T:       P: "))
  LCD.str(String("T:     C")) 
  LCD.Move(2,1)
  LCD.str(String("RH:    %")) 

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}                      