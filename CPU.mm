//
//  CPU.m
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CPU.h"
#import "PPU.h"
#import "Controller.h"
#import "Mappers.h"
#import "APU.h"

u16 pc;
u8 sp;
u8 A;
u8 X;
u8 Y;
u8 P;
int cycles;
float tcount;
u8* memory;
u8 theopcode;
Opcode opc;
u16 operand;
bool reset;
u8 joypad1;
bool inVBLANK;
float scanline_cycles;
xEmitter* emit = NULL;
bool dynarec = false;

bool lastWriteWas2006;
bool lastWriteWasHorizontal;
u8 backup_2006;
u8 vramBuffer;
bool vramRead;
u8 mapper;

void WriteMemory(u16 pos, u8 data)
{
	CheckMapperWrite(pos, data);
	if (pos < 0x800)
	{
		memory[pos] = data;
		memory[pos + 0x800] = data;
		memory[pos + 0x1000] = data;
		memory[pos + 0x1800] = data;
	}
	else if (pos >= 0x800 && pos < 0x1000)
	{
		memory[pos - 0x800] = data;
		memory[pos] = data;
		memory[pos + 0x800] = data;
		memory[pos + 0x1000] = data;
	}
	else if (pos >= 0x1000 && pos < 0x1800)
	{
		memory[pos - 0x1000] = data;
		memory[pos - 0x800] = data;
		memory[pos] = data;
		memory[pos + 0x800] = data;
	}
	else if (pos >= 0x1800 && pos < 0x2000)
	{
		memory[pos - 0x1800] = data;
		memory[pos - 0x1000] = data;
		memory[pos - 0x800] = data;
		memory[pos] = data;
	}
	else if (pos == 0x2000)
	{
		memory[0x2000] = data;
		WriteVramReg(0x2000, data);
	}
	else if (pos == 0x2001)
	{
		memory[0x2001] = data;
		WriteVramReg(0x2001, data);
	}
	else if (pos == 0x2004)
		WriteSPR(memory[0x2003]++, data);
	else if (pos == 0x2005 && !lastWriteWasHorizontal)
	{
		scrollx = data;
		lastWriteWasHorizontal = true;
	}
	else if (pos == 0x2005 && lastWriteWasHorizontal)
	{
		scrolly = data;
		lastWriteWasHorizontal = false;
	}
	else if (pos == 0x2006 && !lastWriteWas2006)
	{
		memory[0x2006] = data;
		lastWriteWas2006 = true;
		vramRead = 0;
	}
	else if (pos == 0x2006 && lastWriteWas2006)
	{
		backup_2006 = data;
		lastWriteWas2006 = false;
		vramRead = 0;
	}
	else if (pos == 0x2007)
	{
		u8 aa = memory[0x2006];
		u8 bb = backup_2006;
		u16 addr = ((u16)aa << 8) | bb;
		WriteVRAM(addr, data);
		if ((memory[0x2000] >> 2) & 0x1)
			addr += 32;
		else
			addr++;
		backup_2006 = (addr & 0xFF);
		memory[0x2006] = ((addr >> 8) & 0xFF);
	}
	else if (pos == 0x4014)
	{
		WriteSPRP(0, &memory[((u16)data << 8)], 0x100);
		cycles -= 514;
		memory[0x4014] = data;
	}
	else if (pos == 0x4016)
	{
		static u8 lastWrite = 0;
		if (lastWrite == 1 && data == 0)
		{
			joypad1 = 0;
			lastWrite = 0;
		}
		else
		{
			lastWrite = data;
			joypad1 = (joypad1 + 1) % 23;
			//memory[pos] &= 0xFE;
			//memory[pos] |= (data & 0x1);
		}
	}
	else if (pos >= 0x4000 && pos <= 0x4016)
	{
		APUWrite(pos, data);
		memory[pos] = data;
	}
	else
		memory[pos] = data;
}

void WriteMemory16(u16 pos, u16 data)
{
	WriteMemory(pos, (data & 0xFF));
	WriteMemory(pos + 1, ((data >> 8) & 0xFF));
}

void WriteMemoryP(u16 pos, u8* data, u16 length)
{
	for (int z = 0; z < length; z++)
		memory[pos+z] = data[z];
}

void WriteMemory16P(u16 pos, u16* data, u16 length)
{
	for (int z = 0; z < length; z++)
	{
		memory[pos] = (data[z] & 0xFF);
		memory[pos + 1] = ((data[z] >> 8) & 0xFF);
	}
}

void EnableVBLANK()
{
	memory[0x2002] |= 0x80;
}

void EnableSpriteHit()
{
	memory[0x2002] |= 0x40;
}

void DisableVBLANK()
{
	memory[0x2002] &= 0x7F;
}

void DisableSpriteHit()
{
	memory[0x2002] &= 0xBF;
}

void EnableEightSprites()
{
	memory[0x2002] |= (1 << 5);
}

void DisableEightSprites()
{
	memory[0x2002] &= ~(1 << 5);
}

u8 ReadMemory(u16 pos)
{
	if (pos == 0x2002)
	{
		u8 mem = memory[0x2002];
		memory[0x2002] &= 0x7F;
		backup_2006 = 0;
		return mem;
	}
	else if (pos == 0x2004)
		return ReadSPR(memory[0x2003]++);
	else if (pos == 0x2007 && !((memory[0x2002] >> 4) & 0x1))
	{
		u8 aa = memory[0x2006];
		u8 bb = backup_2006;
		u16 addr = ((u16)aa << 8) | bb;
		if (addr < 0x3F00)
		{
			if (!vramRead)
			{
				vramRead = true;
				vramBuffer = ReadVRAM(addr);
				if ((memory[0x2000] >> 2) & 0x1)
					addr += 32;
				else
					addr++;
				memory[0x2006] = ((addr >> 8) & 0xFF);
				backup_2006 = (addr & 0xFF);
				return 0;
			}
			else
			{
				u8 ret = ReadVRAM(addr);
				if ((memory[0x2000] >> 2) & 0x1)
					addr += 32;
				else
					addr++;
				memory[0x2006] = ((addr >> 8) & 0xFF);
				backup_2006 = (addr & 0xFF);
				u8 prev = vramBuffer;
				vramBuffer = ret;
				return prev;
			}
		}
	/*	u8 ret = ReadVRAM(addr);
		if ((memory[0x2000] >> 2) & 0x1)
			addr += 32;
		else
			addr++;
		memory[0x2006] = ((addr >> 8) & 0xFF);
		backup_2006 = (addr & 0xFF);
		return ret;*/
	}
	else if (pos > 0x2007 && pos < 0x4000)
	{
		u8 place = (pos - 0x2000) % 8;
		return memory[place + 0x2000];
	}
	else if (pos == 0x4015)
		return APURead(pos);
	else if (pos == 0x4016)
	{
		u8 ret = 0;
		memory[pos] &= 0xFE;
		if (joypad1 < 8)
			ret = kdown[joypad1];
		else if (joypad1 == 19)
			ret = 1;
		joypad1 = (joypad1 + 1) % 23;
		memory[pos] |= ret;
		return ret;
	}
	return memory[pos];
}

u16 ReadMemory16(u16 pos)
{
	return (ReadMemory(pos) | (ReadMemory(pos+1) << 8));
}

void Push(u8 data)
{
	memory[sp + 0x100] = data;
	sp -= 1;
}

void Push16(u16 data)
{
	memory[sp + 0x100] = ((data >> 8) & 0xFF);
	sp -= 1;
	memory[sp + 0x100] = (data & 0xFF);
	sp -= 1;
}

u8 Pop()
{
	sp += 1;
	return memory[sp + 0x100];
}

u16 Pop16()
{
	sp += 1;
	u8 the1 = memory[sp + 0x100];
	sp += 1;
	u16 the2 =  (u16)memory[sp + 0x100] << 8;
	return (the2 | the1);
}

void Init()
{
	Stop();
	PPU_Reset();
	if (!APUInit())
	{
		if (NSRunAlertPanel(@"Error", @"Could not init sound. Continue?",
							@"Yes", @"No", nil) == NSAlertAlternateReturn)
		{
			Stop();
			return;
		}
	}
	memory = (u8*)malloc(0x10000);
	memset(memory, 0, 0xFFFF);
	//memset(memory, 0xFF, 0xFFFF);	// Apparently this is right
	/*if (dynarec)
	{
		emit = new xEmitter;
		if (!emit)
		{
			dynarec = false;
			NSRunAlertPanel(@"Error",
							@"Could not create CPU structure. Defaulting to interpreter",
							@"Ok", nil, nil);
		}
		else
			emit->Alloc(0x8000 * 4);
	}*/
}

void Reset()
{
	A = X = Y = P = 0x0;
	sp = 0xFF;
	pc = ReadMemory16(0xFFFC);
	backup_2006 = 0;
	lastWriteWas2006 = false;
	lastWriteWasHorizontal = false;
	vramRead = false;
	vramBuffer = 0;
	memset(&opc, 0, sizeof(opc));
	joypad1 = 0;
	inVBLANK = false;
	scanline_cycles = 0;
	if (dynarec)
	
	APUReset();
}

void Stop()
{
	if (memory)
	{
		free(memory);
		memory = NULL;
	}
	PPU_Stop();
	APUStop();
}

void SetCarryFlag(bool set)
{
	if (set)
		P |= 0x1;
	else
		P &= 0xFE;
}

void SetZeroFlag(bool set)
{
	if (set)
		P |= 0x2;
	else
		P &= 0xFD;
}

void SetInterruptFlag(bool set)
{
	if (set)
		P |= 0x4;
	else
		P &= 0xFB;
}

void SetDecimalMode(bool set)
{
	if (set)
		P |= 0x8;
	else
		P &= 0xF7;
}

void SetBreakCommand(bool set)
{
	if (set)
		P |= 0x10;
	else
		P &= 0xEF;
}

void SetOverflowFlag(bool set)
{
	if (set)
		P |= 0x40;
	else
		P &= 0xBF;
}

void SetNegativeFlag(bool set)
{
	if (set)
		P |= 0x80;
	else
		P &= 0x7F;
}

bool CarryFlag()
{
	return (P & 0x1);
}

bool ZeroFlag()
{
	return ((P >> 1) & 0x1);
}

bool InterruptFlag()
{
	return ((P >> 2) & 0x1);
}

bool DecimalMode()
{
	return ((P >> 3) & 0x1);
}

bool BreakCommand()
{
	return ((P >> 4) & 0x1);
}

bool OverflowFlag()
{
	return ((P >> 6) & 0x1);
}

bool NegativeFlag()
{
	return ((P >> 7) & 0x1);
}

void Fetch()
{
	theopcode = ReadMemory(pc);
	opc = opcodes[theopcode];
}

void Step()
{
	Fetch();
	pc++;
	PerformStep(theopcode);
	tcount -= opc.cycles;
	if (cycles <= 0)
	{
		cycles += INTERRUPT_PERIOD;
		// Handle Interrupt
		
		if (enterVBLANK && (memory[0x2000] >> 7) & 0x1 && !inVBLANK)	// V-blank
		{
			Push16(pc);
			Push(P);
			pc = ReadMemory16(0xFFFA);
			SetInterruptFlag(1);
			inVBLANK = true;
		}
		else if (reset)
		{
			reset = false;
			Reset();
		}
	} 
	
	while (scanline_cycles >= CYCLES_PER_SCANLINE)
	{
		updateGraphics++;
		scanline_cycles -= CYCLES_PER_SCANLINE;
	}
}

void Execute(float count)
{
	if (cpuPaused)
		return;
	
	tcount += count;
	while (tcount > 0)
	{
		Fetch();
		pc++;
		int prevC = cycles;
		PerformStep(theopcode);
		tcount -= (prevC - cycles);
		APUExecuteOp(prevC - cycles);
	}
	/*while (scanline_cycles >= 83758.1244)
	{
		updateGraphics++;
		scanline_cycles -= 83758.1244;
	}*/
}

void PerformStep(u16 opcode)
{
	operand = opc.exec();
	//s16 back = cycles;
	cycles -= opc.cycles;
	//scanline_cycles += (back - cycles) * (48/15.0);
}
