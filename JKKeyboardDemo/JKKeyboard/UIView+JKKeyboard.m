//
//  UIView+JKKeyboard.m
//  JKKeyboardDemo
//
//  Created by Jakub Kleň on 8.2.2014.
//  Copyright (c) 2014 Jakub Kleň. All rights reserved.
//

#import "UIView+JKKeyboard.h"
#import "JKKeyboardObserver.h"


@implementation UIView (JKKeyboard)

#pragma mark Class

+ (void)animateWithKeyboardNotification:(NSNotification *)notification animations:(void (^)(void))animations {
    UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [self animateWithKeyboardNotification:notification curve:curve animations:animations];
}

+ (void)animateWithKeyboardNotification:(NSNotification *)notification curve:(UIViewAnimationCurve)curve animations:(void (^)(void))animations {
    CGFloat duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    if(duration <= 0.0) {
        duration = 0.15;
    }
    
    [self animateWithKeyboardDuration:duration curve:curve animations:animations];
}

+ (void)animateWithKeyboardDuration:(CGFloat)duration curve:(UIViewAnimationCurve)curve animations:(void (^)(void))animations {
    if(animations) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:curve];
        
        animations();
        
        [UIView commitAnimations];
    }
}

#pragma mark Properties

- (CGRect)keyboardFrameInView {
    JKKeyboardObserver *observer = [JKKeyboardObserver sharedObserver];
    return [self convertRect:observer.keyboardFrameInRootView fromView:observer.rootView];
}

- (CGFloat)keyboardIntersectionInView {
    CGFloat keyboardIntersectionInView = self.bounds.size.height - self.keyboardFrameInView.origin.y;
    keyboardIntersectionInView = MAX(0.0, keyboardIntersectionInView);
    
    return keyboardIntersectionInView;
}

- (CGFloat)keyboardIntersectionFromMarginInView {
    return MAX(0.0, self.keyboardIntersectionInView - self.layoutMargins.bottom);
}

- (CGFloat)keyboardIntersectionFromSafeAreaInView {
    CGFloat bottomSafeAreaInset = 0.0;
    if (@available(iOS 11.0, *)) {
        bottomSafeAreaInset = self.safeAreaInsets.bottom;
    }

    return MAX(0.0, self.keyboardIntersectionInView - bottomSafeAreaInset);
}

- (UIResponder *)firstResponder {
    if(self.isFirstResponder) {
        return self;
    }
    
    for(UIView *subView in self.subviews) {
        UIResponder *firstResponder = subView.firstResponder;
        
        if(firstResponder) {
            return firstResponder;
        }
    }
    
    return nil;
}

@end
