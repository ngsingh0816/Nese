//
//  Rom.h
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "types.h"
#import <vector>

extern BOOL ReadRom(NSString* filename);
extern u8** pgr_banks;
extern int sizePGR;
extern u8** chr_banks;
extern int sizeCHR;