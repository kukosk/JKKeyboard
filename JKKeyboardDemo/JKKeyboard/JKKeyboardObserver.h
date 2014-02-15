//
//  JKKeyboardObserver.h
//  JKKeyboardDemo
//
//  Created by Jakub Kleň on 8.2.2014.
//  Copyright (c) 2014 Jakub Kleň. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString *const JKKeyboardWillShowNotification;
extern NSString *const JKKeyboardDidShowNotification;
extern NSString *const JKKeyboardWillChangeFrameNotification;
extern NSString *const JKKeyboardDidChangeFrameNotification;
extern NSString *const JKKeyboardWillHideNotification;
extern NSString *const JKKeyboardDidHideNotification;

extern NSString *const JKKeyboardObserverKeyboardMoveNotification;


@interface JKKeyboardObserver : NSObject

@property (readonly, strong, nonatomic) UIView *rootView;
@property (readonly, assign, nonatomic) CGRect keyboardFrameInRootView;


+ (instancetype) alloc __attribute__((unavailable("Not available, singleton...")));
+ (instancetype) new __attribute__((unavailable("Not available, singleton...")));
- (instancetype) init __attribute__((unavailable("Not available, singleton...")));

+ (instancetype)sharedObserver;

@end
