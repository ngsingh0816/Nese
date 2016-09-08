//
//  ALSound.h
//  Nese
//
//  Created by Singh on 6/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenAL/al.h>
#import <OpenAL/alc.h>
#import "types.h"

extern u32 ri;

@interface ALSound : NSObject 
{
	ALCdevice* device;
	ALCcontext* context;
	u32* sources;
	u32* buffers;
	
	// Config
	NSWindow* config;
	NSRect windowRect;
}

- (id) init;

- (bool) loadSound;
- (void) unloadData;

// Config
- (void) applyConfig;
- (void) readConfig;
- (void) saveConfig;
- (void) showConfig;
- (BOOL) windowShouldClose: (id) sender;

- (void) updateSound;

- (void) dealloc;

@end
