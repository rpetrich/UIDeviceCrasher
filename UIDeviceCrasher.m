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

CHDeclareClass(UIDevice);

CHOptimizedClassMethod(0, self, UIDevice *, UIDevice, currentDevice)
{
	if (!allowed)
		@throw [NSException exceptionWithName:@"UIDeviceNotAllowed" reason:@"Check the call stack to see which extension is using [UIDevice currentDevice] improperly" userInfo:nil];
	return CHSuper(0, UIDevice, currentDevice);
}

CHDeclareClass(NSException);

CHOptimizedClassMethod(1, super, id, NSException, allocWithZone, NSZone *, zone)
{
	NSLog(@"NSException created from %@", [NSThread callStackSymbols]);
	return CHSuper(1, NSException, allocWithZone, zone);
}

CHConstructor
{
	MSHookFunction(&UIApplicationInitialize, &$UIApplicationInitialize, (void **)&_UIApplicationInitialize);
	CHLoadLateClass(UIDevice);
	CHHook(0, UIDevice, currentDevice);
	if ([NSThread respondsToSelector:@selector(callStackSymbols)]) {
		CHLoadClass(NSException);
		CHHook(1, NSException, allocWithZone);
	}
}
