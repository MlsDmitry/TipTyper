//
//  BPTextView.m
//  TipTyper
//
//  Created by Bruno Philipe on 2/23/14.
//  TipTyper – The simple plain-text editor for OS X.
//  Copyright (c) 2014 Bruno Philipe. All rights reserved.
//  
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

#import "BPTextView.h"
#import "BPLayoutManager.h"

#define kBP_KEYCODE_RETURN 36

//static NSTouchBarItemIdentifier BPTouchBarForTextFieldIdentifier = @"com.brunophilipe.TipTyper.TouchBar.BPTextField";

@interface BPTextView ()

@end

@implementation BPTextView

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		BPLayoutManager *layoutManager = [BPLayoutManager new];
		[self.textContainer replaceLayoutManager:layoutManager];
	}
	return self;
}

- (NSUInteger)countTabCharsFromLocation:(NSUInteger)location spareSpaces:(NSUInteger *)spareSpaces
{
	NSUInteger count = 0, spaces = 0;
	NSString *string = self.string;
	unichar chr;
	BOOL finished = NO;

	/* The current character might be a tab or a space, so we conider it in the count. */

	while (!finished && location < string.length) {
		chr = [string characterAtIndex:location];
		if (chr == '\t') {
			count++;
			location++;
		} else if (chr == ' ') {
			spaces++;
			location++;
		} else {
			/* Found a character different fom space or tab, we can exit the loop now. */
			finished = YES;
		}
	}

	/* If the caller sent a pointer to return the spare spaces count, set the value there. */
	if (spareSpaces != NULL) {
		*spareSpaces = spaces;
		return count;
	}

	/* There can be a mixture of tabs and spaces in a single line. We should take everything into account. */
	return count + spaces/self.tabSize;
}

- (NSString*)buildStringWithTabsCount:(NSUInteger)count
{
	NSMutableString *str = [NSMutableString stringWithCapacity:count];
	for (NSUInteger i=0; i<count; i++) {
		[str appendString:@"\t"];
	}
	return [str copy];
}

- (NSString*)buildStringWithSpacesCount:(NSUInteger)count
{
	NSMutableString *str = [NSMutableString stringWithCapacity:count];
	for (NSUInteger i=0; i<count; i++) {
		[str appendString:@" "];
	}
	return [str copy];
}

- (void)keyDown:(NSEvent *)theEvent
{
	[super keyDown:theEvent];

	/* Automatic tab insertion. */
	if (self.shouldInsertTabsOnLineBreak && theEvent.keyCode == kBP_KEYCODE_RETURN) {
		NSRange range = [self rangeForUserTextChange];
		NSString *string = self.string;
		NSUInteger location = 0, count = 0;
		unichar chr;

		range.location--;

		if (range.location < string.length) {
			chr = [string characterAtIndex:range.location];
			if (chr == '\n') {
				[string getLineStart:&location end:nil contentsEnd:nil forRange:NSMakeRange(range.location, 1)];
				count = [self countTabCharsFromLocation:location spareSpaces:NULL];

				if (self.shouldInsertSpacesInsteadOfTabs) {
					[self insertText:[self buildStringWithSpacesCount:count * self.tabSize]];
				} else {
					[self insertText:[self buildStringWithTabsCount:count]];
				}
			}
		}
	}
}

- (void)insertTab:(id)sender
{
	if (self.shouldInsertSpacesInsteadOfTabs) {
		[self insertText:[self buildStringWithSpacesCount:self.tabSize]];
	} else {
		[super insertTab:sender];
	}
}

- (void)increaseIndentation
{
	NSMutableArray *ranges = [[self selectedRanges] mutableCopy];
	NSUInteger totalCharactersAdded = 0;

	for (NSUInteger rangeIndex = 0; rangeIndex < ranges.count; rangeIndex++)
	{
		NSRange currentRange = [[ranges objectAtIndex:rangeIndex] rangeValue];
		NSUInteger charactersAdded = 0;

		currentRange.location += totalCharactersAdded;
		currentRange.length   += 0;

		NSString *text = self.string;
		NSString *substring = [text substringWithRange:currentRange];
		NSMutableArray *lineStarts = [NSMutableArray new];
		
		void (^indentationBlock)(NSRange) = ^(NSRange substringRange)
		{
			NSUInteger lineStart = 0;
			
			[text getLineStart:&lineStart
						   end:nil
				   contentsEnd:nil
					  forRange:NSMakeRange(currentRange.location + substringRange.location, substringRange.length)];
			
			[lineStarts addObject:@(lineStart)];
		};

		if ([substring length] != 0)
		{
            NSArray<NSString*> *lines = [substring componentsSeparatedByString:@"\n"];
            NSUInteger currentPosition = 0;
            
            for (id line in lines) {
                indentationBlock(NSMakeRange(currentPosition, [line length]));
                currentPosition += [line length];
            }
		}
		else
		{
			indentationBlock(NSMakeRange(0, 0));
		}

		for (NSUInteger line=0; line<lineStarts.count; line++)
		{
			charactersAdded = [self increaseIndentationAtLocation:[[lineStarts objectAtIndex:line] integerValue] + charactersAdded * line];
		}

		[ranges replaceObjectAtIndex:rangeIndex
						  withObject:[NSValue valueWithRange:NSMakeRange(currentRange.location + charactersAdded,
																		 currentRange.length + charactersAdded * (lineStarts.count - 1))]];

		totalCharactersAdded += charactersAdded * lineStarts.count;
	}

	[self setSelectedRanges:ranges];
}

- (void)decreaseIndentation
{
	NSMutableArray *ranges = [[self selectedRanges] mutableCopy];
	NSUInteger totalCharactersRemoved = 0;

	for (NSUInteger rangeIndex = 0; rangeIndex < ranges.count; rangeIndex++)
	{
		NSRange currentRange = [[ranges objectAtIndex:rangeIndex] rangeValue];
		NSUInteger charactersRemoved = 0, charactersRemovedFirstLine = 0;

		currentRange.location -= totalCharactersRemoved;

		NSString *text = self.string;
		NSString *substring = [text substringWithRange:currentRange];
		NSMutableArray *lineStarts = [NSMutableArray new];
		
        void (^indentationBlock)(NSRange) = ^(NSRange substringRange)
        {
            NSUInteger lineStart = 0;
            
            [text getLineStart:&lineStart
                           end:nil
                   contentsEnd:nil
                      forRange:NSMakeRange(currentRange.location + substringRange.location, substringRange.length)];
            
            [lineStarts addObject:@(lineStart)];
        };

		if ([substring length] != 0)
		{
//			[substring enumerateSubstringsInRange:NSMakeRange(0, substring.length)
//										  options:NSStringEnumerationByLines
//									   usingBlock:indentationBlock];
            NSArray<NSString*> *lines = [substring componentsSeparatedByString:@"\n"];
            NSUInteger currentPosition = 0;
            
            for (id line in lines) {
                indentationBlock(NSMakeRange(currentPosition, [line length]));
                currentPosition += [line length];
            }
		}
		else
		{
			indentationBlock(NSMakeRange(0, 0));
		}

		for (NSUInteger line=0; line<lineStarts.count; line++) {
			charactersRemoved += [self decreaseIndentationAtLocation:[[lineStarts objectAtIndex:line] integerValue] - charactersRemoved];
			if (line == 0)
				charactersRemovedFirstLine = charactersRemoved;
		}

		NSRange newRange;

		if (currentRange.location == 0)
		{
			if (currentRange.length == 0)
			{
				newRange = currentRange;
			}
			else if (currentRange.length < charactersRemoved)
			{
				newRange = NSMakeRange(currentRange.location, 0);
			}
			else
			{
				newRange = NSMakeRange(currentRange.location, currentRange.length - charactersRemoved);
			}
		}
		else if (currentRange.location - charactersRemovedFirstLine < [text length]
				 && [text characterAtIndex:(currentRange.location - charactersRemovedFirstLine)] == '\n')
		{
			if (currentRange.length == 0)
			{
				newRange = NSMakeRange(currentRange.location - charactersRemoved, currentRange.length);
			}
			else
			{
				newRange = NSMakeRange(currentRange.location, currentRange.length - charactersRemoved);
			}
		}
		else
		{
			newRange = NSMakeRange(currentRange.location - charactersRemovedFirstLine, currentRange.length - (charactersRemoved - charactersRemovedFirstLine));
		}

		[ranges replaceObjectAtIndex:rangeIndex withObject:[NSValue valueWithRange:newRange]];

		totalCharactersRemoved += charactersRemoved;
	}

	[self setSelectedRanges:ranges];
}

- (NSUInteger)increaseIndentationAtLocation:(NSUInteger)location
{
	if (self.shouldInsertSpacesInsteadOfTabs) {
		[self insertText:[self buildStringWithSpacesCount:self.tabSize] replacementRange:NSMakeRange(location, 0)];
		return self.tabSize;
	} else {
		[self insertText:[self buildStringWithTabsCount:1] replacementRange:NSMakeRange(location, 0)];
		return 1;
	}
}

- (NSUInteger)decreaseIndentationAtLocation:(NSUInteger)location
{
	NSUInteger spaces;
	NSUInteger count = [self countTabCharsFromLocation:location spareSpaces:&spaces];

	if (count > 0) {
		[self insertText:@"" replacementRange:NSMakeRange(location, 1)];
		return 1;
	} else if (spaces > 0) {
		[self insertText:@"" replacementRange:NSMakeRange(location, MIN(spaces, self.tabSize))];
		return spaces;
	}

	return 0;
}

//- (NSTouchBar*)makeTouchBar
//{
//	if ([[self window] isKindOfClass:[BPDocumentWindow class]])
//	{
//		BPDocumentWindow *window = (BPDocumentWindow*)[self window];
//
//		NSTouchBar *bar = [[NSTouchBar alloc] init];
//
//		[bar setDelegate:window];
//
//		// Set the default ordering of items.
//		[bar setDefaultItemIdentifiers:[window defaultTouchBarIdentifiers]];
//		[bar setCustomizationIdentifier: BPTouchBarForTextFieldIdentifier];
//
//		return bar;
//	}
//
//	return nil;
//}

@end
