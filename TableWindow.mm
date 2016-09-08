//
//  TableWindow.m
//  Emu
//
//  Created by Singh on 6/11/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "TableWindow.h"


@implementation TableWindow

// Creation
- (void) awakeFromNib
{
	items = [NSMutableArray new ]; // Set Items as new
	[self setDataSource:self];	// Set the data
	[self reloadData];	// Refresh
}

// Cleanup
- (void) dealloc
{
	// Release Everything
	[items release];
	[super dealloc];
}

// Items
- (NSMutableArray *)items {
	return items;
}

// Object At Row
- (id) itemAtRow: (unsigned)row
{
	if (row >= [ items count ])
		return nil;
	return [ items objectAtIndex:row ];
}

// Text
- (id) selectedRowItemforColumnIdentifier:(NSString * )anIdentifier
{
	// If a row is selected, give the object of the column's selected row
	if ([self selectedRow] != -1)
		return [[items objectAtIndex:[self selectedRow]] objectForKey:anIdentifier];
	
	// Otherwise give nothing
	return nil;
}

// Replace row
- (void) replaceRow: (unsigned)row item: (NSDictionary*) obj
{
	[ items replaceObjectAtIndex:row withObject:obj ];
	[ items retain ];
	[ self reloadData ];	// Refresh
}

// Delete all items
- (void) removeAllRows
{
	[ self setItems:[ NSMutableArray new ] ];
}

// Set
- (void) setItems:(NSMutableArray *) anArray 
{
	// Check to see if equal
	if (items == anArray)
		return;
	// Set
	[items release];
	items = anArray;
	[items retain];
	// Refresh
	[self reloadData];
}

// Add
- (void) addRow:(NSDictionary *) item 
{
	// Push back object
	[items insertObject:item atIndex:[items count]];
	// Refresh
	[self reloadData];
}

// Remove
- (void) removeRow:(unsigned) row 
{
	// Delete
	[items removeObjectAtIndex:row];
	// Refresh
	[self reloadData];
}

// Mouse Down
- (void) mouseDown:(NSEvent *)theEvent
{
	[ super mouseDown: theEvent ];
	if ([ theEvent modifierFlags ] & NSControlKeyMask)
		[ self rightMouseDown:theEvent ];
}

// Right Mouse Down
- (void) rightMouseDown:(NSEvent *)theEvent
{
	[ super rightMouseDown: theEvent ];
	if ([ [ self target ] respondsToSelector:rightAction ])
		[ [ self target ] performSelector:rightAction withObject: self ];
}

// Right Mouse Down Action
- (SEL) rightAction
{
	return rightAction;
}

// Right Mouse Down Action
- (void) setRightAction: (SEL) sel
{
	rightAction = sel;
}

// Number of rows
- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView 
{
	return [items count];
}

// Other stuff
- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	if (row != -1)
		return [[items objectAtIndex:row] objectForKey:[tableColumn identifier]];
	
	return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object 
   forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
	[ items replaceObjectAtIndex:row withObject:object ];
}

@end
