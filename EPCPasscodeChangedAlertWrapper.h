@interface EPCPasscodeChangedAlertWrapper : NSObject 
@property (copy) void(^completionBlock)(UIAlertView *alertView, NSInteger buttonIndex);
@end