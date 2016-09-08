/*
 * Original Windows comment:
 * "This code was created by Jeff Molofee 2000
 * A HUGE thanks to Fredric Echols for cleaning up
 * and optimizing the base code, making it more flexible!
 * If you've found this code useful, please let me know.
 * Visit my site at nehe.gamedev.net"
 * 
 * Cocoa port by Bryan Blackburn 2002; www.withay.com
 */

/* Lesson01View.h */

#import <Cocoa/Cocoa.h>

extern NSMutableString* statusMessage;
extern NSColor* statusColor;

@interface GLView : NSOpenGLView
{
    int colorBits;
	int depthBits;
	
	// Config
	NSRect windowRect;
	int fullscreen;
	NSWindow* config;
	NSButton* fullScreen;
	
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
		   depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen;
- (void) reshape;
- (void) drawRect:(NSRect)rect withPad: (id) pad;
- (BOOL) isFullScreen;
- (void) setFullScreen:(BOOL) fullScrn;
- (void) dealloc;

// Config
- (void) showConfig;
- (void) applyConfig;
- (void) readConfig;
- (void) saveConfig;
- (void) checkFullScreen: (id) sender;
- (BOOL) windowShouldClose: (id) sender;

@end

@interface CustomGLView : GLView
{
	NSSize customSize;
}

- (void) setSize: (NSSize) newSize;
- (NSSize) size;

@end

