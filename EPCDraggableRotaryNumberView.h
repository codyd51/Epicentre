@interface EPCDraggableRotaryNumberView : UIView {
	UIPanGestureRecognizer* _panRec;
	UILabel* _label;
}
@property (nonatomic, retain, readonly) NSString* character;
@property (nonatomic, retain, readonly) NSString* displayableCharacter;
-(id)initWithDefaultSizeWithCharacter:(NSString*)character;
-(void)updateNumberLabel;
-(CALayer*)outlineLayer;
@end