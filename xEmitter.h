/*
 *  xEmitter.h
 *  Nese
 *
 *  Created by MILAP on 2/5/11.
 *  Copyright 2011 __MyCompanyName__. All rights reserved.
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "types.h"

typedef enum
{
	EAX = 0,
	EBX = 3,
	ECX = 1,
	EDX = 2,
	ESI = 6,
	EDI = 7,
	EBP = 5,
	ESP = 4 
} x86Reg;

class xEmitter
{
public:
	xEmitter();
	~xEmitter();
	void Alloc(u32 si);
	void Dealloc();
	void Flush();
	void Execute();
	u32 Start();
	void SetStart(u32 str);
	u32 PTR();
	void SetPTR(u32 i);
	void Write8(u8 data);
	void Write16(u16 data);
	void Write32(u32 data);
	
	// Instructions
	void ADD(x86Reg reg, u8 val);
	void ADC(x86Reg reg, u8 val);
	void AND(x86Reg reg, u8 val);
	void XOR(x86Reg reg, u8 val);
	void OR(x86Reg reg, u8 val);
	void SUB(x86Reg reg, u8 val);
	void CMP(x86Reg reg, u8 val);
	void MOV(x86Reg dest, u8 src);
	void MOV16RtoM(u32 to, x86Reg from);
	void RET();
	void INC(x86Reg reg);
	void DEC(x86Reg reg);
	void PUSH(x86Reg reg);
	void POP(x86Reg reg);
	void JMP(u32 address);
	void ModRM(u8 mod, u8 rm, x86Reg reg);
	
	u8* instr;
	u32 ptr;
	u32 size;
	u32 start;
};