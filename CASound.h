//
//  CASound.h
//  Nese
//
//  Created by Neil Singh on 7/4/16.
//
//

#import <Foundation/Foundation.h>

@interface CASound : NSObject
{	
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
