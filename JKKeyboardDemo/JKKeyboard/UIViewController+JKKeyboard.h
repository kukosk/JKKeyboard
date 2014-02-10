//
//  UIViewController+JKKeyboard.h
//  JKKeyboardDemo
//
//  Created by Jakub Kleň on 9.2.2014.
//  Copyright (c) 2014 Jakub Kleň. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIViewController (JKKeyboard)

typedef void (^ JKKeyboardMoveBlock)(CGRect keyboardFrameInRootView, CGFloat keyboardIntersectionInRootView, CGFloat keyboardVisibility, BOOL shouldLayoutIfNeeded);

@property (assign, nonatomic) BOOL isObserving;
@property (readonly, assign, nonatomic) UIInterfaceOrientation currentOrientation;

@property (copy, nonatomic) JKKeyboardMoveBlock keyboardMoveBlock;


- (void)callKeyboardMoveBlockWithShouldLayoutIfNeeded:(BOOL)shouldLayoutIfNeeded;

@end
