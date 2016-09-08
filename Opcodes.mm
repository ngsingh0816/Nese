//
//  Opcodes.m
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Opcodes.h"
#import "OpcFunc.h"
#import "CPU.h"
#import "Controller.h"

Opcode opcodes[0x100];

Opcode MakeOpcode(NSString* name, u8 cycles, NSString* mode, u16 (*exec)())
{
	Opcode opcode;
	opcode.name = [ [ NSString stringWithString:name ] retain ];
	opcode.cycles = cycles;
	opcode.mode = [ [ NSString stringWithString:mode ] retain ];
	opcode.exec = exec;
	return (const Opcode)opcode;
}

u16 Invalid()
{
	Opcode lastOpc;
	u16 backup = pc - 1;
	bool found = false;
checkLast:
	while (!found)
	{
		backup--;
		lastOpc = opcodes[ReadMemory(backup)];
		if (![ lastOpc.name isEqualToString:@"Invalid" ])
			found = true;
	}
	/*NSString* mode = lastOpc.mode;
	u8 num = 0;
	if ([ mode isEqualToString:Immediate ] || [ mode isEqualToString:ZeroPage ] ||
		[ mode isEqualToString:ZeroPageX ] || [ mode isEqualToString:ZeroPageY ] ||
		[ mode isEqualToString:IndexedIndirect ] || [ mode isEqualToString:IndirectIndexed ]
		|| [ mode isEqualToString:Relative ])
		num = 1;
	else if ([ mode isEqualToString:Absolute ] || [ mode isEqualToString:AbsoluteX ]
			 || [ mode isEqualToString:AbsoluteY ])
		num = 2;
	if (backup + num != pc - 1)
		goto checkLast;*/
	
	int z = NSRunAlertPanel(@"Error",
@"Invalid Opcode 0x%X PC = 0x%X.\nLast valid opcode = 0x%X(%@) pc = 0x%X Continue or go back?",
							@"No", @"Yes", @"Go Back", theopcode, pc-1,// 0, @"",
							ReadMemory(backup), lastOpc.name, backup);
	if (z == NSAlertDefaultReturn)
		stop = true;
	else if (z == NSAlertOtherReturn)
		pc = backup;
	return 0;
}

// Actual Opcodes
u16 BRK()
{
	if (InterruptFlag())
		return pc;
	Push16(pc);
	SetBreakCommand(1);
	Push(P);
	pc = ReadMemory16(0xFFFE);
	SetInterruptFlag(1);
	return pc;
}

u16 ADC(u8 data)
{
	u16 result = (u16)A + data + (u8)CarryFlag();
	A = (result & 0xFF);
	SetCarryFlag(result > 0xFF);
	SetZeroFlag(A == 0);
	BOOL sameSign = ((A >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((A >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetOverflowFlag(sameSign && diffSign);
	SetNegativeFlag((A >> 7) & 0x1);	
	return data;
}

u16 AND(u8 data)
{
	A &= data;
	SetZeroFlag(A == 0);
	SetNegativeFlag(A >> 7);
	return data;
}

u16 CP(u8 reg, u8 data)
{
	u16 result = reg - data;
	SetCarryFlag(result < 0x100);
	result &= 0xFF;
	SetZeroFlag(result == 0);
	SetNegativeFlag(result >> 7);
	return data;
}

u16 EOR(u8 data)
{
	A ^= data;
	SetZeroFlag(A == 0);
	SetNegativeFlag(A >> 7);
	return data;
}

u16 LD(u8* reg, u8 data)
{
	(*reg) = data;
	SetZeroFlag(data == 0);
	SetNegativeFlag(data >> 7);
	return data;
}

u16 OR(u8* reg, u8 data)
{
	(*reg) |= data;
	SetZeroFlag((*reg) == 0);
	SetNegativeFlag((*reg) >> 7);
	return data;
}

u16 SBC(u8 data)
{		
	bool added = !CarryFlag();
	u16 result = (u16)A - data - added;
	BOOL sameSign = ((A >> 7) & 0x1) == ((data >> 7) & 0x1);
	BOOL diffSign = ((A >> 7) & 0x1) != ((result >> 7) & 0x1);
	SetOverflowFlag(!sameSign && diffSign);
	A = (result & 0xFF);
	SetZeroFlag(A == 0);
	SetNegativeFlag(A >> 7);
	SetCarryFlag(result < 0x100);
	return data;
}

u16 PH(u8 reg)
{
	Push(reg);
	return reg;
}

u16 PL(u8* reg)
{
	(*reg) = Pop();
	SetZeroFlag((*reg) == 0);
	SetNegativeFlag((*reg) >> 7);
	return (*reg);
}

u16 T(u8 data, u8* reg)
{
	(*reg) = data;
	SetZeroFlag(data == 0);
	SetNegativeFlag(data >> 7);
	return data;
}

u16 ASL(u8* place)
{
	u8 ret = (*place);
	SetCarryFlag((*place) >> 7);
	(*place) <<= 1;
	SetZeroFlag((*place) == 0);
	SetNegativeFlag((*place) >> 7);
	return ret;
}

u16 BIT(u8 data)
{
	u8 result = A & data;
	SetZeroFlag(result == 0);
	SetOverflowFlag((data >> 6) & 0x1);
	SetNegativeFlag(data >> 7);
	return data;
}

u16 DEC(u8* data)
{
	u8 ret = (*data);
	(*data)--;
	SetZeroFlag((*data) == 0);
	SetNegativeFlag((*data) >> 7);
	return ret;
}

u16 INC(u8* data)
{
	u8 ret = (*data);
	(*data)++;
	SetZeroFlag((*data) == 0);
	SetNegativeFlag((*data) >> 7);
	return ret;
}

u16 LSR(u8* data)
{
	u8 ret = (*data);
	SetCarryFlag((*data) & 0x1);
	(*data) >>= 1;
	SetZeroFlag((*data) == 0);
	SetNegativeFlag((*data) >> 7);
	return ret;
}

u16 ROL(u8* data)
{
	u8 ret = (*data);
	u8 i = CarryFlag();
	SetCarryFlag((*data) >> 7);
	(*data) <<= 1;
	(*data) |= i;
	SetZeroFlag((*data) == 0);
	SetNegativeFlag((*data) >> 7);
	return ret;
}

u16 ROR(u8* data)
{
	u8 ret = (*data);
	u8 i = CarryFlag() * 0x80;
	SetCarryFlag((*data) & 0x1);
	(*data) >>= 1;
	(*data) |= i;
	SetZeroFlag((*data) == 0);
	SetNegativeFlag((*data) >> 7);
	return ret;
}

u16 JMP(u16 addr)
{
	pc = addr;
	return addr;
}

u16 BRANCH(bool condition)
{
	if (!condition)
	{
		pc++;
		return pc;
	}
	s8 position = ReadRelative(&pc);
	cycles--;
	if ((pc ^ (pc + position)) & 0x100)
		cycles--;
	pc += position;
	return pc;
}

u16 JSR(u16 addr)
{
	Push16(pc-1);
	pc = addr;
	return addr;
}

void CreateCodes()
{
	for (int z = 0; z < 0x100; z++)
		opcodes[z] = MakeOpcode(@"Invalid", 0, None, Invalid);
	
	opcodes[0x00] = MakeOpcode(@"BRK", 7, Implied, BRK);
	opcodes[0x01] = MakeOpcode(@"ORA", 6, IndexedIndirect, IndirectX_ORA);
	opcodes[0x05] = MakeOpcode(@"ORA", 3, ZeroPage, ZeroPage_ORA);
	opcodes[0x06] = MakeOpcode(@"ASL", 5, ZeroPage, ZeroPage_ASL);
	opcodes[0x08] = MakeOpcode(@"PHP", 3, Implied, PHP);
	opcodes[0x09] = MakeOpcode(@"ORA", 2, Immediate, Immediate_ORA);
	opcodes[0x0A] = MakeOpcode(@"ASL", 2, Accumulator, Accumulator_ASL);
	opcodes[0x0D] = MakeOpcode(@"ORA", 4, Absolute, Absolute_ORA);
	opcodes[0x0E] = MakeOpcode(@"ASL", 6, Absolute, Absolute_ASL);
	opcodes[0x10] = MakeOpcode(@"BPL", 2, Relative, BPL);
	opcodes[0x11] = MakeOpcode(@"ORA", 5, IndirectIndexed, IndirectY_ORA);
	opcodes[0x15] = MakeOpcode(@"ORA", 4, ZeroPageX, ZeroPageX_ORA);
	opcodes[0x16] = MakeOpcode(@"ASL", 6, ZeroPageX, ZeroPageX_ASL);
	opcodes[0x18] = MakeOpcode(@"CLC", 2, Implied, CLC);
	opcodes[0x19] = MakeOpcode(@"ORA", 4, AbsoluteY, AbsoluteY_ORA);
	opcodes[0x1D] = MakeOpcode(@"ORA", 4, AbsoluteX, AbsoluteX_ORA);
	opcodes[0x1E] = MakeOpcode(@"ASL", 7, AbsoluteX, AbsoluteX_ASL);
	opcodes[0x20] = MakeOpcode(@"JSR", 6, Absolute, Absolute_JSR);
	opcodes[0x21] = MakeOpcode(@"AND", 6, IndexedIndirect, IndirectX_AND);
	opcodes[0x24] = MakeOpcode(@"BIT", 3, ZeroPage, ZeroPage_BIT);
	opcodes[0x25] = MakeOpcode(@"AND", 3, ZeroPage, ZeroPage_AND);
	opcodes[0x26] = MakeOpcode(@"ROL", 5, ZeroPage, ZeroPage_ROL);
	opcodes[0x28] = MakeOpcode(@"PLP", 4, Implied, PLP);
	opcodes[0x29] = MakeOpcode(@"AND", 2, Immediate, Immediate_AND);
	opcodes[0x2A] = MakeOpcode(@"ROL", 2, Accumulator, Accumulator_ROL);
	opcodes[0x2C] = MakeOpcode(@"BIT", 4, Absolute, Absolute_BIT);
	opcodes[0x2D] = MakeOpcode(@"AND", 4, Absolute, Absolute_AND);
	opcodes[0x2E] = MakeOpcode(@"ROL", 6, Absolute, Absolute_ROL);
	opcodes[0x30] = MakeOpcode(@"BMI", 2, Relative, BMI);
	opcodes[0x31] = MakeOpcode(@"AND", 5, IndirectIndexed, IndirectY_AND);
	opcodes[0x35] = MakeOpcode(@"AND", 4, ZeroPageX, ZeroPageX_AND);
	opcodes[0x36] = MakeOpcode(@"ROL", 6, ZeroPageX, ZeroPageX_ROL);
	opcodes[0x38] = MakeOpcode(@"SEC", 2, Implied, SEC);
	opcodes[0x39] = MakeOpcode(@"AND", 4, AbsoluteY, AbsoluteY_AND);
	opcodes[0x3D] = MakeOpcode(@"AND", 4, AbsoluteX, AbsoluteX_AND);
	opcodes[0x3E] = MakeOpcode(@"ROL", 7, AbsoluteX, AbsoluteX_ROL);
	opcodes[0x40] = MakeOpcode(@"RTI", 6, Implied, RTI);
	opcodes[0x41] = MakeOpcode(@"EOR", 6, IndexedIndirect, IndirectX_EOR);
	opcodes[0x45] = MakeOpcode(@"EOR", 3, ZeroPage, ZeroPage_EOR);
	opcodes[0x46] = MakeOpcode(@"LSR", 5, ZeroPage, ZeroPage_LSR);
	opcodes[0x48] = MakeOpcode(@"PHA", 3, Implied, PHA);
	opcodes[0x49] = MakeOpcode(@"EOR", 2, Immediate, Immediate_EOR);
	opcodes[0x4A] = MakeOpcode(@"LSR", 2, Accumulator, Accumulator_LSR);
	opcodes[0x4C] = MakeOpcode(@"JMP", 3, Absolute, Absolute_JMP);
	opcodes[0x4D] = MakeOpcode(@"EOR", 4, Absolute, Absolute_EOR);
	opcodes[0x4E] = MakeOpcode(@"LSR", 6, Absolute, Absolute_LSR);
	opcodes[0x50] = MakeOpcode(@"BVC", 2, Relative, BVC);
	opcodes[0x51] = MakeOpcode(@"EOR", 5, IndirectIndexed, IndirectY_EOR);
	opcodes[0x55] = MakeOpcode(@"EOR", 4, ZeroPageX, ZeroPageX_EOR);
	opcodes[0x56] = MakeOpcode(@"LSR", 6, ZeroPageX, ZeroPageX_LSR);
	opcodes[0x58] = MakeOpcode(@"CLI", 2, Implied, CLI);
	opcodes[0x59] = MakeOpcode(@"EOR", 4, AbsoluteY, AbsoluteY_EOR);
	opcodes[0x5D] = MakeOpcode(@"EOR", 4, AbsoluteX, AbsoluteX_EOR);
	opcodes[0x5E] = MakeOpcode(@"LSR", 7, AbsoluteX, AbsoluteX_LSR);
	opcodes[0x60] = MakeOpcode(@"RTS", 6, Implied, RTS);
	opcodes[0x61] = MakeOpcode(@"ADC", 6, IndexedIndirect, IndirectX_ADC);
	opcodes[0x65] = MakeOpcode(@"ADC", 3, ZeroPage, ZeroPage_ADC);
	opcodes[0x66] = MakeOpcode(@"ROR", 5, ZeroPage, ZeroPage_ROR);
	opcodes[0x68] = MakeOpcode(@"PLA", 4, Implied, PLA);
	opcodes[0x69] = MakeOpcode(@"ADC", 2, Immediate, Immediate_ADC);
	opcodes[0x6A] = MakeOpcode(@"ROR", 2, Accumulator, Accumulator_ROR);
	opcodes[0x6C] = MakeOpcode(@"JMP", 5, Indirect, Indirect_JMP);
	opcodes[0x6D] = MakeOpcode(@"ADC", 4, Absolute, Absolute_ADC);
	opcodes[0x6E] = MakeOpcode(@"ROR", 6, Absolute, Absolute_ROR);
	opcodes[0x70] = MakeOpcode(@"BVS", 2, Relative, BVS);
	opcodes[0x71] = MakeOpcode(@"ADC", 5, IndirectIndexed, IndirectY_ADC);
	opcodes[0x75] = MakeOpcode(@"ADC", 4, ZeroPageX, ZeroPage_ADC);
	opcodes[0x76] = MakeOpcode(@"ROR", 6, ZeroPageX, ZeroPageX_ROR);
	opcodes[0x78] = MakeOpcode(@"SEI", 2, Implied, SEI);
	opcodes[0x79] = MakeOpcode(@"ADC", 4, AbsoluteY, AbsoluteY_ADC);
	opcodes[0x7D] = MakeOpcode(@"ADC", 4, AbsoluteX, AbsoluteX_ADC);
	opcodes[0x7E] = MakeOpcode(@"ROR", 7, AbsoluteX, AbsoluteX_ROR);
	opcodes[0x81] = MakeOpcode(@"STA", 6, IndexedIndirect, IndirectX_STA);
	opcodes[0x84] = MakeOpcode(@"STY", 3, ZeroPage, ZeroPage_STY);
	opcodes[0x85] = MakeOpcode(@"STA", 3, ZeroPage, ZeroPage_STA);
	opcodes[0x86] = MakeOpcode(@"STX", 3, ZeroPage, ZeroPage_STX);
	opcodes[0x88] = MakeOpcode(@"DEY", 2, Implied, DEY); 
	opcodes[0x8A] = MakeOpcode(@"TXA", 2, Implied, TXA);
	opcodes[0x8C] = MakeOpcode(@"STY", 4, Absolute, Absolute_STY);
	opcodes[0x8D] = MakeOpcode(@"STA", 4, Absolute, Absolute_STA);
	opcodes[0x8E] = MakeOpcode(@"STX", 4, Absolute, Absolute_STX);
	opcodes[0x90] = MakeOpcode(@"BCC", 2, Relative, BCC);
	opcodes[0x91] = MakeOpcode(@"STA", 6, IndirectIndexed, IndirectY_STA);
	opcodes[0x94] = MakeOpcode(@"STY", 4, ZeroPageX, ZeroPageX_STY);
	opcodes[0x95] = MakeOpcode(@"STA", 4, ZeroPageX, ZeroPageX_STA);
	opcodes[0x96] = MakeOpcode(@"STX", 4, ZeroPageY, ZeroPageY_STX);
	opcodes[0x98] = MakeOpcode(@"TYA", 2, Implied, TYA);
	opcodes[0x99] = MakeOpcode(@"STA", 5, AbsoluteY, AbsoluteY_STA);
	opcodes[0x9A] = MakeOpcode(@"TXS", 2, Implied, TXS);
	opcodes[0x9D] = MakeOpcode(@"STA", 5, AbsoluteX, AbsoluteX_STA);
	opcodes[0xA0] = MakeOpcode(@"LDY", 2, Immediate, Immediate_LDY);
	opcodes[0xA1] = MakeOpcode(@"LDA", 6, IndexedIndirect, IndirectX_LDA);
	opcodes[0xA2] = MakeOpcode(@"LDX", 2, Immediate, Immediate_LDX);
	opcodes[0xA4] = MakeOpcode(@"LDY", 3, ZeroPage, ZeroPage_LDY);
	opcodes[0xA5] = MakeOpcode(@"LDA", 3, ZeroPage, ZeroPage_LDA);
	opcodes[0xA6] = MakeOpcode(@"LDX", 3, ZeroPage, ZeroPage_LDX);
	opcodes[0xA8] = MakeOpcode(@"TAY", 2, Implied, TAY);
	opcodes[0xA9] = MakeOpcode(@"LDA", 2, Immediate, Immediate_LDA);
	opcodes[0xAA] = MakeOpcode(@"TAX", 2, Implied, TAX);
	opcodes[0xAC] = MakeOpcode(@"LDY", 4, Absolute, Absolute_LDY);
	opcodes[0xAD] = MakeOpcode(@"LDA", 4, Absolute, Absolute_LDA);
	opcodes[0xAE] = MakeOpcode(@"LDX", 4, Absolute, Absolute_LDX);
	opcodes[0xB0] = MakeOpcode(@"BCS", 2, Relative, BCS);
	opcodes[0xB1] = MakeOpcode(@"LDA", 5, IndirectIndexed, IndirectY_LDA);
	opcodes[0xB4] = MakeOpcode(@"LDY", 4, ZeroPageX, ZeroPageX_LDY);
	opcodes[0xB5] = MakeOpcode(@"LDA", 4, ZeroPageX, ZeroPageX_LDA);
	opcodes[0xB6] = MakeOpcode(@"LDX", 4, ZeroPageY, ZeroPageY_LDX);
	opcodes[0xB8] = MakeOpcode(@"CLV", 2, Implied, CLV);
	opcodes[0xB9] = MakeOpcode(@"LDA", 4, AbsoluteY, AbsoluteY_LDA);
	opcodes[0xBA] = MakeOpcode(@"TSX", 2, Implied, TSX);
	opcodes[0xBC] = MakeOpcode(@"LDY", 4, AbsoluteX, AbsoluteX_LDY);
	opcodes[0xBD] = MakeOpcode(@"LDA", 4, AbsoluteX, AbsoluteX_LDA);
	opcodes[0xBE] = MakeOpcode(@"LDX", 4, AbsoluteY, AbsoluteY_LDX);
	opcodes[0xC0] = MakeOpcode(@"CPY", 2, Immediate, Immediate_CPY);
	opcodes[0xC1] = MakeOpcode(@"CMP", 6, IndexedIndirect, IndirectX_CMP);
	opcodes[0xC4] = MakeOpcode(@"CPY", 3, ZeroPage, ZeroPage_CPY);
	opcodes[0xC5] = MakeOpcode(@"CMP", 3, ZeroPage, ZeroPage_CMP);
	opcodes[0xC6] = MakeOpcode(@"DEC", 5, ZeroPage, ZeroPage_DEC);
	opcodes[0xC8] = MakeOpcode(@"INY", 2, Implied, INY);
	opcodes[0xC9] = MakeOpcode(@"CMP", 2, Immediate, Immediate_CMP);
	opcodes[0xCA] = MakeOpcode(@"DEX", 2, Implied, DEX);
	opcodes[0xCC] = MakeOpcode(@"CPY", 4, Absolute, Absolute_CPY);
	opcodes[0xCD] = MakeOpcode(@"CMP", 4, Absolute, Absolute_CMP);
	opcodes[0xCE] = MakeOpcode(@"DEC", 6, Absolute, Absolute_DEC);
	opcodes[0xD0] = MakeOpcode(@"BNE", 2, Relative, BNE);
	opcodes[0xD1] = MakeOpcode(@"CMP", 5, IndirectIndexed, IndirectY_CMP);
	opcodes[0xD5] = MakeOpcode(@"CMP", 4, ZeroPageX, ZeroPageX_CMP);
	opcodes[0xD6] = MakeOpcode(@"DEC", 6, ZeroPageX, ZeroPageX_DEC);
	opcodes[0xD8] = MakeOpcode(@"CLD", 2, Implied, CLD);
	opcodes[0xD9] = MakeOpcode(@"CMP", 4, AbsoluteY, AbsoluteY_CMP);
	opcodes[0xDD] = MakeOpcode(@"CMP", 4, AbsoluteX, AbsoluteX_CMP);
	opcodes[0xDE] = MakeOpcode(@"DEC", 7, AbsoluteX, AbsoluteX_DEC);
	opcodes[0xE0] = MakeOpcode(@"CPX", 2, Immediate, Immediate_CPX);
	opcodes[0xE1] = MakeOpcode(@"SBC", 6, IndexedIndirect, IndirectX_SBC);
	opcodes[0xE4] = MakeOpcode(@"CPX", 3, ZeroPage, ZeroPage_CPX);
	opcodes[0xE5] = MakeOpcode(@"SBC", 3, ZeroPage, ZeroPage_SBC);
	opcodes[0xE6] = MakeOpcode(@"INC", 5, ZeroPage, ZeroPage_INC);
	opcodes[0xE8] = MakeOpcode(@"INX", 2, Implied, INX);
	opcodes[0xE9] = MakeOpcode(@"SBC", 2, Immediate, Immediate_SBC);
	opcodes[0xEA] = MakeOpcode(@"NOP", 2, Implied, NOP);
	opcodes[0xEC] = MakeOpcode(@"CPX", 4, Absolute, Absolute_CPX);
	opcodes[0xED] = MakeOpcode(@"SBC", 4, Absolute, Absolute_SBC);
	opcodes[0xEE] = MakeOpcode(@"INC", 6, Absolute, Absolute_INC);
	opcodes[0xF0] = MakeOpcode(@"BEQ", 2, Relative, BEQ);
	opcodes[0xF1] = MakeOpcode(@"SBC", 5, IndirectIndexed, IndirectY_SBC);
	opcodes[0xF5] = MakeOpcode(@"SBC", 4, ZeroPageX, ZeroPageX_SBC);
	opcodes[0xF6] = MakeOpcode(@"INC", 6, ZeroPageX, ZeroPageX_INC);
	opcodes[0xF8] = MakeOpcode(@"SED", 2, Implied, SED);
	opcodes[0xF9] = MakeOpcode(@"SBC", 4, AbsoluteY, AbsoluteY_SBC);
	opcodes[0xFD] = MakeOpcode(@"SBC", 4, AbsoluteX, AbsoluteX_SBC);
	opcodes[0xFE] = MakeOpcode(@"INC", 7, AbsoluteX, AbsoluteX_INC);
}