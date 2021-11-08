# project: test RFM69 module on Linux Raspberry pi 3B+
# Developer : Hamid Reza Tanhaei
# RFM module in transmitting mode
# continuously transmitting blocks of 64-byte data
#
from time import sleep
import spidev
import RPi.GPIO as Gpio
#from decorator import DEF
LED1 = 21
LED2 = 16
KEY1 = 12
KEY2 = 5
RFM_RST = 23
RFM_D0 = 19
RFM_D1 = 13
RFM_D2 = 6
RFM_D3 = 20
RFM_D4 = 26
RFM_D5 = 22
# RFM69 Register Addresses:
RegFifo = 0x00
RegOpMode = 0x01
RegDataModul = 0x02
RegBitrateMsb = 0x03
RegBitrateLsb = 0x04
RegFdevMsb = 0x05
RegFdevLsb = 0x06
RegFrfMsb = 0x07
RegFrfMid = 0x08
RegFrfLsb = 0x09
RegOsc1 = 0x0A
RegAfcCtrl = 0x0B
RegListen1 = 0x0D
RegListen2 = 0x0E
RegListen3 = 0x0F
RegVersion = 0x10
# Transmitter Registers:
RegPaLevel = 0x11
RegPaRamp = 0x12
RegOcp = 0x13
# Receiver Registers:
RegLna = 0x18
RegRxBw = 0x19
RegAfcBw = 0x1A
RegOokPeak = 0x1B
RegOokAvg = 0x1C
RegOokFix = 0x1D
RegAfcFei = 0x1E
RegAfcMsb = 0x1F
RegAfcLsb = 0x20
RegFeiMsb = 0x21
RegFeiLsb = 0x22
RegRssiConfig = 0x23
RegRssiValue = 0x24
# IRQ and Pin Mapping Registers:
RegDioMapping1 = 0x25
RegDioMapping2 = 0x26
RegIrqFlags1 = 0x27
RegIrqFlags2 = 0x28
RegRssiThresh = 0x29
RegRxTimeout1 = 0x2A
RegRxTimeout2 = 0x2B
# Packet Engine Registers:
RegPreambleMsb = 0x2c
RegPreambleLsb = 0x2d
RegSyncConfig = 0x2e
RegSyncValue1 = 0x2f
RegSyncValue2 = 0x30
RegSyncValue3 = 0x31
RegSyncValue4 = 0x32
RegSyncValue5 = 0x33
RegSyncValue6 = 0x34
RegSyncValue7 = 0x35
RegSyncValue8 = 0x36
RegPacketConfig1 = 0x37
RegPayloadLength = 0x38
RegNodeAdrs = 0x39
RegBroadcastAdrs = 0x3A
RegAutoModes = 0x3B
RegFifoThresh = 0x3C
RegPacketConfig2 = 0x3D
RegAesKey1 = 0x3E
RegAesKey2 = 0x3F
RegAesKey3 = 0x40
RegAesKey4 = 0x41
RegAesKey5 = 0x42
RegAesKey6 = 0x43
RegAesKey7 = 0x44
RegAesKey8 = 0x45
RegAesKey9 = 0x46
RegAesKey10 = 0x47
RegAesKey11 = 0x48
RegAesKey12 = 0x49
RegAesKey13 = 0x4A
RegAesKey14 = 0x4B
RegAesKey15 = 0x4C
RegAesKey16 = 0x4D
# Test Registers:
RegTestLna = 0x58
RegTestPa1 = 0x5A
RegTestPa2 = 0x5C
RegTestDagc = 0x6F
RegTestAfc = 0x71
#
# config_len = 21
RFM69_Config = [
    [RegOpMode, 0x00],  # sleep mode
    [RegDataModul, 0x00],
    [RegBitrateMsb, 0x06],
    [RegBitrateLsb, 0x83],  # 19.2 Kbps
    [RegFdevMsb, 0x03],
    [RegFdevLsb, 0x33],  # 50 KHz
    [RegFrfMsb, 0x6C],
    [RegFrfMid, 0x80],
    [RegFrfLsb, 0x00],  # 434 MHz
    [RegRxBw, 0x4A], # RX BW 100 KHz
    [RegPaLevel, 0x7F],
    [RegOcp, 0x00],
    [RegPreambleMsb, 0x00],
    [RegPreambleLsb, 0x08],
    [RegSyncConfig, 0x98],
    [RegSyncValue1, 0x55],
    [RegSyncValue2, 0x63],
    [RegSyncValue3, 0xAA],
    [RegSyncValue4, 0x79],
    [RegPacketConfig1, 0x50],
    [RegPacketConfig2, 0x42],
    [RegPayloadLength, 0x40]
]

TX_pyld_len = 0x40  # Reg: RFM_RegPyldLen
dat = 0x00
TX_data = []
for idx in range(TX_pyld_len):
    dat += 0x01
    TX_data.append(dat)

print('TX data:', TX_data)

Gpio.setwarnings(False)
Gpio.cleanup()
Gpio.setmode(Gpio.BCM)
Gpio.setup(LED1, Gpio.OUT, initial=Gpio.LOW)
Gpio.setup(LED2, Gpio.OUT, initial=Gpio.LOW)
Gpio.setup(KEY1, Gpio.IN)
Gpio.setup(KEY2, Gpio.IN)
Gpio.setup(RFM_D0, Gpio.IN)
Gpio.setup(RFM_D1, Gpio.IN)
Gpio.setup(RFM_D2, Gpio.IN)
Gpio.setup(RFM_D3, Gpio.IN)
Gpio.setup(RFM_D4, Gpio.IN)
Gpio.setup(RFM_D5, Gpio.IN)
Gpio.output(LED2, Gpio.HIGH)

# reset RFM module
print('Reset RFM module')
sleep(1)
Gpio.setup(RFM_RST, Gpio.OUT, initial=Gpio.HIGH)
sleep(0.1)
Gpio.setup(RFM_RST, Gpio.IN, Gpio.PUD_DOWN)
sleep(1)
#
# We only have SPI bus 0 available to us on the Pi
bus = 0
# Device is the chip select pin CE0
device = 0
# Enable SPI
spi = spidev.SpiDev()
# Open a connection to a specific bus and device (chip select pin)
spi.open(bus, device)
print('Spi opened')
# Set SPI speed and mode
spi.max_speed_hz = 1000000
spi.mode = 0  # (CPOL & CPHA = 0 & 0)
#
msg = [RegVersion, 0x00]
result = spi.xfer2(msg)
print('RFM version:', hex(result.pop()))
#
# Initialize RFM69:
for i in range(len(RFM69_Config)):
    msg = [0x80 | RFM69_Config[i][0], RFM69_Config[i][1]]
    result = spi.xfer2(msg)
    sleep(0.01)
#
ReadBack_Regs = []
for i in range(len(RFM69_Config)):
    msg = [RFM69_Config[i][0], RFM69_Config[i][1]]
    result = spi.xfer2(msg)
    ReadBack_Regs.append(result.pop())
    sleep(0.01)
print('RFM Regs:', ReadBack_Regs)
msg = [0x80 | RegOpMode, 0x04]
spi.xfer2(msg)
cntr = 0

while Gpio.input(KEY1) == 1:
    if True:  # Gpio.input(KEY2) == 0:
        Gpio.output(LED1, Gpio.HIGH)

        TX_data[3] += 0x01
        msg = [0x80 | RegFifo]
        msg.extend(TX_data)
        spi.writebytes2(msg)
        cntr += 1
        print('TX start...', cntr)
        msg = [0x80 | RegOpMode, 0x0C]
        spi.xfer2(msg)
        Tx_counter = 0
        while Gpio.input(RFM_D0) == 0:
            sleep(0.001)
            Tx_counter += 1
            if Tx_counter > 1000:
                break
        print('IRQ TxDone after:', Tx_counter, 'ms')
        msg = [0x80 | RegOpMode, 0x04]
        spi.xfer2(msg)
        Gpio.output(LED1, Gpio.LOW)
        sleep(1)

spi.close()
print('Spi closed')
Gpio.cleanup()
