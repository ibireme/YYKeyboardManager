//
//  ViewController.m
//  YYKeyboardManagerDemo
//
//  Created by ibireme on 15/10/14.
//  Copyright © 2015 ibireme. All rights reserved.
//

#import "ViewController.h"
#import <YYKeyboardManager/YYKeyboardManager.h>

@interface ViewController () <YYKeyboardObserver>
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *button;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _button = [UIButton buttonWithType:UIButtonTypeCustom];
    _button.frame = CGRectMake(0, 0, 80, 40);
    _button.center = CGPointMake(CGRectGetWidth(self.view.bounds) / 2, CGRectGetHeight(self.view.bounds) / 3);
    _button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [_button addTarget:self action:@selector(buttonTapped) forControlEvents:UIControlEventTouchUpInside];
    [_button setTitle:@"Toggle" forState:UIControlStateNormal];
    [_button setTitleColor:[UIColor colorWithRed:0.062 green:0.518 blue:0.998 alpha:1.000] forState:UIControlStateNormal];
    [self.view addSubview:_button];
    
    _textField = [UITextField new];
    _textField.backgroundColor = [UIColor colorWithRed:0.791 green:0.861 blue:0.999 alpha:1.000];
    CGRect frame = CGRectZero;
    frame.size.width = self.view.frame.size.width;
    frame.size.height = 40;
    frame.origin.y = self.view.frame.size.height - frame.size.height;
    _textField.frame = frame;
    _textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:_textField];
    
    
    [[YYKeyboardManager defaultManager] addObserver:self];
}

- (void)dealloc {
    [[YYKeyboardManager defaultManager] removeObserver:self];
}

- (void)buttonTapped {
    if (_textField.isFirstResponder) {
        [_textField resignFirstResponder];
    } else {
        [_textField becomeFirstResponder];
    }
}

#pragma mark - @protocol YYKeyboardObserver

- (void)keyboardChangedWithTransition:(YYKeyboardTransition)transition {
    [UIView animateWithDuration:transition.animationCurve delay:0 options:transition.animationOption animations:^{
        CGRect kbFrame = [[YYKeyboardManager defaultManager] convertRect:transition.toFrame toView:self.view];
        CGRect textframe = _textField.frame;
        textframe.size.width = kbFrame.size.width;
        textframe.origin.y = kbFrame.origin.y - textframe.size.height;
        _textField.frame = textframe;
    } completion:^(BOOL finished) {
        
    }];
}

@end
