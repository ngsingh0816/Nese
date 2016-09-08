//
//  APU.m
//  Nese
//
//  Created by MILAP on 5/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "APU.h"
#import "Controller.h"

Square square1;
Square square2;
Triangle triangle;
Noise noise;
DMC dmc; 
u8 controlSound;
double* record;

double dutyCycles[4] = {
	0.5,//0.125,
	0.5,//0.25,
	0.5,
	0.5,//0.75,
};

/*u8 lengthCounter[0x20] = {
	10, 254, 20, 2, 40, 4, 80, 6, 160, 8, 60, 10, 14, 12, 26, 14,
	12, 16, 24, 18, 48, 20, 96, 22, 192, 24, 72, 26, 16, 28, 32, 30,
};*/

u8 lengthCounter00[0x08] = {
	0x05, 0x0A, 0x14, 0x28, 0x50, 0x1E, 0x07, 0x0D,
};

u8 lengthCounter01[0x08] = {
	0x06, 0x0C, 0x18, 0x30, 0x60, 0x24, 0x08, 0x10,
};

u8 lengthCounter10[0x10] = {
	0x7F, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD, 0xE, 0xF
};

s32 LengthConversion(u8 data)
{
	if ((data >> 3) & 0x1)
		return lengthCounter10[(data >> 4) & 0xF];
	if ((data >> 7) & 0x1)
		return lengthCounter01[(data >> 4) & 0x7];
	return lengthCounter00[(data >> 4) & 0x7];
}

u32 noiseTimer[0x10] = {
	0x4, 0x8, 0x10, 0x20, 0x30, 0x40, 0x50, 0x66, 0x7F, 0xBE, 0xFE, 0x17D,
	0x1FC, 0x3F9, 0x7F2, 0xFE4
};

u32 dmcRates[0x10] = {
	428, 380, 340, 320, 286, 254, 226, 214, 190, 160, 142, 128, 106, 84, 72, 54,
};

bool APUInit()
{
	//record = (double*)malloc(1000);
	if (audio)
		return [ audio loadSound ];
	return false;
}

void APUReset()
{
	memset(&square1, 0, sizeof(square1));
	memset(&square2, 0, sizeof(square2));
	memset(&triangle, 0, sizeof(triangle));
	memset(&noise, 0, sizeof(noise));
	memset(&dmc, 0, sizeof(dmc));
	
	square1.phase = 1;
	square2.phase = 1;
	triangle.phase = 1;
	noise.shift = 1;
}

void APUStop()
{
	if (audio)
		[ audio unloadData ];
	if (record)
	{
		FILE* file = fopen("dump.txt", "w");
		for (int z = 0; z < ri && z < 1000; z++)
			fprintf(file, "%.2f\n", record[z]);
		fclose(file);
		free(record);
		record = NULL;
	}
}

u8 APURead(u16 pos)
{
	u8 ret = 0;
	ret |= (square1.length != 0);
	ret |= (square2.length != 0) << 1;
	ret |= (triangle.length != 0) << 2;
	ret |= (noise.length != 0) << 3;
	//ret |= (dmc.remaining != 0) << 4;
	return ret;
}

void APUWrite(u16 pos, u8 data)
{
	switch (pos)
	{
		case 0x4000:
			square1.control = data;
			square1.env.loop = (data >> 5) & 0x1;
			square1.env.constant = (data >> 4) & 0x1;
			square1.env.divider = (data & 0xF) + 1;
			square1.changed = true;
			break;
		case 0x4001:
			square1.enableSweep = (data >> 7) & 0x1;
			square1.period = ((data >> 4) & 0x7) + 1;
			square1.negative = (data >> 3) & 0x1;
			square1.shift = data & 0x7;
			square1.changed = true;
			break;
		case 0x4002:
			square1.periodLow = data;
			square1.changed = true;
			break;
		case 0x4003:
			square1.periodHigh = (data & 0x7);
			if (!((square1.control >> 5) & 0x1) && (controlSound & 0x1))
				square1.length = LengthConversion(data);
			else
				square1.length = 0;
			square1.env.start = true;
			square1.changed = true;
			break;
		case 0x4004:
			square2.control = data;
			square2.env.loop = (data >> 5) & 0x1;
			square2.env.constant = (data >> 4) & 0x1;
			square2.env.divider = (data & 0xF) + 1;
			square2.changed = true;
			break;
		case 0x4005:
			square2.enableSweep = (data >> 7) & 0x1;
			square2.period = ((data >> 4) & 0x7) + 1;
			square2.negative = (data >> 3) & 0x1;
			square2.shift = data & 0x7;
			break;
		case 0x4006:
			square2.periodLow = data;
			square2.changed = true;
			break;
		case 0x4007:
			square2.periodHigh = (data & 0x7);
			if (!((square2.control >> 5) & 0x1) && ((controlSound >> 1) & 0x1))
				square2.length = LengthConversion(data);
			else
				square2.length = 0;
			square2.env.start = true;
			square2.changed = true;
			break;
		case 0x4008:
			triangle.control = (data & 0x80);
			triangle.counter = (data & 0x7F);
			triangle.changed = true;
			break;
		case 0x400A:
			triangle.periodLow = data;
			triangle.changed = true;
			break;
		case 0x400B:
			triangle.periodHigh = (data & 0x7);
			triangle.length = LengthConversion(data);
			triangle.changed = true;
			break;
		case 0x400C:
			noise.control = data;
			noise.changed = true;
			break;
		case 0x400E:
			noise.period = noiseTimer[(data & 0xF)];
			noise.timer = noiseTimer[(data & 0xF)];
			noise.control |= (data & 0x80);
			noise.changed = true;
			break;
		case 0x400F:
			noise.length = LengthConversion(data);
			noise.changed = true;
			noise.env.start = true;
			break;
		case 0x4010:
			dmc.control = (data & 0xC0);
			dmc.period = dmcRates[(data & 0xF)];
			dmc.changed = true;
			break;
		case 0x4011:
			dmc.counter = (data & 0x7F);
			dmc.changed = true;
			break;
		case 0x4012:
			dmc.address = (1 << 15) | (1 << 14) | (data << 6);
			dmc.changed = true;
			break;
		case 0x4013:
			dmc.length = (data << 4) | 0x1;
			dmc.changed = true;
			break;
		case 0x4015:
			controlSound = data;
			break;
	}
}

// Timer
void APUExecuteOp(s32 numOfCycles)
{
	if (noise.period != 0)
	{
		noise.period -= numOfCycles;
		if (noise.period <= 0)
		{
			noise.period = noiseTimer[ReadMemory(0x4003) & 0xF];
			int bit = ((noise.control >> 7) & 0x1) ? 6 : 1;
			int feedback = (noise.shift & 0x1) ^ ((noise.shift >> bit) & 0x1);
			noise.shift >>= 1;
			noise.shift |= ((feedback & 0x1) << 14);
		}
	}
}

void APUDoLoop()
{
	if (cpuPaused)
		return;
	
	bool square1Length = (!((square1.control >> 5) & 0x1) && (controlSound & 0x1));
	bool square2Length = (!((square2.control >> 5) & 0x1) && ((controlSound >> 1) & 0x1));
	bool triangleLength = (!((triangle.control >> 7) & 0x1) && ((controlSound >> 2) & 0x1));
	bool noiseLength = (!((noise.control >> 5) & 0x1) && (controlSound >> 3) & 0x1);
	
	for (int z = 0; z < 2; z++)
	{
		// Check Length Counter
		if (square1Length && square1.length != 0)
			square1.length--;		// Count down
		
		// Check Length Counter
		if (square2Length && square2.length != 0)
			square2.length--;		// Count down
		
		// Check Length Counter
		if (triangleLength && triangle.length != 0)
			triangle.length--;
		
		// Check Length Counter
		if (noiseLength && noise.length != 0)
			noise.length--;
	}
	
	for (int z = 0; z < 4; z++)
	{
		// Square 1 Envelope
		if (square1.env.start)
		{
			square1.env.start = false;
			square1.env.counter = 0xF;
			square1.env.divider = (ReadMemory(0x4000) & 0xF) + 1;
		}
		else	// Output divider clock
		{
			if (square1.env.counter != 0)
				square1.env.counter--;
			else if (square1.env.loop)
				square1.env.counter = 0xF;
		}
		
		// Square 2 Envelope
		if (square2.env.start)
		{
			square2.env.start = false;
			square2.env.counter = 0xF;
			square2.env.divider = (square1.control & 0xF) + 1;
		}
		else	// Output divider clock
		{
			if (square2.env.counter != 0)
				square2.env.counter--;
			else if (square2.env.loop)
				square2.env.counter = 0xF;
		}
		
		// Triangle Linear Counter
		if (triangle.length != 0)
		{
			if ((triangle.control >> 7) & 0x1)
				triangle.counter = (square2.control & 0x7F);
			else if (triangle.counter != 0)
				triangle.counter--;
		}
		
		// Noise Envelope
		if (noise.env.start)
		{
			noise.env.start = false;
			noise.env.counter = 0xF;
			noise.env.divider = (noise.control & 0xF) + 1;
		}
		else	// Output divider clock
		{
			if (noise.env.counter != 0)
				noise.env.counter--;
			else if (noise.env.loop)
				noise.env.counter = 0xF;
		}
	}
	if ((ReadMemory(0x4017) >> 7) & 0x1)
		BRK();
	
	if (square1.enableSweep && square1.period)
		square1.period--;
	if (square2.enableSweep && square2.period)
		square2.period--;
	
	[ audio updateSound ];
}

