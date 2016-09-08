//
//  Pad.h
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern bool kdown[8];

@interface Pad : NSObject {
	unichar keys[8];
	NSMutableArray* down;
	
	// Config
	NSWindow* config;
	NSRect windowRect;
}

- (id) init;
- (unichar*) keys;
- (void) setKeys: (unichar*) newkeys;
- (void) keyDown: (NSEvent*) theEvent;
- (void) keyUp: (NSEvent*) theEvent;
- (void) updateKeys;
- (void) dealloc;

// Config
- (void) applyConfig;
- (void) readConfig;
- (void) saveConfig;
- (void) showConfig;
- (BOOL) windowShouldClose: (id) sender;

@end
