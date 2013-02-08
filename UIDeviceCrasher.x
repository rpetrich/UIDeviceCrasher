#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>

static bool allowed;
static NSArray *badSymbols;

size_t UIApplicationInitialize();

MSHook(size_t, UIApplicationInitialize)
{
	allowed = true;
	return _UIApplicationInitialize();
}

%hook UIDevice

+ (UIDevice *)currentDevice
{
	if (!allowed && !badSymbols) {
		NSArray *symbols = [NSThread callStackSymbols];
		@synchronized (self) {
			if (badSymbols)
				[symbols release];
			else
				badSymbols = symbols;
		}
	}
	return %orig();
}

%end

%hook SpringBoard

- (void)_reportAppLaunchFinished
{
	%orig();
	if (badSymbols) {
		UIAlertView *av = [[UIAlertView alloc] init];
		av.title = @"UIDeviceCrasher";
		av.message = [badSymbols description];
		[av addButtonWithTitle:@"OK"];
		[av show];
		[av release];
	}
}

%end

%ctor
{
	MSHookFunction(&UIApplicationInitialize, &$UIApplicationInitialize, (void **)&_UIApplicationInitialize);
	%init();
}
