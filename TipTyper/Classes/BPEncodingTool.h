//
//  EncodingTool.h
//  TipTyper
//
//  Created by Bruno Philipe on 4/29/13.
//  TipTyper – The simple plain-text editor for OS X.
//  Copyright (c) 2013 Bruno Philipe. All rights reserved.
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

#import <Foundation/Foundation.h>

@interface BPEncodingTool : NSObject

+ (BPEncodingTool *)sharedTool;

- (NSString *)nameForEncoding:(NSStringEncoding)encoding;
- (NSArray *)getAllEncodings;
- (NSStringEncoding)encodingForEncodingName:(NSString *)name;

+ (NSString*)loadStringWithPathAskingForEncoding:(NSURL*)fileURL usedEncoding:(NSStringEncoding*)usedEncoding;
+ (NSStringEncoding)requestEncoding:(NSStringEncoding)oldEncoding;

@end
