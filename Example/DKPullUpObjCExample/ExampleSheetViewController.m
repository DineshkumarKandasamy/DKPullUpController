#import "ExampleSheetViewController.h"

@interface ExampleSheetViewController ()
@property (nonatomic, strong, readwrite) DKPullUpController *sheet;
@end

@implementation ExampleSheetViewController

- (instancetype)initWithWidth:(CGFloat)width {
    self = [super init];
    if (!self) { return nil; }

    _sheet = [[DKPullUpController alloc] init];
    _sheet.layoutMode = DKPullUpLayoutModeBottom;
    _sheet.pullUpPreferredSize = CGSizeMake(width, 600);
    _sheet.pullUpIntermediateSnapPoints = @[@320];
    _sheet.pullUpDefaultDragHandleColor = UIColor.systemTealColor;
    _sheet.pullUpDefaultDragHandleWidth = 48;
    _sheet.pullUpDefaultDragHandleHeight = 6;
    _sheet.pullUpDefaultDragHandleCornerRadius = 3;

    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    contentView.layer.cornerRadius = 16;
    contentView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    contentView.clipsToBounds = YES;
    _sheet.pullUpContentView = contentView;

    UILabel *heading = [[UILabel alloc] init];
    heading.text = @"Library";
    heading.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    heading.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:heading];

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.alwaysBounceVertical = YES;
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:scrollView];

    UIStackView *items = [[UIStackView alloc] init];
    items.axis = UILayoutConstraintAxisVertical;
    items.spacing = 0;
    items.translatesAutoresizingMaskIntoConstraints = NO;
    for (NSString *item in @[@"Overview", @"Favorites", @"Recent", @"Collections",
                             @"Saved", @"Shared", @"Archive", @"Settings"]) {
        UILabel *row = [[UILabel alloc] init];
        row.text = item;
        [row.heightAnchor constraintEqualToConstant:52.0].active = YES;
        [items addArrangedSubview:row];
    }
    [scrollView addSubview:items];
    [NSLayoutConstraint activateConstraints:@[
        [heading.topAnchor constraintEqualToAnchor:contentView.topAnchor constant:34],
        [heading.leadingAnchor constraintEqualToAnchor:contentView.layoutMarginsGuide.leadingAnchor],
        [heading.trailingAnchor constraintEqualToAnchor:contentView.layoutMarginsGuide.trailingAnchor],
        [scrollView.topAnchor constraintEqualToAnchor:heading.bottomAnchor constant:12],
        [scrollView.leadingAnchor constraintEqualToAnchor:contentView.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:contentView.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:contentView.bottomAnchor],
        [items.topAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor],
        [items.leadingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor constant:20],
        [items.trailingAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor constant:-20],
        [items.bottomAnchor constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor],
        [items.widthAnchor constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor constant:-40]
    ]];
    [_sheet attachScrollView:scrollView];

    return self;
}

@end
