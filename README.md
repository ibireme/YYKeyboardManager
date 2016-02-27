YYKeyboardManager
==============

[![License MIT](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://raw.githubusercontent.com/ibireme/YYKeyboardManager/master/LICENSE)&nbsp;
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)&nbsp;
[![CocoaPods](http://img.shields.io/cocoapods/v/YYKeyboardManager.svg?style=flat)](http://cocoapods.org/?q=YYKeyboardManager)&nbsp;
[![CocoaPods](http://img.shields.io/cocoapods/p/YYKeyboardManager.svg?style=flat)](http://cocoapods.org/?q=YYKeyboardManager)&nbsp;
[![Support](https://img.shields.io/badge/support-iOS%206%2B%20-blue.svg?style=flat)](https://www.apple.com/nl/ios/)&nbsp;
[![Build Status](https://travis-ci.org/ibireme/YYKeyboardManager.svg?branch=master)](https://travis-ci.org/ibireme/YYKeyboardManager)

iOS utility class allows you to access keyboard view and track keyboard animation.<br/>
(It was used by [YYText](https://github.com/ibireme/YYText))

> ![demo](https://raw.github.com/ibireme/YYKeyboardManager/master/Demo/snapshot.gif
)

Compatibility
==============
iPhone / iPad / iPod with iOS 6 / 7 / 8 / 9.


Usage
==============
	
	// Get keyboard manager
	YYKeyboardManager *manager = [YYKeyboardManager defaultManager];
	
	// Get keyboard view and window
	UIView *view = manager.keyboardView;
	UIWindow *window = manager.keyboardWindow;
	
	// Get keyboard status
	BOOL visible = manager.keyboardVisible;
	CGRect frame = manager.keyboardFrame;
	frame = [manager convertRect:frame toView:self.view];
	
	// Track keyboard animation
	[manager addObserver:self];
	- (void)keyboardChangedWithTransition:(YYKeyboardTransition)transition {
	    CGRect fromFrame = [manager convertRect:transition.fromFrame toView:self.view];
	    CGRect toFrame =  [manager convertRect:transition.toFrame toView:self.view];
	    BOOL fromVisible = transition.fromVisible;
	    BOOL toVisible = transition.toVisible;
	    NSTimeInterval animationDuration = transition.animationDuration;
	    UIViewAnimationCurve curve = transition.animationCurve;
	}

Installation
==============

### CocoaPods

1. Add `pod 'YYKeyboardManager'` to your Podfile.
2. Run `pod install` or `pod update`.
3. Import \<YYKeyboardManager/YYKeyboardManager.h\>.


### Carthage

1. Add `github "ibireme/YYKeyboardManager"` to your Cartfile.
2. Run `carthage update --platform ios` and add the framework to your project.
3. Import \<YYKeyboardManager/YYKeyboardManager.h\>.


### Manually

1. Download all the files in the YYKeyboardManager subdirectory.
2. Add the source files to your Xcode project.
3. Import `YYKeyboardManager.h`.


Documentation
==============
Full API documentation is available on [CocoaDocs](http://cocoadocs.org/docsets/YYKeyboardManager/).<br/>
You can also install documentation locally using [appledoc](https://github.com/tomaz/appledoc).


Requirements
==============
This library requires `iOS 6.0+` and `Xcode 7.0+`.


License
==============
YYKeyboardManager is provided under the MIT license. See LICENSE file for details.



<br/><br/>
---
中文介绍
==============
iOS 键盘监听管理工具类。<br/>
(该工具是从 [YYText](https://github.com/ibireme/YYText) 提取出来的独立组件)

> ![demo](https://raw.github.com/ibireme/YYKeyboardManager/master/Demo/snapshot.gif
)

兼容性
==============
该项目能很好的兼容 iPhone / iPad / iPod，兼容 iOS 6 / 7 / 8 / 9，
并且能很好的处理屏幕旋转。

用法
==============
	// 获取键盘管理器
	YYKeyboardManager *manager = [YYKeyboardManager defaultManager];
	
	// 获取键盘的 view 和 window
	UIView *view = manager.keyboardView;
	UIWindow *window = manager.keyboardWindow;
	
	// 获取键盘当前状态
	BOOL visible = manager.keyboardVisible;
	CGRect frame = manager.keyboardFrame;
	frame = [manager convertRect:frame toView:self.view];
	
	// 监听键盘动画
	[manager addObserver:self];
	- (void)keyboardChangedWithTransition:(YYKeyboardTransition)transition {
	    CGRect fromFrame = [manager convertRect:transition.fromFrame toView:self.view];
	    CGRect toFrame =  [manager convertRect:transition.toFrame toView:self.view];
	    BOOL fromVisible = transition.fromVisible;
	    BOOL toVisible = transition.toVisible;
	    NSTimeInterval animationDuration = transition.animationDuration;
	    UIViewAnimationCurve curve = transition.animationCurve;
	}


安装
==============

### CocoaPods

1. 在 Podfile 中添加 `pod 'YYKeyboardManager'`。
2. 执行 `pod install` 或 `pod update`。
3. 导入 \<YYKeyboardManager/YYKeyboardManager.h\>。


### Carthage

1. 在 Cartfile 中添加 `github "ibireme/YYKeyboardManager"`。
2. 执行 `carthage update --platform ios` 并将生成的 framework 添加到你的工程。
3. 导入 \<YYKeyboardManager/YYKeyboardManager.h\>。


### 手动安装

1. 下载 YYKeyboardManager 文件夹内的所有内容。
2. 将 YYKeyboardManager 内的源文件添加(拖放)到你的工程。
3. 导入 `YYKeyboardManager.h`。


文档
==============
你可以在 [CocoaDocs](http://cocoadocs.org/docsets/YYKeyboardManager/) 查看在线 API 文档，也可以用 [appledoc](https://github.com/tomaz/appledoc) 本地生成文档。


系统要求
==============
该项目最低支持 `iOS 6.0` 和 `Xcode 7.0`。


许可证
==============
YYKeyboardManager 使用 MIT 许可证，详情见 LICENSE 文件。


