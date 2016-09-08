//
//  Mappers.h
//  Nese
//
//  Created by MILAP on 5/8/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "types.h"
#include <vector>

extern std::vector<u8> registers;
extern u8 writes;
extern u8 lastWrite;
extern void ResetMapper();
extern bool CheckMapperWrite(u16 pos, u8 data);
extern void MapperLoadRom();