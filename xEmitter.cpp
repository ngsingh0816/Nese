/*
 *  xEmitter.cpp
 *  Nese
 *
 *  Created by MILAP on 2/5/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include "xEmitter.h"

xEmitter::xEmitter()
{
}

xEmitter::~xEmitter()
{
}

void xEmitter::Alloc(u32 si)
{
	instr = (u8*)malloc(si);
	memset(instr, 0, si);
	ptr = 0;
	size = si;
}

void xEmitter::Dealloc()
{
	if (instr)
	{
		free(instr);
		instr = NULL;
	}
	ptr = 0;
}

void xEmitter::Flush()
{
	ptr = start;
}

void xEmitter::Execute()
{
	void (*dynacode)();
	if (instr)
	{
		dynacode = (void (*)())malloc(ptr - start);
		memcpy((void*)dynacode, &instr[start], ptr - start);
		dynacode();
		free((void*)dynacode);
		dynacode = NULL;
	}
}

u32 xEmitter::Start()
{
	return start;
}

void xEmitter::SetStart(u32 str)
{
	if (str < size)
		start = str;
}

u32 xEmitter::PTR()
{
	return ptr;
}

void xEmitter::SetPTR(u32 i)
{
	if (i < size)
		ptr = i;
}

void xEmitter::Write8(u8 data)
{
	instr[ptr++] = data;
}

void xEmitter::Write16(u16 data)
{
	*((u16*)(instr + ptr)) = data;
	ptr += 2;
}

void xEmitter::Write32(u32 data)
{
	*((u32*)(instr + ptr)) = data;
	ptr += 4;
}

void xEmitter::ModRM(u8 mod, u8 rm, x86Reg reg)
{
	Write8((mod << 6) | (rm << 4 ) | (reg));
}

// Instructions

void xEmitter::ADD(x86Reg reg, u8 val)
{
	Write8(0x04);
	Write8(val);
}

void xEmitter::ADC(x86Reg reg, u8 val)
{
	Write8(0x14);
	Write8(val);
}

void xEmitter::AND(x86Reg reg, u8 val)
{
	Write8(0x24);
	Write8(val);
}

void xEmitter::XOR(x86Reg reg, u8 val)
{
	Write8(0x34);
	Write8(val);
}

void xEmitter::OR(x86Reg reg, u8 val)
{
	Write8(0x0C);
	Write8(val);
}

void xEmitter::SUB(x86Reg reg, u8 val)
{
	Write8(0x2C);
	Write8(val);
}

void xEmitter::CMP(x86Reg reg, u8 val)
{
	Write8(0x3C);
	Write8(val);
}

void xEmitter::MOV(x86Reg dest, u8 src);
{
	Write8(0xB0 + dest);
	Write8(src);
}

void xEmitter::MOV16RtoM(u32 to, x86Reg from)
{
	Write8(0x66);
	Write8(0x89);
	ModRM(0, from, (x86Reg)DISP32);
	Write32(to);
}

void xEmitter::RET()
{
	Write8(0xC3);
}

void xEmitter::INC(x86Reg reg)
{
	Write8(0x40 + (u8)reg);
}

void xEmitter::DEC(x86Reg reg)
{
	Write8(0x48 + (u8)reg);
}

void xEmitter::PUSH(x86Reg reg)
{
	Write8(0x50 + (u8)reg);
}

void xEmitter::POP(x86Reg reg)
{
	Write8(0x58 + (u8)reg);
}

void xEmitter::JMP(u32 address)
{
	Write8(0xEA);
	Write16((address >> 32) & 0xFFFF);
	Write32(address & 0xFFFFFF);
}
