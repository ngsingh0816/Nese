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

/* Lesson01View.m */

#import "GLView.h"
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import "CPU.h"
#import "PPU.h"
#import "Pad.h"
#import "Controller.h"

NSMutableString* statusMessage = nil;
NSColor* statusColor = nil;

@interface GLView (InternalMethods)
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;
- (BOOL) initGL;
@end

@implementation GLView

- (void) applyConfig
{
	[ self setFullScreen:fullscreen ];
	[ self reshape ];
}

- (void) readConfig
{
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/OpenGL.txt",
						  [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "r");
	if (file)
	{
		float x, y, width, height;
		fscanf(file, "Rect = { %f, %f, %f, %f }\n", &x, &y, &width, &height);
		fscanf(file, "Fullscreen = %i\n", &fullscreen);
		windowRect = NSMakeRect(x, y, width, height);
		fclose(file);
	}
}

- (void) saveConfig
{
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/OpenGL.txt",
						  [ [ NSBundle mainBundle ] resourcePath ] ] UTF8String ], "w");
	if (file)
	{
		windowRect = [ config frame ];
		fprintf(file, "Rect = { %.0f, %.0f, %.0f, %.0f }\n", windowRect.origin.x,
				windowRect.origin.y, windowRect.size.width, windowRect.size.height);
		fprintf(file, "Fullscreen = %i\n", fullscreen);
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
	[ config setTitle:@"OpenGL Plugin" ];
	
	fullScreen = [ [ [ NSButton alloc ] initWithFrame:NSMakeRect(10,
							windowRect.size.height - 30, 260, 25) ] retain ];
	[ fullScreen setButtonType:NSSwitchButton ];
	[ fullScreen setBezelStyle:NSRoundedBezelStyle ];
	[ fullScreen setTitle:@"FullScreen" ];
	[ fullScreen setState:fullscreen ];
	[ fullScreen setTarget:self ];
	[ fullScreen setAction:@selector(checkFullScreen:) ];
	[ fullScreen setToolTip:
	 @"Changes from windowed to fullscreen. (Can't be changed while ingame)" ];
	[ [ config contentView ] addSubview:fullScreen ];
	
	[ config makeKeyAndOrderFront:self ];
}

- (BOOL) windowShouldClose: (id) sender
{
	if (sender == config)
	{
		[ self saveConfig ];
		[ config orderOut:self ];
		
		[ fullScreen removeFromSuperview ];
		[ fullScreen release ];
	}
	return YES;
}

- (void) checkFullScreen: (id) sender
{
	fullscreen = !fullscreen;
	[ self saveConfig ];
}

- (id) initWithFrame:(NSRect)frame colorBits:(int)numColorBits
		   depthBits:(int)numDepthBits fullscreen:(BOOL)runFullScreen
{
    NSOpenGLPixelFormat *pixelFormat;
	
    colorBits = numColorBits;
    depthBits = numDepthBits;
	
	windowRect = NSMakeRect(300, 500, 300, 200);

    pixelFormat = [ self createPixelFormat:frame ];
    if (pixelFormat != nil)
    {
        self = [ super initWithFrame:frame pixelFormat:pixelFormat ];
        [ pixelFormat release ];
        if (self)
        {
            [ [ self openGLContext ] makeCurrentContext ];
            if (fullscreen || runFullScreen)
                [ self setFullScreen:YES ];
            [ self reshape ];
            if (![ self initGL ])
            {
                [ self clearGLContext ];
                self = nil;
            }
        }
    }
    else
        self = nil;
	
    return self;
}


/*
 * Create a pixel format and possible switch to full screen mode
 */
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame
{
    NSOpenGLPixelFormatAttribute pixelAttribs[ 16 ];
    int pixNum = 0;
    NSOpenGLPixelFormat *pixelFormat;
	
    pixelAttribs[ pixNum++ ] = NSOpenGLPFADoubleBuffer;
    pixelAttribs[ pixNum++ ] = NSOpenGLPFAAccelerated;
    pixelAttribs[ pixNum++ ] = NSOpenGLPFAColorSize;
    pixelAttribs[ pixNum++ ] = colorBits;
    pixelAttribs[ pixNum++ ] = NSOpenGLPFADepthSize;
    pixelAttribs[ pixNum++ ] = depthBits;
	
	pixelAttribs[ pixNum ] = 0;
    pixelFormat = [ [ NSOpenGLPixelFormat alloc ]
				   initWithAttributes:pixelAttribs ];
	
    return pixelFormat;
}


/*
 * Initial OpenGL setup
 */
- (BOOL) initGL
{ 
	glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    glShadeModel( GL_SMOOTH );                     // Enable smooth shading
    glClearColor( 0.0f, 0.0f, 0.0f, 0.5f );    // Black background
    glClearDepth( 1.0f );                            // Depth buffer setup
    glEnable( GL_DEPTH_TEST );                     // Enable depth testing
    glDepthFunc( GL_LEQUAL );                      // Type of depth test to do
    // Really nice perspective calculations
    glHint( GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST );
    
    return TRUE;
}


/*
 * Resize ourself
 */
- (void) reshape
{ 
    NSRect sceneBounds;
    
    [ [ self openGLContext ] update ];
    sceneBounds = [ self bounds ];
    // Reset current viewport
    glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
    glMatrixMode( GL_PROJECTION );    // Select the projection matrix
    glLoadIdentity();                     // and reset it
    // Calculate the aspect ratio of the view
    gluOrtho2D(0, 255, 231, 7);
    glMatrixMode( GL_MODELVIEW );     // Select the modelview matrix
    glLoadIdentity();                     // and reset it
}


/*
 * Called when the system thinks we need to draw.
 */
- (void) drawRect:(NSRect)rect withPad: (id) pad
{
	static float draws = 0;
	if (frameSkip == 0)
		draws = 0;
	if ((int)draws != 0)
	{
		if ((int)draws >= (int)frameSkip)
			draws = frameSkip - (int)frameSkip;
		else
			draws++;
		
		return;
	}
	
	[ self lockFocus ];
	
	PPU_DrawScanline();
	for (int z = 0; z < frameSkip; z++)
	{
		PPU_SkipFrames();
	}
	
	[ pad updateKeys ];
	
	if (statusMessage != nil && [ statusMessage length ] != 0)
	{
		WriteString(statusMessage, statusColor, [ NSColor clearColor ], [ NSColor clearColor ],
				NSMakePoint(0, 0), 12, @"Helvetica");
	}
	
	[ [ self openGLContext ] flushBuffer ];
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glClearColor(background.red / 255.0, background.green / 255.0,
					background.blue / 255.0, 1);
	
	[ self unlockFocus ];
	draws++;
}


/*
 * Are we full screen?
 */
- (BOOL) isFullScreen
{
    return [ self isInFullScreenMode ];
}

- (void) setFullScreen:(BOOL) fullScrn
{
	if ([ self isFullScreen ] == fullScrn)
		return;
	
	if (fullscreen)
		[ self enterFullScreenMode:[ NSScreen mainScreen ] withOptions:nil ];
	else
		[ self exitFullScreenModeWithOptions: nil ];
}


/*
 * Cleanup
 */
- (void) dealloc
{
    if ([ self isFullScreen ])
        [ self setFullScreen:NO ];
  	[ super dealloc ];
}

@end

@implementation CustomGLView

- (void) reshape
{
	NSRect sceneBounds;
    
    [ [ self openGLContext ] update ];
    sceneBounds = [ self bounds ];
    // Reset current viewport
    glViewport( 0, 0, sceneBounds.size.width, sceneBounds.size.height );
    glMatrixMode( GL_PROJECTION );    // Select the projection matrix
    glLoadIdentity();                     // and reset it
    // Calculate the aspect ratio of the view
    gluOrtho2D(0, customSize.width, customSize.height, 8);
    glMatrixMode( GL_MODELVIEW );     // Select the modelview matrix
    glLoadIdentity();                     // and reset it
}

- (void) setSize: (NSSize) newSize
{
	customSize = newSize;
}

- (NSSize) size
{
	return customSize;
}

@end

