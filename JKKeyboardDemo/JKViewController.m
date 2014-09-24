//
//  JKViewController.m
//  JKKeyboardDemo
//
//  Created by Jakub Kleň on 8.2.2014.
//  Copyright (c) 2014 Jakub Kleň. All rights reserved.
//

#import "JKViewController.h"
#import "JKKeyboard.h"


@interface JKViewController () <UITextFieldDelegate, UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *replyView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *replyViewBottomSpaceLayoutConstraint;

@end


@implementation JKViewController

#pragma mark Lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSUInteger posInNavController = [self posInNavController];
	self.title = [NSString stringWithFormat:@"ViewController %ld", (long)posInNavController];
	
	__weak typeof(self) weakSelf = self;
	
	self.keyboardMoveBlock = ^(CGRect keyboardFrameInRootView, CGFloat keyboardIntersectionInRootView, CGFloat keyboardVisibility, BOOL shouldLayoutIfNeeded)
	{
		typeof(self) self = weakSelf;
		
        self.replyViewBottomSpaceLayoutConstraint.constant = self.view.keyboardIntersectionInView;
		
		if(shouldLayoutIfNeeded)
		{
			[self.view layoutIfNeeded];
		}
		
		[self updateScrollViewContentInsets];
		
		
		// just logging
		NSString *gapString = @"     ";
		NSString *logGap = [@"" stringByPaddingToLength:(posInNavController * gapString.length) withString:gapString startingAtIndex:0];
		NSLog(@"%@INTERSECTION:%6.1f    VISIBILITY:%.2f    ROOT: %@    VIEW:%@", logGap, self.view.keyboardIntersectionInView, keyboardVisibility, NSStringFromCGRect(keyboardFrameInRootView), NSStringFromCGRect(self.view.keyboardFrameInView));
	};
}

#pragma mark Methods

- (void)updateScrollViewContentInsets
{
	UIEdgeInsets newInsets = self.scrollView.contentInset;
	newInsets.bottom = self.replyView.bounds.size.height + self.view.keyboardIntersectionInView;
	
	self.scrollView.contentInset = newInsets;
	self.scrollView.scrollIndicatorInsets = newInsets;
	
	// maybe think about tweaking contentInset only when we need, as it would prevent 'over'scrolling being dismissed when dismissing interactively
}

- (NSUInteger)posInNavController
{
	NSUInteger vcIndex = [self.navigationController.viewControllers indexOfObject:self];
	return (vcIndex != NSNotFound) ? vcIndex : self.navigationController.viewControllers.count;
}

- (IBAction)pushViewController:(UIButton *)sender
{
	JKViewController *vc = [[JKViewController alloc] init];
	[self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)tapGestureRecognizerDidTap:(UITapGestureRecognizer *)sender
{
	[self.view.window endEditing:NO];
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    if(self.scrollView.isScrolledToBottom)
	{
		self.scrollView.shouldScrollToBottomOnNextKeyboardWillShow = YES;
	}
	
	return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if(self.scrollView.isScrolledToBottom)
	{
		self.scrollView.shouldScrollToBottomOnNextKeyboardWillShow = YES;
	}
	
	return YES;
}

@end
