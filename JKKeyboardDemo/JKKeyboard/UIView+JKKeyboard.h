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
@property (readonly, assign, nonatomic) CGFloat keyboardIntersectionInView;

@property (readonly, strong, nonatomic) UIResponder *firstResponder;


+ (void)animateWithKeyboardNotification:(NSNotification *)notification animations:(void (^)(void))animations;
- (void)reassignFirstResponder;

@end
