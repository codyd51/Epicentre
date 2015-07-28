#import "EPCRingView.h"
#import "EPCDraggableRotaryNumberView.h"
#import "EPCExpandingChestView.h"
#import "EPCPreferences.h"
#import "Common.h"

@interface EPCExpandingChestView (Private)
-(void)showLockGlyphAnimated:(BOOL)animated;
-(void)hideLockGlyphAnimated:(BOOL)animated;
-(void)dimAnimated:(BOOL)animated;
-(void)undimAnimated:(BOOL)animated;
-(void)_setInitialLockGlyphSize;
@end

//function for returning the coordinates of an arbitrary element within an arbitrary number of elements with an arbitrary radius around a circle with an arbitrary center
//TODO better name
//CGPoint pointForIndex(NSInteger index) withinTotalCount:(NSInteger)totalCount withRadius:(CGFloat)radius fromCenter:(CGPoint)center {
CGPoint calculatedPlacement(CGFloat index, CGFloat totalCount, CGFloat radius, CGPoint center) {
	return CGPointMake(center.x + radius * cos((2*M_PI * index/totalCount) - M_PI_2), center.y + radius * sin((2*M_PI * index/totalCount) - M_PI_2));
}

@implementation EPCRingView
+(id)sharedRingView {
	static dispatch_once_t p = 0;
	__strong static id _sharedObject = nil;
	 
	dispatch_once(&p, ^{
		_sharedObject = [[self alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	});

	return _sharedObject;
}
-(id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		_needsSetup = NO;
	}
	return self;
}
-(void)_setupUI {
	[self shuffleButtons];

	_chestView = nil;
	[_buttons removeAllObjects];
	for (UIView* subview in self.subviews) {
		[subview removeFromSuperview];
	}
	CGRect bounds = [[UIScreen mainScreen] bounds];
	self.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));

	_chestView = [[EPCExpandingChestView alloc] initWithDefaultSize];
	_chestView.center = self.center;
	[self addSubview:_chestView];

	//create buttons by iterating through each char
	_buttons = [[NSMutableArray alloc] init];
	for (int i = 0; i <= 9; i++) {
		EPCDraggableRotaryNumberView* numberView = [[EPCDraggableRotaryNumberView alloc] initWithDefaultSizeWithCharacter:[NSString stringWithFormat:@"%i", i]];
		[_buttons addObject:numberView];
	}

	//layout buttons in initial collapsed position
	NSArray* collapsedPosition = [self mappedCollapsedButtonPositions];
	for (int i = 0; i < _buttons.count; i++) {
		EPCDraggableRotaryNumberView* numberView = _buttons[i];
		[self addSubview:numberView];
		numberView.frame = CGRectFromString(collapsedPosition[i]);
		numberView.alpha = 0.0;
	}

	//instantiate stack
	_enteredStack = [[NSMutableString alloc] initWithString:@""];
}
-(void)_setCachedPassword:(NSString*)pass {
	_cachedMD5Pass = pass;
	_cachedMD5PassUnhashedLength = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:kPasscodeLengthPath] encoding:NSUTF8StringEncoding];
}
-(NSArray*)_mappedButtonPositionsForRadius:(CGFloat)radius {
	NSMutableArray* result = [[NSMutableArray alloc] init];
	for (EPCDraggableRotaryNumberView* numberView in _buttons) {
		CGFloat numRad = numberView.frame.size.width/2;
		CGPoint calculatedCenter = calculatedPlacement([_buttons indexOfObject:numberView], _buttons.count, radius, _chestView.center);
		CGRect frame = CGRectMake(calculatedCenter.x - numRad, calculatedCenter.y - numRad, numRad*2, numRad*2);
		[result addObject:NSStringFromCGRect(frame)];
	}

	return result;
}
-(NSArray*)mappedFinalButtonPositions {
	return [self _mappedButtonPositionsForRadius:kEPCDefaultRotaryRadius];
}
-(NSArray*)mappedCollapsedButtonPositions {
	return [self _mappedButtonPositionsForRadius:0];
}
-(void)popStackValue {
	//if there is more than zero characters in the string
	if (_enteredStack.length > 0) {
		NSString* poppedValue = [_enteredStack substringFromIndex:[_enteredStack length] - 1];
		[_enteredStack deleteCharactersInRange:NSMakeRange(_enteredStack.length - 1, 1)];
		[_chestView _shrinkForPoppedValueAnimated:YES];
		[self popValueOffChest:poppedValue animated:YES];
	}
	//zero characters in the string
	else {
		[self notifyActionDisallowedAnimated:YES];
	}
}
-(void)pushStackValue:(NSString*)value {
	[_enteredStack appendString:value];

	[_chestView _expandForPushedValueAnimated:YES];

	[self _evaluateStack];
}
-(void)popValueOffChest:(NSString*)poppedValue animated:(BOOL)animated {
	EPCDraggableRotaryNumberView* newNumberView = [[EPCDraggableRotaryNumberView alloc] initWithDefaultSizeWithCharacter:poppedValue];
	newNumberView.center = _chestView.center;
	[self addSubview:newNumberView];
	newNumberView.alpha = 0.0;
	//add this number view to the buttons array and remove the original
	EPCDraggableRotaryNumberView* numberView = [_buttons objectAtIndex:poppedValue.intValue];
	[_buttons removeObjectAtIndex:poppedValue.intValue];
	[_buttons insertObject:newNumberView atIndex:poppedValue.intValue];
	[self disintegrateNumberView:numberView animated:animated withCompletion:^{	
		[UIView animateWithDuration:(animated ? 0.075 : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
			newNumberView.alpha = 1.0;
		} completion:nil];
		[self snapNumberViewToDesignatedPosition:newNumberView animated:animated];
	}];
}
-(BOOL)_evaluateStack {
	//if it's not the same length just stop here
	if (!(_enteredStack.length == [self passcodeLength])) return NO;

	if ([[self MD5dStack] isEqualToString:_cachedMD5Pass]) {
		//correct passcode
		[self _performUnlockAction];
		return YES;
	}
	else {
		//incorrect passcode
		[self notifyActionDisallowedAnimated:YES];
	}
	return NO;
}
-(NSString*)MD5dStack {
	return [_enteredStack MD5String];
}
-(NSInteger)passcodeLength {
	return [_cachedMD5PassUnhashedLength intValue];
}
-(BOOL)_performUnlockAction {
	//turn green right before we unlock
	__block BOOL ret = NO;
	[_chestView performPasscodeAcceptedAnimationAnimated:YES withCompletion:^{
		NSLog(@"inside completion block");
		//[attemptToUnlockUIFromNotification];
		ret = [[objc_getClass("SBLockScreenManager") sharedInstance] attemptUnlockWithPasscode:_enteredStack];
	}];
	return ret;
}
-(void)notifyActionDisallowedAnimated:(BOOL)animated {
	[_chestView performActionDisallowedAnimationAnimated:animated];

	//reset size and clear stack
	[UIView animateWithDuration:(animated ? 0.4 : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		for (int i = 0; i < _enteredStack.length; i++) {
			[_chestView _shrinkForPoppedValueAnimated:animated];
		}
		//for (int i = _enteredStack.length - 1; i >= 0; i--) {
		//	[self popStackValue];
		//}
	} completion:^(BOOL finished){
		[self clearStack];
	}];
}
#define kEPCSignificantAnimationQueueDelay 0.05
-(void)expandAnimated:(BOOL)animated {
	//if its already expanded, quit
	if (_isExpanded) return;

	[self collapseAnimated:NO];
	/*
	No delay:
	0, 5

	0.1s delay:
	1, 4, 6, 9

	0.2s delay:
	2, 3, 7, 8
	*/

	//The following follows the same spring animation described in -regenerateNumber

	NSArray* springOut1 = [self _mappedButtonPositionsForRadius:kEPCDefaultRotaryRadius + 2];
	NSArray* springIn1 = [self _mappedButtonPositionsForRadius:kEPCDefaultRotaryRadius - 2];
	NSArray* springOut2 = [self _mappedButtonPositionsForRadius:kEPCDefaultRotaryRadius + 1];
	NSArray* final = [self mappedFinalButtonPositions];

	NSArray* group1 = @[_buttons[0], 
						_buttons[5]];
	NSArray* group2 = @[_buttons[1], 
						_buttons[4], 
						_buttons[6], 
						_buttons[9]];
	NSArray* group3 = @[_buttons[2], 
						_buttons[3],
						_buttons[7], 
						_buttons[8]];

	[UIView animateWithDuration:(animated ? 0.1 : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		for (EPCDraggableRotaryNumberView* numberView in _buttons) {
			numberView.alpha = 0.0;
		}
	}];
	[UIView animateWithDuration:(animated ? kEPCSpringAnimationPhaseOneDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		_chestView.transform = CGAffineTransformIdentity;
		[_chestView showLockGlyphAnimated:animated];
		[_chestView _setInitialLockGlyphSize];
		//[_chestView adjustLockViewRemainConstantSize];

		for (int i = 0; i < group1.count; i++) {
			EPCDraggableRotaryNumberView* numberView = group1[i];
			numberView.frame = CGRectFromString(springOut1[[_buttons indexOfObject:numberView]]);
			numberView.alpha = 1.0;
		}
	} completion:^(BOOL finished){
		[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
			for (int i = 0; i < group1.count; i++) {
				EPCDraggableRotaryNumberView* numberView = group1[i];
				numberView.frame = CGRectFromString(springIn1[[_buttons indexOfObject:numberView]]);
				numberView.alpha = 1.0;
			}
		} completion:^(BOOL finished){
			[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
				for (int i = 0; i < group1.count; i++) {
					EPCDraggableRotaryNumberView* numberView = group1[i];
					numberView.frame = CGRectFromString(springOut2[[_buttons indexOfObject:numberView]]);
					numberView.alpha = 1.0;
				}
			} completion:^(BOOL finished){
				[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
					for (int i = 0; i < group1.count; i++) {
						EPCDraggableRotaryNumberView* numberView = group1[i];
						numberView.frame = CGRectFromString(final[[_buttons indexOfObject:numberView]]);
						numberView.alpha = 1.0;
					}
				}];
			}];
		}];
	}];
	[UIView animateWithDuration:(animated ? kEPCSpringAnimationPhaseTwoDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		for (int i = 0; i < group2.count; i++) {
			EPCDraggableRotaryNumberView* numberView = group2[i];
			numberView.frame = CGRectFromString(springOut1[[_buttons indexOfObject:numberView]]);
			numberView.alpha = 1.0;
		}
	} completion:^(BOOL finished){
		[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
			for (int i = 0; i < group2.count; i++) {
				EPCDraggableRotaryNumberView* numberView = group2[i];
				numberView.frame = CGRectFromString(springIn1[[_buttons indexOfObject:numberView]]);
				numberView.alpha = 1.0;
			}
		} completion:^(BOOL finished){
			[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
				for (int i = 0; i < group2.count; i++) {
					EPCDraggableRotaryNumberView* numberView = group2[i];
					numberView.frame = CGRectFromString(springOut2[[_buttons indexOfObject:numberView]]);
					numberView.alpha = 1.0;
				}
			} completion:^(BOOL finished){
				[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
					for (int i = 0; i < group2.count; i++) {
						EPCDraggableRotaryNumberView* numberView = group2[i];
						numberView.frame = CGRectFromString(final[[_buttons indexOfObject:numberView]]);
						numberView.alpha = 1.0;
					}
				}];
			}];
		}];
	}];
	[UIView animateWithDuration:(animated ? kEPCSpringAnimationPhaseThreeDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		for (int i = 0; i < group3.count; i++) {
			EPCDraggableRotaryNumberView* numberView = group3[i];
			numberView.frame = CGRectFromString(springOut1[[_buttons indexOfObject:numberView]]);
			numberView.alpha = 1.0;
		}
	} completion:^(BOOL finished){
		[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
			for (int i = 0; i < group3.count; i++) {
				EPCDraggableRotaryNumberView* numberView = group3[i];
				numberView.frame = CGRectFromString(springIn1[[_buttons indexOfObject:numberView]]);
				numberView.alpha = 1.0;
			}
		} completion:^(BOOL finished){
			[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
				for (int i = 0; i < group3.count; i++) {
					EPCDraggableRotaryNumberView* numberView = group3[i];
					numberView.frame = CGRectFromString(springOut2[[_buttons indexOfObject:numberView]]);
					numberView.alpha = 1.0;
				}
			} completion:^(BOOL finished){
				[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
					for (int i = 0; i < group3.count; i++) {
						EPCDraggableRotaryNumberView* numberView = group3[i];
						numberView.frame = CGRectFromString(final[[_buttons indexOfObject:numberView]]);
						numberView.alpha = 1.0;
					}
				} completion:nil];
			}];
		}];
	}];

	_isExpanded = YES;
}
-(void)collapseAnimated:(BOOL)animated {
	//if its already collapsed, quit
	if (!_isExpanded) return;

	NSArray* collapsedPosition = [self mappedCollapsedButtonPositions];

	/*
	No delay:
	0, 5

	0.1s delay:
	1, 4, 6, 9

	0.2s delay:
	2, 3, 7, 8
	*/

	[UIView animateWithDuration:(animated ? kEPCSpringAnimationPhaseOneDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		((EPCDraggableRotaryNumberView*)_buttons[0]).frame = CGRectFromString(collapsedPosition[0]);
		((EPCDraggableRotaryNumberView*)_buttons[5]).frame = CGRectFromString(collapsedPosition[5]);
	}];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (animated ? kEPCSpringAnimationPhaseOneDuration - 0.225 : 0.0) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[UIView animateWithDuration:(animated ? 0.1 : 0.0) animations:^{
			((EPCDraggableRotaryNumberView*)_buttons[0]).alpha = 0.0;
			((EPCDraggableRotaryNumberView*)_buttons[5]).alpha = 0.0;
		}];
	});
	[UIView animateWithDuration:(animated ? kEPCSpringAnimationPhaseTwoDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		((EPCDraggableRotaryNumberView*)_buttons[1]).frame = CGRectFromString(collapsedPosition[1]);
		((EPCDraggableRotaryNumberView*)_buttons[4]).frame = CGRectFromString(collapsedPosition[4]);
		((EPCDraggableRotaryNumberView*)_buttons[6]).frame = CGRectFromString(collapsedPosition[6]);
		((EPCDraggableRotaryNumberView*)_buttons[9]).frame = CGRectFromString(collapsedPosition[8]);
	}];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (animated ? kEPCSpringAnimationPhaseTwoDuration - 0.225 : 0.0) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[UIView animateWithDuration:(animated ? 0.1 : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
			((EPCDraggableRotaryNumberView*)_buttons[1]).alpha = 0.0;
			((EPCDraggableRotaryNumberView*)_buttons[4]).alpha = 0.0;
			((EPCDraggableRotaryNumberView*)_buttons[6]).alpha = 0.0;
			((EPCDraggableRotaryNumberView*)_buttons[9]).alpha = 0.0;
		}];
	});
	[UIView animateWithDuration:(animated ? kEPCSpringAnimationPhaseThreeDuration : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		//shrink the chest view
		_chestView.transform = CGAffineTransformScale(_chestView.transform, 0.2, 0.2);
		[_chestView hideLockGlyphAnimated:animated];

		((EPCDraggableRotaryNumberView*)_buttons[2]).frame = CGRectFromString(collapsedPosition[2]);
		((EPCDraggableRotaryNumberView*)_buttons[3]).frame = CGRectFromString(collapsedPosition[3]);
		((EPCDraggableRotaryNumberView*)_buttons[7]).frame = CGRectFromString(collapsedPosition[7]);
		((EPCDraggableRotaryNumberView*)_buttons[8]).frame = CGRectFromString(collapsedPosition[9]);
	}];
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (animated ? kEPCSpringAnimationPhaseThreeDuration - 0.225 : 0.0) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
		[UIView animateWithDuration:(animated ? 0.1 : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
			((EPCDraggableRotaryNumberView*)_buttons[2]).alpha = 0.0;
			((EPCDraggableRotaryNumberView*)_buttons[3]).alpha = 0.0;
			((EPCDraggableRotaryNumberView*)_buttons[7]).alpha = 0.0;
			((EPCDraggableRotaryNumberView*)_buttons[8]).alpha = 0.0;
		} completion:nil];
	});

	//clear stack
	[self clearStack];

	//create a new shuffle
	[self updateShuffleOrder];

	_isExpanded = NO;
}
-(void)clearStack {
	[_enteredStack setString:@""];
}
-(void)viewDragged:(UIPanGestureRecognizer *)gesture {
	EPCDraggableRotaryNumberView* numberView = (EPCDraggableRotaryNumberView*)gesture.view;
	if (gesture.state == UIGestureRecognizerStateBegan) {
		_prevCoord = [gesture locationInView:numberView];
	}
	CGPoint newCoord = [gesture locationInView:numberView];
	CGFloat dX = newCoord.x - _prevCoord.x;
	CGFloat dY = newCoord.y - _prevCoord.y;

	numberView.frame = CGRectMake(numberView.frame.origin.x+dX, numberView.frame.origin.y+dY, numberView.frame.size.width, numberView.frame.size.height);

	//check if it was held over the chest view
	if (gesture.state == UIGestureRecognizerStateChanged) {
		//if the frames overlap
		if (CGRectIntersectsRect(numberView.frame, _chestView.frame)) {
			//dim chest view
			[_chestView dimAnimated:YES];
		}
		else {
			[_chestView undimAnimated:YES];
		}
	}

	//check if it was dropped on the chest view
	if (gesture.state == UIGestureRecognizerStateEnded) {
		//undim chest view
		[_chestView undimAnimated:YES];

		//if the frames overlap
		if (CGRectIntersectsRect(numberView.frame, _chestView.frame)) {
			//make his number view disappear
			[self regenerateNumberView:numberView animated:YES];

			//push stack value which expands chest view
			[self pushStackValue:([[EPCPreferences sharedInstance] shouldUseLocation] ? numberView.character : numberView.displayableCharacter)];
		}
		//if they don't overlap, snap the number view back to its designated position
		else {
			[self snapNumberViewToDesignatedPosition:numberView animated:YES];
		}
	}
}
-(void)snapNumberViewToDesignatedPosition:(EPCDraggableRotaryNumberView*)numberView animated:(BOOL)animated {
	[UIView animateWithDuration:(animated ? 0.8 : 0) delay:0.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
		numberView.frame = CGRectFromString([self mappedFinalButtonPositions][numberView.character.intValue]);
	} completion:nil];
}
-(void)snapNumberViewToChestCenterAndRegenerate:(EPCDraggableRotaryNumberView*)numberView animated:(BOOL)animated {
	[UIView animateWithDuration:(animated ? 0.175 : 0) delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		numberView.alpha = 0.0;
		numberView.center = _chestView.center;
		//numberView.transform = CGAffineTransformScale(numberView.transform, 0.75, 0.75);
	} completion:^(BOOL finished){
		[self pushStackValue:([[EPCPreferences sharedInstance] shouldUseLocation] ? numberView.character : numberView.displayableCharacter)];
		[self regenerateNumberView:numberView animated:animated];
	}];
}
-(void)buttonTapped:(EPCDraggableRotaryNumberView*)button {
	[self snapNumberViewToChestCenterAndRegenerate:button animated:YES];
}
-(void)regenerateNumberView:(EPCDraggableRotaryNumberView*)numberView animated:(BOOL)animated {
	//remove old one from the superview
	//[numberView removeFromSuperview];
	numberView.alpha = 0.0;

	//make a new one and place it at the proper position depending on whether the ring is collapsed or not
	EPCDraggableRotaryNumberView* newNumberView = [[EPCDraggableRotaryNumberView alloc] initWithDefaultSizeWithCharacter:numberView.character];
	CGRect newFrame = CGRectFromString([self mappedFinalButtonPositions][newNumberView.character.intValue]);

	//add this number view to the buttons array and remove the original
	//should be the same as numberView.character, but we're being safe
	NSInteger index = [_buttons indexOfObject:numberView];
	[_buttons removeObjectAtIndex:index];
	[_buttons insertObject:newNumberView atIndex:index];

	//save original transform
	CGAffineTransform t = CGAffineTransformIdentity;
	//set alpha to 0, set size to zero, and set frame in preperation for following animation
	newNumberView.frame = newFrame;
	newNumberView.alpha = 0.0;
	newNumberView.transform = CGAffineTransformScale(newNumberView.transform, 0.0, 0.0);
	[self addSubview:newNumberView];

	//Animation explanation:
	//grow from an invisible point
	//fade in finishes before growing finishes
	//grows a bit too big
	//shrinks back down, a bit too small
	//grows again, just a tad too big
	//shrinks back to correct size
	[UIView animateWithDuration:(animated ? 0.1 : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		newNumberView.alpha = 1.0;
	}];
	[UIView animateWithDuration:(animated ? 0.2 : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		newNumberView.transform = CGAffineTransformScale(t, 1.12f, 1.12f);
	} completion:^(BOOL finished){
		[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
			newNumberView.transform = CGAffineTransformScale(t, 0.85f, 0.85f);
		} completion:^(BOOL finished){
			[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
				newNumberView.transform = CGAffineTransformScale(t, 1.05f, 1.05f);
			} completion:^(BOOL finished){
				[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
					newNumberView.transform = CGAffineTransformIdentity;
					//ensure it didn't drift
					newNumberView.center = CGPointMake(CGRectGetMidX(newFrame), CGRectGetMidY(newFrame));
				} completion:nil];
			}];
		}];
	}];

	[numberView removeFromSuperview];
}
-(void)regenerateViewWithNumber:(NSInteger)number animated:(BOOL)animated {
	[self regenerateNumberView:_buttons[number] animated:animated];
}
-(void)disintegrateNumberView:(EPCDraggableRotaryNumberView*)numberView animated:(BOOL)animated withCompletion:(void(^)(void))completion {
	CGAffineTransform t = numberView.transform;
	[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		numberView.transform = CGAffineTransformScale(t, 1.15f, 1.15f);
	} completion:^(BOOL finished){
		[UIView animateWithDuration:(animated ? 0.3 : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
			numberView.alpha = 0.0;
		}];
		[UIView animateWithDuration:(animated ? kEPCSpringBounceAnimationDuration : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
			numberView.transform = CGAffineTransformScale(numberView.transform, 0.001f, 0.001f);
		} completion:^(BOOL finished){
			if (finished) {
				[numberView removeFromSuperview];
				completion();
			}
		}];
	}];
}
-(void)disintegrateViewWithNumber:(NSInteger)number animated:(BOOL)animated withCompletion:(void(^)(void))completion {
	[self disintegrateNumberView:_buttons[number] animated:animated withCompletion:completion];
}
-(void)standardSetup {
	[self reloadUIElements];
	[self _retreivePasswordCache];
}
-(void)_retreivePasswordCache {
	//set the hashed password to the ring view's cached pass
	NSString* hashedPass = [[NSString alloc] initWithData:[[NSFileManager defaultManager] contentsAtPath:kPasscodePath] encoding:NSUTF8StringEncoding];
	NSLog(@"hashedPass: %@", hashedPass);
	if (![[NSFileManager defaultManager] fileExistsAtPath:kPasscodePath]) [self _setNeedsSetup:YES];
	[self _setCachedPassword:hashedPass];
}
-(void)reloadUIElements {
	[self _setupUI];
	[self _updateUICornerRadii];
}
-(void)notifyPreferencesChanged {
	[self reloadUIElements];
}
-(BOOL)_needsSetup {
	return _needsSetup;
}
-(void)_setNeedsSetup:(BOOL)needed {
	_needsSetup = needed;
}
-(void)shuffleButtons {
	_shuffledButtons = [[NSMutableArray alloc] initWithCapacity:10];
	for (int i = 0; i <= 9; i++) {
		[_shuffledButtons addObject:@(i)];
	}
	[_shuffledButtons shuffle];
}
-(void)updateShuffleOrder {
	[self shuffleButtons];
	for (EPCDraggableRotaryNumberView* numberView in _buttons) {
		[numberView updateNumberLabel];
	}
}
-(void)_updateUICornerRadii {
	[_chestView.layer replaceSublayer:[_chestView.layer.sublayers objectAtIndex:0] with:[_chestView outlineLayer]];
	for (EPCDraggableRotaryNumberView* numberView in _buttons) {
		[numberView.layer replaceSublayer:[numberView.layer.sublayers objectAtIndex:0] with:[numberView outlineLayer]];
	}
}
-(NSString*)randomDisplayedNumberForActualCharacter:(NSString*)character {
	return [NSString stringWithFormat:@"%i", [[_shuffledButtons objectAtIndex:character.intValue] intValue]];
}

@end
