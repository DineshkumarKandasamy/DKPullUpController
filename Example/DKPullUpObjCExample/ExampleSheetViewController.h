#import <UIKit/UIKit.h>
@import DKPullUpController;

@interface ExampleSheetViewController : NSObject

@property (nonatomic, strong, readonly) DKPullUpController *sheet;

- (instancetype)initWithWidth:(CGFloat)width;

@end
