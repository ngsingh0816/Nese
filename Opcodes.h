//
//  Opcodes.h
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "types.h"

#define None		@"None"
#define ZeroPage	@"ZeroPage"
#define ZeroPageX	@"ZeroPage X"
#define ZeroPageY	@"ZeroPage Y"
#define Absolute	@"Absolute"
#define AbsoluteX	@"Absolute X"
#define AbsoluteY	@"Absolute Y"
#define Immediate	@"Immediate"
#define Indirect	@"Indirect"
#define IndexedIndirect @"Indexed Indirect"
#define IndirectIndexed	@"Indirect Indexed"
#define Relative	@"Relative"
#define Implied		@"Implied"
#define Accumulator	@"Accumulator"

typedef struct
{
	NSString* name;
	u8 cycles;
	NSString* mode;
	u16 (*exec)();
} Opcode;
extern Opcode opcodes[0x100];

void CreateCodes();

extern u16 BRK();
extern u16 ADC(u8 data);
extern u16 AND(u8 data);
extern u16 CP(u8 reg, u8 data);
extern u16 EOR(u8 data);
extern u16 LD(u8* reg, u8 data);
extern u16 OR(u8* reg, u8 data);
extern u16 SBC(u8 data);
extern u16 DEC(u8* reg);
extern u16 INC(u8* reg);
extern u16 PH(u8 reg);
extern u16 PL(u8* reg);
extern u16 T(u8 data, u8* reg);
extern u16 ASL(u8* place);
extern u16 BIT(u8 data);
extern u16 DEC(u8* data);
extern u16 INC(u8* data);
extern u16 LSR(u8* data);
extern u16 ROL(u8* data);
extern u16 ROR(u8* data);
extern u16 BRANCH(bool condition);
extern u16 JMP(u16 addr);
extern u16 JSR(u16 addr);
