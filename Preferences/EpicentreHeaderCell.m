#import "EpicentreHeaderCell.h"

@implementation EpicentreHeaderCell

-(instancetype)initWithSpecifier:(PSSpecifier *)specifier {
	if (self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"]) {
		headerView = [[UIImageView alloc] initWithImage:specifier.properties[@"iconImage"]];
		[headerView setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];
		[headerView setContentMode:UIViewContentModeScaleAspectFit];
		[headerView setCenter:CGPointMake(headerView.center.x, headerView.center.y*0.1)];
		[self addSubview:headerView];
	}
	return self;
}

-(CGFloat)preferredHeightForWidth:(CGFloat)width {
	return 150;
}

@end