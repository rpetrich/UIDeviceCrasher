#import <Foundation/Foundation.h>
#import <CaptainHook/CaptainHook.h>

static bool allowed;

CHDeclareClass(UIApplication);

CHOptimizedClassMethod(1, super, id, UIApplication, allocWithZone, NSZone *, zone)
{
	allowed = true;
	return CHSuper(1, UIApplication, allocWithZone, zone);
}

CHDeclareClass(UIDevice);

CHOptimizedClassMethod(0, super, UIDevice *, UIDevice, currentDevice)
{
	if (!allowed)
		@throw [NSException exceptionWithName:@"UIDeviceNotAllowed" reason:@"Check the call stack to see which extension is using [UIDevice currentDevice] improperly" userInfo:nil];
	return CHSuper(0, UIDevice, currentDevice);
}

CHConstructor
{
	CHLoadLateClass(UIApplication);
	CHHook(1, UIApplication, allocWithZone);
	CHLoadLateClass(UIDevice);
	CHHook(0, UIDevice, currentDevice);
}
