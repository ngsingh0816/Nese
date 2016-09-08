//
//  CASound.m
//  Nese
//
//  Created by Neil Singh on 7/4/16.
//
//

#import "CASound.h"
#import "APU.h"
#import <AudioToolbox/AudioToolbox.h>

static double sampleRate = 1789773;
static double hostRate = 44100;

void SquareWave(float* data, int count, int volume, double halfPeriod,
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
		data[z] = (*phase) * volume / 15.0 / 3;
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

void TriangleWave(float* data, int count, double halfPeriod,
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
		data[(int)z] = (*phase) * step32[(int)other] * 1 / 15.0 / 5;
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

void OtherWave(float* data, int count, int volume, double halfPeriod,
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
		data[z] = (*phase) * volume / 15.0 / 3;
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

// This is our render callback. It will be called very frequently for short
// buffers of audio (512 samples per call on my machine).
OSStatus WaveRenderCallback(void * inRefCon,
							AudioUnitRenderActionFlags * ioActionFlags,
							const AudioTimeStamp * inTimeStamp,
							UInt32 inBusNumber,
							UInt32 inNumberFrames,
							AudioBufferList * ioData)
{
	/*// inRefCon is the context pointer we passed in earlier when setting the render callback
	double currentPhase = *((double *)inRefCon);
	// ioData is where we're supposed to put the audio samples we've created
	Float32 * outputBuffer = (Float32 *)ioData->mBuffers[0].mData;
	const double frequency = 440.;
	const double phaseStep = (frequency / 44100.) * (M_PI * 2.);
	
	for(int i = 0; i < inNumberFrames; i++) {
		outputBuffer[i] = sin(currentPhase);
		currentPhase += phaseStep;
	}
	
	// If we were doing stereo (or more), this would copy our sine wave samples
	// to all of the remaining channels
	for(int i = 1; i < ioData->mNumberBuffers; i++) {
		memcpy(ioData->mBuffers[i].mData, outputBuffer, ioData->mBuffers[i].mDataByteSize);
	}
	
	// writing the current phase back to inRefCon so we can use it on the next call
	*((double *)inRefCon) = currentPhase;
	return noErr;*/
	
	double currentPhase = *((double *)inRefCon);
	Float32 * outputBuffer = (Float32 *)ioData->mBuffers[0].mData;
	
	bool square1Length = (!((square1.control >> 5) & 0x1) && (controlSound & 0x1));
	bool square2Length = (!((square2.control >> 5) & 0x1) && ((controlSound >> 1) & 0x1));
	bool triangleLength = (!((triangle.control >> 7) & 0x1) && ((controlSound >> 2) & 0x1));
	bool noiseLength = (!((noise.control >> 5) & 0x1) && (controlSound >> 3) & 0x1);
	
	for(int i = 0; i < inNumberFrames; i++)
		outputBuffer[i] = 0;
	
	// Square 1
	if (square1Length != 0)
	{
		double period = (square1.periodLow | (square1.periodHigh << 8)) + 1;
		period = (((double)hostRate / sampleRate) * period);
		if (period != 0)
		{
			u8 volume = 0;
			if (square1.env.constant)
				volume = (square1.control & 0xF);
			else
				volume = 5;//square1.env.counter;
			if (volume != 0)
			{
				float data[inNumberFrames];
				SquareWave(data, inNumberFrames, volume, period * 2, &square1.delay, &square1.phase,
					dutyCycles[(square1.control >> 6)], square1.enableSweep, square1.negative, square1.period, square1.shift);
				for (int z = 0; z < inNumberFrames; z++)
					outputBuffer[z] += data[z];
			}
		}
	}
	
	// Square 2
	if (square2Length != 0)
	{
		double period = (square2.periodLow | (square2.periodHigh << 8)) + 1;
		period = (((double)hostRate / sampleRate) * period);
		if (period != 0)
		{
			u8 volume = 0;
			if (square2.env.constant)
				volume = (square2.control & 0xF);
			else
				volume = 5;//square2.env.counter;
			if (volume != 0)
			{
				float data[inNumberFrames];
				SquareWave(data, inNumberFrames, volume, period * 2, &square2.delay, &square2.phase,
					dutyCycles[(square2.control >> 6)], square2.enableSweep, square2.negative, square2.period, square2.shift);
				for (int z = 0; z < inNumberFrames; z++)
					outputBuffer[z] += data[z];
			}
		}
	}
	
	// Triangle
	if (triangleLength != 0)
	{
		if (triangle.length != 0 && triangle.counter != 0)
		{
			double period = (triangle.periodLow | (triangle.periodHigh << 8)) + 1;
			period = (((double)hostRate / sampleRate) * period) * 4;
			if (period != 0)
			{
				float data[inNumberFrames];
				TriangleWave(data, inNumberFrames, period, &triangle.current, &triangle.phase, 0.5);
				for (int z = 0; z < inNumberFrames; z++)
					outputBuffer[z] += data[z];
			}
		}
	}
	
	// Noise
	/*if ((noise.length != 0 || !noiseLength) && !(noise.shift & 0x1))
	{
		double period = 1.0 / noise.timer * hostRate;// * 1 * ((double)hostRate / sampleRate);
		if (period != 0)
		{
			u8 volume = 0;
			if (square1.env.constant)
				volume = (noise.control & 0xF);
			else
				volume = noise.env.counter;
			
			if (volume != 0)
			{
				float data[inNumberFrames];
				OtherWave(data, inNumberFrames, volume * 5, period, &noise.delay, &noise.phase, 0.5);
				for (int z = 0; z < inNumberFrames; z++)
					outputBuffer[z] += data[z];
			}
		}
	}*/
	
	*((double *)inRefCon) = currentPhase;
	return noErr;
}

@implementation CASound
{
	double renderPhase;
	AudioUnit outputUnit;
}

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
	//  First, we need to establish which Audio Unit we want.
	
	//  We start with its description, which is:
	AudioComponentDescription outputUnitDescription = {
		.componentType         = kAudioUnitType_Output,
		.componentSubType      = kAudioUnitSubType_DefaultOutput,
		.componentManufacturer = kAudioUnitManufacturer_Apple
	};
	
	//  Next, we get the first (and only) component corresponding to that description
	AudioComponent outputComponent = AudioComponentFindNext(NULL, &outputUnitDescription);
	
	//  Now we can create an instance of that component, which will create an
	//  instance of the Audio Unit we're looking for (the default output)
	AudioComponentInstanceNew(outputComponent, &outputUnit);
	AudioUnitInitialize(outputUnit);
	
	//  Next we'll tell the output unit what format our generated audio will
	//  be in. Generally speaking, you'll want to stick to sane formats, since
	//  the output unit won't accept every single possible stream format.
	//  Here, we're specifying floating point samples with a sample rate of
	//  44100 Hz in mono (i.e. 1 channel)
	AudioStreamBasicDescription ASBD = {
		.mSampleRate       = hostRate,
		.mFormatID         = kAudioFormatLinearPCM,
		.mFormatFlags      = kAudioFormatFlagsNativeFloatPacked,
		.mChannelsPerFrame = 1,
		.mFramesPerPacket  = 1,
		.mBitsPerChannel   = sizeof(Float32) * 8,
		.mBytesPerPacket   = sizeof(Float32),
		.mBytesPerFrame    = sizeof(Float32)
	};
	
	AudioUnitSetProperty(outputUnit,
						 kAudioUnitProperty_StreamFormat,
						 kAudioUnitScope_Input,
						 0,
						 &ASBD,
						 sizeof(ASBD));
	
	//  Next step is to tell our output unit which function we'd like it
	//  to call to get audio samples. We'll also pass in a context pointer,
	//  which can be a pointer to anything you need to maintain state between
	//  render callbacks. We only need to point to a double which represents
	//  the current phase of the sine wave we're creating.
	AURenderCallbackStruct callbackInfo = {
		.inputProc       = WaveRenderCallback,
		.inputProcRefCon = &renderPhase
	};
	
	AudioUnitSetProperty(outputUnit,
						 kAudioUnitProperty_SetRenderCallback,
						 kAudioUnitScope_Global,
						 0,
						 &callbackInfo,
						 sizeof(callbackInfo));
	
	//  Here we're telling the output unit to start requesting audio samples
	//  from our render callback. This is the line of code that starts actually
	//  sending audio to your speakers.
	AudioOutputUnitStart(outputUnit);
	
	return true;
}

- (void) unloadData
{
	AudioOutputUnitStop(outputUnit);
	AudioUnitUninitialize(outputUnit);
	AudioComponentInstanceDispose(outputUnit);
}

- (void) updateSound
{
}

- (void) applyConfig
{
}

- (void) readConfig
{
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/CoreAudio.txt",
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
	FILE* file = fopen([ [ NSString stringWithFormat:@"%@/CoreAudio.txt",
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
	[ config setTitle:@"CoreAudio Plugin" ];
	
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
