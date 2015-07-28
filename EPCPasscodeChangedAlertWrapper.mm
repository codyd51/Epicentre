#import "EPCPasscodeChangedAlertWrapper.h"
#import "Common.h"

@implementation EPCPasscodeChangedAlertWrapper
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (self.completionBlock)
		self.completionBlock(alertView, buttonIndex);
}
- (void)alertViewCancel:(UIAlertView *)alertView {
	if (self.completionBlock)
		self.completionBlock(alertView, alertView.cancelButtonIndex);
}
@end