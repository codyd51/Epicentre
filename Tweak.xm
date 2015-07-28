#import "Common.h"
#import "EPCRingView.h"
#import "EPCPreferences.h"
#import "EPCPasscodeChangedAlertHandler.h"

@interface EPCRingView (Private)
-(void)_setCachedPassword:(NSString*)password;
-(void)standardSetup;
-(BOOL)_needsSetup;
-(void)_setNeedsSetup:(BOOL)needed;
@end

%group Main

//remove the passcode dots
//we hook this higher class instead of TPRevealingRingView because EPCDraggableRotaryNumberView needs this method
%hook SBSimplePasscodeEntryFieldButton
-(id)_bezierPathForRect:(CGRect)arg1 cornerRadius:(CGFloat)arg2 {
	if ([[EPCRingView sharedRingView] _needsSetup]) {
		return %orig;
	}
	return nil;
}
%end

//add our ring view where the passcode view would be
%hook SBLockScreenScrollView
-(void)setPasscodeView:(UIView*)arg1 {
	%orig;

	if ([[EPCRingView sharedRingView] _needsSetup]) return;

	((EPCRingView*)[EPCRingView sharedRingView]).center = arg1.center;
	[arg1 addSubview:[EPCRingView sharedRingView]];

	//arg1.center = CGPointMake(arg1.center.x + arg1.frame.size.width, arg1.center.y);
}
%end

%hook SBLockScreenView
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	%orig;

	BOOL isSwipingTowardsPasscodePage = NO;
	if ([self associatedScrollViewOffset] > scrollView.contentOffset.x) {
		isSwipingTowardsPasscodePage = YES;
		[self setAssociatedScrollViewOffset:scrollView.contentOffset.x];
	}
	else if ([self associatedScrollViewOffset] < scrollView.contentOffset.x) {
		isSwipingTowardsPasscodePage = NO;
		[self setAssociatedScrollViewOffset:scrollView.contentOffset.x];
	}
	else return;

	CGFloat scrollThreshold = (CGRectGetMidX([[UIScreen mainScreen] bounds])) * 0.75; // ~ 140px;
	if (isSwipingTowardsPasscodePage && scrollView.contentOffset.x < scrollThreshold) {
		[[EPCRingView sharedRingView] expandAnimated:YES];
	}
	else if (!isSwipingTowardsPasscodePage && scrollView.contentOffset.x > scrollThreshold) {
		[[EPCRingView sharedRingView] collapseAnimated:YES];
	}
}
%new
-(void)setAssociatedScrollViewOffset:(CGFloat)offset {
	 objc_setAssociatedObject(self, @selector(associatedScrollViewOffset), [NSNumber numberWithFloat:offset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%new
-(CGFloat)associatedScrollViewOffset {
	return [(NSNumber*)objc_getAssociatedObject(self, @selector(associatedScrollViewOffset)) floatValue];
}
%new
-(id)copiedViewForPreferencesPreview {
	return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}
%end

//provide our own implementation for the number pad
%hook SBUIPasscodeLockNumberPad
-(id)initWithDefaultSizeAndLightStyle:(BOOL)arg1 {
	if ([[EPCRingView sharedRingView] _needsSetup]) return %orig;
	return nil;
}
//TODO move this into iOS 7 group
-(id)initWithDefaultSize {
	if ([[EPCRingView sharedRingView] _needsSetup]) return %orig;
	return nil;
}
%end

//expand/collapse when swiping to/from passcode page
%hook SBLockScreenViewController
-(void)lockScreenView:(id)view didScrollToPage:(NSInteger)page {
	%orig;

	//if the passcode file does not exist, use the setup IMP
	//else, use the Main IMP
	if ([[EPCRingView sharedRingView] _needsSetup]) {
		SBLockScreenView* lockScreenView = [self lockScreenView];
		NSLog(@"lockScreenView: %@", lockScreenView);
		if (!lockScreenView.passcodeView) {
			[lockScreenView setPasscodeView:[[%c(SBUIPasscodeLockViewWithKeypad) alloc] initWithLightStyle:YES]];
		}
		SBUIPasscodeLockViewWithKeypad* passcodeView = lockScreenView.passcodeView;
		NSLog(@"passcodeView: %@", passcodeView);
		//inform them they need to enter their passcode to use Epicentre
		if (page == 0) {
			if ([passcodeView respondsToSelector:@selector(updateStatusText:subtitle:animated:)]) {
				[passcodeView updateStatusText:MSHookIvar<UILabel*>(passcodeView, "_statusTitleView").text subtitle:@"Enter your passcode to begin using Epicentre." animated:YES];
			}
			else {
				[passcodeView _updateStatusText:MSHookIvar<UILabel*>(passcodeView, "_statusTitleView").text subtitle:@"Enter your passcode to begin using Epicentre." animated:YES];
			}
		}
		else {
			//update with blank text so the spacing is correct
			if ([passcodeView respondsToSelector:@selector(updateStatusText:subtitle:animated:)]) {
				[passcodeView updateStatusText:MSHookIvar<UILabel*>(passcodeView, "_statusTitleView").text subtitle:@" " animated:YES];
			}
			else {
				[passcodeView _updateStatusText:MSHookIvar<UILabel*>(passcodeView, "_statusTitleView").text subtitle:@" " animated:YES];
			}
		}
	}
	else {
		if (page == 0) {
			//scrolled to passcode page
			[[EPCRingView sharedRingView] expandAnimated:YES];
		}
		else {
			//swiped away from passcode page
			[[EPCRingView sharedRingView] collapseAnimated:NO];
		}
	}
}	
%end
%hook SBLockScreenManager
//grab original passcode, hash it, store it to disk
-(BOOL)attemptUnlockWithPasscode:(NSString*)passcode {
	//if the one they entered was correct
	BOOL o = %orig;
	//if the passcode file does not exist, use the setup IMP
	//else, use the Main IMP
	if (o && [[EPCRingView sharedRingView] _needsSetup]) {
		//set passcode length
		[[NSFileManager defaultManager] createFileAtPath:kPasscodeLengthPath contents:[[NSString stringWithFormat:@"%i", (int)passcode.length] dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];

		NSString* hashedStr = [passcode MD5String];
		[[NSFileManager defaultManager] createFileAtPath:kPasscodePath contents:[hashedStr dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
		[[EPCRingView sharedRingView] _setCachedPassword:hashedStr];
		[[EPCRingView sharedRingView] _setNeedsSetup:NO];
	}
	return o;
}
%end

%end

%ctor {
	//if the tweak is disabled, quit
	if (![[EPCPreferences sharedInstance] isEnabled]) return;

	//even if the user does not have a passcode set we still want to listen for this notification
	//so the check for no passcode is placed after we register for it
	//To listen for when the passcode is changed we can either
	//register for the notification with name com.apple.managedconfiguration.passcodechanged
	//or hook -[MCProfileManager changePasscodeFrom:to:outError:] (which provides both the old and new pass in plaintext)
	//we do the former because it is less hooks and does not require an IPC implementation
	//(as the latter method is fired in Preferences)
	[[NSNotificationCenter defaultCenter] addObserverForName:@"com.apple.managedconfiguration.passcodechanged" 
										  object:nil 
										  queue:nil 
										  usingBlock:^(NSNotification* notification){
											  [[NSFileManager defaultManager] removeItemAtPath:kPasscodePath error:nil];
											  [[EPCRingView sharedRingView] _setNeedsSetup:YES];
											  [[EPCRingView sharedRingView] _setCachedPassword:nil];

											  //someone please find a better way to handle this besides killing SB
											  EPCPasscodeChangedAlertHandler* alertHandler = [[EPCPasscodeChangedAlertHandler alloc] init];
											  [alertHandler displayRespringAlert];
										  }];

	if (![[%c(SBDeviceLockController) sharedController] deviceHasPasscodeSet]) return;

	%init(Main);

	[[EPCRingView sharedRingView] standardSetup];
}
