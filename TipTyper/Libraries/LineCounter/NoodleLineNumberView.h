//
//  NoodleLineNumberView.h
//  Line View Test
//
//  Created by Paul Kim on 9/28/08.
//  Copyright (c) 2008 Noodlesoft, LLC. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

#import <Cocoa/Cocoa.h>

@class NoodleLineNumberMarker;

@interface NoodleLineNumberView : NSRulerView

// Array of character indices for the beginning of each line
@property (atomic, retain) NSMutableArray *lineIndices;

- (id)initWithScrollView:(NSScrollView *)aScrollView;

- (void)setFont:(NSFont *)aFont;
- (NSFont *)font;

- (void)setTextColor:(NSColor *)color;
- (NSColor *)textColor;

- (void)setAlternateTextColor:(NSColor *)color;
- (NSColor *)alternateTextColor;

- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;

- (NSUInteger)lineNumberForLocation:(float)location;
- (NoodleLineNumberMarker *)markerAtLine:(unsigned)line;

- (void)calculateLines;

@end
