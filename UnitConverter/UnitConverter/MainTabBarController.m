#import "MainTabBarController.h"
#import "HomeViewController.h"
#import "FavoritesViewController.h"
#import "HistoryViewController.h"
#import "SettingsViewController.h"

@implementation MainTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSArray *items = @[@[[HomeViewController new], @"Convert", @"arrow.left.arrow.right"],
                       @[[FavoritesViewController new], @"Favorites", @"star"],
                       @[[HistoryViewController new], @"History", @"clock.arrow.circlepath"],
                       @[[SettingsViewController new], @"Settings", @"gearshape"]];
    NSMutableArray *navs = [NSMutableArray array];
    for (NSArray *item in items) {
        UIViewController *vc = item[0];
        vc.title = item[1];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.navigationBar.prefersLargeTitles = YES;
        nav.tabBarItem = [[UITabBarItem alloc] initWithTitle:item[1] image:[UIImage systemImageNamed:item[2]] tag:0];
        [navs addObject:nav];
    }
    self.viewControllers = navs;
}

@end
