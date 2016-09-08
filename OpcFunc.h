//
//  OpcFunc.h
//  Nese
//
//  Created by MILAP on 4/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Opcodes.h"
#import "CPU.h"
#import "Mappers.h"
#import "Rom.h"

// Implied
u16 CLC()
{
	SetCarryFlag(0);
	return 0;
}

u16 CLD()
{
	SetDecimalMode(0);
	return 0;
}

u16 CLI()
{
	SetInterruptFlag(0);
	inVBLANK = false;
	return 0;
}

u16 CLV()
{
	SetOverflowFlag(0);
	return 0;
}

u16 DEX()
{
	return DEC(&X);
}

u16 DEY()
{
	return DEC(&Y);
}

u16 INX()
{
	return INC(&X);
}

u16 INY()
{
	return INC(&Y);
}

u16 NOP()
{
	return 0;
}

u16 PHA()
{
	return PH(A);
}

u16 PHP()
{
	return PH(P);
}

u16 PLA()
{
	return PL(&A);
}

u16 PLP()
{
	return PL(&P);
}

u16 RTI()
{
	P = Pop();
	pc = Pop16();
	inVBLANK = false;
	return pc;
}

u16 RTS()
{
	pc = Pop16() + 1;
	return pc;
}

u16 SEC()
{
	SetCarryFlag(1);
	return 1;
}

u16 SED()
{
	SetDecimalMode(1);
	return 1;
}

u16 SEI()
{
	SetInterruptFlag(1);
	return 1;
}

u16 TAX()
{
	return T(A, &X);
}

u16 TAY()
{
	return T(A, &Y);
}

u16 TSX()
{
	return T(sp, &X);
}

u16 TXA()
{
	return T(X, &A);
}

u16 TXS()
{
	return T(X, &sp);
}

u16 TYA()
{
	return T(Y, &A);
}

// Zero Page
u16 ZeroPage_ADC()
{
	return (ADC(ReadZeroPage(&pc)));
}

u16 ZeroPage_AND()
{
	return (AND(ReadZeroPage(&pc)));
}

u16 ZeroPage_ASL()
{
	u16 backup = pc;
	u8 data = ReadZeroPage(&pc);
	u16 ret = ASL(&data);
	WriteZeroPage(&backup, data);
	return ret;
}

u16 ZeroPage_BIT()
{
	return (BIT(ReadZeroPage(&pc)));
}

u16 ZeroPage_CMP()
{
	return (CP(A, ReadZeroPage(&pc)));
}

u16 ZeroPage_CPX()
{
	return (CP(X, ReadZeroPage(&pc)));
}

u16 ZeroPage_CPY()
{
	return (CP(Y, ReadZeroPage(&pc)));
}

u16 ZeroPage_DEC()
{
	u16 backup = pc;
	u8 data = ReadZeroPage(&pc);
	u16 ret = DEC(&data);
	WriteZeroPage(&backup, data);
	return ret;
	
}

u16 ZeroPage_EOR()
{
	return (EOR(ReadZeroPage(&pc)));
}

u16 ZeroPage_INC()
{
	u16 backup = pc;
	u8 data = ReadZeroPage(&pc);
	u16 ret = INC(&data);
	WriteZeroPage(&backup, data);
	return ret;
}

u16 ZeroPage_LDA()
{
	return (LD(&A, ReadZeroPage(&pc)));
}

u16 ZeroPage_LDX()
{
	return (LD(&X, ReadZeroPage(&pc)));
}

u16 ZeroPage_LDY()
{
	return (LD(&Y, ReadZeroPage(&pc)));
}

u16 ZeroPage_LSR()
{
	u16 backup = pc;
	u8 data = ReadZeroPage(&pc);
	u16 ret = LSR(&data);
	WriteZeroPage(&backup, data);
	return ret;
}

u16 ZeroPage_ROL()
{
	u16 backup = pc;
	u8 data = ReadZeroPage(&pc);
	u16 ret = ROL(&data);
	WriteZeroPage(&backup, data);
	return ret;
}

u16 ZeroPage_ROR()
{
	u16 backup = pc;
	u8 data = ReadZeroPage(&pc);
	u16 ret = ROR(&data);
	WriteZeroPage(&backup, data);
	return ret;
}

u16 ZeroPage_STA()
{
	return WriteZeroPage(&pc, A);
}

u16 ZeroPage_STX()
{
	return WriteZeroPage(&pc, X);
}

u16 ZeroPage_STY()
{
	return WriteZeroPage(&pc, Y);
}

u16 ZeroPage_ORA()
{
	return (OR(&A, ReadZeroPage(&pc)));
}

u16 ZeroPage_SBC()
{
	return SBC(ReadZeroPage(&pc));
}

// Zero Page Y
u16 ZeroPageY_LDX()
{
	return (LD(&X, ReadZeroPageReg(&pc, Y)));
}

u16 ZeroPageY_STX()
{
	return WriteZeroPageReg(&pc, Y, X);
}

// Zero Page X
u16 ZeroPageX_ADC()
{
	return ADC(ReadZeroPageReg(&pc, X));
}

u16 ZeroPageX_AND()
{
	return AND(ReadZeroPageReg(&pc, X));
}

u16 ZeroPageX_ASL()
{
	u16 backup = pc;
	u8 data = ReadZeroPageReg(&pc, X);
	u16 ret =  ASL(&data);
	WriteZeroPageReg(&backup, X, data);
	return ret;
}

u16 ZeroPageX_CMP()
{
	return CP(A, ReadZeroPageReg(&pc, X));
}

u16 ZeroPageX_DEC()
{
	u16 backup = pc;
	u8 data = ReadZeroPageReg(&pc, X);
	u16 ret =  DEC(&data);
	WriteZeroPageReg(&backup, X, data);
	return ret;	
}

u16 ZeroPageX_EOR()
{
	return EOR(ReadZeroPageReg(&pc, X));
}

u16 ZeroPageX_INC()
{
	u16 backup = pc;
	u8 data = ReadZeroPageReg(&pc, X);
	u16 ret =  INC(&data);
	WriteZeroPageReg(&backup, X, data);
	return ret;	
}

u16 ZeroPageX_LDA()
{
	return LD(&A, ReadZeroPageReg(&pc, X));
}

u16 ZeroPageX_LDY()
{
	return LD(&Y, ReadZeroPageReg(&pc, X));
}

u16 ZeroPageX_LSR()
{
	u16 backup = pc;
	u8 data = ReadZeroPageReg(&pc, X);
	u16 ret =  LSR(&data);
	WriteZeroPageReg(&backup, X, data);
	return ret;	
}

u16 ZeroPageX_ORA()
{
	return OR(&A, ReadZeroPageReg(&pc, X));
}

u16 ZeroPageX_ROL()
{
	u16 backup = pc;
	u8 data = ReadZeroPageReg(&pc, X);
	u16 ret =  ROL(&data);
	WriteZeroPageReg(&backup, X, data);
	return ret;
}

u16 ZeroPageX_ROR()
{
	u16 backup = pc;
	u8 data = ReadZeroPageReg(&pc, X);
	u16 ret =  ROR(&data);
	WriteZeroPageReg(&backup, X, data);
	return ret;	
}

u16 ZeroPageX_SBC()
{
	return SBC(ReadZeroPageReg(&pc, X));
}

u16 ZeroPageX_STA()
{
	return WriteZeroPageReg(&pc, X, A);
}

u16 ZeroPageX_STY()
{
	return WriteZeroPageReg(&pc, X, Y);
}


// Accumulator
u16 Accumulator_ASL()
{
	return ASL(&A);
}

u16 Accumulator_LSR()
{
	return LSR(&A);
}

u16 Accumulator_ROL()
{
	return ROL(&A);
}

u16 Accumulator_ROR()
{
	return ROR(&A);
}

// Absolute X
u16 AbsoluteX_ADC()
{
	return ADC(ReadIndexedAbsolute(&pc, X));
}

u16 AbsoluteX_AND()
{
	return AND(ReadIndexedAbsolute(&pc, X));
}

u16 AbsoluteX_CMP()
{
	return CP(A, ReadIndexedAbsolute(&pc, X));
}

u16 AbsoluteX_EOR()
{
	return EOR(ReadIndexedAbsolute(&pc, X));
}

u16 AbsoluteX_LDA()
{
	return LD(&A, ReadIndexedAbsolute(&pc, X));
}

u16 AbsoluteX_LDY()
{
	return LD(&Y, ReadIndexedAbsolute(&pc, X));
}

u16 AbsoluteX_ORA()
{
	return OR(&A, ReadIndexedAbsolute(&pc, X));
}

u16 AbsoluteX_SBC()
{
	return SBC(ReadIndexedAbsolute(&pc, X));
}

u16 AbsoluteX_ASL()
{
	u16 backup = pc;
	u8 data = ReadIndexedAbsolute(&pc, X);
	u16 ret =  ASL(&data);
	WriteIndexedAbsolute(&backup, X, data);
	return ret;	
}

u16 AbsoluteX_LSR()
{
	u16 backup = pc;
	u8 data = ReadIndexedAbsolute(&pc, X);
	u16 ret =  LSR(&data);
	WriteIndexedAbsolute(&backup, X, data);
	return ret;	
}

u16 AbsoluteX_DEC()
{
	u16 backup = pc;
	u8 data = ReadIndexedAbsolute(&pc, X);
	u16 ret =  DEC(&data);
	WriteIndexedAbsolute(&backup, X, data);
	return ret;	
}

u16 AbsoluteX_INC()
{
	u16 backup = pc;
	u8 data = ReadIndexedAbsolute(&pc, X);
	u16 ret =  INC(&data);
	WriteIndexedAbsolute(&backup, X, data);
	return ret;	
}

u16 AbsoluteX_STA()
{
	return WriteIndexedAbsolute(&pc, X, A);
}

u16 AbsoluteX_ROL()
{
	u16 backup = pc;
	u8 data = ReadIndexedAbsolute(&pc, X);
	u16 ret =  ROL(&data);
	WriteIndexedAbsolute(&backup, X, data);
	return ret;
}

u16 AbsoluteX_ROR()
{
	u16 backup = pc;
	u8 data = ReadIndexedAbsolute(&pc, X);
	u16 ret =  ROR(&data);
	WriteIndexedAbsolute(&backup, X, data);
	return ret;
}

// Absolute Y
u16 AbsoluteY_ADC()
{
	return ADC(ReadIndexedAbsolute(&pc, Y));
}

u16 AbsoluteY_AND()
{
	return AND(ReadIndexedAbsolute(&pc, Y));
}

u16 AbsoluteY_CMP()
{
	return CP(A, ReadIndexedAbsolute(&pc, Y));
}

u16 AbsoluteY_EOR()
{
	return EOR(ReadIndexedAbsolute(&pc, Y));
}

u16 AbsoluteY_LDA()
{
	return LD(&A, ReadIndexedAbsolute(&pc, Y));
}

u16 AbsoluteY_LDX()
{
	return LD(&X, ReadIndexedAbsolute(&pc, Y));
}

u16 AbsoluteY_ORA()
{
	return OR(&A, ReadIndexedAbsolute(&pc, Y));
}

u16 AbsoluteY_SBC()
{
	return SBC(ReadIndexedAbsolute(&pc, Y));
}

u16 AbsoluteY_STA()
{
	return WriteIndexedAbsolute(&pc, Y, A);
}

// Indirect
u16 Indirect_JMP()
{
	u8 bb = ReadMemory(pc++);
	u8 cc = ReadMemory(pc++);
	u16 point = (((u16)cc << 8) | bb);
	u8 xx = ReadMemory(point);
	u8 yy = ReadMemory((point + 1) & 0xFFFF);
	return JMP((((u16)yy << 8) | xx));
}

// Indexed Indirect X
u16 IndirectX_ADC()
{
	return ADC(ReadIndexedIndirect(&pc, X));
}

u16 IndirectX_AND()
{
	return AND(ReadIndexedIndirect(&pc, X));
}

u16 IndirectX_CMP()
{
	return CP(A, ReadIndexedIndirect(&pc, X));
}

u16 IndirectX_EOR()
{
	return EOR(ReadIndexedIndirect(&pc, X));
}

u16 IndirectX_LDA()
{
	return LD(&A, ReadIndexedIndirect(&pc, X));
}

u16 IndirectX_ORA()
{
	return OR(&A, ReadIndexedIndirect(&pc, X));
}

u16 IndirectX_SBC()
{
	return SBC(ReadIndexedIndirect(&pc, X));
}

u16 IndirectX_STA()
{
	return WriteIndexIndirect(&pc, X, A);
}

// Indirect Indexed Y
u16 IndirectY_ADC()
{
	return ADC(ReadIndirectIndexed(&pc, Y));
}

u16 IndirectY_AND()
{
	return AND(ReadIndirectIndexed(&pc, Y));
}

u16 IndirectY_CMP()
{
	return CP(A, ReadIndirectIndexed(&pc, Y));
}

u16 IndirectY_EOR()
{
	return EOR(ReadIndirectIndexed(&pc, Y));
}

u16 IndirectY_LDA()
{
	return LD(&A, ReadIndirectIndexed(&pc, Y));
}

u16 IndirectY_ORA()
{
	return OR(&A, ReadIndirectIndexed(&pc, Y));
}

u16 IndirectY_SBC()
{
	return SBC(ReadIndirectIndexed(&pc, Y));
}

u16 IndirectY_STA()
{
	return WriteIndirectIndexed(&pc, Y, A);
}

// Absolute
u16 Absolute_ADC()
{
	return ADC(ReadAbsolute(&pc));
}

u16 Absolute_AND()
{
	return AND(ReadAbsolute(&pc));
}

u16 Absolute_ASL()
{
	u16 backup = pc;
	u8 data = ReadAbsolute(&pc);
	u16 ret = ASL(&data);
	WriteAbsolute(&backup, data);
	return ret;
}

u16 Absolute_BIT()
{
	return BIT(ReadAbsolute(&pc));
}

u16 Absolute_CMP()
{
	return CP(A, ReadAbsolute(&pc));
}

u16 Absolute_CPX()
{
	return CP(X, ReadAbsolute(&pc));
}

u16 Absolute_CPY()
{
	return CP(Y, ReadAbsolute(&pc));
}

u16 Absolute_DEC()
{
	u16 backup = pc;
	u8 data = ReadAbsolute(&pc);
	u16 ret = DEC(&data);
	WriteAbsolute(&backup, data);
	return ret;
}

u16 Absolute_EOR()
{
	return EOR(ReadAbsolute(&pc));
}

u16 Absolute_INC()
{
	u16 backup = pc;
	u8 data = ReadAbsolute(&pc);
	u16 ret =  INC(&data);
	WriteAbsolute(&backup, data);
	return ret;
}

u16 Absolute_JMP()
{
	u8 aa = ReadMemory(pc++);
	u8 bb = ReadMemory(pc++);
	pc = ((u16)bb << 8) | aa;
	return pc;
}

u16 Absolute_JSR()
{
	u8 aa = ReadMemory(pc++);
	u8 bb = ReadMemory(pc++);
	return JSR(((u16)bb << 8) | aa);
}

u16 Absolute_LDA()
{
	return LD(&A, ReadAbsolute(&pc));
}

u16 Absolute_LDX()
{
	return LD(&X, ReadAbsolute(&pc));
}

u16 Absolute_LDY()
{
	return LD(&Y, ReadAbsolute(&pc));
}

u16 Absolute_LSR()
{
	u16 backup = pc;
	u8 data = ReadAbsolute(&pc);
	u16 ret =  LSR(&data);
	WriteAbsolute(&backup, data);
	return ret;
}

u16 Absolute_ORA()
{
	return OR(&A, ReadAbsolute(&pc));
}

u16 Absolute_ROL()
{
	u16 backup = pc;
	u8 data = ReadAbsolute(&pc);
	u16 ret =  ROL(&data);
	WriteAbsolute(&backup, data);
	return ret;
}

u16 Absolute_ROR()
{
	u16 backup = pc;
	u8 data = ReadAbsolute(&pc);
	u16 ret =  ROR(&data);
	WriteAbsolute(&backup, data);
	return ret;
}

u16 Absolute_SBC()
{
	return SBC(ReadAbsolute(&pc));
}

u16 Absolute_STA()
{
	return WriteAbsolute(&pc, A);
}

u16 Absolute_STX()
{
	return WriteAbsolute(&pc, X);
}

u16 Absolute_STY()
{
	return WriteAbsolute(&pc, Y);
}

// Relative
u16 BCC()
{
	return BRANCH(!CarryFlag());
}

u16 BCS()
{
	return BRANCH(CarryFlag());
}

u16 BEQ()
{
	return BRANCH(ZeroFlag());
}

u16 BMI()
{
	return BRANCH(NegativeFlag());
}

u16 BNE()
{
	return BRANCH(!ZeroFlag());
}

u16 BPL()
{
	return BRANCH(!NegativeFlag());
}

u16 BVC()
{
	return BRANCH(!OverflowFlag());
}

u16 BVS()
{
	return BRANCH(OverflowFlag());
}

// Immediate
u16 Immediate_ADC()
{
	return (ADC(ReadImmediate(&pc)));
}

u16 Immediate_AND()
{
	return (AND(ReadImmediate(&pc)));
}

u16 Immediate_CMP()
{
	return (CP(A, ReadImmediate(&pc)));
}

u16 Immediate_CPX()
{
	return (CP(X, ReadImmediate(&pc)));
}

u16 Immediate_CPY()
{
	return (CP(Y, ReadImmediate(&pc)));
}

u16 Immediate_EOR()
{
	return (EOR(ReadImmediate(&pc)));
}

u16 Immediate_LDA()
{
	return (LD(&A, ReadImmediate(&pc)));
}

u16 Immediate_LDX()
{
	return (LD(&X, ReadImmediate(&pc)));
}

u16 Immediate_LDY()
{
	return (LD(&Y, ReadImmediate(&pc)));
}

u16 Immediate_ORA()
{
	return (OR(&A, ReadImmediate(&pc)));
}

u16 Immediate_SBC()
{
	return (SBC(ReadImmediate(&pc)));
}