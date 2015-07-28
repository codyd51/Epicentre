@interface EPCPreferences : NSObject
@property(nonatomic, readonly) BOOL isEnabled;
@property(nonatomic, readonly) BOOL shouldScrambleNumbers;
@property(nonatomic, readonly) BOOL shouldUseLocation;
@property(nonatomic, readonly) NSInteger rotaryNumberViewSize;
@property(nonatomic, readonly) CGFloat cornerRadius;
+(instancetype)sharedInstance;
-(BOOL)boolForKey:(NSString *)key default:(BOOL)defaultVal;
-(NSInteger)intForKey:(NSString *)key default:(NSInteger)defaultVal;
-(void)reloadPrefs;
@end