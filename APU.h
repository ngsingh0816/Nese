//
//  APU.h
//  Nese
//
//  Created by MILAP on 5/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import	"types.h"
#import "CPU.h"

#define NUM_CHANNELS	5

typedef struct
{
	bool start;
	bool loop;
	bool constant;
	u8 divider;
	u8 counter;
} Envelope;

typedef struct
{
	u8 control;
	u8 periodLow;
	u8 periodHigh;
	bool enableSweep;
	u8 period;
	bool negative;
	u8 shift;
	s32 length;
	double delay;
	int phase;
	Envelope env;
	bool changed;
} Square;

typedef struct
{
	u8 control;
	u8 periodLow;
	u8 periodHigh;
	s32 length;
	s32 counter;
	double current;
	int phase;
	bool changed;
} Triangle;

typedef struct
{
	u8 control;
	s32 period;
	u32 length;
	u16 shift;
	u16 timer;
	Envelope env;
	bool changed;
	double delay;
	int phase;
} Noise;

typedef struct
{
	u8 control;
	u8 counter;
	u16 period;
	u16 address;
	u16 length;
	double delay;
	int phase;
	bool changed;
} DMC;

extern Square square1;
extern Square square2;
extern Triangle triangle;
extern Noise noise;
extern DMC dmc;
extern u8 controlSound;
extern double dutyCycles[4];

u8 APURead(u16 pos);
void APUWrite(u16 pos, u8 data);
void APUDoLoop();

bool APUInit();
void APUReset();
void APUStop();

void APUExecuteOp(s32 numOfCycles);

extern double* record;


