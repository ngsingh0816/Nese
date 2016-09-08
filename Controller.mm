//
//  Controller.m
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Controller.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>

NSString* filename = nil;
bool stop = false;
float frameSkip = 0;
u32 updateGraphics = 0;
bool cpuPaused = false;
bool spriteLabel = false;

id glView;
id pad;
id audio;

@implementation Controller

- (void) awakeFromNib
{
	[ (NSApplication*)NSApp setDelegate:(id<NSApplicationDelegate>)self ];    // We want delegate notifications
    renderTimer = nil;
    [ emuWindow makeFirstResponder:self ];
	running = false;
	CreateCodes();
	
	[ emuWindow setDelegate:(id)self ];
	[ palleteWindow setDelegate:(id) self ];
	[ perferenceWindow setDelegate:(id) self ];
	
	// Init plugins
	pad = [ [ [ Pad alloc ] init ] retain ];
	//audio = [ [ [ ALSound alloc ] init ] retain ];
	audio = [ [ [ CASound alloc ] init ] retain ];
	
	// Config
	[ self readPreferences ];
	[ glView readConfig ];
	[ pad readConfig ];
	[ audio readConfig ];
}

- (void) savePreferences
{
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/config.txt",
						  [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "w");
	if (file)
	{
		fprintf(file, "FPS = %.2f\n", [ fpsValue doubleValue ]);
		fprintf(file, "Video = %s\n", [ [ [ videoPlugin stringValue ] 
			stringByReplacingOccurrencesOfString:@" " withString:@"%20" ] UTF8String ]);
		fprintf(file, "Audio = %s\n", [ [ [ audioPlugin stringValue ] 
			stringByReplacingOccurrencesOfString:@" " withString:@"%20" ] UTF8String ]);
		fprintf(file, "Controller = %s\n", [ [ [ controllerPlugin stringValue ] 
			stringByReplacingOccurrencesOfString:@" " withString:@"%20" ] UTF8String ]);
		fclose(file);
	}
}

- (void) readPreferences
{
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/config.txt",
						  [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "r");
	if (file)
	{
		float f;
		fscanf(file, "FPS = %f\n", &f);
		[ fpsValue setDoubleValue:f ];
		char* videoP = (char*)malloc(512);
		char* audioP = (char*)malloc(512);
		char* controllerP = (char*)malloc(512);
		fscanf(file, "Video = %s\n", videoP);
		fscanf(file, "Audio = %s\n", audioP);
		fscanf(file, "Controller = %s\n", controllerP);
		fclose(file);
		
		free(videoP);
		free(audioP);
		free(controllerP);
	}
}

- (IBAction) open: (id) sender
{
	NSOpenPanel* openPanel = [ NSOpenPanel openPanel ];
	if ([ openPanel runModalForTypes:[ NSArray arrayWithObject:@"nes" ] ])
	{
		if (!ReadRom([ openPanel filename ]))
			NSRunAlertPanel(@"Error", @"Invalid File", @"Ok", nil, nil);
		else
		{
			filename = [ [ NSString stringWithString:[ openPanel filename ] ] retain ];
			[ self startEmulation ];
		}
	}
}

- (IBAction) play: (id) sender
{
	if (running || !filename)
		return;
	if (!ReadRom(filename))
	{
		NSRunAlertPanel(@"Error", @"Invalid File", @"Ok", nil, nil);
		return;
	}
	[ self startEmulation ];
}

- (IBAction) pause: (id) sender
{
	if (filename == nil)
		return;
	if (![ [ sender title ] isEqualToString:@"Resume" ])
	{
		[ sender setTitle:@"Resume" ];
		[ self setStatusMessage:@"Paused" ];
		[ step setEnabled:YES ];
		cpuPaused = true;
	}
	else
	{
		[ sender setTitle:@"Pause" ];
		[ self setStatusMessage:@"Resumed" ];
		[ step setEnabled:NO ];
		cpuPaused = false;
	}
}

- (IBAction) stop: (id) sender
{
	if (filename == nil)
		return;
	Stop();
	stop = false;
	running = false;
	[ glView removeFromSuperview ];
	[ renderTimer invalidate ];
	[ fpsTimer invalidate ];
	[ emuWindow setTitle:@"Nese" ];
}

- (void) updateDebugger
{
	Fetch();
	
	if ([ debuggerWindow isVisible ])
	{
		[ pcVal setStringValue:[ Controller decToHex:pc ] ];
		[ aVal setStringValue:[ Controller decToHex:A ] ];
		[ xVal setStringValue:[ Controller decToHex:X ] ];
		[ yVal setStringValue:[ Controller decToHex:Y ] ];
		[ spVal setStringValue:[ Controller decToHex:sp ] ];
		[ opcVal setStringValue:opc.name ];
		
		[ carryFlag setState:(P & 0x1) ];
		[ zeroFlag setState:((P >> 1) & 0x1) ];
		[ interruptFlag setState:((P >> 2) & 0x1) ];
		[ decimalFlag setState:((P >> 3) & 0x1) ];
		[ breakFlag setState:((P >> 4) & 0x1) ];
		[ overflowFlag setState:((P >> 6) & 0x1) ];
		[ negativeFlag setState:((P >> 7) & 0x1) ];
		[ pVal setStringValue:[ Controller decToHex:P ] ];
		
		u16 backup = pc + 1;
		s32 opr = 0;
		u16 addr = 0;
		if ([ opc.mode isEqualToString:ZeroPage ])
		{
			addr = ReadMemory(backup);
			opr = ReadZeroPage(&backup);
		}
		else if ([ opc.mode isEqualToString:ZeroPageX ])
		{
			addr = ReadMemory(backup) + X;
			opr = ReadZeroPageReg(&backup, X);
		}
		else if ([ opc.mode isEqualToString:ZeroPageY ])
		{
			addr = ReadMemory(backup) + Y;
			opr = ReadZeroPageReg(&backup, Y);
		}
		else if ([ opc.mode isEqualToString:Absolute ])
		{
			u8 aa = ReadMemory(backup);
			u8 bb = ReadMemory(backup+1);
			addr = ((u16)bb << 8) | aa;
			if ([ opc.name isEqualToString:@"JMP" ] || [ opc.name isEqualToString:@"JSR" ])
				opr = addr;
			else
				opr = ReadAbsolute(&backup);
		}
		else if ([ opc.mode isEqualToString:AbsoluteX ])
		{
			u8 aa = ReadMemory(backup);
			u8 bb = ReadMemory(backup+1);
			addr = (((u16)bb << 8) | aa) + X;
			opr = ReadIndexedAbsolute(&backup, X);
		}
		else if ([ opc.mode isEqualToString:AbsoluteY ])
		{
			u8 aa = ReadMemory(backup);
			u8 bb = ReadMemory(backup+1);
			addr = (((u16)bb << 8) | aa) + Y;
			opr = ReadIndexedAbsolute(&backup, Y);
		}
		else if ([ opc.mode isEqualToString:Immediate ])
		{
			addr = backup;
			opr = ReadImmediate(&backup);
		}
		else if ([ opc.mode isEqualToString:Indirect ])
		{
			u8 bb = ReadMemory(backup);
			u8 cc = ReadMemory(backup+1);
			u8 xx = ReadMemory(((u16)cc << 8) | bb);
			u8 yy = ReadMemory(((u16)cc << 8) | bb);
			opr = (((u16)yy << 8) | xx);
			addr = opr;
		}
		else if ([ opc.mode isEqualToString:IndexedIndirect ])
		{
			u8 bb = ReadMemory(backup);
			u8 xx = ReadMemory((bb + X) & 0xFF);
			u8 yy = ReadMemory((bb + X + 1) & 0xFF);
			addr = (xx | (u16)(yy << 8));
			opr = ReadIndexedIndirect(&backup, X);
		}
		else if ([ opc.mode isEqualToString:IndirectIndexed ])
		{
			u8 bb = ReadMemory(backup);
			u8 xx = ReadMemory(bb);
			u8 yy = ReadMemory((bb + 1) & 0xFF);
			u16 point = xx | (u16)(yy << 8);
			addr = point + Y;
			opr = ReadIndirectIndexed(&backup, Y);
		}
		else if ([ opc.mode isEqualToString:Relative ])
		{
			opr = (s8)ReadMemory(backup);
			addr = backup + opr + 1;
		}
		else if ([ opc.mode isEqualToString:Implied ])
		{
			opr = 0;
			addr = 0;
		}
		else if ([ opc.mode isEqualToString:Accumulator ])
		{
			opr = 0;
			addr = 0;
		}
		
		[ oprVal setStringValue:[ Controller decToHex:opr ] ];
		[ addrVal setStringValue:[ Controller decToHex:addr ] ];
		[ memVal setStringValue:[ NSString stringWithFormat:@"Memory[0x%X] = 0x%X", addr,
								 ReadMemory(addr) ] ];
	}
}

- (void) stayCol: (NSTimer*) timer
{
	[ NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(subCol:)
									userInfo:nil repeats:YES ];
}

- (void) subCol: (NSTimer*) timer
{
	colorTimer++;
	statusColor = [ [ NSColor colorWithCalibratedRed:0.7 green:0.7 
					blue:0 alpha:[ statusColor alphaComponent ] - (1 / 20.0) ] retain ];
	if (colorTimer == 20)
	{
		colorTimer = 0;
		[ timer invalidate ];
		[ statusColor release ];
		statusColor = nil;
		[ statusMessage release ];
		statusMessage = nil;
	}
}

- (void) addCol: (NSTimer*) timer
{
	colorTimer++;
	statusColor = [ [ NSColor colorWithCalibratedRed:0.7 green:0.7 
						blue:0 alpha:[ statusColor alphaComponent ] + (1 / 20.0) ] retain ];
	if (colorTimer == 20)
	{
		colorTimer = 0;
		[ timer invalidate ];
		[ NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(stayCol:)
										userInfo:nil repeats:NO ];
	}
}

																
- (void) setStatusMessage: (NSString*) str
{
	if (statusMessage != nil)
		return;
	statusMessage = [ [ NSMutableString stringWithString:str ] retain ];
	int offset = 0;
	while ([ statusMessage length ] - offset > 42)
	{
		[ statusMessage insertString:@"\n" atIndex:42 + offset ];
		offset += 43;
	}
	
	statusColor = [ [ NSColor colorWithCalibratedRed:0.7 green:0.7 blue:0 alpha:0 ] retain ];
	colorTimer = 0;
	[ NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector: @selector(addCol:)
									userInfo:nil repeats:YES ];
}

- (void) startEmulation
{
	// Setup timer and window
	if (glView)
		[ glView release ];
	glView = [ [ [ GLView alloc ] initWithFrame:[ emuWindow frame ] colorBits:16 depthBits:16
									 fullscreen:NO ] retain ];
	[ emuWindow setContentView:glView ];
	[ self setupRenderTimer ];
	[ emuWindow setTitle:[ NSString stringWithFormat:@"Nese - %@", filename ] ];
	[ self setStatusMessage:[ NSString stringWithFormat:@"Loaded - %@", filename ] ];
	if ([ debuggerWindow isVisible ])
		[ self pause:paused ];
	[ self updateDebugger ];
	
	[ emuWindow makeKeyAndOrderFront:self ];
	running = true;
	
	// Reset Plugins
	[ glView applyConfig ];
	[ audio applyConfig ];
	[ pad applyConfig ];
}

- (void) setupRenderTimer
{
	NSTimeInterval timeInterval = 0;
	if ([ fpsValue doubleValue ] != 0)
		timeInterval = 1 / [ fpsValue doubleValue ];
	
    renderTimer = [ [ NSTimer scheduledTimerWithTimeInterval:timeInterval
													  target:self
													selector:@selector( execute: )
													userInfo:nil repeats:YES ] retain ];
    [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
									forMode:NSEventTrackingRunLoopMode ];
    [ [ NSRunLoop currentRunLoop ] addTimer:renderTimer
									forMode:NSModalPanelRunLoopMode ];
	
	fpsTimer = [ [ NSTimer scheduledTimerWithTimeInterval:1 target:self
				selector:@selector(findFPS) userInfo:nil repeats:YES ] retain] ;
}

- (IBAction) configVideo: (id) sender
{
	[ glView showConfig ];
}

- (IBAction) configAudio: (id) sender
{
	[ audio showConfig ];
}

- (IBAction) selectAudio:(id)sender
{
	[ audio release ];
	
	if (running)
		[ audio unloadData ];
	
	if ([ [ [ audioPlugin selectedItem ] title ] hasPrefix:@"CoreAudio" ])
		audio = [ [ [ CASound alloc ] init ] retain ];
	else
		audio = [ [ [ ALSound alloc ] init ] retain ];
	
	if (running)
		[ audio loadSound ];
}

- (IBAction) configController: (id) sender
{
	[ pad showConfig ];
}

- (void) findFPS
{
	float truefps = fps;
	/*float oldFrame = frameSkip;
	if (truefps < [ fpsValue intValue ])
		frameSkip = ([ fpsValue doubleValue ] / truefps) - 1;
	else
		frameSkip = 0;
	truefps *= (1 + oldFrame);*/
	
	[ emuWindow setTitle:[ NSString stringWithFormat:@"Nese - (%.2f fps)",
					truefps ] ];
	fps = 0;
}

- (void) keyDown:(NSEvent *)theEvent
{
	[ pad keyDown:theEvent ];
}

- (void) keyUp:(NSEvent *)theEvent
{
	[ pad keyUp:theEvent ];
}

- (IBAction) saveState: (id) sender
{
	NSSavePanel* save = [ NSSavePanel savePanel ];
	[ save setAllowedFileTypes:[ NSArray arrayWithObject:@"sav" ] ];
	if ([ save runModal ])
	{
		NSString* filename = [ [ NSString alloc ] initWithString:[ save filename ] ];
		
		FILE* file = fopen([ filename UTF8String ], "wb");
		fwrite(&pc, 2, 1, file);
		fwrite(&sp, 1, 1, file);
		fwrite(&A, 1, 1, file);
		fwrite(&X, 1, 1, file);
		fwrite(&Y, 1, 1, file);
		fwrite(&P, 1, 1, file);
		fwrite(spr_ram, 1, 0x100, file);
		fwrite(vram, 1, 0x10000, file);
		fwrite(memory, 1, 0x8000, file);
		fclose(file);
		file = NULL;
		
		[ filename release ];
		filename = nil;
	}
}

- (IBAction) loadState: (id) sender
{
	if (!memory)
		return;
	NSOpenPanel* save = [ NSOpenPanel openPanel ];
	[ save setAllowedFileTypes:[ NSArray arrayWithObject:@"sav" ] ];
	if ([ save runModal ])
	{
		NSString* filename = [ [ NSString alloc ] initWithString:[ save filename ] ];
		
		FILE* file = fopen([ filename UTF8String ], "rb");
		fread(&pc, 2, 1, file);
		fread(&sp, 1, 1, file);
		fread(&A, 1, 1, file);
		fread(&X, 1, 1, file);
		fread(&Y, 1, 1, file);
		fread(&P, 1, 1, file);
		fread(spr_ram, 1, 0x100, file);
		fread(vram, 1, 0x10000, file);
		fread(memory, 1, 0x8000, file);
		fclose(file);
		file = NULL;
		
		[ filename release ];
		filename = nil;
	}
}


- (void) execute: (NSTimer*) timer
{
	if (stop)
	{
		[ self stop:self ];
		[ timer invalidate ];
	}
	else
	{
		[ self updateGLView ];
		fps++;
		[ self updateDebugger ];
	}
}

- (IBAction) reset: (id) sender
{
	reset = true;
	[ renderTimer invalidate ];
	[ self setupRenderTimer ];
	[ self setStatusMessage:@"Reset" ];
}

+ (NSString*) decToHex:(s32) val
{
	if (val < 0)
		return [ NSString stringWithFormat:@"-0x%X", abs(val) ];
	return [ NSString stringWithFormat:@"0x%X", val ];
}

+ (unsigned int) hexToDec:(NSString*) val
{
	NSString* final;
	if ([ val hasPrefix:@"0x" ])
		final = [ [ val substringFromIndex:2 ] retain ];
	else
		final = [ val retain ];
	unsigned int total = 0;
	for (int z = 0; z < [ final length ]; z++)
	{
		char data = [ final characterAtIndex:z ];
		int ret = 0;
		switch (data)
		{
			case '0': ret = 0; break;
			case '1': ret = 1; break;
			case '2': ret = 2; break;
			case '3': ret = 3; break;
			case '4': ret = 4; break;
			case '5': ret = 5; break;
			case '6': ret = 6; break;
			case '7': ret = 7; break;
			case '8': ret = 8; break;
			case '9': ret = 9; break;
			case 'a':
			case 'A': ret = 10; break;
			case 'b':
			case 'B': ret = 11; break;
			case 'c':
			case 'C': ret = 12; break;
			case 'd':
			case 'D': ret = 13; break;
			case 'e':
			case 'E': ret = 14; break;
			case 'f':
			case 'F': ret = 15; break;
		}
		switch (z)
		{
			case 0: total += (ret * 0x1000); break;
			case 1: total += (ret * 0x100); break;
			case 2: total += (ret * 0x10); break;
			case 3: total += ret; break;
		}
	}
	return total;
}

- (IBAction) setPC: (id) sender
{
	pc = [ Controller hexToDec:[ pcVal stringValue ] ];
	[ self updateDebugger ];
}

- (IBAction) setA: (id) sender
{
	A = [ Controller hexToDec:[ aVal stringValue ] ];
}

- (IBAction) setX: (id) sender
{
	X = [ Controller hexToDec:[ xVal stringValue ] ];
}

- (IBAction) setY: (id) sender
{
	Y = [ Controller hexToDec:[ yVal stringValue ] ];
}

- (IBAction) setSP: (id) sender
{
	sp = [ Controller hexToDec:[ spVal stringValue ] ];
}

- (IBAction) setCarryFlag: (id) sender
{
	SetCarryFlag([ sender state ]);
	[ pVal setStringValue:[ Controller decToHex:P ] ];
}

- (IBAction) setZeroFlag: (id) sender
{
	SetZeroFlag([ sender state ]);
	[ pVal setStringValue:[ Controller decToHex:P ] ];
}

- (IBAction) setInterruptDisable: (id) sender
{
	SetInterruptFlag([ sender state ]);
	[ pVal setStringValue:[ Controller decToHex:P ] ];
}

- (IBAction) setDecimalMode: (id) sender
{
	SetDecimalMode([ sender state ]);
	[ pVal setStringValue:[ Controller decToHex:P ] ];
}

- (IBAction) setBreakCommand: (id) sender
{
	SetBreakCommand([ sender state ]);
	[ pVal setStringValue:[ Controller decToHex:P ] ];
}

- (IBAction) setOverflowFlag: (id) sender
{
	SetOverflowFlag([ sender state ]);
	[ pVal setStringValue:[ Controller decToHex:P ] ];
}

- (IBAction) setNegativeFlag: (id) sender
{
	SetNegativeFlag([ sender state ]);
	[ pVal setStringValue:[ Controller decToHex:P ] ];
}

- (IBAction) setProcessorStatus: (id) sender
{
	P = [ Controller hexToDec:[ pVal stringValue ] ];
}

- (IBAction) viewOpc: (id) sender
{
}

- (IBAction) step: (id) sender
{
	for (int z = 0; z < [ stepNumber intValue ]; z++)
	{
		Fetch();
		Step();
		
		while (updateGraphics > 0)
		{
			[ self updateGLView ];
			fps++;
			updateGraphics--;
		}
	}
		 
	[ self updateDebugger ];
}

- (void) drawPallete
{
	[ palleteView lockFocus ];
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
	
	for (int z = 0; z < 16; z++)
	{
		glLoadIdentity();
		glTranslated(z * 16 , 0, 0);
		Color color = pallete[ReadVRAM(0x3F00 + z) % 64];
		glColor3d(color.red / 255.0, color.green / 255.0, color.blue / 255.0);
		glBegin(GL_QUADS);
		{
			glVertex2d(0, 0);
			glVertex2d(16, 0);
			glVertex2d(16, 112);
			glVertex2d(0, 112);
		}
		glEnd();
	}
	
	for (int z = 0; z < 16; z++)
	{
		glLoadIdentity();
		glTranslated(z * 16 , 112, 0);
		Color color = pallete[ReadVRAM(0x3F10 + z) % 64];
		glColor3d(color.red / 255.0, color.green / 255.0, color.blue / 255.0);
		glBegin(GL_QUADS);
		{
			glVertex2d(0, 0);
			glVertex2d(16, 0);
			glVertex2d(16, 112);
			glVertex2d(0, 112);
		}
		glEnd();
	}
	
	[ [ palleteView openGLContext ] flushBuffer ];
	[ palleteView unlockFocus ];
}

- (void) updateGLView
{
	[ glView drawRect:[ glView frame ] withPad:pad ];
	if ([ palleteWindow isVisible ])
		[ self drawPallete ]; 
}

- (IBAction) showPallete: (id) sender
{
	if ([ palleteWindow isVisible ])
		return;
	
	palleteView = [ [ [ GLView alloc ] initWithFrame:NSMakeRect(20, 20, 435, 319) 
										 colorBits:16 depthBits:16 fullscreen:NO ] retain ];
	[ [ palleteWindow contentView ] addSubview:palleteView ];
	[ palleteWindow makeKeyAndOrderFront:self ];
}

- (IBAction) showName: (id) sender
{
	if ([ nameTableWindow isVisible ])
		return;
	
	nameTableView = [ [ [ CustomGLView alloc ] initWithFrame:NSMakeRect(20, 70, 513, 481) 
										   colorBits:16 depthBits:16 fullscreen:NO ] retain ];
	[ nameTableView setSize:NSMakeSize(511, 479) ];
	[ [ nameTableWindow contentView ] addSubview:nameTableView ];
	[ nameTableWindow makeKeyAndOrderFront:self ];
}

- (IBAction) drawName: (id) sender
{
	[ nameTableView lockFocus ];
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glClearColor(background.red / 255.0, background.green / 255.0, background.blue / 255.0, 1);
	
	u16 nameAddress;
	u16 attrAddress;
	u16 screenPattern = ((ReadMemory(0x2000) >> 4) & 0x1) * 0x1000;
	for (int z = 0; z < 4; z++)
	{
		nameAddress = nameTables[z];
		attrAddress = attrTables[z];
		for (u8 y = 0; y < 240; y++)
		{
			for (u8 x = 0;;)
			{
				u16 pixel = ReadVRAM(((x / 8) + ((y / 8) * 0x20)) + nameAddress);
				u8 sprite1 = ReadVRAM(screenPattern + (pixel * 16) + (y % 8));
				u8 sprite2 = ReadVRAM(screenPattern + (pixel * 16) + 8 + (y % 8));
				
				glLoadIdentity();
				switch (z)
				{
					case 0:
						glTranslated(x, y, 0);
						break;
					case 1:
						glTranslated(x + 256, y, 0);
						break;
					case 2:
						glTranslated(x, y + 240, 0);
						break;
					case 3:
						glTranslated(x + 256, y + 240, 0);
						break;
				}
				for (int qe = 0; qe < 8; qe++)
				{
					u8 spr = ((sprite1 >> (7-qe)) & 0x1) | (((sprite2 >> (7-qe)) & 0x1) << 1);
					if (spr == 0)
						continue;
					u8 col = spr;
					u8 bit = ((((x / 8) % 4) > 1) + ((((y / 8) % 4) > 1) * 2)) * 2;
					u8 ocol = ((ReadVRAM(attrAddress + (x / 0x20) + ((y / 0x20) * 8)))
							   >> bit) & 0x3;
					
					if ((col | (ocol << 2)) % 4 == 0)
						continue;
					
					Color color = pallete[ReadVRAM(0x3F00 + (col | ((ocol) << 2)))];
					glColor3d(color.red / 255.0, color.green / 255.0, color.blue / 255.0);
					glBegin(GL_QUADS);
					{
						glVertex2d(qe, 0);
						glVertex2d((qe + 1), 0);
						glVertex2d((qe + 1), 1);
						glVertex2d(qe, 1);
					}
					glEnd();
				}
				
				x += 8;
				if (x == 0)
					break;
			}
		}
	}
	
	glLoadIdentity();
	glColor3d(1, 1, 1);
	glBegin(GL_LINES);
	{
		glVertex2d(256, 0);
		glVertex2d(256, 479);
		
		glVertex2d(0, 240);
		glVertex2d(511, 240);
	}
	glEnd();
	
	[ [ nameTableView openGLContext ] flushBuffer ];
	[ nameTableView unlockFocus ];
}

- (BOOL) windowShouldClose: (id) sender
{
	if (sender == emuWindow)
		[ self stop:sender ];
	else if (sender == palleteWindow)
	{
		[ palleteWindow orderOut:self ];
		[ palleteView removeFromSuperview ];
		[ palleteView release ];
	}
	else if (sender == nameTableWindow)
	{
		[ nameTableWindow orderOut:self ];
		[ nameTableView removeFromSuperview ];
		[ nameTableView release ];
	}
	else if (sender == perferenceWindow)
		[ self savePreferences ];

	return YES;
}

- (void) dealloc
{
	if (glView)
		[ glView release ];
	if (pad)
		[ pad release ];
	if (audio)
		[ audio release ];
	[ super dealloc ];
}

@end
