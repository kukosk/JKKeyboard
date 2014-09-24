//
//  JKAppDelegate.m
//  JKKeyboardDemo
//
//  Created by Jakub Kleň on 8.2.2014.
//  Copyright (c) 2014 Jakub Kleň. All rights reserved.
//

#import "JKAppDelegate.h"
#import "JKViewController.h"


@interface JKAppDelegate () <UISplitViewControllerDelegate>

@property (strong, nonatomic) UIViewController *rootViewController;

@end


@implementation JKAppDelegate

#pragma mark Lifecycle

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	[self.window makeKeyAndVisible];
	
	return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    return YES;
}

#pragma mark Properties

- (UIWindow *)window {
	if(!_window) {
		UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
		window.rootViewController = self.rootViewController;
		
		self.window = window;
	}
	
	return _window;
}

- (UIViewController *)rootViewController {
	if(!_rootViewController) {
		UIViewController *vc = nil;
		
		if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			UISplitViewController *splitVC = [[UISplitViewController alloc] init];
			splitVC.viewControllers = @[[[UINavigationController alloc] initWithRootViewController:[[JKViewController alloc] init]], [[UINavigationController alloc] initWithRootViewController:[[JKViewController alloc] init]]];
			splitVC.delegate = self;
			
			vc = splitVC;
		} else {
			vc = [[UINavigationController alloc] initWithRootViewController:[[JKViewController  alloc] init]];
		}
		
		self.rootViewController = vc;
	}
	
	return _rootViewController;
}

#pragma mark Methods

- (BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation {
	return NO;
}

@end
