''*******************************************************************
''*  File       : MPL115A1                                          *
''*  Purpose    : Provide an interface to the MPL115A1 sensor,      *
''*               reading pressure and temperature                  *
''*  Author     : John R. Leeman                                    *
''*  E-mail     : kd5wxb@gmail.com                                  *
''*  Notes      : 2/13/14                                           *
''*******************************************************************
{{

CSN - Pin 26
SDO - Pin 27
SDI - Pin 28
SCK - Pin 29
SDN - No Connection
Gnd - 0 V
VDD - +3.3 V
}}
CON
  _CLKMODE = XTAL1+ PLL16X
  _XINFREQ = 5_000_000
 
  CS    = 24
  SDO   = 25
  SDI   = 26
  SCK   = 27
  SDN   = 23

OBJ
  PST   : "Parallax Serial Terminal"
  F     : "FloatMath"
  FS    : "FloatString"

VAR
  byte CoefResponse[17]
  byte ReadResponse[9]
  long a0, a0I, a0F, b1, b1I, b1F, b2, b2I, b2F, c12, c12I, c12F
  long Padc, Tadc, Pcomp,P

DAT
  CoefRegs byte $88,$00,$8A,$00,$8C,$00,$8E,$00,$90,$00,$92,$00,$94,$00,$96,$00,$00
  ReadRes  byte $80,$00,$82,$00,$84,$00,$86,$00,$00
  
PUB Main   
  Pause_MS(1000) 
  PST.Start(115200)                                        ' Start the Parallax Serial Terminal cog                
  PST.Str(String("DEBUG SERIAL TERMINAL:"))       ' Heading

  StartSensor

  Repeat
    P := GetReading
    Pause_MS(2000)
    PST.Str(String(13,"Main (hPa): "))
    PST.Str(FS.FloatToString(P))
 
PUB StartSensor

  dira[CS]~~
  dira[SDI]~~                                                                       
  dira[SCK]~~
  dira[SDO]~
  dira[SDN]~~

  outa[SDN]~~
  outa[CS]~~
  outa[SDI]~~
  outa[SCK]~

  ReadCoeffs

PUB GetReading : Pressure | i, response, t1, t2
      
  ' Start conversion and wait 3ms
  outa[CS]~
  response :=  WriteByte(SDI,$24)
  WriteByte(SDI,$00)
  outa[CS]~~
  Pause_MS(3)

  ' Get Readings
  outa[CS]~
  repeat i from 0 to 8
    ReadResponse[i] := WriteByte(SDI,ReadRes[i])

  outa[CS]~~
  Padc := (ReadResponse[1] << 8) | ReadResponse[3]
  Tadc := (ReadResponse[5] << 8) | ReadResponse[7]

  Padc>>=6
  Tadc>>=6

  Tadc := F.FFloat(Tadc)
  Padc := F.FFloat(Padc)

  t1 := F.FMul(c12,Tadc)
  t2 := F.FMul(b2,Tadc)
  t1 := F.FAdd(b1,t1)
  t1 := F.FMul(t1,Padc)
  t1 := F.FAdd(a0,t1)
  Pcomp := F.FAdd(t1,t2)

  
  Pressure := F.FSub(115.0,50.0)
  Pressure := F.FDiv(Pressure, 1023.0)
  Pressure := F.FMul(Pressure, Pcomp)
  Pressure := F.FAdd(Pressure, 50.0)
  Pressure := F.FMul(Pressure, 10.0)

PRI ReadCoeffs | i
  'PST.Str(String(13, "Reading Coefs..."))
  Pause_MS(1) ' If I remove this, the conversion fails... mystery abounds       
  outa[CS]~  ' Pull Chip Select LOW
  repeat i from 0 to 16
    CoefResponse[i] := WriteByte(SDI,CoefRegs[i])

  outa[CS]~~ 

  a0  := (CoefResponse[1] << 8) | CoefResponse[3]
  b1  := (CoefResponse[5] << 8) | CoefResponse[7]
  b2  := (CoefResponse[9] << 8) | CoefResponse[11]
  c12 := (CoefResponse[13] << 8) | CoefResponse[15]

' a0
  'PST.Str(String(13,"a0:   "))
  'PST.hex(a0,4)
  'PST.Char(" ")
  a0I := (~~a0 ~> 3)
  a0F := (a0 & %0111) 
  a0  := F.FFloat(a0I)
  a0  := F.FAdd(a0,F.FDiv(F.FFloat(a0F),8.0))
  'PST.Str(String("   a0:  "))
  'PST.Str(FS.FloatToString(a0))
  
'b1
  'PST.Str(String(13,"b1:   "))
  'PST.hex(b1,4)
  'PST.Char(" ")
  b1I := (~~b1 ~> 13)
  b1F := (b1 & $1FFF)
  b1  := F.FFloat(b1I)
  b1  := F.FAdd(b1,F.FDiv(F.FFloat(b1F),8192.0))
  'PST.Str(String("   b1:  "))
  'PST.Str(FS.FloatToString(b1))

'b2
  'PST.Str(String(13,"b2:   "))
  'PST.hex(b2,4)
  'PST.Char(" ")
  b2I := (~~b2 ~> 14)
  b2F := (b2 & $3FFF)
  b2  := F.FFloat(b2I)
  b2  := F.Fadd(b2,F.FDiv(F.FFloat(b2F), 16384.0))
  'PST.Str(String("   b2:  "))
  'PST.Str(FS.FloatToString(b2))
  

'c12
  'PST.Str(String(13,"c12:  "))
  'PST.hex(c12,4)
  'PST.Char(" ")
  c12  := F.Fdiv(F.FFloat(c12), 16777216.0) 
  'PST.Str(String("  c12:  "))
  'PST.Str(FS.FloatToString(c12))
  'PST.NewLine

PRI WriteByte (txpin, command) | response
' This will transmit a byte to a device on the txpin
' using the chip select pin (cspin)
  outa[SCK]~ 'Drop Clock
  command ><= 8
  repeat 8
    outa[txpin] := command & $01 'Set output bit
    command >>=1
    outa[SCK]~~ 'Raise Clock
    response := (response<<1) + ina[SDO]
    outa[SCK]~ 'Drop Clock
  return response & $ff

PRI Pause_MS(mS)
  waitcnt(clkfreq/1000 * mS + cnt)