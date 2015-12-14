#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import "EPCPasscodeChangedAlertWrapper.h"

#define kTweakName @"Epicentre"
#ifdef DEBUG
	#define NSLog(FORMAT, ...) NSLog(@"[%@: %s - %i] %@", kTweakName, __FILE__, __LINE__, [NSString stringWithFormat:FORMAT, ##__VA_ARGS__])
#else
	#define NSLog(FORMAT, ...) do {} while(0)
#endif

#define kEPCDraggableRotartyNumberViewDefaultSize /*30*/ [[EPCPreferences sharedInstance] rotaryNumberViewSize]
#define kEPCExpandingChestViewDefaultSize kEPCDraggableRotartyNumberViewDefaultSize
#define kEPCExpandingChestViewCollapsedSize 5
#define kEPCDefaultRotaryRadius kEPCDraggableRotartyNumberViewDefaultSize*3.333333333333
#define kEPCCollapsedRotaryRadius kEPCDraggableRotartyNumberViewDefaultSize*2
#define kEPCSpringAnimationPhaseOneDuration 0.3
#define kEPCSpringAnimationPhaseTwoDuration 0.35
#define kEPCSpringAnimationPhaseThreeDuration 0.4
#define kEPCSpringBounceAnimationDuration 0.15
#define kPasscodePath 					@"/var/mobile/Library/Preferences/Epicentre/pass.txt"
#define kPasscodeLengthPath 			@"/var/mobile/Library/Preferences/Epicentre/length.txt"
#define kEPCExpandingChestViewLockGlyph @"/Library/Application Support/Epicentre/lock"

//md5 additions
@interface NSString (EPCExtensions)
-(NSString*)MD5String;
@end
@implementation NSString (EPCExtensions)
-(NSString*)MD5String {
	const char *cStr = [self UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(cStr, strlen(cStr), result);
	return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
		result[0], result[1],
		result[2], result[3],
		result[4], result[5],
		result[6], result[7],
		result[8], result[9],
		result[10], result[11],
		result[12], result[13],
		result[14], result[15]
	];
}
@end

static char kNSCBAlertWrapper;
@implementation UIAlertView (EPCExtensions)
- (void)showWithCompletion:(void(^)(UIAlertView *alertView, NSInteger buttonIndex))completion {
	EPCPasscodeChangedAlertWrapper *alertWrapper = [[EPCPasscodeChangedAlertWrapper alloc] init];
	alertWrapper.completionBlock = completion;
	self.delegate = alertWrapper;

	// Set the wrapper as an associated object
	objc_setAssociatedObject(self, &kNSCBAlertWrapper, alertWrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

	// Show the alert as normal
	[self show];
}
@end

@implementation NSMutableArray (EPCShuffling)
- (void)shuffle {
    NSUInteger count = [self count];
    for (NSUInteger i = 0; i < count - 1; ++i) {
        NSInteger remainingCount = count - i;
        NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t )remainingCount);
        [self exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
    }
}
@end

//convenience extension
@interface UIView (EPCExtensions)
+ (void)animateWithDuration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(void (^)(void))animations;
+ (void)animateWithDuration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
@end
@implementation UIView (EPCExtensions)
+ (void)animateWithDuration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(void (^)(void))animations {
	[self.class animateWithDuration:duration delay:0.0 options:options animations:animations completion:nil];
}
+ (void)animateWithDuration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
	[self.class animateWithDuration:duration delay:0.0 options:options animations:animations completion:completion];
}
@end

@interface SBUIPasscodeLockNumberPad : UIView
-(id)initWithDefaultSizeAndLightStyle:(BOOL)arg1;
//iOS 7
-(id)initWithDefaultSize;
@end
@interface SBPasscodeNumberPadButton : UIView
@end
@interface TPNumberPadButton : UIControl
@end
@interface TPRevealingRingView : UIView
-(id)initWithFrame:(CGRect)arg1 paddingOutsideRing:(unsigned int)arg2;
-(id)_bezierPathForRect:(CGRect)arg1 cornerRadius:(CGFloat)arg2;
@end
@interface SBUIFourDigitPasscodeEntryField : UIView
@end
@interface SBLockScreenScrollView : UIScrollView
@property (nonatomic, retain) UIView* passcodeView;
@end
@interface SBUIPasscodeLockViewWithKeypad : UIView
-(id)initWithLightStyle:(BOOL)style;
-(void)updateStatusText:(id)arg1 subtitle:(id)arg2 animated:(BOOL)arg3;
//iOS 7
-(void)_updateStatusText:(id)arg1 subtitle:(id)arg2 animated:(BOOL)arg3;
@end
@interface SBLockScreenView : UIView
@property (nonatomic,retain) UIView* statusTextView;
@property (nonatomic,retain) SBUIPasscodeLockViewWithKeypad* passcodeView; 
@end
@interface SBLockScreenViewController : UIViewController
-(SBLockScreenView*)lockScreenView;
@end
@interface SBLockScreenManager : NSObject
+(id)sharedInstance;
-(BOOL)attemptUnlockWithPasscode:(NSString*)passcode;
@end
@interface SBDeviceLockController : NSObject
+(id)sharedController;
-(BOOL)deviceHasPasscodeSet;
@end

@interface SBLockScreenView (EPCExtensions)
@property (nonatomic, assign) CGFloat associatedScrollViewOffset;
-(id)copiedViewForPreferencesPreview;
@end