//
//  JKKeyboardObserver.m
//  JKKeyboardDemo
//
//  Created by Jakub Kleň on 8.2.2014.
//  Copyright (c) 2014 Jakub Kleň. All rights reserved.
//

#import "JKKeyboardObserver.h"
#import "UIView+JKKeyboard.h"


static int KVOJKKeyboardObserverKeyboardFrame;

NSString *const JKKeyboardWillShowNotification = @"JKKeyboardWillShowNotification";
NSString *const JKKeyboardDidShowNotification = @"JKKeyboardDidShowNotification";
NSString *const JKKeyboardWillChangeFrameNotification = @"JKKeyboardWillChangeFrameNotification";
NSString *const JKKeyboardDidChangeFrameNotification = @"JKKeyboardDidChangeFrameNotification";
NSString *const JKKeyboardWillHideNotification = @"JKKeyboardWillHideNotification";
NSString *const JKKeyboardDidHideNotification = @"JKKeyboardDidHideNotification";

NSString *const JKKeyboardObserverKeyboardMoveNotification = @"JKKeyboardObserverKeyboardMoveNotification";

static JKKeyboardObserver *sharedObserver;


@interface JKKeyboardObserver ()

@property (assign, nonatomic) BOOL isObserving, isKeyboardVisible, isShowingKeyboard, isHidingKeyboard, isInteractivelyHidingKeyboard, didFrameHideKeyboard, lastWillHideWasCausedByUserInteraction;
@property (assign, nonatomic) NSInteger willChangeFrameCalledTimes;
@property (assign, nonatomic) CGRect lastKeyboardFrame;

@property (readwrite, assign, nonatomic) CGRect keyboardFrameInRootView;
@property (strong, nonatomic) UIView *keyboardActiveView;

@end


@implementation JKKeyboardObserver

#pragma mark Class

+ (void)load {
	//to make sure we have the root view
	[[NSOperationQueue mainQueue] addOperationWithBlock:^ {
		 [self sharedObserver];
	 }];
}

+ (instancetype)sharedObserver {
	@synchronized(self) {
		if(!sharedObserver) {
			sharedObserver = [[super alloc] initUniqueInstance];
		}
	}
	
	return sharedObserver;
}

#pragma mark Lifecycle

- (id)initUniqueInstance {
	if(self = [super init]) {
		CGSize rootViewSize = self.rootView.bounds.size;
		//as we don't know how the root view is rotated in early states of app initialization
		CGFloat keyboardY = MAX(rootViewSize.width, rootViewSize.height);
		_keyboardFrameInRootView = CGRectMake(0.0, keyboardY, 0.0, 0.0);
		
		self.didFrameHideKeyboard = YES;
		self.isObserving = YES;
	}
	
	return self;
}

- (void)dealloc {
	self.isObserving = NO;
}

#pragma mark Properties

- (void)setIsObserving:(BOOL)isObserving {
	BOOL oldIsObserving = _isObserving;
	_isObserving = isObserving;
	
	if(oldIsObserving != self.isObserving) {
		if(oldIsObserving) {
			[self removeObservers_JKKeyboardObserver];
		}
		
		if(self.isObserving) {
			[self addObservers_JKKeyboardObserver];
		}
	}
}

- (UIView *)rootView {
	UIWindow *appWindow = [[[UIApplication sharedApplication] delegate] window];
	return (appWindow.subviews > 0) ? appWindow.subviews[0] : appWindow.rootViewController.view;
}

- (void)setKeyboardFrameInRootView:(CGRect)keyboardFrameInRootView {
	CGRect oldKeyboardFrameInRootView = _keyboardFrameInRootView;
	_keyboardFrameInRootView = keyboardFrameInRootView;
	
	if(!CGRectEqualToRect(oldKeyboardFrameInRootView, self.keyboardFrameInRootView)) {
		[[NSNotificationCenter defaultCenter] postNotificationName:JKKeyboardObserverKeyboardMoveNotification object:self];
	}
}

- (void)setKeyboardActiveView:(UIView *)keyboardActiveView {
	UIView *oldKeyboardActiveView = _keyboardActiveView;
	_keyboardActiveView = keyboardActiveView;
	
	if(oldKeyboardActiveView != self.keyboardActiveView) {
		if(oldKeyboardActiveView) {
			[oldKeyboardActiveView removeObserver:self forKeyPath:@"frame" context:&KVOJKKeyboardObserverKeyboardFrame];
            [oldKeyboardActiveView.layer removeObserver:self forKeyPath:@"frame" context:&KVOJKKeyboardObserverKeyboardFrame];
            [oldKeyboardActiveView.layer removeObserver:self forKeyPath:@"bounds" context:&KVOJKKeyboardObserverKeyboardFrame];
            [oldKeyboardActiveView.layer removeObserver:self forKeyPath:@"position" context:&KVOJKKeyboardObserverKeyboardFrame];
            [oldKeyboardActiveView.layer removeObserver:self forKeyPath:@"transform" context:&KVOJKKeyboardObserverKeyboardFrame];
            [oldKeyboardActiveView.layer removeObserver:self forKeyPath:@"zPosition" context:&KVOJKKeyboardObserverKeyboardFrame];
            [oldKeyboardActiveView.layer removeObserver:self forKeyPath:@"anchorPoint" context:&KVOJKKeyboardObserverKeyboardFrame];
            [oldKeyboardActiveView.layer removeObserver:self forKeyPath:@"anchorPointZ" context:&KVOJKKeyboardObserverKeyboardFrame];
		}
		
		if(self.keyboardActiveView) {
            [self.keyboardActiveView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&KVOJKKeyboardObserverKeyboardFrame];
            [self.keyboardActiveView.layer addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&KVOJKKeyboardObserverKeyboardFrame];
            [self.keyboardActiveView.layer addObserver:self forKeyPath:@"bounds" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&KVOJKKeyboardObserverKeyboardFrame];
            [self.keyboardActiveView.layer addObserver:self forKeyPath:@"position" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&KVOJKKeyboardObserverKeyboardFrame];
			[self.keyboardActiveView.layer addObserver:self forKeyPath:@"transform" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&KVOJKKeyboardObserverKeyboardFrame];
            [self.keyboardActiveView.layer addObserver:self forKeyPath:@"zPosition" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&KVOJKKeyboardObserverKeyboardFrame];
            [self.keyboardActiveView.layer addObserver:self forKeyPath:@"anchorPoint" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&KVOJKKeyboardObserverKeyboardFrame];
            [self.keyboardActiveView.layer addObserver:self forKeyPath:@"anchorPointZ" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&KVOJKKeyboardObserverKeyboardFrame];
		}
	}
}

#pragma mark Methods

- (void)updateKeyboardActiveView {
    if(!self.keyboardActiveView) {
        NSArray *appWindows = [[UIApplication sharedApplication] windows];
        
        for(UIWindow *window in appWindows) {
            NSArray *keyboardContainers = [window.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass:%@", NSClassFromString(@"UIInputSetContainerView")]];
            
            if(keyboardContainers.count > 0) {
                NSArray *keyboards = [[keyboardContainers[0] subviews] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass:%@", NSClassFromString(@"UIInputSetHostView")]];
                
                if(keyboards.count > 0) {
                    self.keyboardActiveView = keyboards[0];
                    break;
                }
            }
        }
        
        //pre-iOS8 fallback
        if(!self.keyboardActiveView) {
            for(UIWindow *window in appWindows) {
                NSArray *keyboards = [window.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self isKindOfClass:%@", NSClassFromString(@"UIPeripheralHostView")]];
                
                if(keyboards.count > 0) {
                    self.keyboardActiveView = keyboards[0];
                    break;
                }
            }
        }
    }
}

- (CGRect)endFrameFromNotification:(NSNotification *)notification keyboardShouldBeVisible:(BOOL)shouldBeVisible {
	CGRect keyboardFrame = [self endFrameFromNotification:notification];
	
	if(shouldBeVisible) {
		keyboardFrame.origin.y = self.rootView.bounds.size.height - keyboardFrame.size.height;
	} else {
		keyboardFrame.origin.y = self.rootView.bounds.size.height;
	}
	
	return keyboardFrame;
}

- (CGRect)endFrameFromNotification:(NSNotification *)notification
{
	CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
	
	keyboardFrame = [self.rootView convertRect:keyboardFrame fromView:nil];
	
	//don't yet know why, but apple sometimes gives us inf values for origin
	//zero sizes should be ok
	
	if(keyboardFrame.origin.x == INFINITY) {
		keyboardFrame.origin.x = 0.0;
	}
	
	if(keyboardFrame.origin.y == INFINITY) {
		keyboardFrame.origin.y = self.rootView.bounds.size.height;
	}
	
	return keyboardFrame;
}

#pragma mark Observing

- (void)keyboardWillShow:(NSNotification *)notification {
	if(!self.isKeyboardVisible) {
		self.isShowingKeyboard = YES;
		
		CGRect endFrame = [self endFrameFromNotification:notification keyboardShouldBeVisible:YES];
        
		[UIView animateWithKeyboardNotification:notification animations:^ {
			 self.keyboardFrameInRootView = endFrame;
		}];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:JKKeyboardWillShowNotification object:notification.object userInfo:notification.userInfo];
	}
}

- (void)keyboardDidShow:(NSNotification *)notification {
	if(!self.isKeyboardVisible) {
		self.isKeyboardVisible = YES;
		self.didFrameHideKeyboard = NO;
		
        [self updateKeyboardActiveView];
		
		self.isShowingKeyboard = NO;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:JKKeyboardDidShowNotification object:notification.object userInfo:notification.userInfo];
	}
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
	self.willChangeFrameCalledTimes++;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JKKeyboardWillChangeFrameNotification object:notification.object userInfo:notification.userInfo];
}

- (void)keyboardDidChangeFrame:(NSNotification *)notification {
	if(self.willChangeFrameCalledTimes > 0) {
		self.willChangeFrameCalledTimes--;
	} else if(self.lastWillHideWasCausedByUserInteraction) {
		//triggered when toggling the split keyboard on/off on iPad. One of those notifications is missing, so we have to update the frame this way. The second notif does not change the actual value.
		CGRect endFrame = [self endFrameFromNotification:notification];
		
		[UIView animateWithKeyboardNotification:notification animations:^ {
			 self.keyboardFrameInRootView = endFrame;
		}];
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JKKeyboardDidChangeFrameNotification object:notification.object userInfo:notification.userInfo];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	if(self.isKeyboardVisible) {
		self.isHidingKeyboard = YES;
		
		self.lastWillHideWasCausedByUserInteraction = [notification.userInfo[@"UIKeyboardFrameChangedByUserInteraction"] boolValue];
		CGRect endFrame = [self endFrameFromNotification:notification keyboardShouldBeVisible:NO];
        //to fix an issue in reported value
        UIViewAnimationCurve curve = [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue] - (NSInteger)self.isInteractivelyHidingKeyboard;
        
		if(!self.didFrameHideKeyboard && !self.lastWillHideWasCausedByUserInteraction) {
			[UIView animateWithKeyboardNotification:notification curve:curve animations:^ {
				 self.keyboardFrameInRootView = endFrame;
			}];
		}
		
		[[NSNotificationCenter defaultCenter] postNotificationName:JKKeyboardWillHideNotification object:notification.object userInfo:notification.userInfo];
	}
}

- (void)keyboardDidHide:(NSNotification *)notification {
	if(self.isKeyboardVisible) {
		self.isKeyboardVisible = NO;
		self.isHidingKeyboard = NO;
        self.isInteractivelyHidingKeyboard = NO;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:JKKeyboardDidHideNotification object:notification.object userInfo:notification.userInfo];
	}
}

- (void)addObservers_JKKeyboardObserver {
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)removeObservers_JKKeyboardObserver {
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[notificationCenter removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[notificationCenter removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
	[notificationCenter removeObserver:self name:UIKeyboardDidChangeFrameNotification object:nil];
	[notificationCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[notificationCenter removeObserver:self name:UIKeyboardDidHideNotification object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if(context == &KVOJKKeyboardObserverKeyboardFrame) {
        NSValue *oldValue = change[NSKeyValueChangeOldKey];
        NSValue *newValue = change[NSKeyValueChangeNewKey];
        BOOL valuesAreSame = (oldValue == newValue || [oldValue isEqual:newValue]);
        
        if(!valuesAreSame) {
            CGRect newFrame = self.keyboardActiveView.frame;
            
            if(!CGRectEqualToRect(newFrame, self.lastKeyboardFrame)) {
                self.lastKeyboardFrame = newFrame;
                
                if(!CGRectIsEmpty(newFrame)) {
                    if(self.isKeyboardVisible && !self.isShowingKeyboard && !self.isHidingKeyboard) {
                        self.isInteractivelyHidingKeyboard = YES;
                        
                        if(!self.didFrameHideKeyboard) {
                            CGRect newFrameInRootView = [self.keyboardActiveView.window convertRect:newFrame toView:self.rootView];
                            CGFloat maxYPos = self.rootView.bounds.size.height;
                            
                            self.keyboardFrameInRootView = newFrameInRootView;
                            self.didFrameHideKeyboard = (newFrameInRootView.origin.y >= maxYPos);
                        }
                    }
                }
            }
        }
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
