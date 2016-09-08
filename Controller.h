//
//  Controller.h
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TableWindow.h"

#import "GLView.h"
#import "Pad.h"
#import "ALSound.h"
#import "CASound.h"

#import "Rom.h"
#import "CPU.h"
#import "PPU.h"
#import "APU.h"
#import "Opcodes.h"

extern NSString* filename;
extern bool stop;
extern float frameSkip;
extern u32 updateGraphics;
extern bool spriteLabel;
extern bool cpuPaused;

extern id glView;
extern id pad;
extern id audio;

@interface Controller : NSResponder {
	IBOutlet NSWindow* emuWindow;
	IBOutlet NSWindow* debuggerWindow;
	
	IBOutlet NSWindow* perferenceWindow;
	IBOutlet NSTextField* fpsValue;
	IBOutlet NSPopUpButton* videoPlugin;
	IBOutlet NSPopUpButton* audioPlugin;
	IBOutlet NSPopUpButton* controllerPlugin;
	
	IBOutlet NSTextField* pcVal;
	IBOutlet NSTextField* aVal;
	IBOutlet NSTextField* xVal;
	IBOutlet NSTextField* yVal;
	IBOutlet NSTextField* spVal;
	IBOutlet NSTextField* opcVal;
	IBOutlet NSTextField* oprVal;
	IBOutlet NSTextField* addrVal;
	IBOutlet NSButton* zeroFlag;
	IBOutlet NSButton* carryFlag;
	IBOutlet NSButton* overflowFlag;
	IBOutlet NSButton* negativeFlag;
	IBOutlet NSButton* decimalFlag;
	IBOutlet NSButton* interruptFlag;
	IBOutlet NSButton* breakFlag;
	IBOutlet NSTextField* pVal;
	IBOutlet NSTextField* stepNumber;
	IBOutlet NSTextField* memVal;
	IBOutlet NSButton* step;
	IBOutlet NSButton* doHex;
	IBOutlet TableWindow* memoryViewer;
	IBOutlet NSWindow* palleteWindow;
	IBOutlet NSWindow* nameTableWindow;
	IBOutlet NSButton* paused;
	
	NSTimer* renderTimer;
	NSTimer* ppuTimer;
	NSTimer* fpsTimer;
	int fps;
	bool running;
	int colorTimer;
	
	GLView* palleteView;
	CustomGLView* nameTableView;
	
	NSMutableArray* keys;
}

+ (NSString*) decToHex:(s32) val;
+ (unsigned int) hexToDec:(NSString*) val;

- (void) updateDebugger;

- (void) savePreferences;
- (void) readPreferences;

- (IBAction) reset: (id) sender;

- (IBAction) setPC: (id) sender;
- (IBAction) setA: (id) sender;
- (IBAction) setX: (id) sender;
- (IBAction) setY: (id) sender;
- (IBAction) setSP: (id) sender;
- (IBAction) setCarryFlag: (id) sender;
- (IBAction) setZeroFlag: (id) sender;
- (IBAction) setInterruptDisable: (id) sender;
- (IBAction) setDecimalMode: (id) sender;
- (IBAction) setBreakCommand: (id) sender;
- (IBAction) setOverflowFlag: (id) sender;
- (IBAction) setNegativeFlag: (id) sender;
- (IBAction) setProcessorStatus: (id) sender;
- (IBAction) viewOpc: (id) sender;
- (IBAction) step: (id) sender;

- (IBAction) saveState: (id) sender;
- (IBAction) loadState: (id) sender;

- (void) awakeFromNib;
- (void) keyDown:(NSEvent *)theEvent;
- (void) keyUp:(NSEvent *)theEvent;
- (void) startEmulation;
- (IBAction) open: (id) sender;
- (void) findFPS;
- (void) setupRenderTimer;
- (void) execute:(NSTimer *)timer;
- (void) updateGLView;
- (void) dealloc;

// Config
- (IBAction) configVideo: (id) sender;
- (IBAction) configAudio: (id) sender;
- (IBAction) selectAudio: (id)sender;
- (IBAction) configController: (id) sender;

- (void) setStatusMessage: (NSString*) str;

- (IBAction) play: (id) sender;
- (IBAction) pause: (id) sender;
- (IBAction) stop: (id) sender;

- (IBAction) showPallete: (id) sender;
- (void) drawPallete;
- (IBAction) showName: (id) sender;
- (IBAction) drawName: (id) sender;

- (BOOL) windowShouldClose: (id) sender;

@end
