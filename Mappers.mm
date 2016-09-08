//
//  Mappers.m
//  Nese
//
//  Created by MILAP on 5/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Mappers.h"
#import "Rom.h"
#import "CPU.h"
#import "PPU.h"

std::vector<u8> registers;
u8 writes;
u8 lastWrite;

void MapperLoadRom()
{
	switch (mapper)
	{
		case 0:
		{
			if (sizePGR == 1)
			{
				WriteMemoryP(0x8000, pgr_banks[0], 0x4000);
				WriteMemoryP(0xC000, pgr_banks[0], 0x4000);
			}
			else
			{
				WriteMemoryP(0x8000, pgr_banks[0], 0x4000);
				WriteMemoryP(0xC000, pgr_banks[1], 0x4000);
			}
			break;
		}
		case 1:
		case 2:
		{
			WriteMemoryP(0x8000, pgr_banks[0], 0x4000);
			WriteMemoryP(0xC000, pgr_banks[sizePGR - 1], 0x4000);
		}
		case 3:
			WriteMemoryP(0x8000, pgr_banks[0], 0x4000);
			if (sizePGR == 1)
				WriteMemoryP(0xC000, pgr_banks[0], 0x4000);
			else
				WriteMemoryP(0xC000, pgr_banks[1], 0x4000);
			break;
	}
}

void ResetMapper()
{
	registers.clear();
	switch (mapper)
	{
		case 0:
			break;
		case 1:	// MMC1
			registers.resize(4);
			registers[0] = 0xC;
			lastWrite = -1;
			break;
		case 2:	// UNROM
			break;
		case 3:
			break;
	}
	writes = 0;
}

void SwitchBanks(u16 pos, u8* data, u16 length)
{
	WriteMemoryP(pos, data, length);
}

void SwapCHR(u16 pos, u8* data, u16 length)
{
	WriteVRAMP(pos, data, length);
}

bool CheckMapperWrite(u16 pos, u8 data)
{
	switch (mapper)
	{
		case 0:		// None
			return false;
		case 1:		// MMC1
		{
			if (pos >= 0x8000 && pos < 0xA000)
			{
				if (lastWrite != 0)
				{
					lastWrite = 0;
					writes = 0;
				}
				registers[0] &= 0xFF - (1 << writes);
				registers[0] |= (data & 0x1) << writes;
				writes++;
				if ((data >> 7) & 0x1)
				{
					writes = 0;
					u8 backup4 = registers[0] >> 4;
					registers[0] = 0xC | backup4;
					break;
				}
				
				if (writes != 5)
					break;
				
				mirroring = (MirrorType)((registers[0] & 0x1) + 1);
				if (!(registers[0] >> 1) & 0x1)
					mirroring = SINGLE;
				
				writes = 0;
			}
			else if (pos >= 0xA000 && pos < 0xC000)
			{
				if (lastWrite != 1)
				{
					lastWrite = 1;
					writes = 0;
				}
				registers[1] &= 0xFF - (1 << writes);
				registers[1] |= (data & 0x1) << writes;
				writes++;
				if ((data >> 7) & 0x1)
				{
					writes = 0;
					//registers[1] = 0;
					break;
				}
				
				if (writes != 5)
					break;
				
				writes = 0;
				if (sizeCHR == 0)
					break;
				
				if (!((registers[0] >> 4) & 0x1))
				{
					SwapCHR(0x0, chr_banks[registers[1] & 0x1F], 0x1000);
				}
				else
				{
					SwapCHR(0x0, chr_banks[(registers[1] >> 1) & 0x1F], 0x1000);
					SwapCHR(0x1000, chr_banks[((registers[1] >> 1) + 1) &
											  0x1F], 0x1000);
				}
			}
			else if (pos >= 0xC000 && pos < 0xE000)
			{
				if (lastWrite != 2)
				{
					lastWrite = 2;
					writes = 0;
				}
				registers[2] &= 0xFF - (1 << writes);
				registers[2] |= (data & 0x1) << writes;
				writes++;
				if ((data >> 7) & 0x1)
				{
					writes = 0;
				//	registers[2] = 0;
					break;
				}
				
				if (writes != 5)
					break;
				
				if ((registers[0] >> 4) & 0x1)
					SwapCHR(0x1000, chr_banks[registers[2] & 0x1F], 0x1000);
				
				writes = 0;
			}
			else if (pos >= 0xE000)
			{
				if (lastWrite != 3)
				{
					lastWrite = 3;
					writes = 0;
				}
				registers[3] &= 0xFF - (1 << writes);
				registers[3] |= (data & 0x1) << writes;
				writes++;
				if ((data >> 7) & 0x1)
				{
					writes = 0;
				//	registers[3] = 0;
					break;
				}
				
				if (writes != 5)
					break;
				
				if ((registers[0] >> 3) & 0x1)
				{
					if (!(registers[0] >> 2) & 0x1)
					{
						SwitchBanks(0x8000, pgr_banks[0], 0x4000);
						SwitchBanks(0xC000, pgr_banks[registers[3]], 0x4000);
					}
					else
					{
						SwitchBanks(0x8000, pgr_banks[registers[3]], 0x4000);
						SwitchBanks(0xC000, pgr_banks[sizePGR - 1], 0x4000);
					}
				}
				else
				{
					SwitchBanks(0x8000, pgr_banks[(registers[3] >> 1)], 0x4000);
					SwitchBanks(0xC000, pgr_banks[((registers[3] >> 1) + 1)], 0x4000);
				}
				
				writes = 0;
			}
			else
				return false;
			return true;
		}
		case 2:		// UNROM
			if (pos >= 0x8000)
			{
				SwitchBanks(0x8000, pgr_banks[(data & 7)], 0x4000);
				return true;
			}
			return false;
		case 3:
			if (pos >= 0x8000)
			{
				SwapCHR(0x0000, chr_banks[data], 0x2000);
				return true;
			}
			return false;
	}
	return false;
}