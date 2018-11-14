//
//  UIView+JKKeyboard.h
//  JKKeyboardDemo
//
//  Created by Jakub Kleň on 8.2.2014.
//  Copyright (c) 2014 Jakub Kleň. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIView (JKKeyboard)

@property (readonly, assign, nonatomic) CGRect keyboardFrameInView;
@property (readonly, assign, nonatomic) CGFloat keyboardIntersectionInView, keyboardIntersectionFromMarginInView;

@property (readonly, strong, nonatomic) UIResponder *firstResponder;


+ (void)animateWithKeyboardNotification:(NSNotification *)notification animations:(void (^)(void))animations;
+ (void)animateWithKeyboardNotification:(NSNotification *)notification curve:(UIViewAnimationCurve)curve animations:(void (^)(void))animations;
+ (void)animateWithKeyboardDuration:(CGFloat)duration curve:(UIViewAnimationCurve)curve animations:(void (^)(void))animations;

@end
