![Preview](/JKKeyboard.gif)

# JKKeyboard

JKKeyboard keeps track of the keyboard frame, and lets you manage your scroll view insets along with custom views' frames the easy way, handling animations completely transparently for you. It will also help you scrolling down your scroll views with the keyboard when appropriate.

## JKKeyboard.h

This file is the one you import when using JKKeyboard. It takes care of the other imports.

## JKKeyboardObserver

A singleton class which gets initiated automatically, and observes the keyboard frame.

## UIViewController+JKKeyboard

Implements the callback block, so you just call

``` objective-c
self.keyboardMoveBlock = ^(CGRect keyboardFrameInRootView, CGFloat keyboardIntersectionInRootView, CGFloat keyboardVisibility, BOOL shouldLayoutIfNeeded)
{
	//look @ the demo project view controller implementation file for more
};
```

Note: The block gets called automatically in every first viewWillLayoutSubviews after viewWillAppear:

Deallocation and rollback is performed automatically for you when your view controller is about to get deallocated, although if you want to do it earlier, you just set the keyboardMoveBlock to nil;

## UIView+JKKeyboard

Easily obtain the information you need. You can access the keyboard frame and intersection anytime when you views are in the view hierarchy, and in any view using .keyboardFrameInView and .keyboardIntersectionInView properties of your UIViews.

## UIScrollView+JKKeyboard

The main aim of this class is to simplify scrolling your scroll view to bottom when the keyboard is being shown. You're able to do something like

``` objective-c
if(self.scrollView.isScrolledToBottom)
{
	self.scrollView.shouldScrollToBottomOnNextKeyboardWillShow = YES;
}
```

in your text field's textFieldShouldBeginEditing: delegate callback, and your scroll view will do exactly what you'd expect.

## Known issues

There's a minor issue in the animation of the bottom VC after interactively dismissing a VC with opened keyboard (don't yet know why).

# Contact

You can contact me via my web @ [www.kukosk.com](http://www.kukosk.com/) and follow me on twitter [@kukosk](https://twitter.com/kukosk/).

# License

JKKeyboard is available under the MIT license. See LICENSE file for more info.