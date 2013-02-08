#import <Foundation/Foundation.h>
#import <CaptainHook/CaptainHook.h>
#import <substrate.h>

static bool allowed;

size_t UIApplicationInitialize();

MSHook(size_t, UIApplicationInitialize)
{
	allowed = true;
	return _UIApplicationInitialize();
}

%hook UIDevice

+ (UIDevice *)currentDevice
{
	if (!allowed)
		@throw [NSException exceptionWithName:@"UIDeviceNotAllowed" reason:@"Check the call stack to see which extension is using [UIDevice currentDevice] improperly" userInfo:nil];
	return %orig();
}

%end

%group Exception

%hook NSException

+ (id)allocWithZone:(NSZone *)zone
{
	NSLog(@"NSException created from %@", [NSThread callStackSymbols]);
	return %orig();
}

%end

%end

%ctor
{
	MSHookFunction(&UIApplicationInitialize, &$UIApplicationInitialize, (void **)&_UIApplicationInitialize);
	%init();
	if ([NSThread respondsToSelector:@selector(callStackSymbols)]) {
		%init(Exception);
	}
}
