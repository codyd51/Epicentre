@interface EPCExpandingChestView : UIView {
	CAShapeLayer *_ringShapeLayer;
	UIImageView* _lockGlyphView;
}
-(id)initWithDefaultSize;
-(void)_expandForPushedValueAnimated:(BOOL)animated;
-(void)_shrinkForPoppedValueAnimated:(BOOL)animated;
-(void)performActionDisallowedAnimationAnimated:(BOOL)animated;
-(void)performPasscodeAcceptedAnimationAnimated:(BOOL)animated withCompletion:(void(^)(void))completion;
-(CALayer*)outlineLayer;
@end