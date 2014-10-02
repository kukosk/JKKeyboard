//
//  UIViewController+JKKeyboard.m
//  JKKeyboardDemo
//
//  Created by Jakub Kleň on 9.2.2014.
//  Copyright (c) 2014 Jakub Kleň. All rights reserved.
//

#import "UIViewController+JKKeyboard.h"
#import "JKKeyboardObserver.h"
#import "UIView+JKKeyboard.h"
#import "JRSwizzle.h"
#import <objc/message.h>


@interface UIViewController ()

@property (readwrite, assign, nonatomic) UIInterfaceOrientation currentOrientation;
@property (assign, nonatomic) BOOL canActivateKeyboardMoveBlock, shouldCallKeyboardMoveBlock;

@end


@implementation UIViewController (JKKeyboard)

#pragma mark Lifecycle

+ (void)load {
    [self jr_swizzleMethod:@selector(viewDidLoad) withMethod:@selector(viewDidLoad_UIViewController_JKKeyboard) error:nil];
    [self jr_swizzleMethod:@selector(viewWillAppear:) withMethod:@selector(viewWillAppear_UIViewController_JKKeyboard:) error:nil];
    [self jr_swizzleMethod:@selector(viewDidAppear:) withMethod:@selector(viewDidAppear_UIViewController_JKKeyboard:) error:nil];
    [self jr_swizzleMethod:@selector(viewWillLayoutSubviews) withMethod:@selector(viewWillLayoutSubviews_UIViewController_JKKeyboard) error:nil];
    [self jr_swizzleMethod:@selector(viewWillDisappear:) withMethod:@selector(viewWillDisappear_UIViewController_JKKeyboard:) error:nil];
    [self jr_swizzleMethod:@selector(didRotateFromInterfaceOrientation:) withMethod:@selector(didRotateFromInterfaceOrientation_UIViewController_JKKeyboard:) error:nil];
    [self jr_swizzleMethod:NSSelectorFromString(@"dealloc") withMethod:@selector(dealloc_UIViewController_JKKeyboard) error:nil];
}

- (void)viewDidLoad_UIViewController_JKKeyboard {
    [self viewDidLoad_UIViewController_JKKeyboard];
    
    self.currentOrientation = self.interfaceOrientation;
}

- (void)viewWillAppear_UIViewController_JKKeyboard:(BOOL)animated {
    [self viewWillAppear_UIViewController_JKKeyboard:animated];
    
    if([self respondsToSelector:@selector(transitionCoordinator)] && self.transitionCoordinator) {
        //prevents animation glitches in .view
        //seems like apple is doing some magic under the hood, resetting the frames of the animated views somehow (affecting our ones)
        [self.transitionCoordinator animateAlongsideTransitionInView:self.view animation:^(id<UIViewControllerTransitionCoordinatorContext> context){ } completion:nil];
    }
    
    self.canActivateKeyboardMoveBlock = YES;
}

- (void)viewDidAppear_UIViewController_JKKeyboard:(BOOL)animated {
    [self viewDidAppear_UIViewController_JKKeyboard:animated];
    
    [self layoutForCurrentOrientation_UIViewController_JKKeyboard];
    
    dispatch_async(dispatch_get_main_queue(), ^ {
        [self activateKeyboardMoveBlock_UIViewController_JKKeyboard];
    });
}

- (void)viewWillLayoutSubviews_UIViewController_JKKeyboard {
    [self viewWillLayoutSubviews_UIViewController_JKKeyboard];
    
    [self activateKeyboardMoveBlock_UIViewController_JKKeyboard];
}

- (void)viewWillDisappear_UIViewController_JKKeyboard:(BOOL)animated {
    self.canActivateKeyboardMoveBlock = NO;
    self.shouldCallKeyboardMoveBlock = NO;
    
    [self viewWillDisappear_UIViewController_JKKeyboard:animated];
}

- (void)didRotateFromInterfaceOrientation_UIViewController_JKKeyboard:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self didRotateFromInterfaceOrientation_UIViewController_JKKeyboard:fromInterfaceOrientation];
    
    [self layoutForCurrentOrientation_UIViewController_JKKeyboard];
}

- (void)dealloc_UIViewController_JKKeyboard {
    if(self.keyboardMoveBlock) {
        self.keyboardMoveBlock = nil;
    }
    
    [self dealloc_UIViewController_JKKeyboard];
}

#pragma mark Properties

- (BOOL)isObserving {
    return [objc_getAssociatedObject(self, @selector(isObserving)) boolValue];
}

- (void)setIsObserving:(BOOL)isObserving {
    BOOL oldIsObserving = self.isObserving;
    objc_setAssociatedObject(self, @selector(isObserving), @(isObserving), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    if(oldIsObserving != self.isObserving) {
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        
        if(oldIsObserving) {
            [notificationCenter removeObserver:self name:JKKeyboardObserverKeyboardMoveNotification object:nil];
        }
        
        if(self.isObserving) {
            [notificationCenter addObserver:self selector:@selector(keyboardDidMove_UIViewController_JKKeyboard:) name:JKKeyboardObserverKeyboardMoveNotification object:nil];
        }
    }
}

- (UIInterfaceOrientation)currentOrientation {
    return [objc_getAssociatedObject(self, @selector(currentOrientation)) integerValue];
}

- (void)setCurrentOrientation:(UIInterfaceOrientation)currentOrientation {
    objc_setAssociatedObject(self, @selector(currentOrientation), @(currentOrientation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (JKKeyboardMoveBlock)keyboardMoveBlock {
    return objc_getAssociatedObject(self, @selector(keyboardMoveBlock));
}

- (void)setKeyboardMoveBlock:(JKKeyboardMoveBlock)keyboardMoveBlock {
    JKKeyboardMoveBlock oldKeyboardMoveBlock = self.keyboardMoveBlock;
    objc_setAssociatedObject(self, @selector(keyboardMoveBlock), keyboardMoveBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    if(oldKeyboardMoveBlock != self.keyboardMoveBlock) {
        self.isObserving = !!self.keyboardMoveBlock;
    }
}

- (BOOL)canActivateKeyboardMoveBlock {
    return [objc_getAssociatedObject(self, @selector(canActivateKeyboardMoveBlock)) boolValue];
}

- (void)setCanActivateKeyboardMoveBlock:(BOOL)canActivateKeyboardMoveBlock {
    objc_setAssociatedObject(self, @selector(canActivateKeyboardMoveBlock), @(canActivateKeyboardMoveBlock), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)shouldCallKeyboardMoveBlock {
    return [objc_getAssociatedObject(self, @selector(shouldCallKeyboardMoveBlock)) boolValue];
}

- (void)setShouldCallKeyboardMoveBlock:(BOOL)shouldCallKeyboardMoveBlock {
    objc_setAssociatedObject(self, @selector(shouldCallKeyboardMoveBlock), @(shouldCallKeyboardMoveBlock), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark Methods

- (void)callKeyboardMoveBlockWithShouldLayoutIfNeeded:(BOOL)shouldLayoutIfNeeded {
    if(self.keyboardMoveBlock && self.shouldCallKeyboardMoveBlock) {
        JKKeyboardObserver *observer = [JKKeyboardObserver sharedObserver];
        UIView *rootView = observer.rootView;
        
        CGRect keyboardFrameInRootView = rootView.keyboardFrameInView;
        CGFloat keyboardIntersectionInRootView = rootView.keyboardIntersectionInView;
        CGFloat keyboardVisibility = (keyboardFrameInRootView.size.height > 0) ? keyboardIntersectionInRootView / keyboardFrameInRootView.size.height : 0.0;
        BOOL rotatesInterfaceOrientation = self.interfaceOrientation != self.currentOrientation;
        BOOL isActive = (self.view.window && (!self.navigationController || self == self.navigationController.visibleViewController));
        shouldLayoutIfNeeded = shouldLayoutIfNeeded && !rotatesInterfaceOrientation && isActive;
        
        __weak typeof(self) weakSelf = self;
        self.keyboardMoveBlock(weakSelf, keyboardFrameInRootView, keyboardIntersectionInRootView, keyboardVisibility, shouldLayoutIfNeeded);
    }
}

- (void)activateKeyboardMoveBlock_UIViewController_JKKeyboard {
    if(!self.shouldCallKeyboardMoveBlock && self.canActivateKeyboardMoveBlock) {
        self.shouldCallKeyboardMoveBlock = YES;
        [self callKeyboardMoveBlockWithShouldLayoutIfNeeded:NO];
    }
}

- (void)layoutForCurrentOrientation_UIViewController_JKKeyboard {
    self.currentOrientation = self.interfaceOrientation;
}

#pragma mark Observing

- (void)keyboardDidMove_UIViewController_JKKeyboard:(NSNotification *)notification {
    [self callKeyboardMoveBlockWithShouldLayoutIfNeeded:YES];
}

@end
