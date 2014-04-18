''*******************************************************************
''*  File       : HTU21D                                            *
''*  Purpose    : Provide an interface to the HTU21D sensor,        *
''*               reading humidity and temperature                  *
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
 
  SCK    = 28
  SDA    = 29

VAR

byte ACK, checksum, msb, lsb
'long temperature, humidity


OBJ
  PST    : "Parallax Serial Terminal"
  F     : "FloatMath"
  FS    : "FloatString"


'PUB Main
'  PST.Start(115200)                                        ' Start the Parallax Serial Terminal cog                
'  PST.Str(String("DEBUG SERIAL TERMINAL:"))       ' Heading
'  StartSensor
'  repeat
'    ReadTemp
'    ReadHumid
'    Pause_MS(1000)

PUB StartSensor

  ' Set SCK and SDA to output and high
  ' We wait 15 mS for the sensor to stabalize
  dira[SCK]~~
  dira[SDA]~~
  outa[SCK]~~
  outa[SDA]~~
  Pause_MS(15) 'Wait 15 mS

  ' Do a soft reset
  StartTrans
  ACK := SendCmd($80)
  ACK := SendCmd($FE)
  StopTrans

  Pause_MS(15) 'Wait 15 mS


PUB ReadTemp : temperature
  ' Trigger No Hold Master Temp Measurement
  StartTrans
  ACK := SendCmd($80)  ' I2C Address + write
  ACK := SendCmd($F3)  ' Command to start temperature conversion
  ACK := 1
  repeat while ACK&$1==1
    StartTrans
    ACK := SendCmd($81)

  ' Read 3 bytes from the sensor, the MSB, LSB, and Checksum
  ' The MSB and LSB have ACK from the micro, the checksum
  ' is NACK followed by the stop sequence.

  msb := ReadByte(0)
  lsb := ReadByte(0)
  temperature := (msb << 8) |  lsb
  
  'PST.Str(String(13,"Temperature ADC: $"))
  'PST.hex(temperature,4)
  checksum := ReadByte(1)
  'PST.Str(String(13,"Temperature Checksum: $"))
  'PST.hex(checksum,1)
  StopTrans

  temperature := temperature & $FFFC
  temperature := F.FFloat(temperature)
  temperature := F.FDiv(temperature,65536.0)
  temperature := F.FMul(temperature,175.72)
  temperature := F.FSub(temperature,46.85)
  return temperature
  
  

PUB ReadHumid : humidity
  ' Trigger No Hold Master Humidity Measurement
  StartTrans
  ACK := SendCmd($80)  ' I2C Address + write
  ACK := SendCmd($F5)  ' Command to start humidity conversion
  ACK := 1
  repeat while ACK&$1==1
    StartTrans
    ACK := SendCmd($81)

  ' Read 3 bytes from the sensor, the MSB, LSB, and Checksum
  ' The MSB and LSB have ACK from the micro, the checksum
  ' is NACK followed by the stop sequence.

  msb := ReadByte(0)
  lsb := ReadByte(0)
  humidity := (msb << 8) |  lsb
  
  'PST.Str(String(13,"Humidity ADC: $"))
  'PST.hex(humidity,4)
  checksum := ReadByte(1)
  'PST.Str(String(13,"Humidity Checksum: $"))
  'PST.hex(checksum,1)
  StopTrans

  humidity := humidity & $FFFC
  humidity := F.FFloat(humidity)
  humidity := F.FDiv(humidity,65536.0)
  humidity := F.FMul(humidity,125.0)
  humidity := F.FSub(humidity,6.0)
  return humidity



PRI ReadByte(ackbit) : data
  data := 0
  dira[SDA]~
  repeat 8
    data := (data<<1)|ina[SDA]
    outa[SCK]~~
    outa[SCK]~
    
     
    
  ' Send the ACK/NACK bit  
  dira[SDA]~~
  'PST.Str(String(13,"Setting Ackbit: "))
  'PST.bin(ackbit&$1,1)
  outa[SDA] := ackbit & $1 
  outa[SCK]~~
  outa[SCK]~
  outa[SDA]~
  

PRI StartTrans
  outa[SDA]~~
  dira[SDA]~~ ' Make sure SDA is an output
  outa[SCK]~~
  outa[SDA]~
  outa[SCK]~

PRI StopTrans
  outa[SCK]~~  ' Take Clock High
  outa[SDA]~~  ' Take data line high
  'dira[SCK]~   ' Let lines float
  'dira[SDA]~
  

PRI SendCmd(cmd) : ackbit
  'PST.Str(String(13,"Sending Command: "))
  'PST.bin(cmd,8)

  dira[SCK]~~
  ackbit := 0  ' Initially set the ackbit to 0
  cmd <<= 24  ' Left shift our data 24 bits to line up in 32-bit register
  repeat 8
    outa[SDA] := (cmd <-= 1) & 1 ' Put data on the SDA line
    outa[SCK]~~                   ' Raise the clock to validate the data
    outa[SCK]~                    ' Drop the clock

  ' Now we read in the ACK
  dira[SDA]~                      ' Make SDA an input
  outa[SCK]~~
  ackbit := ina[SDA]              ' Store the ACK
  outa[SCK]~
  dira[SDA]~~
  outa[SDA]~

PRI Pause_MS(mS)
  waitcnt(clkfreq/1000 * mS + cnt)