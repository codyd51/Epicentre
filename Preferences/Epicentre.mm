#import <Preferences/Preferences.h>

@interface EpicentreListController: PSListController {
}
@end

@implementation EpicentreListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Epicentre" target:self];
	}
	return _specifiers;
}
@end

// vim:ft=objc
