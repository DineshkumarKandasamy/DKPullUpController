#import <UIKit/UIKit.h>
@import DKPullUpController;

@interface ObjCExampleViewController : UIViewController
@property (nonatomic, strong) DKPullUpController *sheet;
@property (nonatomic, strong) UISegmentedControl *positions;
@property (nonatomic, strong) UISegmentedControl *layouts;
@property (nonatomic, strong) UIBarButtonItem *visibilityButton;
@property (nonatomic) BOOL didPresentSheet;
@property (nonatomic) BOOL isTransitioning;
@end

@implementation ObjCExampleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Pull-up Sheet";
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;

    self.visibilityButton = [[UIBarButtonItem alloc] initWithTitle:@"Hide"
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(toggleSheet)];
    self.navigationItem.rightBarButtonItem = self.visibilityButton;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Sheet controls";
    titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];

    self.positions = [[UISegmentedControl alloc] initWithItems:@[@"Small", @"Medium", @"Large"]];
    self.positions.selectedSegmentIndex = 0;
    [self.positions addTarget:self action:@selector(changePosition)
              forControlEvents:UIControlEventValueChanged];

    self.layouts = [[UISegmentedControl alloc] initWithItems:@[@"Bottom", @"Auto", @"Side"]];
    self.layouts.selectedSegmentIndex = 0;
    [self.layouts addTarget:self action:@selector(changeLayout)
           forControlEvents:UIControlEventValueChanged];

    UIStackView *controls = [[UIStackView alloc] initWithArrangedSubviews:@[
        titleLabel, self.positions, self.layouts
    ]];
    controls.axis = UILayoutConstraintAxisVertical;
    controls.spacing = 16;
    controls.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:controls];
    [NSLayoutConstraint activateConstraints:@[
        [controls.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:24],
        [controls.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],
        [controls.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor]
    ]];

    self.sheet = [[DKPullUpController alloc] init];
    self.sheet.layoutMode = DKPullUpLayoutModeBottom;
    self.sheet.pullUpPreferredSize = CGSizeMake(self.view.bounds.size.width, 600);
    self.sheet.pullUpIntermediateSnapPoints = @[@320];
    self.sheet.pullUpDefaultDragHandleColor = UIColor.systemTealColor;
    self.sheet.pullUpDefaultDragHandleWidth = 48;
    self.sheet.pullUpDefaultDragHandleHeight = 6;
    self.sheet.pullUpDefaultDragHandleCornerRadius = 3;

    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    contentView.layer.cornerRadius = 16;
    contentView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    contentView.clipsToBounds = YES;
    self.sheet.pullUpContentView = contentView;

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
    [self.sheet attachScrollView:scrollView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.didPresentSheet) {
        self.didPresentSheet = YES;
        [self showSheet];
    }
}

- (void)showSheet {
    if (self.isTransitioning) { return; }
    self.isTransitioning = YES;
    __weak typeof(self) weakSelf = self;
    [self.sheet addToParent:self initialVisibleHeight:160 animated:YES completion:^(BOOL finished) {
        weakSelf.isTransitioning = NO;
        weakSelf.visibilityButton.title = @"Hide";
    }];
}

- (void)toggleSheet {
    if (self.isTransitioning) { return; }
    if (self.sheet.parentViewController == nil) {
        [self showSheet];
        return;
    }
    self.isTransitioning = YES;
    __weak typeof(self) weakSelf = self;
    [self.sheet removeAnimated:YES completion:^(BOOL finished) {
        weakSelf.isTransitioning = NO;
        weakSelf.visibilityButton.title = @"Show";
    }];
}

- (void)changePosition {
    NSArray<NSNumber *> *points = self.sheet.pullUpSnapPoints;
    if (points.count == 0) { return; }
    NSUInteger index = MIN((NSUInteger)MAX(0, self.positions.selectedSegmentIndex), points.count - 1);
    [self.sheet moveToVisibleHeight:points[index].doubleValue animated:YES completion:nil];
}

- (void)changeLayout {
    switch (self.layouts.selectedSegmentIndex) {
        case 1:
            self.sheet.layoutMode = DKPullUpLayoutModeAutomatic;
            break;
        case 2:
            self.sheet.layoutMode = DKPullUpLayoutModeSide;
            break;
        default:
            self.sheet.layoutMode = DKPullUpLayoutModeBottom;
            break;
    }
}

@end

@interface ObjCExampleSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation ObjCExampleSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) { return; }
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    ObjCExampleViewController *viewController = [[ObjCExampleViewController alloc] init];
    self.window.rootViewController = [[UINavigationController alloc]
        initWithRootViewController:viewController];
    [self.window makeKeyAndVisible];
}

@end

@interface ObjCExampleAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation ObjCExampleAppDelegate

- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                                   options:(UISceneConnectionOptions *)options {
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
        sessionRole:connectingSceneSession.role];
    configuration.delegateClass = ObjCExampleSceneDelegate.class;
    return configuration;
}

@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass(ObjCExampleAppDelegate.class));
    }
}
