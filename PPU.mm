//
//  PPU.m
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PPU.h"
#import "CPU.h"
#import "Controller.h"
#import "GLString.h"
#import "APU.h"

u8* vram;
u8* spr_ram;

bool enterVBLANK = false;

u8 sprSize = 8;
u16 screenPattern = 0x1000;
u16 spritePattern = 0x0000;
u8 table = 0;
u16 nameAddress = L1;
u16 attrAddress = A1;
u8 monochrome = 0xFF;
Color background = (Color){ 0, 0, 0 };
bool showBackground;
bool showSprites;
MirrorType mirroring = HORIZONTAL;
u8 scrollx = 0;
u8 scrolly = 0;

u8 waited = 0;

u16 xpos = 0;
u8 ypos = 0;

u16 nameTables[4] = { L1, L2, L3, L4 };
u16 attrTables[4] = { A1, A2, A3, A4 };

Color pallete[64] =
{
	{0x80,0x80,0x80}, {0x00,0x00,0xBB}, {0x37,0x00,0xBF}, {0x84,0x00,0xA6},
	{0xBB,0x00,0x6A}, {0xB7,0x00,0x1E}, {0xB3,0x00,0x00}, {0x91,0x26,0x00},
	{0x7B,0x2B,0x00}, {0x00,0x3E,0x00}, {0x00,0x48,0x0D}, {0x00,0x3C,0x22},
	{0x00,0x2F,0x66}, {0x00,0x00,0x00}, {0x05,0x05,0x05}, {0x05,0x05,0x05},
	
	{0xC8,0xC8,0xC8}, {0x00,0x59,0xFF}, {0x44,0x3C,0xFF}, {0xB7,0x33,0xCC},
	{0xFF,0x33,0xAA}, {0xFF,0x37,0x5E}, {0xFF,0x37,0x1A}, {0xD5,0x4B,0x00},
	{0xC4,0x62,0x00}, {0x3C,0x7B,0x00}, {0x1E,0x84,0x15}, {0x00,0x95,0x66},
	{0x00,0x84,0xC4}, {0x11,0x11,0x11}, {0x09,0x09,0x09}, {0x09,0x09,0x09},
	
	{0xFF,0xFF,0xFF}, {0x00,0x95,0xFF}, {0x6F,0x84,0xFF}, {0xD5,0x6F,0xFF},
	{0xFF,0x77,0xCC}, {0xFF,0x6F,0x99}, {0xFF,0x7B,0x59}, {0xFF,0x91,0x5F},
	{0xFF,0xA2,0x33}, {0xA6,0xBF,0x00}, {0x51,0xD9,0x6A}, {0x4D,0xD5,0xAE},
	{0x00,0xD9,0xFF}, {0x66,0x66,0x66}, {0x0D,0x0D,0x0D}, {0x0D,0x0D,0x0D},
	
	{0xFF,0xFF,0xFF}, {0x84,0xBF,0xFF}, {0xBB,0xBB,0xFF}, {0xD0,0xBB,0xFF},
	{0xFF,0xBF,0xEA}, {0xFF,0xBF,0xCC}, {0xFF,0xC4,0xB7}, {0xFF,0xCC,0xAE},
	{0xFF,0xD9,0xA2}, {0xCC,0xE1,0x99}, {0xAE,0xEE,0xB7}, {0xAA,0xF7,0xEE},
	{0xB3,0xEE,0xFF}, {0xDD,0xDD,0xDD}, {0x11,0x11,0x11}, {0x11,0x11,0x11}
};

void Mirror(u16 pos, u8 data)
{
	if (pos >= L4)
	{
		switch (mirroring)
		{
			case HORIZONTAL:
				vram[(pos - L4) + L2] = data; 
				break;
			case VERTICAL:
				vram[(pos - L4) + L2] = data; 
				break;
			case SINGLE:
				vram[(pos - L4) + L1] = data; 
				vram[(pos - L4) + L2] = data; 
				vram[(pos - L4) + L3] = data;
			default:
				break;
		}
	}
	else if (pos >= L3)
	{
		switch (mirroring)
		{
			case HORIZONTAL:
				vram[(pos - L3) + L2] = data; 
				break;
			case VERTICAL:
				vram[(pos - L3) + L1] = data; 
				break;
			case SINGLE:
				vram[(pos - L3) + L1] = data; 
				vram[(pos - L3) + L2] = data; 
				vram[(pos - L3) + L4] = data;
			default:
				break;
		}
	}
	else if (pos >= L2)
	{
		switch (mirroring)
		{
			case HORIZONTAL:
				vram[(pos - L2) + L1] = data; 
				break;
			case VERTICAL:
				vram[(pos - L2) + L4] = data; 
				break;
			case SINGLE:
				vram[(pos - L2) + L1] = data; 
				vram[(pos - L2) + L3] = data;
				vram[(pos - L2) + L4] = data;
			default:
				break;
		}
	}
	else
	{
		switch (mirroring)
		{
			case HORIZONTAL:
				vram[(pos - L1) + L2] = data; 
				break;
			case VERTICAL:
				vram[(pos - L1) + L3] = data; 
				break;
			case SINGLE:
				vram[(pos - L1) + L2] = data;
				vram[(pos - L1) + L3] = data;
				vram[(pos - L1) + L4] = data;
			default:
				break;
		}
	}
}

void WriteVRAM(u16 pos, u8 data)
{
	if (pos >= 0x2000 && pos < 0x3000)
		Mirror(pos, data);
	else if (pos == 0x3F00)
		vram[0x3F10] = data;
	else if (pos == 0x3F10)
		vram[0x3F00] = data;
	vram[pos] = data;
}

void WriteVRAMP(u16 pos, u8* data, u16 length)
{
	for (int z = 0; z < length; z++)
		vram[pos + z] = data[z];
}

void WriteVramReg(u16 pos, u8 data)
{
	switch (pos)
	{
		case 0x2000:
		{
			sprSize = (((data >> 5) & 0x1) * 8) + 8;
			screenPattern = ((data >> 4) & 0x1) * 0x1000;
			table = data & 0x3;
			nameAddress = nameTables[table];
			attrAddress = attrTables[table];
			break;
		}
		case 0x2001:
		{
			monochrome = (!(data & 0x1)) * 0xFF;
			background = (Color){ (data >> 5) & 0x1, (data >> 6) & 0x1, (data >> 7) & 0x1 };
			showBackground = (data >> 3) & 0x1;
			showSprites = (data >> 4) & 0x1;
			break;
		}
	}
}

u8 ReadVRAM(u16 pos)
{
/*	u16 thepos = pos;
	if (thepos >= 0x2000 && thepos < 0x3000)
	{
		if (thepos >= L1 && thepos < L2)
			thepos -= L1;
		else if (thepos >= L2 && thepos < L3)
			thepos -= L2;
		else if (thepos >= L3 && thepos < L4)
			thepos -= L3;
		else
			thepos -= L4;
		switch (mirroring)
		{
			case HORIZONTAL:
			{
				if (pos >= L3)
					vram[thepos + L2];
				else
					vram[thepos + L1];
			}
			case VERTICAL:
			{
				if ((pos >= L3 && pos < L4) || (pos < L2))
					vram[thepos+ L1];
				else
					vram[thepos + L2];
			}
			case SINGLE:
				return vram[thepos + L1];
		}
	}*/
	return vram[pos];
}

void WriteSPR(u8 pos, u8 data)
{
	spr_ram[pos] = data;
}

void WriteSPRP(u8 pos, u8* data, u16 length)
{
	for (int z = 0; z < length; z++)
		WriteSPR(pos + z, data[z]);
}

u8 ReadSPR(u16 pos)
{
	return spr_ram[pos];
}

void PPU_Reset()
{
	vram = (u8*)malloc(0x10000);
	spr_ram = (u8*)malloc(0x100);
	enterVBLANK = false;
}

void PPU_Stop()
{
	if (vram)
	{
		free(vram);
		vram = NULL;
	}
	if (spr_ram)
	{
		free(spr_ram);
		spr_ram = NULL;
	}
}


bool WaitScanline(u8 lines)
{
	waited++;
	Execute(CYCLES_PER_SCANLINE);
	if (waited == lines)
	{
		waited = 0;
		return true;
	}
	return false;
}

u8 NumberOfWaited()
{
	return waited;
}

void PPU_SkipFrames()
{
	DisableSpriteHit();
	Execute(CYCLES_PER_SCANLINE);	// dummy scanline
	for (ypos = 0;; ypos += 8)
	{
		if (enterVBLANK)
		{
			if (cycles <= 0)
				cycles += INTERRUPT_PERIOD;
			else
				Execute(cycles);
			if (((ReadMemory(0x2000) >> 7) & 0x1) && !inVBLANK)	// V-blank
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
			
			if (WaitScanline(20))
			{
				enterVBLANK = false;
				DisableVBLANK();
				if (monochrome)
					background = (Color)pallete[ReadVRAM(0x3F00)];
				break;
			}
			continue;
		}
		glLoadIdentity();
		
		if (ypos >= 240)
		{
			if (cpuPaused)
				break;
			
			Execute(CYCLES_PER_SCANLINE);	// 2nd dummy scanline
			//if (WaitScanline(3))
			{
				ypos = 0;
				enterVBLANK = true;
				EnableVBLANK();
			}
			continue;
		}
		
		if (!showBackground)
		{
			Execute(CYCLES_PER_SCANLINE * 8);
			DisableEightSprites();
			for (int y = 0; y < 8; y++)
			{
				ypos++;
				PPU_DrawSpriteLine();
			}
			continue;
		}
		
		if (ypos > 231 || ypos <= 7)
		{
			ypos++;
			Execute(CYCLES_PER_SCANLINE);
			continue;
		}
		
		
		Execute(CYCLES_PER_SCANLINE * 8);
		DisableEightSprites();
	}
	
	APUDoLoop();
}

void PPU_DrawScanline()
{	
	Execute(CYCLES_PER_SCANLINE);	// dummy scanline
	for (ypos = 0; ; ypos += 8)
	{
		if (enterVBLANK)
		{
			if (cycles <= 0)
				cycles += INTERRUPT_PERIOD;
			else
				Execute(cycles);
			if (((ReadMemory(0x2000) >> 7) & 0x1) && !inVBLANK)	// V-blank
			{
				Push16(pc);
				Push(P);
				pc = ReadMemory16(0xFFFA);
				SetInterruptFlag(1);
				inVBLANK = true;
				DisableSpriteHit();
			}
			else if (reset)
			{
				reset = false;
				Reset();
			}
			
			if (WaitScanline(20))
			{
				enterVBLANK = false;
				DisableVBLANK();
				if (monochrome)
					background = (Color)pallete[ReadVRAM(0x3F00)];
				break;
			}
			continue;
		}
		glLoadIdentity();
		
		if (ypos >= 240)
		{
			if (cpuPaused)
				break;
	
			Execute(CYCLES_PER_SCANLINE * 2);	// 2nd dummy scanline
			//if (WaitScanline(3))
			{
				ypos = 0;
				enterVBLANK = true;
				EnableVBLANK();
			}
			continue;
		}
		
		if (!showBackground)
		{
			Execute(CYCLES_PER_SCANLINE * 8);
			DisableEightSprites();
			for (int y = 0; y < 8; y++)
			{
				ypos++;
				PPU_DrawSpriteLine();
			}
			ypos -= 8;
			if (ypos == 239)
			{
				glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
				glClearColor(background.red, background.green, background.blue, 1);
			}
			continue;
		}
		
		if (ypos > 231 || ypos <= 7)
		{
			Execute(CYCLES_PER_SCANLINE * 8);
			continue;
		}
	
		
		glLoadIdentity();
		glBegin(GL_POINTS);
		xpos = 0;
		for (;;)
		{
			Execute(CYCLES_PER_SCANLINE / 4.0);
			
			u16 newx = xpos + scrollx - (scrollx % 8);
			u16 newy = ypos + scrolly - (scrolly % 8);
			
			nameAddress = nameTables[table];
			attrAddress = attrTables[table];
		
			if (newy + scrolly > 239)
			{
				newy %= 240;
				nameAddress = nameTables[(table + 2) & 3];
				attrAddress = attrTables[(table + 2) & 3];
			}
			else if (newx > 0xFF)
			{
				newx &= 0xFF;
				nameAddress = nameTables[(table + 1) & 3];
				attrAddress = attrTables[(table + 1) & 3];
			}
			
			for (int te = 0; te < 8; te++)
			{
				u16 pixel = ReadVRAM(((newx / 8) + ((newy / 8) * 0x20)) + nameAddress);
				u8 sprite1 = ReadVRAM(screenPattern + (pixel * 16) + te);
				u8 sprite2 = ReadVRAM(screenPattern + (pixel * 16) + 8 + te);
				
				//glLoadIdentity();
				//glTranslated(xpos - (scrollx % 8), ypos - (scrolly % 8), 0);
				float transX = xpos - (scrollx % 8), transY = ypos - (scrolly % 8);
				for (int qe = 0; qe < 8; qe++)
				{
					u8 spr = ((sprite1 >> (7-qe)) & 0x1) | (((sprite2 >> (7-qe)) & 0x1) << 1);
					if (spr == 0)
						continue;
					
					u8 col = spr;
					u8 bit = ((((newx / 8) & 3) > 1) + ((((newy / 8) & 3) > 1) * 2)) * 2;
					u8 ocol = ((ReadVRAM(attrAddress + (newx / 0x20)
										 + ((newy / 0x20) * 8)))
						>> bit) & 0x3;
					Color color = pallete[ReadVRAM(0x3F00 + (col | (ocol << 2)))];
					glColor3d(color.red / 255.0, color.green / 255.0, color.blue / 255.0);
					/*glBegin(GL_QUADS);
					{
						glVertex2d(qe, te);
						glVertex2d((qe + 1), te);
						glVertex2d((qe + 1), te + 1);
						glVertex2d(qe, te + 1);
					}
					glEnd();*/
					glVertex2d(qe + transX, te + transY);
				}
			}
			
			xpos += 8;
			if (xpos == 264)
				break;
		}
		DisableEightSprites();
		
		int backup = ypos;
		for (int te = 0; te < 8; te++)
		{
			ypos++;
			PPU_DrawSpriteLine();
		}
		glEnd();
		ypos = backup;
	}
	
	APUDoLoop();
}

// Write text to screen
void WriteString(NSString* str, NSColor* text, NSColor* box, NSColor* border,
				 NSPoint location, double size, NSString* fontName)
{
	// Init string and font
	NSFont* font = [ NSFont fontWithName:fontName size:size ];
	if (font == nil)
		return;
	
	GLString* string = [ [ GLString alloc ] initWithString:str withAttributes:[ NSDictionary
		dictionaryWithObjectsAndKeys:text, NSForegroundColorAttributeName, font,
				NSFontAttributeName, nil ] withTextColor: text withBoxColor: box 
										   withBorderColor: border ];
	
	// Get ready to draw
	int s = 0;
	glGetIntegerv (GL_MATRIX_MODE, &s);
	glMatrixMode (GL_PROJECTION);
	glPushMatrix();
	glLoadIdentity ();
	glMatrixMode (GL_MODELVIEW);
	glPushMatrix();
	
	// Draw
	glLoadIdentity();    // Reset the current modelview matrix
	glScaled(2.0 / 256, -2.0 / 224, 1.0);
	glTranslated(-256 / 2.0, -224 / 2.0, 0.0);
	glColor4f(1.0f, 1.0f, 1.0f, 1.0f);	// Make right color
	
	[ string drawAtPoint:location ];
	
	// Reset things
	glPopMatrix(); // GL_MODELVIEW
	glMatrixMode (GL_PROJECTION);
    glPopMatrix();
    glMatrixMode (s);
	
	// Cleanup
	[ string release ];
}

void PPU_DrawSpriteLine()
{
	if (!showSprites || ypos > 239)
		return;
	
	u8 numofs = 0;
	for (s32 i = 63; i >= 0; i--)
	{
		// Get Info
		u8 y = ReadSPR((i*4))+2;
		if ((y > ypos || (y + sprSize) <= ypos) || y == 0xF0)
			continue;
		if (numofs == 8)
		{
			EnableEightSprites();
			break;
		}
		
		numofs++;
		
		u16 num = ReadSPR((i*4)+1);
		u8 attr = ReadSPR((i*4)+2);
		u8 x = ReadSPR((i*4)+3);
		u8 yp = ypos - y;
		
		if (spriteLabel && yp == 4)
		{
			WriteString([ NSString stringWithFormat:@"%i", i / 4 ],
						[ NSColor whiteColor ], [ NSColor clearColor ],
						[ NSColor clearColor ], NSMakePoint(x, y), 8, @"Helvetica");
		}
		
		u16 sprPattern = spritePattern;
		if (sprSize == 16)
		{
			if ((num % 2) == 0)
				sprPattern = 0x0000;
			else
				sprPattern = 0x1000;
		}
		u16 patternTableAddr = (num * 16) + sprPattern;
		
		if ((attr >> 7 ) & 0x1)
			yp = 7 - yp;
		
		u8 flipped = !(((attr >> 6) & 0x1)) * 7;
		bool visible = !((attr >> 5) & 0x1);
		
		u8 spr1 = ReadVRAM(patternTableAddr + yp);
		u8 spr2 = ReadVRAM(patternTableAddr + yp + 0x8);
		u8 spr3 = 0;
		u8 spr4 = 0;
		if (sprSize == 16)
		{
			spr3 = ReadVRAM(patternTableAddr + yp + 0x10);
			spr4 = ReadVRAM(patternTableAddr + yp + 0x18);
		}
		
		u8 totalY = yp;
		if ((attr >> 7) & 0x1)
			totalY = abs(sprSize - yp - 1);
		
		u8* spr = (u8*)malloc(24);
		glReadPixels(xpos, ypos, 8, 1, GL_UNSIGNED_BYTE, GL_RGB, spr);
		for (int xp = 0; xp < 8; xp++)
		{
			u8 col = 0;
			if (sprSize == 8 || yp < 8)
			{
				col = (((spr1 >> (abs(flipped-xp))) & 0x1) |
						(((spr2 >> (abs(flipped-xp))) & 0x1) << 1)) & 0x3;
			}
			else
			{
				col = (((spr3 >> (abs(flipped-xp))) & 0x1) |
					   (((spr4 >> (abs(flipped-xp))) & 0x1) << 1)) & 0x3;
			}
			u8 ocol = attr & 0x3;
			
			if (col == 0)
				continue;
			
			/*u16 newx = x + scrollx + xp;
			u16 newy = y + scrolly + yp;
			newy %= 240;
			newx &= 0xFF;
			
			nameAddress = nameTables[table];
			attrAddress = attrTables[table];
			
			if (newy > 239)
			{
				newy %= 240;
				nameAddress = nameTables[(table + 2) & 3];
				attrAddress = attrTables[(table + 2) & 3];
			}
			else if (newx > 255)
			{
				newx &= 255;
				nameAddress = nameTables[(table + 1) & 3];
				attrAddress = attrTables[(table + 1) & 3];
			}*/
			
		/*	u16 pixel = ReadVRAM(((newx / 8) + ((newy / 8) * 0x20)) + nameAddress);
			u8 sprite1 = ReadVRAM(screenPattern + (pixel * 16) + (newy & 7));
			u8 sprite2 = ReadVRAM(screenPattern + (pixel * 16) + 8 + (newy & 7));
			u8 spr = ((sprite1 >> (newx & 7)) & 0x1) |
				(((sprite2 >> (newx & 7)) & 0x1) << 1);
			u8 bit = ((((newx / 8) & 3) > 1) + ((((newy / 8) & 3) > 1) * 2)) * 2;
			u8 ospr = ((ReadVRAM(attrAddress + (newx / 0x20) + ((newy / 0x20) * 8)))
					   >> bit) & 0x3;*/
			//if (i == 0 && ((spr | (ospr << 2)) != 0))
			
			if (i == 0 && spr[0 + (3 * xp)] != background.red &&
				spr[1 + (3 * xp)] != background.green && spr[2 + (3 * xp)] != background.blue)
				EnableSpriteHit();
			if (spr[0 + (3 * xp)] != background.red && spr[1 + (3 * xp)] !=
					background.green && spr[2 + (3 * xp)] != background.blue && !visible)
				continue;
			
			Color color = pallete[ReadVRAM(0x3F10 + (col | (ocol << 2)))];
			//glLoadIdentity();
			glColor3d(color.red / 255.0, color.green / 255.0, color.blue / 255.0);
			/*glBegin(GL_QUADS);
			{
				glVertex2d(xp + x, totalY + y);
				glVertex2d(xp + x + 1, totalY + y);
				glVertex2d(xp + x + 1, totalY + y + 1);
				glVertex2d(xp + x, totalY + y + 1);
			}
			glEnd();*/
			glVertex2d(xp + x, totalY + y);
		}
		free(spr);
		spr = NULL;
	}
}

void PPU_DrawSprites()
{
	if (!showSprites)
		return;
	
	for (u16 i = 0; i < 0x100; i += 4)
	{
		// Get Info
		u8 y = ReadSPR(i);
		if (y == 0xF0 || y == 0)
			continue;
		u16 num = ReadSPR(i+1);
		u8 attr = ReadSPR(i+2);
		u8 x = ReadSPR(i+3);
		if (x == 0)
			continue;
		
		glLoadIdentity();
		glTranslated(x, y, 0);
		u16 patternTableAddr = spritePattern + (num * 16);
		if ((attr >> 7) & 0x1)
			patternTableAddr += 8;
		u8 flipped = !(((attr >> 6) & 0x1)) * 7;
		bool visible = !((attr >> 5) & 0x1);
		for (int yp = 0; yp < 8; yp++)
		{
			u8 spr1 = ReadVRAM(patternTableAddr);
			u8 spr2 = ReadVRAM(patternTableAddr + 8);
			if ((attr >> 5) & 0x1)
				patternTableAddr--;
			else
				patternTableAddr++;
			for (int xp = 0; xp < 8; xp++)
			{
				u8 col = (((spr1 >> (abs(flipped-xp))) & 0x1) |
					(((spr2 >> (abs(flipped-xp))) & 0x1) << 1)) & 0x3;
				if (col == 0)
					continue;
				
				u16 pixel = ReadVRAM(((x / 8) + ((y / 8) * 0x20)) + nameAddress);
				u8 sprite1 = ReadVRAM(screenPattern + (pixel * 16) + ((y + yp) % 8));
				u8 sprite2 = ReadVRAM(screenPattern + (pixel * 16) + 8 + ((y + yp) % 8));
				u8 spr = ((sprite1 >> (x % 8)) & 0x1) | (((sprite2 >> (x % 8)) & 0x1) << 1);
				if (i == 0 && spr != 0)
					EnableSpriteHit();
				else if (spr != 0 && !visible)
					continue;
				
				u8 ocol = attr & 0x3;
				Color color = pallete[ReadVRAM(0x3F10 + (col | (ocol << 2)))];
				glColor3d(color.red, color.green, color.blue);
				glBegin(GL_QUADS);
				{
					glVertex2d(xp, yp);
					glVertex2d(xp + 1, yp);
					glVertex2d(xp + 1, yp + 1);
					glVertex2d(xp, yp + 1);
				}
				glEnd();
			}
		}
	}
}


