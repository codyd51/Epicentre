#import "EPCDraggableRotaryNumberView.h"
#import "EPCRingView.h"
#import "EPCPreferences.h"
#import "Common.h"

@implementation EPCDraggableRotaryNumberView
-(id)initWithDefaultSizeWithCharacter:(NSString*)character {
	if (self = [super initWithFrame:CGRectMake(0, 0, kEPCDraggableRotartyNumberViewDefaultSize, kEPCDraggableRotartyNumberViewDefaultSize)]) {
		_character = character;
		if (![[EPCPreferences sharedInstance] shouldScrambleNumbers]) _displayableCharacter = _character;
		else {
			//random number
			_displayableCharacter = [[EPCRingView sharedRingView] randomDisplayedNumberForActualCharacter:_character];
		}

		//add ring outline
		[self.layer addSublayer:[self outlineLayer]];

		//add character
		_label = [[UILabel alloc] initWithFrame:self.frame];
		_label.textAlignment = NSTextAlignmentCenter;
		_label.textColor = [UIColor whiteColor];
		_label.text = _displayableCharacter;
		_label.adjustsFontSizeToFitWidth = YES;
		_label.center = self.center;
		[self addSubview:_label];

		//set up dragging recognizer
		_panRec = [[UIPanGestureRecognizer alloc] initWithTarget:[EPCRingView sharedRingView] action:@selector(viewDragged:)];
		[self addGestureRecognizer:_panRec];

		//tap to enter number
		UITapGestureRecognizer* tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
		[self addGestureRecognizer:tapRec];
	}
	return self;
}
-(CALayer*)outlineLayer {
	UIBezierPath* borderPath = [UIBezierPath bezierPathWithRoundedRect:self.frame cornerRadius:[[EPCPreferences sharedInstance] cornerRadius]]; 
	CAShapeLayer* ringShapeLayer = [CAShapeLayer layer];
	ringShapeLayer.path = borderPath.CGPath;
	ringShapeLayer.bounds = CGPathGetBoundingBox(ringShapeLayer.path);
	ringShapeLayer.strokeColor = [[UIColor whiteColor]  colorWithAlphaComponent:0.2].CGColor;
	ringShapeLayer.fillColor = [UIColor clearColor].CGColor;
	ringShapeLayer.lineWidth = 2;
	ringShapeLayer.position = CGPointMake(self.frame.size.width/2.0, self.frame.size.height/2.0);
	ringShapeLayer.anchorPoint = CGPointMake(.5, .5);
	return ringShapeLayer;
}
-(void)tapped {
	//TODO add animation here
	[[EPCRingView sharedRingView] buttonTapped:self];
}
-(void)updateNumberLabel {
	if (![[EPCPreferences sharedInstance] shouldScrambleNumbers]) _displayableCharacter = _character;
	else {
		//random number
		_displayableCharacter = [[EPCRingView sharedRingView] randomDisplayedNumberForActualCharacter:_character];
	}
	_label.text = _displayableCharacter;
}
@end