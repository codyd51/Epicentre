#import "EPCExpandingChestView.h"
#import "EPCDraggableRotaryNumberView.h"

@interface EPCRingView : UIView {
	EPCExpandingChestView* _chestView;
	NSMutableArray* _buttons;
	NSMutableArray* _shuffledButtons;
	CGPoint _prevCoord;
	BOOL _isExpanded;
	NSString* _cachedMD5Pass;
	NSString* _cachedMD5PassUnhashedLength;
	NSMutableString* _enteredStack;
	BOOL _needsSetup;
}
@property (nonatomic, assign, readonly) BOOL isExpanded;
+(instancetype)sharedRingView;
-(NSArray*)mappedFinalButtonPositions;
-(NSArray*)mappedCollapsedButtonPositions;
-(void)expandAnimated:(BOOL)animated;
-(void)collapseAnimated:(BOOL)animated;
-(void)regenerateNumberView:(EPCDraggableRotaryNumberView*)numberView animated:(BOOL)animated;
-(void)regenerateViewWithNumber:(NSInteger)number animated:(BOOL)animated;
-(void)popStackValue;
-(void)pushStackValue:(NSString*)value;
-(BOOL)_evaluateStack;
-(BOOL)_performUnlockAction;
-(void)buttonTapped:(EPCDraggableRotaryNumberView*)button;
-(NSString*)randomDisplayedNumberForActualCharacter:(NSString*)character;
@end