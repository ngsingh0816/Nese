//
//  Pad.m
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "Pad.h"
#import "CPU.h"

bool kdown[8];

@implementation Pad

- (id) init
{
	if (self = [ super init ])
	{
		memset(keys, 0, sizeof(keys));
		down = [ [ NSMutableArray new ] retain ];
		keys[0] = ' ';
		keys[1] = 'B';
		keys[2] = 'Z';
		keys[3] = NSCarriageReturnCharacter;
		keys[4] = NSUpArrowFunctionKey;
		keys[5] = NSDownArrowFunctionKey;
		keys[6] = NSLeftArrowFunctionKey;
		keys[7] = NSRightArrowFunctionKey;
		windowRect = NSMakeRect(300, 500, 300, 200);
	}
	return self;
}

- (unichar*) keys
{
	return keys;
}

- (void) setKeys: (unichar*) newkeys
{
	for (int z = 0; z < sizeof(keys); z++)
		keys[z] = newkeys[z];
}

- (void) keyDown: (NSEvent*) theEvent
{
	/*if ([ theEvent isARepeat ])
		return;
	
	[ down addObject:[ NSNumber numberWithInt:
					  [ [ theEvent characters ] characterAtIndex:0 ] ] ];*/
	for (int z = 0; z < 8; z++)
	{
		if (tolower([ [ theEvent characters ] characterAtIndex:0 ]) == tolower(keys[z]))
		{
			kdown[z] = true;
			break;
		}
	}
}

- (void) keyUp: (NSEvent*) theEvent
{
	//[ down removeAllObjects ];
	//[ down removeObject:[ NSNumber numberWithInt:
	//					[ [ theEvent characters ] characterAtIndex:0 ] ] ];
	for (int z = 0; z < 8; z++)
	{
		if (tolower([ [ theEvent characters ] characterAtIndex:0 ]) == tolower(keys[z]))
		{
			kdown[z] = false;
			break;
		}
	}
}

- (void) updateKeys
{
	/*memset(kdown, 0, 8);
	for (int y = 0; y < [ down count ]; y++)
	{
		for (int z = 0; z < 8; z++)
		{
			if (keys[z] == toupper([ (NSNumber*)[ down objectAtIndex:y ] intValue ]))
			{
				kdown[z] = true;
				break;
			}
		}
	}
	//[ down removeAllObjects ];*/
}

- (void) applyConfig
{
}

- (void) readConfig
{
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/Pad.txt",
						  [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "r");
	if (file)
	{
		float x, y, width, height;
		fscanf(file, "Rect = { %f, %f, %f, %f }\n", &x, &y, &width, &height);
		windowRect = NSMakeRect(x, y, width, height);
		fclose(file);
	}
}

- (void) saveConfig
{
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/Pad.txt",
						  [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "w");
	if (file)
	{
		windowRect = [ config frame ];
		fprintf(file, "Rect = { %.0f, %.0f, %.0f, %.0f }\n", windowRect.origin.x,
				windowRect.origin.y, windowRect.size.width, windowRect.size.height);
		fclose(file);
	}
}

- (void) showConfig
{
	[ self readConfig ];
	
	config = [ [ [ NSWindow alloc ] initWithContentRect:windowRect styleMask:
				(NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask) 
					backing:NSBackingStoreBuffered defer:YES ] retain ];
	[ config setDelegate:(id) self ];
	[ config setTitle:@"Pad Plugin" ];
	
	[ config makeKeyAndOrderFront:self ];
}

- (BOOL) windowShouldClose: (id) sender
{
	if (sender == config)
	{
		[ self saveConfig ];
		[ config orderOut:self ];
	}
	return YES;
}

- (void) dealloc
{
	[ down release ];
	[ super dealloc ];
}

@end
