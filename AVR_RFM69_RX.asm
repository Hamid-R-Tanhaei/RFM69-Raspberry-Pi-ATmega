;================================================;
; RFM69_test1.asm
; Developer : Hamid Reza Tanhaei
; Created: 8/6/2021
; RFM69 module in receiving mode
; continously receiving blocks of 64-byte data from the transmitter
; chip : ATMEL AVR ATmega168pa
; FuseBits: hfuse:0xDE,	lfuse:0x62,	efuse:0x01
; Clock: 1MHz @ internal clock
.INCLUDE "m168padef.inc"
// 
.DEF    temp1			=	R16  
.DEF	temp2			=	R17
.DEF	temp3			=	R18
.DEF	del_cntr		=	R19
.DEF	spi_addr_reg	=	R20
//////////////////////////////////
#define	LED1_ddr	DDRB,4
#define	LED1_out	PORTB,4
//
#define	LED2_ddr	DDRB,5
#define	LED2_out	PORTB,5
//
#define	Key_ddr		DDRB,3
#define	Key_in		PINB,3
#define	Key_out		PORTB,3
//
#define	RF_SCK_DDR		DDRD,5
#define	RF_SCK_OUT		PORTD,5

#define	RF_MISO_DDR		DDRD,7
#define	RF_MISO_IN		PIND,7

#define	RF_MOSI_DDR		DDRD,6
#define	RF_MOSI_OUT		PORTD,6

#define	RF_RST_DDR		DDRB,6
#define	RF_RST_OUT		PORTB,6

#define	RF_NSS_DDR		DDRB,7
#define	RF_NSS_OUT		PORTB,7

#define RF_D0_DDR		DDRB,2
#define RF_D0_IN		PINB,2

#define RF_D1_DDR		DDRB,1
#define RF_D1_IN		PINB,1

#define RF_D2_DDR		DDRB,0
#define RF_D2_IN		PINB,0

#define RF_D5_DDR		DDRD,4
#define RF_D5_IN		PIND,4

#define	RF_Rx_buffer	0x0100

// Common Configuration Registers:
#define	RegFifo			0x00
#define	RegOpMode		0x01
#define	RegDataModul	0x02
#define	RegBitrateMsb	0x03
#define	RegBitrateLsb	0x04
#define	RegFdevMsb		0x05
#define	RegFdevLsb		0x06
#define	RegFrfMsb		0x07
#define	RegFrfMid		0x08
#define	RegFrfLsb		0x09
#define	RegOsc1			0x0A
#define	RegAfcCtrl		0x0B
#define	RegListen1		0x0D
#define	RegListen2		0x0E
#define	RegListen3		0x0F
#define	RegVersion		0x10
// Transmitter Registers:
#define	RegPaLevel		0x11
#define	RegPaRamp 		0x12
#define	RegOcp			0x13
// Receiver Registers:
#define	RegLna			0x18
#define	RegRxBw			0x19
#define	RegAfcBw		0x1A
#define	RegOokPeak		0x1B
#define	RegOokAvg		0x1C
#define	RegOokFix		0x1D
#define	RegAfcFei		0x1E
#define	RegAfcMsb		0x1F
#define	RegAfcLsb		0x20
#define	RegFeiMsb		0x21
#define	RegFeiLsb		0x22
#define	RegRssiConfig	0x23
#define	RegRssiValue	0x24
// IRQ and Pin Mapping Registers:
#define	RegDioMapping1	0x25
#define	RegDioMapping2	0x26
#define	RegIrqFlags1	0x27
#define	RegIrqFlags2	0x28
#define	RegRssiThresh	0x29
#define	RegRxTimeout1	0x2A
#define	RegRxTimeout2	0x2B
// Packet Engine Registers:
#define	RegPreambleMsb	0x2c
#define	RegPreambleLsb	0x2d
#define	RegSyncConfig	0x2e
#define	RegSyncValue1	0x2f
#define	RegSyncValue2	0x30
#define	RegSyncValue3	0x31
#define	RegSyncValue4	0x32
#define	RegSyncValue5	0x33
#define	RegSyncValue6	0x34
#define	RegSyncValue7	0x35
#define	RegSyncValue8	0x36
#define	RegPacketConfig1	0x37
#define	RegPayloadLength	0x38
#define	RegNodeAdrs			0x39
#define	RegBroadcastAdrs	0x3A
#define	RegAutoModes		0x3B
#define	RegFifoThresh		0x3C
#define	RegPacketConfig2	0x3D
#define	RegAesKey1		0x3E
#define	RegAesKey2		0x3F
#define	RegAesKey3		0x40
#define	RegAesKey4		0x41
#define	RegAesKey5		0x42
#define	RegAesKey6		0x43
#define	RegAesKey7		0x44
#define	RegAesKey8		0x45
#define	RegAesKey9		0x46
#define	RegAesKey10		0x47
#define	RegAesKey11		0x48
#define	RegAesKey12		0x49
#define	RegAesKey13		0x4A
#define	RegAesKey14		0x4B
#define	RegAesKey15		0x4C
#define	RegAesKey16		0x4D
// Test Registers:
#define	RegTestLna		0x58
#define	RegTestPa1		0x5A
#define	RegTestPa2		0x5C
#define	RegTestDagc		0x6F
#define	RegTestAfc		0x71
//
//
.MACRO	spi_bit_out
	SBRC	@0, @1
	SBI		RF_MOSI_OUT
	SBRS	@0, @1
	CBI		RF_MOSI_OUT
	NOP
	SBI		RF_SCK_OUT
	CBI		RF_SCK_OUT
.ENDMACRO
//
.MACRO	spi_bit_in
	NOP
	SBIC	RF_MISO_IN
	SBR		@0, @1
	SBIS	RF_MISO_IN
	CBR		@0, @1
	SBI		RF_SCK_OUT
	CBI		RF_SCK_OUT
.ENDMACRO
//
.MACRO	delay_ms	// at clk=1MHz
	LDI		del_cntr,@0
	delay_xms:
	RCALL	delay_1ms
	DEC		del_cntr
	BRNE	delay_xms
.ENDMACRO
/////////////////////////////////////
.org $00
JMP RST  
//.org $06
//JMP watchdog  

//.org $16
//JMP Timer1_cmp_a
.org $40
RST:
CLI
// Stack Pointer
	LDI		temp1,High(RAMEND)
	OUT		SPH,temp1
	LDI		temp1,Low(RAMEND)
	OUT		SPL,temp1
//
delay_ms	100
// turn on WDT on Reset mode (8 sec):
//	LDS		temp2,WDTCSR
//	ORI		temp2,(1<<WDCE) |(1<<WDE)
//	STS		WDTCSR,temp2
//	LDI		temp2,(1<<WDP3)|(1<<WDE)|(1<<WDP0)
//	STS		WDTCSR,temp2
//-----------------------------
CLR		temp1
LDI		temp1,(1<<PRTWI)|(1<<PRSPI)|(1<<PRTIM2)|(1<<PRTIM0)|(1<<PRTIM1)|(1<<PRUSART0)|(1<<PRADC)
STS		PRR,temp1 // power reduction register
//
// Enable pull-up
CLR		temp1
OUT		MCUCR,temp1
//
// Disable any pull-up
//IN		temp1,MCUCR
//ORI		temp1,(1<<PUD)
//OUT		MCUCR,temp1
//
//CLR		temp1
//LDI		temp1,(1<<PRTWI)|(1<<PRSPI)|(1<<PRTIM2)|(1<<PRTIM0)|(1<<PRTIM1)|(1<<PRUSART0)|(1<<PRADC)
//STS		PRR,temp1 // power reduction register
//
SBI	LED1_ddr
SBI	LED2_ddr
CBI	Key_ddr
SBI	Key_out // make pull-up

SBI	RF_NSS_OUT
SBI	RF_NSS_DDR
CBI	RF_SCK_OUT
SBI	RF_SCK_DDR
CBI	RF_MOSI_OUT
SBI	RF_MOSI_DDR
CBI	RF_MISO_DDR
CBI	RF_D0_DDR
CBI	RF_D1_DDR
CBI	RF_D2_DDR
CBI	RF_D5_DDR
SBI	RF_RST_OUT
SBI	RF_RST_DDR
delay_ms	1
//CBI	RF_RST_DDR
CBI	RF_RST_OUT
delay_ms	200

//
//****************************************************************//
Main_Loop: 
	//
	SBI		LED1_out
	SBI		LED2_out
	delay_ms	100
	CBI		LED1_out
	CBI		LED2_out
	delay_ms	100
	//	check module version:
	LDI		temp1, RegVersion
	LDI		temp2, 0x00
	RCALL	RFM_single_read 
	CPI		temp2, 0x24
	BRNE	verify_error
	// initialize RFM69 module
	RCALL	RFM_config
	//
	LDI		temp1, RegOpMode
	LDI		temp2, 0x10		//RX mode
	RCALL	RFM_single_write
	//
	wait_rx_mode:
	NOP
	SBIS	RF_D0_IN
	RJMP	wait_rx_mode
	SBI		LED1_out
	LDI		temp3, 64
	LDI		YH, HIGH(RF_Rx_buffer)
	LDI		YL, LOW(RF_Rx_buffer)
	RCALL	RFM_fifo_read
	RCALL	delay_1ms
	RCALL	delay_1ms
	CBI		LED1_out
	RJMP	wait_rx_mode
	//
	verify_error:
	SBI		LED2_out
	NOP
	RJMP	verify_error
RJMP	Main_Loop
//
//*************************************************************************
RFM_config:
	//
	LDI		temp1, RegOpMode
	LDI		temp2, 0x00		//	sleep mode
	RCALL	RFM_single_write
	//
	LDI		temp1, RegDataModul
	LDI		temp2, 0x00
	RCALL	RFM_single_write
	//
	// BitRate(Kbps): 0x682B -> 1.2, 0x3415 -> 2.4, 0x1A0B -> 4.8,
	// 0X0D05 -> 9.6, 0X0683 -> 19.2,  0X0341 -> 38.4
	LDI		temp1, RegBitrateMsb
	LDI		temp2, 0x06		 // 19.2Kbps
	RCALL	RFM_single_write
	LDI		temp1, RegBitrateLsb
	LDI		temp2, 0x83
	RCALL	RFM_single_write
	//	
	// f_dev = Fstep * Fdev(13:0)
	// 0x0052 -> 5 KHz, 0x00A3 -> 10 KHz, 0x0147 -> 20KHz,
	// 0x01EB -> 30KHz, 0x028F -> 40KHz, 0x0333 -> 50KHz,
	// 0x047B -> 70KHz, 0x051F -> 80KHz, 0x0667 -> 100KHz,
	// 0x099B -> 150KHz, 0x0CCE -> 200KHz,
	LDI		temp1, RegFdevMsb
	LDI		temp2, 0x03		// 50KHz
	RCALL	RFM_single_write
	LDI		temp1, RegFdevLsb
	LDI		temp2, 0x33
	RCALL	RFM_single_write
	//
	// Frf: 434 MHz
	LDI		temp1, RegFrfMsb
	LDI		temp2, 0x6C
	RCALL	RFM_single_write
	LDI		temp1, RegFrfMid
	LDI		temp2, 0x80
	RCALL	RFM_single_write
	LDI		temp1, RegFrfLsb
	LDI		temp2, 0x00
	RCALL	RFM_single_write
	//
	LDI		temp1, RegLna
	LDI		temp2, 0x88
	RCALL	RFM_single_write
	//
	// RxBw(KHz): 0b01010100 -> 20, 0b01001100 -> 25, 0b01000100 -> 31, 0b01010011 -> 41
	// 0b01001011 -> 50, 0b01000011 -> 62, 0b01010010 -> 83, 0b01001010 -> 100
	// 0b01000010 -> 125, 0b01010001 -> 166, 0b01001001 -> 200, 0b01000001 -> 250
	// 0b01010000 -> 333, 0b01001000 -> 400, 0b01000000 -> 500
	// RX BW 166 KHz
	LDI		temp1, RegRxBw
	LDI		temp2, 0b01010001 //166KHz
	RCALL	RFM_single_write
	//
	LDI		temp1, RegRssiThresh
	LDI		temp2, 0xE4
	RCALL	RFM_single_write
	//
	LDI		temp1, RegPreambleMsb
	LDI		temp2, 0x00
	RCALL	RFM_single_write
	//
	LDI		temp1, RegPreambleLsb
	LDI		temp2, 0x04
	RCALL	RFM_single_write
	//
	LDI		temp1, RegSyncConfig
	LDI		temp2, 0x98
	RCALL	RFM_single_write
	//
	LDI		temp1, RegSyncValue1
	LDI		temp2, 0x55
	RCALL	RFM_single_write
	//
	LDI		temp1, RegSyncValue2
	LDI		temp2, 0x63
	RCALL	RFM_single_write
	//
	LDI		temp1, RegSyncValue3
	LDI		temp2, 0xAA
	RCALL	RFM_single_write
	//
	LDI		temp1, RegSyncValue4
	LDI		temp2, 0x79
	RCALL	RFM_single_write
	//
	//RegPacketConfig1: bit(7): 0->fixed_length, 1-> variable_length
	// bit(6-5):DcFree:00->none, 01->Manchester, 10->Whitening
	// bit(4):CrcOn=1, bit(3):CrcAutoClearOff=0, bit(2-1):AddressFiltering:00->none, 01->NodeAddress
	LDI		temp1, RegPacketConfig1
	LDI		temp2, 0b01010000 //0x50
	RCALL	RFM_single_write
	//
	//RegPacketConfig2: bit(7-4): InterPacketRxDelay -> Tdelay=(2^InterpacketRxDelay)/BitRate
	//bit(1): AutoRxRestartOn = 1
	LDI		temp1, RegPacketConfig2
	LDI		temp2, 0b01000010 //0x42
	RCALL	RFM_single_write
	//
	LDI		temp1, RegPayloadLength
	LDI		temp2, 0x40
	RCALL	RFM_single_write
	//
	LDI		temp1, RegTestDagc
	LDI		temp2, 0x30
	RCALL	RFM_single_write
	//
	LDI		temp1, RegTestLna
	LDI		temp2, 0x2D		// 0x2D: High-sens, 0x1B: Normal-sens
	RCALL	RFM_single_write
	//
	LDI		temp1, RegDioMapping1
	LDI		temp2, 0x40
	RCALL	RFM_single_write
	//
RET
//*************************************************************************
RFM_single_write:	// temp1: Reg addr byte, temp2: data byte
	CBI		RF_NSS_OUT
	ORI		temp1, 0x80
	// Address:
	spi_bit_out	temp1, 7
	spi_bit_out	temp1, 6
	spi_bit_out	temp1, 5
	spi_bit_out	temp1, 4
	spi_bit_out	temp1, 3
	spi_bit_out	temp1, 2
	spi_bit_out	temp1, 1
	spi_bit_out	temp1, 0
	// Data:
	spi_bit_out	temp2, 7
	spi_bit_out	temp2, 6
	spi_bit_out	temp2, 5
	spi_bit_out	temp2, 4
	spi_bit_out	temp2, 3
	spi_bit_out	temp2, 2
	spi_bit_out	temp2, 1
	spi_bit_out	temp2, 0
	NOP
	SBI		RF_NSS_OUT
RET
//*************************************************************************
RFM_single_read:	// temp1: Reg addr byte, temp2: data byte
	CBI		RF_NSS_OUT
	NOP
	// Address:
	spi_bit_out	temp1,7
	spi_bit_out	temp1,6
	spi_bit_out	temp1,5
	spi_bit_out	temp1,4
	spi_bit_out	temp1,3
	spi_bit_out	temp1,2
	spi_bit_out	temp1,1
	spi_bit_out	temp1,0
	// data:
	spi_bit_in	temp2,0x80
	spi_bit_in	temp2,0x40
	spi_bit_in	temp2,0x20
	spi_bit_in	temp2,0x10
	spi_bit_in	temp2,0x08
	spi_bit_in	temp2,0x04
	spi_bit_in	temp2,0x02
	spi_bit_in	temp2,0x01
	NOP
	SBI		RF_NSS_OUT
RET
//*************************************************************************
RFM_fifo_write:	// temp1: Reg_Addr, temp3: no.of.bytes, XH:XL: data, temp2: temp_data
	CBI		RF_NSS_OUT
	LDI		temp1, (0x80 | RegFifo)
	// Address:
	spi_bit_out	temp1, 7
	spi_bit_out	temp1, 6
	spi_bit_out	temp1, 5
	spi_bit_out	temp1, 4
	spi_bit_out	temp1, 3
	spi_bit_out	temp1, 2
	spi_bit_out	temp1, 1
	spi_bit_out	temp1, 0
	// burst data:
	wr_nxt_byte:
	LD		temp2,X+
	spi_bit_out	temp2, 7
	spi_bit_out	temp2, 6
	spi_bit_out	temp2, 5
	spi_bit_out	temp2, 4
	spi_bit_out	temp2, 3
	spi_bit_out	temp2, 2
	spi_bit_out	temp2, 1
	spi_bit_out	temp2, 0
	DEC		temp3
	BRNE	wr_nxt_byte
	SBI		RF_NSS_OUT
RET
//***********************************************************
RFM_fifo_read:	// temp1: Reg_Addr, temp3: no.of.bytes, YH:YL: data, temp2: temp_data
	CBI		RF_NSS_OUT
	LDI		temp1, RegFifo
	// Address:
	spi_bit_out	temp1, 7
	spi_bit_out	temp1, 6
	spi_bit_out	temp1, 5
	spi_bit_out	temp1, 4
	spi_bit_out	temp1, 3
	spi_bit_out	temp1, 2
	spi_bit_out	temp1, 1
	spi_bit_out	temp1, 0
	// burst data:
	rd_nxt_byte:
	spi_bit_in	temp2,0x80
	spi_bit_in	temp2,0x40
	spi_bit_in	temp2,0x20
	spi_bit_in	temp2,0x10
	spi_bit_in	temp2,0x08
	spi_bit_in	temp2,0x04
	spi_bit_in	temp2,0x02
	spi_bit_in	temp2,0x01
	ST		Y+,temp2
	DEC		temp3
	BRNE	rd_nxt_byte
	SBI		RF_NSS_OUT
RET
//***********************************************************
delay_1ms:	// 3clks //@clk=1MHz
	PUSH	del_cntr	//2clk
	LDI		del_cntr,247 //1clk
delay_1_loop:
	NOP
	DEC		del_cntr //1clk
	BRNE	delay_1_loop //2clk
	POP		del_cntr	//2clk
RET	//4clk
