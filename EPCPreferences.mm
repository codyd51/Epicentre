#import "EPCPreferences.h"
#import "EPCRingView.h"
#import "Common.h"

@interface EPCRingView (Private)
-(void)notifyPreferencesChanged;
@end

static NSString *const identifier = @"com.phillipt.epicentre";

@implementation EPCPreferences

+(instancetype)sharedInstance {
	static dispatch_once_t p = 0;
	__strong static id _sharedObject = nil;
	 
	dispatch_once(&p, ^{
		_sharedObject = [[self alloc] init];

	});

	return _sharedObject;
}

-(instancetype)init {
	if (self=[super init]) {
		//call before reloadprefs because this only runs once per respring
		//_rotaryNumberViewSize = [self intForKey:@"viewSize" default:30];
		[self reloadPrefsForStartup];
	}
	return self;
}

-(BOOL)boolForKey:(NSString *)key default:(BOOL)defaultVal {
	NSNumber *tempVal = (__bridge NSNumber *)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)identifier);
	return tempVal ? [tempVal boolValue] : defaultVal;
}

-(NSInteger)intForKey:(NSString *)key default:(NSInteger)defaultVal {
	NSNumber *tempVal = (__bridge NSNumber *)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)identifier);
	return tempVal ? [tempVal intValue] : defaultVal;
}

-(CGFloat)floatForKey:(NSString *)key default:(NSInteger)defaultVal {
	NSNumber *tempVal = (__bridge NSNumber *)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)identifier);
	return tempVal ? [tempVal floatValue] : defaultVal;
}

-(id)objectForKey:(NSString *)key default:(id)defaultVal {
	return (__bridge id)CFPreferencesCopyAppValue((CFStringRef)key, (CFStringRef)identifier) ?: defaultVal;
}

-(void)reloadPrefsForStartup {
	CFPreferencesAppSynchronize(CFSTR("com.phillipt.epicentre"));

	_isEnabled = [self boolForKey:@"enabled" default:YES];
	_shouldScrambleNumbers = [self boolForKey:@"shouldScrambleNumbers" default:NO];
	_shouldUseLocation = [self boolForKey:@"shouldUseLocation" default:NO];
	_rotaryNumberViewSize = [self intForKey:@"viewSize" default:30];

	CGFloat scale = [self floatForKey:@"cornerRadius" default:1.0];
	CGFloat minRad = 0.5;
	CGFloat maxRad = _rotaryNumberViewSize/2;
	CGFloat converedRad = (maxRad * scale > minRad) ? maxRad * scale : minRad;
	NSLog(@"scale: %f", scale);
	NSLog(@"maxRad: %f", maxRad);
	NSLog(@"converedRad: %f", converedRad);
	_cornerRadius = converedRad;
}

-(void)reloadPrefs {
	NSLog(@"[Epicentre] reloadPrefs()");

	[self reloadPrefsForStartup];

	NSLog(@"[Epicentre] _rotaryNumberViewSize: %i", _rotaryNumberViewSize);

	[[EPCRingView sharedRingView] notifyPreferencesChanged];
}

@end

static void reloadPrefs() {
	[[EPCPreferences sharedInstance] reloadPrefs];
}

static void __attribute__((constructor)) init() {
	CFNotificationCenterAddObserver (CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, CFSTR("com.phillipt.epicentre/ReloadPrefs"), NULL, 0 );
}
