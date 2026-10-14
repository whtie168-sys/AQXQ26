#import "FavoritesViewController.h"
#import "ConverterViewController.h"
#import "UnitDefinition.h"
#import "LocalStorageManager.h"

@interface FavoritesViewController ()
@property (nonatomic, copy) NSArray<NSDictionary *> *items;
@end

@implementation FavoritesViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reload];
}

- (void)reload {
    self.items = [[LocalStorageManager shared] favorites];
    UILabel *empty = nil;
    if (self.items.count == 0) {
        empty = [UILabel new];
        empty.text = @"No favorites yet\nTap ☆ on a converter to add one";
        empty.numberOfLines = 0;
        empty.textAlignment = NSTextAlignmentCenter;
        empty.textColor = [UIColor secondaryLabelColor];
    }
    self.tableView.backgroundView = empty;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.items[indexPath.row];
    UnitDefinition *from = [UnitDefinition unitWithSymbol:item[UCKeyFrom] category:item[UCKeyCategory]];
    UnitDefinition *to = [UnitDefinition unitWithSymbol:item[UCKeyTo] category:item[UCKeyCategory]];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    UIListContentConfiguration *config = [UIListContentConfiguration subtitleCellConfiguration];
    config.text = [NSString stringWithFormat:@"%@ → %@", from.symbol, to.symbol];
    config.secondaryText = [NSString stringWithFormat:@"%@ · %@ to %@", [UnitDefinition titleForCategory:item[UCKeyCategory]],
                            from.name, to.name];
    config.secondaryTextProperties.color = [UIColor secondaryLabelColor];
    config.image = [UIImage systemImageNamed:[UnitDefinition iconForCategory:item[UCKeyCategory]]];
    cell.contentConfiguration = config;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *item = self.items[indexPath.row];
    ConverterViewController *vc = [[ConverterViewController alloc] initWithCategory:item[UCKeyCategory]
                                                                               from:item[UCKeyFrom] to:item[UCKeyTo] input:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *remove = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Remove"
        handler:^(UIContextualAction *action, UIView *view, void (^done)(BOOL)) {
            [[LocalStorageManager shared] removeFavoriteAtIndex:(NSUInteger)indexPath.row];
            [self reload];
            done(YES);
        }];
    return [UISwipeActionsConfiguration configurationWithActions:@[remove]];
}

@end
