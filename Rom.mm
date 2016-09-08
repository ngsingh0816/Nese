//
//  Rom.m
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Rom.h"
#import "CPU.h"
#import "PPU.h"
#import "Mappers.h"

u8** pgr_banks = NULL;
int sizePGR = 0;
u8** chr_banks = NULL;
int sizeCHR = 0;

BOOL ReadRom(NSString* filename)
{
	for (int z = 0; z < sizePGR; z++)
	{
		free(pgr_banks[z]);
		pgr_banks[z] = NULL;
	}
	free(pgr_banks);
	pgr_banks = NULL;
	sizePGR = 0;
	
	for (int z = 0; z < sizeCHR; z++)
	{
		free(chr_banks[z]);
		chr_banks[z] = NULL;
	}
	free(chr_banks);
	chr_banks = NULL;
	sizeCHR = 0;
	
	FILE* file = fopen([ filename UTF8String ], "rb");
	if (!file)
		return FALSE;
	
	char signature[4];
	fread(signature, 4, 1, file);
	if (signature[0] != 'N' || signature[1] != 'E' ||
		signature[2] != 'S' || signature[3] != 0x1A)
	{
		fclose(file);
		return FALSE;
	}
	
	int numofp = 0;
	fread(&numofp, 1, 1, file);
	if (numofp == 0)
		return FALSE;
	int numofc = 0;
	fread(&numofc, 1, 1, file);
	
	u8 byte1 = 0;
	fread(&byte1, 1, 1, file);
	u8 byte2 = 0;
	fread(&byte2, 1, 1, file);
	
	mapper = ((byte2 >> 4) << 4) | (byte1 >> 4);
	int mirr = (byte1 & 0x1);
	if ((byte1 >> 3) & 0x1)
		mirr = 4;	// Four Screen
	mirroring = (MirrorType)(mirr+1);
	//int battery = (byte1 >> 1) & 0x1;
	int trainer = (byte1 >> 2) & 0x1;
	if (trainer)
	{
		char* buffer = (char*)malloc(512);
		fread(buffer, 512, 1, file);
		free(buffer);
		buffer = NULL;
	}
	
	int numofram = 0;
	fread(&numofram, 1, 1, file);
	if (numofram == 0)
		numofram = 1;
	
	char* buffer = (char*)malloc(7);
	fread(buffer, 7, 1, file);
	free(buffer);
	buffer = NULL;	
	
	Init();
	
	sizePGR = numofp;
	sizeCHR = numofc;
	pgr_banks = (u8**)malloc(numofp * sizeof(u8*));
	chr_banks = (u8**)malloc(numofc * sizeof(u8*));
	
	for (int z = 0; z < numofp; z++)
	{
		u8* data = (u8*)malloc(0x4000);
		fread(data, 0x4000, 1, file);
		pgr_banks[z] = data;
	}
	for (int z = 0; z < numofc; z++)
	{
		u8* data = (u8*)malloc(0x2000);
		fread(data, 0x2000, 1, file);
		chr_banks[z] = data;
	}
	
	MapperLoadRom();
	if (numofc != 0)
		WriteVRAMP(0x0000, chr_banks[numofc - 1], 0x2000);
	
	Reset();
	ResetMapper();
	
	return TRUE;
}