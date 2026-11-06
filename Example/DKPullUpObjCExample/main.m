#import <UIKit/UIKit.h>
#import "ExampleSheetViewController.h"

@interface ObjCExampleViewController : UIViewController
@property (nonatomic, strong) ExampleSheetViewController *sheetController;
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

    self.sheetController = [[ExampleSheetViewController alloc] initWithWidth:self.view.bounds.size.width];
    self.sheetController.sheet.isBackgroundCardEffectEnabled = YES;
    self.sheetController.sheet.backgroundCardScale = 0.9;
    self.sheetController.sheet.backgroundCardVerticalOffset = 24;
    self.sheetController.sheet.backgroundCardCornerRadius = 24;
    self.sheetController.sheet.backgroundCardContentMode = DKPullUpBackgroundCardContentModeLive;
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
    [self.sheetController.sheet addToParent:self initialVisibleHeight:160 animated:YES completion:^(BOOL finished) {
        weakSelf.isTransitioning = NO;
        weakSelf.visibilityButton.title = @"Hide";
    }];
}

- (void)toggleSheet {
    if (self.isTransitioning) { return; }
    if (self.sheetController.sheet.parentViewController == nil) {
        [self showSheet];
        return;
    }
    self.isTransitioning = YES;
    __weak typeof(self) weakSelf = self;
    [self.sheetController.sheet removeAnimated:YES completion:^(BOOL finished) {
        weakSelf.isTransitioning = NO;
        weakSelf.visibilityButton.title = @"Show";
    }];
}

- (void)changePosition {
    NSArray<NSNumber *> *points = self.sheetController.sheet.pullUpSnapPoints;
    if (points.count == 0) { return; }
    NSUInteger index = MIN((NSUInteger)MAX(0, self.positions.selectedSegmentIndex), points.count - 1);
    [self.sheetController.sheet moveToVisibleHeight:points[index].doubleValue animated:YES completion:nil];
}

- (void)changeLayout {
    switch (self.layouts.selectedSegmentIndex) {
        case 1:
            self.sheetController.sheet.layoutMode = DKPullUpLayoutModeAutomatic;
            break;
        case 2:
            self.sheetController.sheet.layoutMode = DKPullUpLayoutModeSide;
            break;
        default:
            self.sheetController.sheet.layoutMode = DKPullUpLayoutModeBottom;
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
