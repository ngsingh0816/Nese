//
//  addr.m
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "addr.h"
#import "CPU.h"

u8 ReadImmediate(u16* pos)
{
	return ReadMemory((*pos)++);
}

u8 WriteImmediate(u16* pos, u8 data)
{
	u16 backup = *pos;
	WriteMemory((*pos)++, data);
	return backup;
}

u8 ReadZeroPage(u16* pos)
{
	return ReadMemory(ReadMemory((*pos)++));
}

u8 WriteZeroPage(u16* pos, u8 data)
{
	u8 backup = ReadMemory((*pos)++);
	WriteMemory(backup, data);
	return backup;
}

u8 ReadZeroPageReg(u16* pos, u8 reg)
{
	return ReadMemory((ReadMemory((*pos)++) + reg) & 0xFF);
}

u8 WriteZeroPageReg(u16* pos, u8 reg, u8 data)
{
	u8 backup = ((ReadMemory((*pos)++) + reg) & 0xFF);
	WriteMemory(backup, data);
	return backup;
}

u8 ReadAbsolute(u16* pos)
{
	return ReadMemory(ReadMemory((*pos)++) | (u16)(ReadMemory((*pos)++) << 8));
}

u16 WriteAbsolute(u16* pos, u8 data)
{
	u16 backup = (ReadMemory((*pos)++) | (u16)(ReadMemory((*pos)++) << 8));
	WriteMemory(backup, data);
	return backup;
}

u8 ReadIndexedAbsolute(u16* pos, u8 reg)
{
	u8 aa = ReadMemory((*pos)++);
	u8 bb = ReadMemory((*pos)++);
	u16 place = (aa | ((u16)bb << 8));
	if ((place ^ (place + reg)) & 0x100)
		cycles--;
	place += reg;
	return ReadMemory(place);
}

u16 WriteIndexedAbsolute(u16* pos, u8 reg, u8 data)
{
	u16 backup = ((ReadMemory((*pos)++) | (u16)(ReadMemory((*pos)++) << 8)) + reg);
	WriteMemory(backup, data);
	return backup;
}

u8 ReadIndexedIndirect(u16* pos, u8 reg)
{
	u8 bb = ReadMemory((*pos)++);
	if (bb < ((bb + reg + 1) & 0xFF))
		cycles--;
	u8 xx = ReadMemory((bb + reg) & 0xFF);
	u8 yy = ReadMemory((bb + reg + 1) & 0xFF);
	u8 ret = ReadMemory(xx | ((u16)yy << 8));
	return ret;
}

u16 WriteIndexIndirect(u16* pos, u8 reg, u8 data)
{
	u8 bb = ReadMemory((*pos)++);
	u8 xx = ReadMemory((bb + reg) & 0xFF);
	u8 yy = ReadMemory((bb + reg + 1) & 0xFF);
	u16 backup = (xx | ((u16)yy << 8));
	WriteMemory(backup, data);
	return backup;
}

u8 ReadIndirectIndexed(u16* pos, u8 reg)
{
	u8 bb = ReadMemory((*pos)++);
	u8 xx = ReadMemory(bb);
	u8 yy = ReadMemory((bb + 1) & 0xFF);
	u16 point = xx | ((u16)yy << 8);
	if ((point ^ (point + reg)) & 0x100)
		cycles--;
	u8 end = ReadMemory(point + reg);
	return end;
}

u16 WriteIndirectIndexed(u16* pos, u8 reg, u8 data)
{
	u8 bb = ReadMemory((*pos)++);
	u8 xx = ReadMemory(bb);
	u8 yy = ReadMemory((bb + 1) & 0xFF);
	u16 point = xx |((u16)yy << 8);
	u16 end = point + reg;
	WriteMemory(end, data);
	return end;
}

s8 ReadRelative(u16* pos)
{
	return ((s8)(ReadMemory((*pos)++)));
}
