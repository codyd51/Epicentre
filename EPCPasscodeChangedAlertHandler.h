@interface EPCPasscodeChangedAlertHandler : NSObject <UIAlertViewDelegate>
-(void)displayRespringAlert;
-(void)_respring;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;
@end