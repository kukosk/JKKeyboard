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

NSString *const JKKeyboardObserverKeyboardMoveNotification = @"JKKeyboardObserverKeyboardMoveNotification";

static JKKeyboardObserver *sharedObserver;


@interface JKKeyboardObserver ()

@property (assign, nonatomic) BOOL isObserving, isKeyboardVisible, isShowingKeyboard, isHidingKeyboard, didFrameHideKeyboard, lastWillHideWasCausedByUserInteraction;
@property (assign, nonatomic) NSInteger willChangeFrameCalledTimes;

@property (readwrite, assign, nonatomic) CGRect keyboardFrameInRootView;
@property (strong, nonatomic) UIResponder *keyboardActiveInput;
@property (strong, nonatomic) UIView *keyboardActiveView;

@end


@implementation JKKeyboardObserver

#pragma mark Class

+ (void)load
{
	//to make sure we have the root view
	[[NSOperationQueue mainQueue] addOperationWithBlock:^
	 {
		 [self sharedObserver];
	 }];
}

+ (instancetype)sharedObserver
{
	@synchronized(self)
	{
		if(!sharedObserver)
		{
			sharedObserver = [[super alloc] initUniqueInstance];
		}
	}
	
	return sharedObserver;
}

#pragma mark Lifecycle

- (id)initUniqueInstance
{
	if(self = [super init])
	{
		CGSize rootViewSize = self.rootView.bounds.size;
		//as we don't know how the root view is rotated in early states of app initialization
		CGFloat keyboardY = MAX(rootViewSize.width, rootViewSize.height);
		_keyboardFrameInRootView = CGRectMake(0.0, keyboardY, 0.0, 0.0);
		
		self.keyboardActiveInput = self.rootView.firstResponder;
		self.didFrameHideKeyboard = YES;
		self.isObserving = YES;
	}
	
	return self;
}

- (void)dealloc
{
	self.isObserving = NO;
}

#pragma mark Properties

- (void)setIsObserving:(BOOL)isObserving
{
	BOOL oldIsObserving = _isObserving;
	_isObserving = isObserving;
	
	if(oldIsObserving != self.isObserving)
	{
		if(oldIsObserving)
		{
			[self removeObservers_JKKeyboardObserver];
		}
		
		if(self.isObserving)
		{
			[self addObservers_JKKeyboardObserver];
		}
	}
}

- (UIView *)rootView
{
	UIWindow *appWindow = [[[UIApplication sharedApplication] delegate] window];
	return (appWindow.subviews > 0) ? appWindow.subviews[0] : appWindow.rootViewController.view;
}

- (void)setKeyboardFrameInRootView:(CGRect)keyboardFrameInRootView
{
	CGRect oldKeyboardFrameInRootView = _keyboardFrameInRootView;
	_keyboardFrameInRootView = keyboardFrameInRootView;
	
	if(!CGRectEqualToRect(oldKeyboardFrameInRootView, self.keyboardFrameInRootView))
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:JKKeyboardObserverKeyboardMoveNotification object:self];
	}
}

- (void)setKeyboardActiveInput:(UIResponder *)keyboardActiveInput
{
	UIResponder *oldKeyboardActiveInput = _keyboardActiveInput;
	_keyboardActiveInput = keyboardActiveInput;
	
	if(oldKeyboardActiveInput != self.keyboardActiveInput)
	{
		[self updateKeyboardActiveViewWithReassign];
	}
}

- (void)setKeyboardActiveView:(UIView *)keyboardActiveView
{
	id oldKeyboardActiveView = _keyboardActiveView;
	_keyboardActiveView = keyboardActiveView;
	
	if(oldKeyboardActiveView != self.keyboardActiveView)
	{
		if(oldKeyboardActiveView)
		{
			[oldKeyboardActiveView removeObserver:self forKeyPath:@"frame" context:&KVOJKKeyboardObserverKeyboardFrame];
		}
		
		if(self.keyboardActiveView)
		{
			[self.keyboardActiveView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:&KVOJKKeyboardObserverKeyboardFrame];
		}
	}
}

#pragma mark Methods

- (void)updateKeyboardActiveViewWithReassign
{
	self.keyboardActiveView = self.keyboardActiveInput.inputAccessoryView.superview;
    
    if(!self.keyboardActiveView)
	{
		self.isObserving = NO;
        [self.rootView reassignFirstResponder];
		self.isObserving = YES;
    }
}

- (CGRect)endFrameFromNotification:(NSNotification *)notification keyboardShouldBeVisible:(BOOL)shouldBeVisible
{
	CGRect keyboardFrame = [self endFrameFromNotification:notification];
	
	if(shouldBeVisible)
	{
		keyboardFrame.origin.y = self.rootView.bounds.size.height - keyboardFrame.size.height;
	}
	else
	{
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
	
	if(keyboardFrame.origin.x == INFINITY)
	{
		keyboardFrame.origin.x = 0.0;
	}
	
	if(keyboardFrame.origin.y == INFINITY)
	{
		keyboardFrame.origin.y = self.rootView.bounds.size.height;
	}
	
	return keyboardFrame;
}

#pragma mark Observing

- (void)keyboardWillShow:(NSNotification *)notification
{
	if(!self.isKeyboardVisible)
	{
		self.isShowingKeyboard = YES;
		
		CGRect endFrame = [self endFrameFromNotification:notification keyboardShouldBeVisible:YES];
		
		[UIView animateWithKeyboardNotification:notification animations:^
		 {
			 self.keyboardFrameInRootView = endFrame;
		 }];
	}
}

- (void)keyboardDidShow:(NSNotification *)notification
{
	if(!self.isKeyboardVisible)
	{
		self.isKeyboardVisible = YES;
		self.didFrameHideKeyboard = NO;
		
		[self updateKeyboardActiveViewWithReassign];
		
		self.isShowingKeyboard = NO;
	}
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
	self.willChangeFrameCalledTimes++;
}

- (void)keyboardDidChangeFrame:(NSNotification *)notification
{
	if(self.willChangeFrameCalledTimes > 0)
	{
		self.willChangeFrameCalledTimes--;
	}
	else if(self.lastWillHideWasCausedByUserInteraction)
	{
		//triggered when toggling the split keyboard on/off on iPad. One of those notifications is missing, so we have to update the frame this way. The second notif does not change the actual value.
		CGRect endFrame = [self endFrameFromNotification:notification];
		
		[UIView animateWithKeyboardNotification:notification animations:^
		 {
			 self.keyboardFrameInRootView = endFrame;
		 }];
	}
}

- (void)keyboardWillHide:(NSNotification *)notification
{
	if(self.isKeyboardVisible)
	{
		self.isHidingKeyboard = YES;
		
		self.lastWillHideWasCausedByUserInteraction = [notification.userInfo[@"UIKeyboardFrameChangedByUserInteraction"] boolValue];
		CGRect endFrame = [self endFrameFromNotification:notification keyboardShouldBeVisible:NO];
		
		if(!self.didFrameHideKeyboard && !self.lastWillHideWasCausedByUserInteraction)
		{
			[UIView animateWithKeyboardNotification:notification animations:^
			 {
				 self.keyboardFrameInRootView = endFrame;
			 }];
		}
	}
}

- (void)keyboardDidHide:(NSNotification *)notification
{
	if(self.isKeyboardVisible)
	{
		self.isKeyboardVisible = NO;
		self.isHidingKeyboard = NO;
	}
}

- (void)responderDidBecomeActive:(NSNotification *)notification
{
	UIResponder *keyboardActiveInput = notification.object;
	
    if(!keyboardActiveInput.inputAccessoryView)
	{
        UITextField *textField = (UITextField *)keyboardActiveInput;
		
        if([textField respondsToSelector:@selector(setInputAccessoryView:)])
		{
            UIView *nullView = [[UIView alloc] initWithFrame:CGRectZero];
            nullView.backgroundColor = [UIColor clearColor];
            textField.inputAccessoryView = nullView;
        }
		
		keyboardActiveInput = (UIResponder *)textField;
    }
	
	self.keyboardActiveInput = keyboardActiveInput;
}

- (void)addObservers_JKKeyboardObserver
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(responderDidBecomeActive:) name:UITextFieldTextDidBeginEditingNotification object:nil];
    [notificationCenter addObserver:self selector:@selector(responderDidBecomeActive:) name:UITextViewTextDidBeginEditingNotification object:nil];
}

- (void)removeObservers_JKKeyboardObserver
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	
	[notificationCenter removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[notificationCenter removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	[notificationCenter removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
	[notificationCenter removeObserver:self name:UIKeyboardDidChangeFrameNotification object:nil];
	[notificationCenter removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[notificationCenter removeObserver:self name:UIKeyboardDidHideNotification object:nil];
	[notificationCenter removeObserver:self name:UITextFieldTextDidBeginEditingNotification object:nil];
    [notificationCenter removeObserver:self name:UITextViewTextDidBeginEditingNotification object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if(context == &KVOJKKeyboardObserverKeyboardFrame)
	{
		CGRect oldFrame = [change[NSKeyValueChangeOldKey] CGRectValue];
		CGRect newFrame = [change[NSKeyValueChangeNewKey] CGRectValue];
		
		UIView *rootView = self.rootView;
		UIView *keyboardWindow = self.keyboardActiveView.window;
		
		oldFrame = [keyboardWindow convertRect:oldFrame toView:rootView];
		newFrame = [keyboardWindow convertRect:newFrame toView:rootView];
		
		if(!CGRectEqualToRect(oldFrame, newFrame) && !CGRectIsEmpty(newFrame))
		{
			if(self.isKeyboardVisible && !self.isShowingKeyboard && !self.isHidingKeyboard)
			{
				CGFloat maxYPos = self.rootView.bounds.size.height;
				
				if(!self.didFrameHideKeyboard)
				{
					self.keyboardFrameInRootView = newFrame;
					self.didFrameHideKeyboard = (newFrame.origin.y >= maxYPos);
				}
			}
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

@end
