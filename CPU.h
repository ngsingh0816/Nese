//
//  CPU.h
//  Nese
//
//  Created by Singh on 2/21/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "types.h"
#import "Opcodes.h"
#import "addr.h"
#include <vector>
#include "xEmitter.h"

#define CYCLES_PER_SCANLINE 113.6673
#define INTERRUPT_PERIOD 7

void WriteMemory(u16 pos, u8 data);
void WriteMemory16(u16 pos, u16 data);
void WriteMemoryP(u16 pos, u8* data, u16 length);
void WriteMemory16P(u16 pos, u16* data, u16 length);
u8 ReadMemory(u16 pos);
u16 ReadMemory16(u16 pos);

void Push(u8 data);
void Push16(u16 data);
u8 Pop();
u16 Pop16();

void Init();
void Reset();
void Stop();

extern bool reset;
extern bool inVBLANK;
extern u8 mapper;

void SetCarryFlag(bool set);
void SetZeroFlag(bool set);
void SetInterruptFlag(bool set);
void SetDecimalMode(bool set);
void SetBreakCommand(bool set);
void SetOverflowFlag(bool set);
void SetNegativeFlag(bool set);
bool CarryFlag();
bool ZeroFlag();
bool InterruptFlag();
bool DecimalMode();
bool BreakCommand();
bool OverflowFlag();
bool NegativeFlag();

void EnableVBLANK();
void EnableSpriteHit();
void DisableVBLANK();
void DisableSpriteHit();
void EnableEightSprites();
void DisableEightSprites();

void Fetch();
void Execute(float count);
void Step();
void PerformStep(u16 opcode);

// Regs
extern u8* memory;
extern u16 pc;
extern u8 sp;	// offset from 0x100
extern u8 A;
extern u8 X;
extern u8 Y;
extern u8 P;
extern int cycles;
extern u8 theopcode;
extern Opcode opc;
extern u16 operand;
extern xEmitter* emit;
extern bool dynarec;
