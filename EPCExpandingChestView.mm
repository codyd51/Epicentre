#import "EPCExpandingChestView.h"
#import "EPCRingView.h"
#import "EPCPreferences.h"
#import "Common.h"

@implementation EPCExpandingChestView 
-(id)initWithDefaultSize {
	if (self = [super initWithFrame:CGRectMake(0, 0, kEPCExpandingChestViewDefaultSize, kEPCExpandingChestViewDefaultSize)]) {
		//add ring outline
		[self.layer addSublayer:[self outlineLayer]];

		//add lock glyph
		_lockGlyphView = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:kEPCExpandingChestViewLockGlyph]];
		_lockGlyphView.image = [_lockGlyphView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
		_lockGlyphView.frame = CGRectMake(0, 0, self.frame.size.width*0.6, self.frame.size.height*0.6);
		_lockGlyphView.center = self.center;
		_lockGlyphView.tintColor = [UIColor whiteColor];
		_lockGlyphView.layer.edgeAntialiasingMask = kCALayerLeftEdge | kCALayerRightEdge | kCALayerBottomEdge | kCALayerTopEdge;
		//the lock view's size remains constant even when the chest view transforms
		_lockGlyphView.autoresizingMask = UIViewAutoresizingNone;
		[self addSubview:_lockGlyphView];

		UITapGestureRecognizer* tapRec = [[UITapGestureRecognizer alloc] initWithTarget:[EPCRingView sharedRingView] action:@selector(popStackValue)];
		[self addGestureRecognizer:tapRec];
	}
	return self;
}
-(CALayer*)outlineLayer {
	UIBezierPath* borderPath = [UIBezierPath bezierPathWithRoundedRect:self.frame cornerRadius:[[EPCPreferences sharedInstance] cornerRadius]];
	_ringShapeLayer = [CAShapeLayer layer];
	_ringShapeLayer.path = borderPath.CGPath;
	_ringShapeLayer.bounds = CGPathGetBoundingBox(_ringShapeLayer.path);
	_ringShapeLayer.fillColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor;
	_ringShapeLayer.position = CGPointMake(self.frame.size.width/2.0, self.frame.size.height/2.0);
	_ringShapeLayer.anchorPoint = CGPointMake(.5, .5);
	return _ringShapeLayer;
}
-(void)_expandForPushedValueAnimated:(BOOL)animated {
	[UIView animateWithDuration:(animated ? 0.25 : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		self.transform = CGAffineTransformScale(self.transform, 1.2f, 1.2f);
		[self adjustLockViewRemainConstantSize];
	}];
}
-(void)_shrinkForPoppedValueAnimated:(BOOL)animated {
	[UIView animateWithDuration:(animated ? 0.25 : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		//yes, this precision is necessary
		self.transform = CGAffineTransformScale(self.transform, 0.8333333333f, 0.8333333333f);
		[self adjustLockViewRemainConstantSize];
	}];
}
-(void)adjustLockViewRemainConstantSize {
	//the lock view remains the same size, so we shrink it by the reciprocal factor of the superview
	_lockGlyphView.transform = CGAffineTransformInvert(self.transform);
}
-(void)hideLockGlyphAnimated:(BOOL)animated {
	[UIView animateWithDuration:(animated ? 0.1 : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		_lockGlyphView.alpha = 0.0;
	}];
}
-(void)showLockGlyphAnimated:(BOOL)animated {
	[UIView animateWithDuration:(animated ? 0.1 : 0.0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		_lockGlyphView.alpha = 1.0;
	}];
}
-(void)performActionDisallowedAnimationAnimated:(BOOL)animated {
	CABasicAnimation *shakeAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
	[shakeAnimation setDuration:(animated ? 0.1 : 0.0)];
	[shakeAnimation setRepeatCount:2];
	[shakeAnimation setAutoreverses:YES];
	[shakeAnimation setFromValue:[NSValue valueWithCGPoint:CGPointMake(self.center.x - self.frame.size.width/6, self.center.y)]];
	[shakeAnimation setToValue:[NSValue valueWithCGPoint:CGPointMake(self.center.x + self.frame.size.width/6, self.center.y)]];
	[self.layer addAnimation:shakeAnimation forKey:@"position"];

	CABasicAnimation *fillColorAnimation = [CABasicAnimation animationWithKeyPath:@"fillColor"];
	fillColorAnimation.duration = (animated ? 0.3 : 0);
	fillColorAnimation.fromValue = (id)_ringShapeLayer.fillColor;
	fillColorAnimation.toValue = (id)[[UIColor colorWithRed:255/255.0f green:30/255.0f blue:25/255.0f alpha:1.0f]  colorWithAlphaComponent:0.6].CGColor;
	fillColorAnimation.repeatCount = 1;
	fillColorAnimation.autoreverses = YES;
	[_ringShapeLayer addAnimation:fillColorAnimation forKey:@"fillColor"];
}
-(void)performPasscodeAcceptedAnimationAnimated:(BOOL)animated withCompletion:(void(^)(void))completion {
	[UIView animateWithDuration:(animated ? 0.3 : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		_ringShapeLayer.fillColor = [[UIColor colorWithRed:100/255.0f green:225/255.0f blue:20/255.0f alpha:1.0f] colorWithAlphaComponent:0.6].CGColor;
	} completion:^(BOOL finished){
		completion();
		//set back to old color
		[self undimAnimated:animated];
	}];
}
#define kEPCDimShrinkFactor 0.9
#define kEPCDimRestoringFactor 1/kEPCDimShrinkFactor
-(void)dimAnimated:(BOOL)animated {
	[UIView animateWithDuration:(animated ? 0.3 : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		_ringShapeLayer.fillColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3].CGColor;
	}];
}
-(void)undimAnimated:(BOOL)animated {
	[UIView animateWithDuration:(animated ? 0.3 : 0) options:UIViewAnimationOptionAllowUserInteraction animations:^{
		_ringShapeLayer.fillColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3].CGColor;
	}];
}
-(void)_setInitialLockGlyphSize {
	_lockGlyphView.transform= CGAffineTransformIdentity;
}
@end