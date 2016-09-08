//
//  ALSound.m
//  Nese
//
//  Created by Singh on 6/5/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ALSound.h"
#import "APU.h"

static double sampleRate = 1789773;
static double hostRate = 44100;
static double size = hostRate;
u32 ri = 0;

void SquareWave(s16* data, int count, int volume, double halfPeriod,
			   double* delay, int* phase, double duty, bool sweep, bool negate, u8 period,
				u32 shift)
{
	u16 realPer = period;
	if ((*delay) <= 0)
	{
		if ((*phase) == 1)
			(*delay) += ((halfPeriod * 2) * duty);
		else
			(*delay) += ((halfPeriod * 2) * (1 - duty));
	}
	
	for (int z = 0; z < count; z++)
	{
		if (sweep && realPer != 0)
		{
			//if (realPer < 0x800)
			//	halfPeriod -= ((double)realPer * (hostRate / sampleRate) * 2);
			realPer <<= shift;
			if (negate)
				realPer ^= 0xFF;
			if (realPer < 0x800 && realPer > 0x8)
				halfPeriod = ((double)realPer * (hostRate / sampleRate) * 2);
			realPer--;
		}
		data[z] = (*phase) * volume;
		(*delay)--;
		if ((*delay) <= 0)
		{
			(*phase) = 1 - (*phase);
			if ((*phase) == 1)
				(*delay) += ((halfPeriod * 2) * duty);
			else
				(*delay) += ((halfPeriod * 2) * (1 - duty));
		}
	}
}

void TriangleWave(s16* data, int count, double halfPeriod,
			   double* delay, int* phase, double duty)
{
	static u8 step32[32] = { 0xF, 0xE, 0xD, 0xC, 0xB, 0xA, 0x9, 0x8, 0x7, 0x6, 0x5, 0x4, 0x3,
		0x2, 0x1, 0x0, 0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xA, 0xB, 0xC, 0xD,
		0xE, 0xF };
	if ((*delay) <= 0)
	{
		if ((*phase) == 1)
			(*delay) += ((halfPeriod * 2) * duty);
		else
			(*delay) += ((halfPeriod * 2) * (1 - duty));
	}
	
	for (double z = 0, other = 0; z < count; z++)
	{
		data[(int)z] = (*phase) * step32[(int)other] * 1;
		(*delay)--;
		if ((*delay) <= 0)
		{
			(*phase) = 1 - (*phase);
			if ((*phase) == 1)
				(*delay) += ((halfPeriod * 2) * duty);
			else
				(*delay) += ((halfPeriod * 2) * (1 - duty));
		}
		other = (other + ((sampleRate / hostRate) * 32));
		while (other > 32)
			other -= 32;
	}
}

void OtherWave(s16* data, int count, int volume, double halfPeriod,
				double* delay, int* phase, double duty)
{
	if ((*delay) <= 0)
	{
		if ((*phase) == 1)
			(*delay) += ((halfPeriod * 2) * duty);
		else
			(*delay) += ((halfPeriod * 2) * (1 - duty));
	}
	
	for (int z = 0; z < count; z++)
	{
		data[z] = (*phase) * volume;
		(*delay)--;
		if ((*delay) <= 0)
		{
			(*phase) = 1 - (*phase);
			if ((*phase) == 1)
				(*delay) += ((halfPeriod * 2) * duty);
			else
				(*delay) += ((halfPeriod * 2) * (1 - duty));
		}
	}
}

@implementation ALSound

- (id) init
{
	if ((self = [ super init ]))
	{
		
		windowRect = NSMakeRect(300, 500, 300, 200);
		return self;
	}
	return nil;
}

- (bool) loadSound
{
	device = alcOpenDevice(NULL);
	if (!device)
		return false;
	context = alcCreateContext(device, NULL);
	alcMakeContextCurrent(context);
	
	alGetError();
	
	buffers = (u32*)malloc(NUM_CHANNELS);
	
	sources = (u32*)malloc(NUM_CHANNELS);
	alGenSources(NUM_CHANNELS, sources);
	if (alGetError() != AL_NO_ERROR)
		return false;
	
	return true;
}

- (void) unloadData
{
	if (buffers)
	{
		for (int z = 0; z < NUM_CHANNELS; z++)
		{
			if (alIsBuffer(buffers[z]))
				alDeleteBuffers(1, &buffers[z]);
		}
		free(buffers);
		buffers = NULL;
	}
	if (sources)
	{
		alDeleteSources(NUM_CHANNELS, sources);
		free(sources);
		sources = NULL;
	}
	if (context || device)
	{
		context = alcGetCurrentContext();
		device = alcGetContextsDevice(context);
		alcMakeContextCurrent(NULL);
		alcDestroyContext(context);
		alcCloseDevice(device);
	}
}

- (void) updateSound
{
	/*static int queue = 0;
	int val = 0;
	alGetSourcei(sources[0], AL_BUFFERS_PROCESSED, &val);
	if (val > 0 && !square1.changed)
	{
		// Requeue the same buffer
		alSourceUnqueueBuffers(sources[0], 1, &buffers[!queue]);
		//alSourceUnqueueBuffers(sources[0], 1, &buffers[queue]);
		alSourceQueueBuffers(sources[0], 1, &buffers[queue]);
		int val = 0;
		alGetSourcei(sources[0], AL_SOURCE_STATE, &val);
		if(val != AL_PLAYING)
			alSourcePlay(sources[0]);
	}
	if (square1.changed)
	{
		square1.changed = FALSE;
		alSourceUnqueueBuffers(sources[0], 1, &buffers[queue]);
		
		queue = !queue;
		
		double period = (square1.periodLow | (square1.periodHigh << 8)) + 1;
		period = (unsigned long)((((double)hostRate / sampleRate) * period) * 2);
		//if (period != 0)
		{
			u8 volume = 0;
			if (square1.env.constant)
				volume = (square1.control & 0xF);
			else
				volume = square1.env.counter;
			//if (volume != 0)
			{
				u32 realSize = size / 60;
				s8* data = new s8[realSize];
				SquareWave(data, realSize, volume * 1, period, &square1.delay, &square1.phase,
						   dutyCycles[(square1.control >> 6)], square1.enableSweep,
						   square1.negative, square1.period, square1.shift);
				if (alIsBuffer(buffers[queue]))
					alDeleteBuffers(1, &buffers[queue]);
				alGenBuffers(1, &buffers[queue]);
				alBufferData(buffers[queue], AL_FORMAT_MONO8, data, realSize, hostRate);
				alSourceQueueBuffers(sources[0], 1, &buffers[queue]);
				
				int val = 0;
				alGetSourcei(sources[0], AL_SOURCE_STATE, &val);
                if(val != AL_PLAYING)
                    alSourcePlay(sources[0]);
				
				delete[] data;
			}
		}
	}*/
	
	/*int playing2 = 0;
	alGetSourcei(sources[0], AL_SOURCE_STATE, &playing2);
	if (playing2 != AL_PLAYING || square1.changed)
	{
		if (square1.changed)
		{
			
		}
		
		double period = (square1.periodLow | (square1.periodHigh << 8)) + 1;
		period = (unsigned long)((((double)hostRate / sampleRate) * period) * 2);
		if (period != 0)
		{
			u8 volume = 0;
			if (square1.env.constant)
				volume = (square1.control & 0xF);
			else
				volume = square1.env.counter;
			if (volume != 0)
			{
				u32 realSize = size / 60;
				s8* data = new s8[realSize];
				SquareWave(data, realSize, volume * 1, period, &square1.delay, &square1.phase,
						   dutyCycles[(square1.control >> 6)], square1.enableSweep,
						   square1.negative, square1.period, square1.shift);
				
				alSourceUnqueueBuffers(sources[0], 1, &buffers[0]);
				if (alIsBuffer(buffers[0]))
					alDeleteBuffers(1, buffers);
				alGenBuffers(1, buffers);
				alBufferData(buffers[0], AL_FORMAT_MONO8, data, realSize, hostRate);
				alSourceQueueBuffers(sources[0], 1, &buffers[0]);
				//alSourcei(sources[0], AL_BUFFER, buffers[0]);
				int val = 0;
				alGetSourcei(sources[0], AL_SOURCE_STATE, &val);
                if(val != AL_PLAYING)
                    alSourcePlay(sources[0]);
				delete[] data;
			}
		}
		
		square1.changed = false;
	}
	*/
	/*int playing2 = 0;
	alGetSourcei(sources[0], AL_SOURCE_STATE, &playing2);
	if (playing2 != AL_PLAYING)
	{
		double period = (square1.periodLow | (square1.periodHigh << 8)) + 1;
		period = (unsigned long)((((double)hostRate / sampleRate) * period) * 2);
		if (period != 0)
		{
			u8 volume = 0;
			if (square1.env.constant)
				volume = (square1.control & 0xF);
			else
				volume = square1.env.counter;
			if (volume != 0)
			{
				u32 realSize = size / 60;
				s8* data = new s8[realSize];
				SquareWave(data, realSize, volume * 1, period, &square1.delay, &square1.phase,
						   dutyCycles[(square1.control >> 6)], square1.enableSweep,
						   square1.negative, square1.period, square1.shift);
				
				if (alIsBuffer(buffers[0]))
					alDeleteBuffers(1, buffers);
				alGenBuffers(1, buffers);
				alBufferData(buffers[0], AL_FORMAT_MONO8, data, realSize, hostRate);
				
				alSourcei(sources[0], AL_BUFFER, buffers[0]);
				alSourcePlay(sources[0]);
				delete[] data;
			}
		}
	}*/
	
	//const int realVol = 5;
	bool square1Length = (!((square1.control >> 5) & 0x1) && (controlSound & 0x1));
	bool square2Length = (!((square2.control >> 5) & 0x1) && ((controlSound >> 1) & 0x1));
	bool triangleLength = (!((triangle.control >> 7) & 0x1) && ((controlSound >> 2) & 0x1));
	bool noiseLength = (!((noise.control >> 5) & 0x1) && (controlSound >> 3) & 0x1);
	
	s16* data  = new s16[(u32)size];
	int playing = false;
	
	// Square 1
	if (square1.changed)
	{
		//static double lastPer = 0;
		//double period = (square1.periodLow | (square1.periodHigh << 8)) + 1;
		//period = (((double)hostRate / sampleRate) * period) * 2;
		//if (lastPer == period)
		//	period = 0;
		//else
		//	lastPer = period;
		//if (period != 0 || square1.length == 0 && square1Length)
		//{
			if (alIsSource(sources[0]))
				alDeleteSources(1, &sources[0]);
			alGenSources(1, &sources[0]);
	//	}
		square1.changed = false;
	}
	alGetSourcei(sources[0], AL_SOURCE_STATE, &playing);
	if (playing != AL_PLAYING)
	{
		if (square1.length != 0)
		{
			double period = (square1.periodLow | (square1.periodHigh << 8)) + 1;
			period = (((double)hostRate / sampleRate) * period) * 1;
			if (period != 0)
			{
				u8 volume = 0;
				if (square1.env.constant)
					volume = (square1.control & 0xF);
				else
					volume = square1.env.counter;
				if (volume != 0)
				{
					SquareWave(data, size, volume * 1, period, &square1.delay, &square1.phase,
							   dutyCycles[(square1.control >> 6)], square1.enableSweep, 
							   square1.negative, square1.period, square1.shift);
				
					if (alIsBuffer(buffers[0]))
						alDeleteBuffers(1, buffers);
					alGenBuffers(1, buffers);
					alBufferData(buffers[0], AL_FORMAT_MONO8, data, size, hostRate);
					
					alSourcei(sources[0], AL_BUFFER, buffers[0]);
					alSourcePlay(sources[0]);
				}
			}
		}
	}
	if (square1.length == 0 && square1Length)
	{
		if (alIsSource(sources[0]))
			alDeleteSources(1, sources);
		alGenSources(1, sources);
	}
	
	// Square 2
	if (square2.changed)
	{
		//static double lastPer = 0;
		//double period = (square2.periodLow | (square2.periodHigh << 8)) + 1;
		//period = (((double)hostRate / sampleRate) * period) * 2;
		//if (lastPer == period)
		//	period = 0;
		//else
		//	lastPer = period;
		//if (period != 0 || square2.length == 0 && square2Length)
		//{
			if (alIsSource(sources[1]))
				alDeleteSources(1, &sources[1]);
			alGenSources(1, &sources[1]);
			
		//if (record)
		//	{
		//		if (ri < 1000)
		//			record[ri++] = (period / 2) * (sampleRate / hostRate);
		//		if (ri == 1000)
		//		{
		//			NSRunAlertPanel(@"Oh Nos", @"Overflow", @"Ok", nil, nil);
		//			ri = 1001;
		//		}
		//	}
		//}
		square2.changed = false;
	}	
	alGetSourcei(sources[1], AL_SOURCE_STATE, &playing);
	if (playing != AL_PLAYING)
	{
		if (square2.length != 0)
		{
			double period = (square2.periodLow | (square2.periodHigh << 8)) + 1;
			period = (((double)hostRate / sampleRate) * period) * 1;
			if (period != 0)
			{
				u8 volume = 0;
				if (square2.env.constant)
					volume = (square2.control & 0xF);
				else
					volume = square2.env.counter;
				if (volume != 0)
				{
					SquareWave(data, size, volume * 1, period, &square2.delay, &square2.phase,
							   dutyCycles[(square2.control >> 6)], square2.enableSweep,
							   square2.negative, square2.period, square2.shift);
					
					if (alIsBuffer(buffers[1]))
						alDeleteBuffers(1, &buffers[1]);
					alGenBuffers(1, &buffers[1]);
					alBufferData(buffers[1], AL_FORMAT_MONO8, data, size, hostRate);
					
					alSourcei(sources[1], AL_BUFFER, buffers[1]);
					alSourcePlay(sources[1]);
				}
			}
		}
	}
	if (square2.length == 0 && square2Length)
	{
		if (alIsSource(sources[1]))
			alDeleteSources(1, &sources[1]);
		alGenSources(1, &sources[1]);
	}
	
	 // Triangle
	if (triangle.changed)
	{
		//static double lastPer = 0;
		//double period = (triangle.periodLow | (triangle.periodHigh << 8)) + 1;
		//period = (((double)hostRate / sampleRate) * period) * 2;
		//if (lastPer == period)
		//		period = 0;
		//else
		//	lastPer = period;
		//if (period != 0 || triangle.length == 0 && triangleLength)
		//{
			if (alIsSource(sources[2]))
				alDeleteSources(1, &sources[2]);
			alGenSources(1, &sources[2]);
		//}
		triangle.changed = false;
	}	
	alGetSourcei(sources[2], AL_SOURCE_STATE, &playing);
	if (playing != AL_PLAYING)
	{
		if (triangle.length != 0 && triangle.counter != 0)
		{
			double period = (triangle.periodLow | (triangle.periodHigh << 8)) + 1;
			period = (((double)hostRate / sampleRate) * period) * 2;
			if (period != 0)
			{
				TriangleWave(data, size, period, &triangle.current, &triangle.phase, 0.5);
				
				if (alIsBuffer(buffers[2]))
					alDeleteBuffers(1, &buffers[2]);
				alGenBuffers(1, &buffers[2]);
				alBufferData(buffers[2], AL_FORMAT_MONO8, data, size, hostRate);
				
				alSourcei(sources[2], AL_BUFFER, buffers[2]);
				alSourcePlay(sources[2]);
			}
		}
	}
	if (triangle.length == 0 && triangleLength)
	{
		if (alIsSource(sources[2]))
			alDeleteSources(1, &sources[2]);
		alGenSources(1, &sources[2]);
	}
	
	// Noise
	if (noise.changed)
	{
		static double lastPer = 0;
		double period = noise.timer * 2 * ((double)hostRate / sampleRate);
		if (lastPer == period)
			period = 0;
		else
			lastPer = period;
		if (period != 0)
		{
			if (alIsSource(sources[3]))
				alDeleteSources(1, &sources[3]);
			alGenSources(1, &sources[3]);
		}
		noise.changed = false;
	}	
	alGetSourcei(sources[3], AL_SOURCE_STATE, &playing);
	if (playing != AL_PLAYING)
	{
		if ((noise.length != 0 || !noiseLength) && !(noise.shift & 0x1))
		{
			double period = noise.timer * 1 * ((double)hostRate / sampleRate);
			if (period != 0)
			{
				u8 volume = 0;
				if (square1.env.constant)
					volume = (noise.control & 0xF);
				else
					volume = noise.env.counter;
				
				if (volume != 0)
				{					
					OtherWave(data, size, volume * 5, period, &noise.delay, &noise.phase, 0.5);
					if (alIsBuffer(buffers[3]))
						alDeleteBuffers(1, &buffers[3]);
					alGenBuffers(1, &buffers[3]);
					alBufferData(buffers[3], AL_FORMAT_MONO8, data, size, hostRate);
					
					alSourcei(sources[3], AL_BUFFER, buffers[3]);
					alSourcePlay(sources[3]);
				}
			}
		}
	}
	if (noise.length == 0 && noiseLength)
	{
		if (alIsSource(sources[3]))
			alDeleteSources(1, &sources[3]);
		alGenSources(1, &sources[3]);
	}
	
	// DMC
	/*if (dmc.changed)
	{
		if (alIsSource(sources[4]))
			alDeleteSources(1, &sources[4]);
		alGenSources(1, &sources[4]);
		dmc.changed = false;
	}	
	alGetSourcei(sources[4], AL_SOURCE_STATE, &playing);
	if (playing != AL_PLAYING)
	{
		if (dmc.counter != 0)
		{
			double period = dmc.period * ((double)hostRate / sampleRate) * 2;
			if (period != 0)
			{
				OtherWave(data, size, dmc.counter * 2, period,
						   &dmc.delay, &dmc.phase, 0.5);
				
				if (alIsBuffer(buffers[4]))
					alDeleteBuffers(1, &buffers[4]);
				alGenBuffers(1, &buffers[4]);
				alBufferData(buffers[4], AL_FORMAT_MONO8, data, size, hostRate);
				
				alSourcei(sources[4], AL_BUFFER, buffers[4]);
				alSourcePlay(sources[4]);
			}
		}
	}
	if (dmc.counter == 0)
	{
		if (alIsSource(sources[4]))
			alDeleteSources(1, &sources[4]);
		alGenSources(1, &sources[4]);
	}*/
	
	delete[] data;
	data = NULL;
}

- (void) applyConfig
{
}

- (void) readConfig
{
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/OpenAL.txt",
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
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/OpenAL.txt",
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
	[ config setTitle:@"OpenAL Plugin" ];
	
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
	[ super dealloc ];
}

@end
