//
//  UIScrollView+JKKeyboard.h
//  JKKeyboardDemo
//
//  Created by Jakub Kleň on 23.1.2014.
//  Copyright (c) 2014 Jakub Kleň. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIScrollView (JKKeyboard)

@property (readonly, assign, nonatomic) CGPoint topOffset, bottomOffset;
@property (readonly, assign, nonatomic) BOOL isScrolledToTop, isScrolledToBottom;
@property (assign, nonatomic) BOOL shouldScrollToBottomOnNextKeyboardWillShow;


- (void)scrollToTopAnimated:(BOOL)animated;
- (void)scrollToBottomAnimated:(BOOL)animated;

@end
