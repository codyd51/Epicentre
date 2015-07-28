#import "EpicentreListController.h"

@implementation EpicentreListController (EPCExtras)
-(void)openTwitter:(PSSpecifier *)specifier {
    NSString *screenName = [specifier.properties[@"handle"] substringFromIndex:1]; //remove the "@"
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tweetbot:///user_profile/%@", screenName]]];
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitterrific:///profile?screen_name=%@", screenName]]];
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"tweetings:///user?screen_name=%@", screenName]]];
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@", screenName]]];
    else
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://mobile.twitter.com/%@", screenName]]];
}
-(void)showTutorial:(PSSpecifier *)specifier {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"youtube:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"youtube://QKA5CT4pUEg"]];
    else 
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.youtube.com/watch?v=QKA5CT4pUEg"]];
}
@end