//
//  NSObject+Swizzling.m
//  JKKeyboardDemo
//
//  Created by Jakub Kleň on 9.2.2014.
//  Copyright (c) 2014 Jakub Kleň. All rights reserved.
//

#import "NSObject+JKRuntimeAdditions.h"
#import <objc/message.h>


@implementation NSObject (JKRuntimeAdditions)

+ (void)swizzle:(SEL)originalSelector with:(SEL)overrideSelector
{
	Method originalMethod = class_getInstanceMethod(self, originalSelector);
    Method overrideMethod = class_getInstanceMethod(self, overrideSelector);
	
    if(class_addMethod(self, originalSelector, method_getImplementation(overrideMethod), method_getTypeEncoding(overrideMethod)))
	{
        class_replaceMethod(self, overrideSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }
	else
	{
        method_exchangeImplementations(originalMethod, overrideMethod);
    }
}

@end
