//
//  YYKeyboardManager.m
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/6/3.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "YYKeyboardManager.h"
#import <objc/runtime.h>


static int _YYKeyboardViewFrameObserverKey;

/// Observer for view's frame/bounds/center/transform
@interface _YYKeyboardViewFrameObserver : NSObject
@property (nonatomic, copy) void (^notifyBlock)(UIView *keyboard);
- (void)addToKeyboardView:(UIView *)keyboardView;
+ (instancetype)observerForView:(UIView *)keyboardView;
@end


@implementation _YYKeyboardViewFrameObserver {
    __unsafe_unretained UIView *_keyboardView;
}
- (void)addToKeyboardView:(UIView *)keyboardView {
    if (_keyboardView == keyboardView) return;
    if (_keyboardView) {
        [self removeFrameObserver];
        objc_setAssociatedObject(_keyboardView, &_YYKeyboardViewFrameObserverKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    _keyboardView = keyboardView;
    if (keyboardView) {
        [self addFrameObserver];
    }
    objc_setAssociatedObject(keyboardView, &_YYKeyboardViewFrameObserverKey, self, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)removeFrameObserver {
    [_keyboardView removeObserver:self forKeyPath:@"frame"];
    [_keyboardView removeObserver:self forKeyPath:@"center"];
    [_keyboardView removeObserver:self forKeyPath:@"bounds"];
    [_keyboardView removeObserver:self forKeyPath:@"transform"];
    _keyboardView = nil;
}

- (void)addFrameObserver {
    if (!_keyboardView) return;
    [_keyboardView addObserver:self forKeyPath:@"frame" options:kNilOptions context:NULL];
    [_keyboardView addObserver:self forKeyPath:@"center" options:kNilOptions context:NULL];
    [_keyboardView addObserver:self forKeyPath:@"bounds" options:kNilOptions context:NULL];
    [_keyboardView addObserver:self forKeyPath:@"transform" options:kNilOptions context:NULL];
}

- (void)dealloc {
    [self removeFrameObserver];
}

+ (instancetype)observerForView:(UIView *)keyboardView {
    if (!keyboardView) return nil;
    return objc_getAssociatedObject(keyboardView, &_YYKeyboardViewFrameObserverKey);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    BOOL isPrior = [[change objectForKey:NSKeyValueChangeNotificationIsPriorKey] boolValue];
    if (isPrior) return;
    
    NSKeyValueChange changeKind = [[change objectForKey:NSKeyValueChangeKindKey] integerValue];
    if (changeKind != NSKeyValueChangeSetting) return;
    
    id newVal = [change objectForKey:NSKeyValueChangeNewKey];
    if (newVal == [NSNull null]) newVal = nil;
    
    if (_notifyBlock) {
        _notifyBlock(_keyboardView);
    }
}

@end



@implementation YYKeyboardManager {
    NSHashTable *_observers;
    
    CGRect _fromFrame;
    BOOL _fromVisible;
    UIInterfaceOrientation _fromOrientation;
    
    CGRect _notificationFromFrame;
    CGRect _notificationToFrame;
    NSTimeInterval _notificationDuration;
    UIViewAnimationCurve _notificationCurve;
    BOOL _hasNotification;
    
    CGRect _observedToFrame;
    BOOL _hasObservedChange;
    
    BOOL _lastIsNotification;
}

- (instancetype)init {
    @throw [NSException exceptionWithName:@"YYKeyboardManager init error" reason:@"Use 'defaultManager' to get instance." userInfo:nil];
    return [super init];
}

- (instancetype)_init {
    self = [super init];
    _observers = [[NSHashTable alloc] initWithOptions:NSPointerFunctionsWeakMemory|NSPointerFunctionsObjectPointerPersonality capacity:0];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_keyboardFrameWillChangeNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    // for iPad (iOS 9)
    if ([UIDevice currentDevice].systemVersion.floatValue >= 9) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_keyboardFrameDidChangeNotification:)
                                                     name:UIKeyboardDidChangeFrameNotification
                                                   object:nil];
    }
    return self;
}

- (void)_initFrameObserver {
    UIView *keyboardView = self.keyboardView;
    if (!keyboardView) return;
    __weak typeof(self) _self = self;
    _YYKeyboardViewFrameObserver *observer = [_YYKeyboardViewFrameObserver observerForView:keyboardView];
    if (!observer) {
        observer = [_YYKeyboardViewFrameObserver new];
        observer.notifyBlock = ^(UIView *keyboard) {
            [_self _keyboardFrameChanged:keyboard];
        };
        [observer addToKeyboardView:keyboardView];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (instancetype)defaultManager {
    static YYKeyboardManager *mgr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mgr = [[self alloc] _init];
    });
    return mgr;
}

+ (void)load {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self defaultManager];
    });
}

- (void)addObserver:(id<YYKeyboardObserver>)observer {
    if (!observer) return;
    [_observers addObject:observer];
}

- (void)removeObserver:(id<YYKeyboardObserver>)observer {
    if (!observer) return;
    [_observers removeObject:observer];
}

- (UIWindow *)keyboardWindow {
    UIWindow *window = nil;
    for (window in [UIApplication sharedApplication].windows) {
        if ([self _getKeyboardViewFromWindow:window]) return window;
    }
    window = [UIApplication sharedApplication].keyWindow;
    if ([self _getKeyboardViewFromWindow:window]) return window;
    
    NSMutableArray *kbWindows = nil;
    for (window in [UIApplication sharedApplication].windows) {
        NSString *windowName = NSStringFromClass(window.class);
        if ([self _systemVersion] < 9) {
            // UITextEffectsWindow
            if (windowName.length == 19 &&
                [windowName hasPrefix:@"UI"] &&
                [windowName hasSuffix:@"TextEffectsWindow"]) {
                if (!kbWindows) kbWindows = [NSMutableArray new];
                [kbWindows addObject:window];
            }
        } else {
            // UIRemoteKeyboardWindow
            if (windowName.length == 22 &&
                [windowName hasPrefix:@"UI"] &&
                [windowName hasSuffix:@"RemoteKeyboardWindow"]) {
                if (!kbWindows) kbWindows = [NSMutableArray new];
                [kbWindows addObject:window];
            }
        }
    }
    
    if (kbWindows.count == 1) {
        return kbWindows.firstObject;
    }
    
    return nil;
}

- (UIView *)keyboardView {
    UIWindow *window = nil;
    UIView *view = nil;
    for (window in [UIApplication sharedApplication].windows) {
        view = [self _getKeyboardViewFromWindow:window];
        if (view) return view;
    }
    window = [UIApplication sharedApplication].keyWindow;
    view = [self _getKeyboardViewFromWindow:window];
    if (view) return view;
    return nil;
}

- (BOOL)isKeyboardVisible {
    UIWindow *window = self.keyboardWindow;
    if (!window) return NO;
    UIView *view = self.keyboardView;
    if (!view) return NO;
    CGRect rect = CGRectIntersection(window.bounds, view.frame);
    if (CGRectIsNull(rect)) return NO;
    if (CGRectIsInfinite(rect)) return NO;
    return rect.size.width > 0 && rect.size.height > 0;
}

- (CGRect)keyboardFrame {
    UIView *keyboard = [self keyboardView];
    if (!keyboard) return CGRectNull;
    
    CGRect frame = CGRectNull;
    UIWindow *window = keyboard.window;
    if (window) {
        frame = [window convertRect:keyboard.frame toWindow:nil];
    } else {
        frame = keyboard.frame;
    }
    return frame;
}

#pragma mark - private

- (double)_systemVersion {
    static double v;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        v = [UIDevice currentDevice].systemVersion.doubleValue;
    });
    return v;
}

- (UIView *)_getKeyboardViewFromWindow:(UIWindow *)window {
    /*
     iOS 6/7:
     UITextEffectsWindow
        UIPeripheralHostView << keyboard
     
     iOS 8:
     UITextEffectsWindow
        UIInputSetContainerView
            UIInputSetHostView << keyboard
     
     iOS 9:
     UIRemoteKeyboardWindow
        UIInputSetContainerView
            UIInputSetHostView << keyboard
     */
    if (!window) return nil;
    
    // Get the window
    NSString *windowName = NSStringFromClass(window.class);
    if ([self _systemVersion] < 9) {
        // UITextEffectsWindow
        if (windowName.length != 19) return nil;
        if (![windowName hasPrefix:@"UI"]) return nil;
        if (![windowName hasSuffix:@"TextEffectsWindow"]) return nil;
    } else {
        // UIRemoteKeyboardWindow
        if (windowName.length != 22) return nil;
        if (![windowName hasPrefix:@"UI"]) return nil;
        if (![windowName hasSuffix:@"RemoteKeyboardWindow"]) return nil;
    }
    
    // Get the view
    if ([self _systemVersion] < 8) {
        // UIPeripheralHostView
        for (UIView *view in window.subviews) {
            NSString *viewName = NSStringFromClass(view.class);
            if (viewName.length != 20) continue;
            if (![viewName hasPrefix:@"UI"]) continue;
            if (![viewName hasSuffix:@"PeripheralHostView"]) continue;
            return view;
        }
    } else {
        // UIInputSetContainerView
        for (UIView *view in window.subviews) {
            NSString *viewName = NSStringFromClass(view.class);
            if (viewName.length != 23) continue;
            if (![viewName hasPrefix:@"UI"]) continue;
            if (![viewName hasSuffix:@"InputSetContainerView"]) continue;
            // UIInputSetHostView
            for (UIView *subView in view.subviews) {
                NSString *subViewName = NSStringFromClass(subView.class);
                if (subViewName.length != 18) continue;
                if (![subViewName hasPrefix:@"UI"]) continue;
                if (![subViewName hasSuffix:@"InputSetHostView"]) continue;
                return subView;
            }
        }
    }
    
    return nil;
}

- (void)_keyboardFrameWillChangeNotification:(NSNotification *)notif {
    if (![notif.name isEqualToString:UIKeyboardWillChangeFrameNotification]) return;
    NSDictionary *info = notif.userInfo;
    if (!info) return;
    
    [self _initFrameObserver];
    
    NSValue *beforeValue = info[UIKeyboardFrameBeginUserInfoKey];
    NSValue *afterValue = info[UIKeyboardFrameEndUserInfoKey];
    NSNumber *curveNumber = info[UIKeyboardAnimationCurveUserInfoKey];
    NSNumber *durationNumber = info[UIKeyboardAnimationDurationUserInfoKey];
    
    CGRect before = beforeValue.CGRectValue;
    CGRect after = afterValue.CGRectValue;
    UIViewAnimationCurve curve = curveNumber.integerValue;
    NSTimeInterval duration = durationNumber.doubleValue;
    
    // ignore zero end frame
    if (after.size.width <= 0 && after.size.height <= 0) return;
    
    _notificationFromFrame = before;
    _notificationToFrame = after;
    _notificationCurve = curve;
    _notificationDuration = duration;
    _hasNotification = YES;
    _lastIsNotification = YES;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_notifyAllObservers) object:nil];
    if (duration == 0) {
        [self performSelector:@selector(_notifyAllObservers) withObject:nil afterDelay:0 inModes:@[NSRunLoopCommonModes]];
    } else {
        [self _notifyAllObservers];
    }
}

- (void)_keyboardFrameDidChangeNotification:(NSNotification *)notif {
    if (![notif.name isEqualToString:UIKeyboardDidChangeFrameNotification]) return;
    NSDictionary *info = notif.userInfo;
    if (!info) return;
    
    [self _initFrameObserver];
    
    NSValue *afterValue = info[UIKeyboardFrameEndUserInfoKey];
    CGRect after = afterValue.CGRectValue;
    
    // ignore zero end frame
    if (after.size.width <= 0 && after.size.height <= 0) return;
    
    _notificationToFrame = after;
    _notificationCurve = UIViewAnimationCurveEaseInOut;
    _notificationDuration = 0;
    _hasNotification = YES;
    _lastIsNotification = YES;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_notifyAllObservers) object:nil];
    [self performSelector:@selector(_notifyAllObservers) withObject:nil afterDelay:0 inModes:@[NSRunLoopCommonModes]];
}

- (void)_keyboardFrameChanged:(UIView *)keyboard {
    if (keyboard != self.keyboardView) return;
    
    UIWindow *window = keyboard.window;
    if (window) {
        _observedToFrame = [window convertRect:keyboard.frame toWindow:nil];
    } else {
        _observedToFrame = keyboard.frame;
    }
    _hasObservedChange = YES;
    _lastIsNotification = NO;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_notifyAllObservers) object:nil];
    [self performSelector:@selector(_notifyAllObservers) withObject:nil afterDelay:0 inModes:@[NSRunLoopCommonModes]];
}

- (void)_notifyAllObservers {
    UIView *keyboard = self.keyboardView;
    UIWindow *window = keyboard.window;
    if (!window) {
        window = [UIApplication sharedApplication].keyWindow;
    }
    if (!window) {
        window = [UIApplication sharedApplication].windows.firstObject;
    }
    
    YYKeyboardTransition trans = {0};
    
    // from
    if (_fromFrame.size.width == 0 && _fromFrame.size.height == 0) { // first notify
        _fromFrame.size.width = window.bounds.size.width;
        _fromFrame.size.height = trans.toFrame.size.height;
        _fromFrame.origin.x = trans.toFrame.origin.x;
        _fromFrame.origin.y = window.bounds.size.height;
    } else if ((_notificationFromFrame.origin.y == window.frame.size.height) &&
             ([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait) &&
             !CGRectEqualToRect(_fromFrame, _notificationToFrame)) {
        _fromFrame.size.width = window.bounds.size.width;
        _fromFrame.size.height = _notificationToFrame.size.height;
        _fromFrame.origin.x = _notificationFromFrame.origin.x;
        _fromFrame.origin.y = _notificationFromFrame.origin.y;
    }
    trans.fromFrame = _fromFrame;
    trans.fromVisible = _fromVisible;
    
    // to
    if (_lastIsNotification || (_hasObservedChange && CGRectEqualToRect(_observedToFrame, _notificationToFrame))) {
        trans.toFrame = _notificationToFrame;
        trans.animationDuration = _notificationDuration;
        trans.animationCurve = _notificationCurve;
        trans.animationOption = _notificationCurve << 16;
        
        // Fix iPad(iOS7) keyboard frame error after rotate device when the keyboard is not docked to bottom.
        if (((int)[self _systemVersion]) == 7) {
            UIInterfaceOrientation ori = [UIApplication sharedApplication].statusBarOrientation;
            if (_fromOrientation != UIInterfaceOrientationUnknown && _fromOrientation != ori) {
                switch (ori) {
                    case UIInterfaceOrientationPortrait: {
                        if (CGRectGetMaxY(trans.toFrame) != window.frame.size.height) {
                            trans.toFrame.origin.y -= trans.toFrame.size.height;
                        }
                    } break;
                    case UIInterfaceOrientationPortraitUpsideDown: {
                        if (CGRectGetMinY(trans.toFrame) != 0) {
                            trans.toFrame.origin.y += trans.toFrame.size.height;
                        }
                    } break;
                    case UIInterfaceOrientationLandscapeLeft: {
                        if (CGRectGetMaxX(trans.toFrame) != window.frame.size.width) {
                            trans.toFrame.origin.x -= trans.toFrame.size.width;
                        }
                    } break;
                    case UIInterfaceOrientationLandscapeRight: {
                        if (CGRectGetMinX(trans.toFrame) != 0) {
                            trans.toFrame.origin.x += trans.toFrame.size.width;
                        }
                    } break;
                    default: break;
                }
            }
        }
    } else {
        trans.toFrame = _observedToFrame;
    }
    
    if (window && trans.toFrame.size.width > 0 && trans.toFrame.size.height > 0) {
        CGRect rect = CGRectIntersection(window.bounds, trans.toFrame);
        if (!CGRectIsNull(rect) && !CGRectIsEmpty(rect)) {
            trans.toVisible = YES;
        }
    }
    
    if (!CGRectEqualToRect(trans.toFrame, _fromFrame)) {
        for (id<YYKeyboardObserver> observer in _observers.copy) {
            if ([observer respondsToSelector:@selector(keyboardChangedWithTransition:)]) {
                [observer keyboardChangedWithTransition:trans];
            }
        }
    }
    
    _hasNotification = NO;
    _hasObservedChange = NO;
    _fromFrame = trans.toFrame;
    _fromVisible = trans.toVisible;
    _fromOrientation = [UIApplication sharedApplication].statusBarOrientation;
}

- (CGRect)convertRect:(CGRect)rect toView:(UIView *)view {
    if (CGRectIsNull(rect)) return rect;
    if (CGRectIsInfinite(rect)) return rect;
    
    UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
    if (!mainWindow) mainWindow = [UIApplication sharedApplication].windows.firstObject;
    if (!mainWindow) { // no window ?!
        if (view) {
            [view convertRect:rect fromView:nil];
        } else {
            return rect;
        }
    }
    
    rect = [mainWindow convertRect:rect fromWindow:nil];
    if (!view) return [mainWindow convertRect:rect toWindow:nil];
    if (view == mainWindow) return rect;
    
    UIWindow *toWindow = [view isKindOfClass:[UIWindow class]] ? (id)view : view.window;
    if (!mainWindow || !toWindow) return [mainWindow convertRect:rect toView:view];
    if (mainWindow == toWindow) return [mainWindow convertRect:rect toView:view];
    
    // in different window
    rect = [mainWindow convertRect:rect toView:mainWindow];
    rect = [toWindow convertRect:rect fromWindow:mainWindow];
    rect = [view convertRect:rect fromView:toWindow];
    return rect;
}

@end
