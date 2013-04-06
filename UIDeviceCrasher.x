#import <Foundation/Foundation.h>
#import <substrate.h>
#import <dlfcn.h>
#import <execinfo.h>
#import <CoreFoundation/CFUserNotification.h>

static bool allowed;
static int symbolCount;
#define MAX_SYMBOLS 1000
static void *symbols[MAX_SYMBOLS];

size_t UIApplicationInitialize();

static BOOL ShouldThrowInsteadOfAlert(void) {
	return [[[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.rpetrich.uidevicecrasher.plist"] objectForKey:@"DCShouldThrow"] boolValue];
}

MSHook(size_t, UIApplicationInitialize)
{
	allowed = true;
	return _UIApplicationInitialize();
}

%hook UIDevice

+ (UIDevice *)currentDevice
{
	if (!allowed) {
		@synchronized (self) {
			if (ShouldThrowInsteadOfAlert()) {
				[NSException raise:NSInternalInconsistencyException format:@"+[UIDevice currentDevice] called before UIApplicationInitialize!"];
			}
			if (symbolCount < MAX_SYMBOLS) {
				symbolCount += backtrace(&symbols[symbolCount], MAX_SYMBOLS - symbolCount);
			}
		}
	}
	return %orig();
}

%end

%hook UIScreen

+ (void)initialize
{
	if (!allowed) {
		@synchronized (self) {
			if (ShouldThrowInsteadOfAlert()) {
				[NSException raise:NSInternalInconsistencyException format:@"+[UIScreen initialize] called before UIApplicationInitialize!"];
			}
			if (symbolCount < MAX_SYMBOLS) {
				symbolCount += backtrace(&symbols[symbolCount], MAX_SYMBOLS - symbolCount);
			}
		}
	}
	%orig();
}

+ (UIScreen *)mainScreen
{
	if (!allowed) {
		@synchronized (self) {
			if (ShouldThrowInsteadOfAlert()) {
				[NSException raise:NSInternalInconsistencyException format:@"+[UIScreen mainScreen] called before UIApplicationInitialize!"];
			}
			if (symbolCount < MAX_SYMBOLS) {
				symbolCount += backtrace(&symbols[symbolCount], MAX_SYMBOLS - symbolCount);
			}
		}
	}
	return %orig();
}

+ (NSArray *)screens
{
	if (!allowed) {
		@synchronized (self) {
			if (ShouldThrowInsteadOfAlert()) {
				[NSException raise:NSInternalInconsistencyException format:@"+[UIScreen screens] called before UIApplicationInitialize!"];
			}
			if (symbolCount < MAX_SYMBOLS) {
				symbolCount += backtrace(&symbols[symbolCount], MAX_SYMBOLS - symbolCount);
			}
		}
	}
	return %orig();
}

%end

%hook SpringBoard

- (void)_reportAppLaunchFinished
{
	%orig();
	if (symbolCount) {
		NSMutableSet *alreadyAdded = [NSMutableSet set];
		[alreadyAdded addObject:@"/Library/MobileSubstrate/DynamicLibraries/AAAUIDeviceCrasher.dylib"];
		[alreadyAdded addObject:@"/Library/Frameworks/CydiaSubstrate.framework/Libraries/SubstrateLoader.dylib"];
		[alreadyAdded addObject:@"/Library/MobileSubstrate/MobileSubstrate.dylib"];
		[alreadyAdded addObject:@"/System/Library/Frameworks/UIKit.framework/UIKit"];
		[alreadyAdded addObject:@"/System/Library/Frameworks/Foundation.framework/Foundation"];
		[alreadyAdded addObject:@"/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation"];
		[alreadyAdded addObject:@"/System/Library/CoreServices/SpringBoard.app/SpringBoard"];
		[alreadyAdded addObject:@"/usr/lib/libobjc.A.dylib"];
		[alreadyAdded addObject:@"/usr/lib/libobjc.dylib"];
		[alreadyAdded addObject:@"/usr/lib/libSystem.B.dylib"];
		[alreadyAdded addObject:@"/usr/lib/libSystem.dylib"];
		NSMutableArray *libraries = [NSMutableArray array];
		Dl_info info;
		for (int i = 0; i < symbolCount; i++) {
			if (dladdr(symbols[i], &info) && info.dli_fname) {
				NSString *string = [NSString stringWithUTF8String:info.dli_fname];
				NSLog(@"UIDeviceCrasher: %@", string);
				if (![alreadyAdded containsObject:string] && ![string hasPrefix:@"/System/Library/PrivateFrameworks/"] && ![string hasPrefix:@"/usr/lib/system/"]) {
					[alreadyAdded addObject:string];
					[libraries addObject:[[string lastPathComponent] stringByDeletingPathExtension]];
				}
			}
		}
		NSString *prefix = [libraries count] ? @"One of the following components may be causing reboots to fail:\n" : @"The following component may be causing reboots to fail:\n";
		NSString *message = [prefix stringByAppendingString:[libraries componentsJoinedByString:@"\n"]];
		NSDictionary *fields = [NSDictionary dictionaryWithObjectsAndKeys:
			@"UIDeviceCrasher", (id)kCFUserNotificationAlertHeaderKey,
			message, kCFUserNotificationAlertMessageKey,
			nil];
		SInt32 error;
		// Leaks, but I don't care
		CFUserNotificationCreate(kCFAllocatorDefault, 0, kCFUserNotificationNoteAlertLevel, &error, (CFDictionaryRef)fields);
	}
}

%end

%ctor
{
	MSHookFunction(&UIApplicationInitialize, &$UIApplicationInitialize, (void **)&_UIApplicationInitialize);
	%init();
}
