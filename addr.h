//
//  addr.h
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "types.h"

extern u8 ReadImmediate(u16* pos);
extern u8 WriteImmediate(u16* pos, u8 data);
extern u8 ReadZeroPage(u16* pos);
extern u8 WriteZeroPage(u16* pos, u8 data);
extern u8 ReadZeroPageReg(u16* pos, u8 reg);
extern u8 WriteZeroPageReg(u16* pos, u8 reg, u8 data);
extern u8 ReadAbsolute(u16* pos);
extern u16 WriteAbsolute(u16* pos, u8 data);
extern u8 ReadIndexedAbsolute(u16* pos, u8 reg);
extern u16 WriteIndexedAbsolute(u16* pos, u8 reg, u8 data);
extern u8 ReadIndexedIndirect(u16* pos, u8 reg);
extern u16 WriteIndexIndirect(u16* pos, u8 reg, u8 data);
extern u8 ReadIndirectIndexed(u16* pos, u8 reg);
extern u16 WriteIndirectIndexed(u16* pos, u8 reg, u8 data);
extern s8 ReadRelative(u16* pos);
