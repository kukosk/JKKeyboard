//
//  NSObject+Swizzling.h
//  JKKeyboardDemo
//
//  Created by Jakub Kleň on 9.2.2014.
//  Copyright (c) 2014 Jakub Kleň. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (JKRuntimeAdditions)

+ (void)swizzle:(SEL)originalSelector with:(SEL)overrideSelector;

@end
