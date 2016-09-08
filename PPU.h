//
//  PPU.h
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "types.h"

typedef struct
{
	u8 red;
	u8 green;
	u8 blue;
} Color;

#define L1		0x2000
#define A1		0x23C0
#define L2		0x2400
#define A2		0x27C0
#define L3		0x2800
#define A3		0x2BC0
#define L4		0x2C00
#define A4		0x2FC0

extern u16 nameTables[4];
extern u16 attrTables[4];
extern u8* vram;
extern u8* spr_ram;

typedef enum
{
	NONE = 0,
	HORIZONTAL,
	VERTICAL,
	SINGLE,
	FOUR,
} MirrorType;

extern bool showBackground;
extern Color background;

extern Color pallete[64];
extern MirrorType mirroring;
extern bool enterVBLANK;
extern u8 scrollx;
extern u8 scrolly;
extern u16 xpos;
extern u8 ypos;

void WriteVRAM(u16 pos, u8 data);
void WriteVRAMP(u16 pos, u8* data, u16 length);
void WriteVramReg(u16 pos, u8 data);
u8 ReadVRAM(u16 pos);
void WriteSPR(u8 pos, u8 data);
void WriteSPRP(u8 pos, u8* data, u16 length);
u8 ReadSPR(u16 pos);

bool WaitScanline(u8 length);
u8 NumberOfWaited();

void WriteString(NSString* str, NSColor* text, NSColor* box, NSColor* border,
				 NSPoint location, double size, NSString* fontName);

void PPU_Reset();
void PPU_Stop();

void PPU_SkipFrames();
void PPU_DrawScanline();
void PPU_DrawSpriteLine();
void PPU_DrawSprites();
