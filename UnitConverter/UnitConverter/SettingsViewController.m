#import "SettingsViewController.h"
#import "LocalStorageManager.h"
#import "NumberFormatterManager.h"

typedef NS_ENUM(NSInteger, SettingsSection) {
    SettingsSectionDisplay,
    SettingsSectionData,
    SettingsSectionInfo,
    SettingsSectionCount
};

@implementation SettingsViewController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SettingsSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == SettingsSectionData ? 1 : 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @[@"Display", @"Data", @"Information"][section];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == SettingsSectionDisplay) {
        NSInteger p = [LocalStorageManager shared].precision;
        return [NSString stringWithFormat:@"Example: %@. Calculations always use full precision; only the display is rounded.",
                [NumberFormatterManager stringFromValue:M_PI * 1000 precision:p]];
    }
    return section == SettingsSectionData ? @"Favorites are kept when history is cleared." : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    UIListContentConfiguration *config = [UIListContentConfiguration valueCellConfiguration];
    LocalStorageManager *storage = [LocalStorageManager shared];
    if (indexPath.section == SettingsSectionDisplay && indexPath.row == 0) {
        config.text = [NSString stringWithFormat:@"Decimal Places: %ld", (long)storage.precision];
        UIStepper *stepper = [UIStepper new];
        stepper.minimumValue = 0;
        stepper.maximumValue = 10;
        stepper.value = storage.precision;
        stepper.accessibilityLabel = @"Decimal places";
        [stepper addTarget:self action:@selector(precisionChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = stepper;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (indexPath.section == SettingsSectionDisplay) {
        config.text = @"Auto-Copy Result";
        UISwitch *toggle = [UISwitch new];
        toggle.on = storage.autoCopy;
        [toggle addTarget:self action:@selector(autoCopyChanged:) forControlEvents:UIControlEventValueChanged];
        toggle.accessibilityLabel = @"Auto-copy result";
        cell.accessoryView = toggle;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (indexPath.section == SettingsSectionData) {
        config = [UIListContentConfiguration cellConfiguration];
        config.text = @"Clear Conversion History";
        config.textProperties.color = [UIColor systemRedColor];
    } else {
        config.text = indexPath.row == 0 ? @"About" : @"Privacy";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.contentConfiguration = config;
    return cell;
}

- (void)precisionChanged:(UIStepper *)stepper {
    [LocalStorageManager shared].precision = (NSInteger)stepper.value;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SettingsSectionDisplay] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)autoCopyChanged:(UISwitch *)toggle {
    [LocalStorageManager shared].autoCopy = toggle.on;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == SettingsSectionData) {
        [self confirmClearHistory];
    } else if (indexPath.section == SettingsSectionInfo) {
        [self showInfoPage:indexPath.row == 0];
    }
}

- (void)confirmClearHistory {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Clear all history?"
                                                                   message:@"Favorites are not affected."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Clear" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [[LocalStorageManager shared] clearHistory];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

/// About / Privacy are plain text pages built from a system text view, no extra class needed.
- (void)showInfoPage:(BOOL)about {
    NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"] ?: @"1.0";
    NSString *text = about
        ? [NSString stringWithFormat:@"Unit Converter %@\n\nA simple offline tool for everyday unit conversions across 8 categories: "
           "length, weight, area, volume, temperature, speed, time and data storage.\n\n"
           "Conversion factors use exact international definitions (e.g. 1 in = 2.54 cm, 1 lb = 0.45359237 kg, "
           "1 US gallon = 3.785411784 L). Data storage distinguishes decimal units (1 KB = 1000 B) from binary units "
           "(1 KiB = 1024 B), and 1 B = 8 bit.", version]
        : @"All conversions are performed locally on your device. The app does not use the network, "
          "does not require an account and contains no advertising, analytics or tracking SDKs.\n\n"
          "Your settings, favorites and up to 200 recent conversions are stored only on this device using the system's "
          "standard app storage (UserDefaults). They are not sent anywhere. You can clear history in Settings at any time, "
          "and deleting the app removes all of its data.";
    UIViewController *vc = [UIViewController new];
    vc.title = about ? @"About" : @"Privacy";
    vc.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    UITextView *textView = [UITextView new];
    textView.editable = NO;
    textView.text = text;
    textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    textView.adjustsFontForContentSizeCategory = YES;
    textView.textContainerInset = UIEdgeInsetsMake(20, 16, 20, 16);
    textView.backgroundColor = [UIColor systemGroupedBackgroundColor];
    vc.view = textView;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
