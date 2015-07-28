#import "EPCPasscodeChangedAlertHandler.h"
#import "Common.h"

@implementation EPCPasscodeChangedAlertHandler
-(void)displayRespringAlert {
	UIAlertView* respringAlert = [[UIAlertView alloc] initWithTitle:@"Epicentre" message:@"Passcode changed. Your device must now respring." delegate:self cancelButtonTitle:@"Respring" otherButtonTitles:nil];
	dispatch_async(dispatch_get_main_queue(), ^{
		[respringAlert showWithCompletion:^(UIAlertView *alertView, NSInteger buttonIndex) {
			[self _respring];
		}];
	});
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSLog(@"clickedButtonAtIndex");
	[self _respring];
}
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	NSLog(@"didDismissWithButtonIndex");
	[self _respring];
}
-(void)_respring {
	system("killall backboardd");
}
@end