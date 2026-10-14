#import "HistoryViewController.h"
#import "ConverterViewController.h"
#import "UnitDefinition.h"
#import "NumberFormatterManager.h"
#import "LocalStorageManager.h"

@interface HistoryViewController ()
@property (nonatomic, copy) NSArray<NSDictionary *> *items;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@end

@implementation HistoryViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;
    self.dateFormatter.timeStyle = NSDateFormatterShortStyle;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Clear All" style:UIBarButtonItemStylePlain
                                                                             target:self action:@selector(confirmClear)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reload];
}

- (void)reload {
    self.items = [[LocalStorageManager shared] history];
    self.navigationItem.rightBarButtonItem.enabled = self.items.count > 0;
    UILabel *empty = nil;
    if (self.items.count == 0) {
        empty = [UILabel new];
        empty.text = @"No conversions yet";
        empty.textAlignment = NSTextAlignmentCenter;
        empty.textColor = [UIColor secondaryLabelColor];
    }
    self.tableView.backgroundView = empty;
    [self.tableView reloadData];
}

- (void)confirmClear {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear all history?"
                                                                   message:@"Favorites are not affected."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[LocalStorageManager shared] clearHistory];
        [self reload];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = self.items[indexPath.row];
    NSString *result = [NumberFormatterManager stringFromValue:[item[UCKeyResult] doubleValue]
                                                     precision:[LocalStorageManager shared].precision];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    UIListContentConfiguration *config = [UIListContentConfiguration subtitleCellConfiguration];
    config.text = [NSString stringWithFormat:@"%@ %@ = %@ %@", item[UCKeyInput], item[UCKeyFrom], result, item[UCKeyTo]];
    config.secondaryText = [NSString stringWithFormat:@"%@ · %@", [UnitDefinition titleForCategory:item[UCKeyCategory]],
                            [self.dateFormatter stringFromDate:item[UCKeyDate]]];
    config.secondaryTextProperties.color = [UIColor secondaryLabelColor];
    config.image = [UIImage systemImageNamed:[UnitDefinition iconForCategory:item[UCKeyCategory]]];
    cell.contentConfiguration = config;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle != UITableViewCellEditingStyleDelete) return;
    [[LocalStorageManager shared] removeHistoryAtIndex:(NSUInteger)indexPath.row];
    self.items = [[LocalStorageManager shared] history];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    if (self.items.count == 0) [self reload];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *item = self.items[indexPath.row];
    ConverterViewController *vc = [[ConverterViewController alloc] initWithCategory:item[UCKeyCategory]
                                                                               from:item[UCKeyFrom]
                                                                                 to:item[UCKeyTo]
                                                                              input:item[UCKeyInput]];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
