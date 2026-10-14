#import "ConverterViewController.h"
#import "UnitDefinition.h"
#import "UnitConverter.h"
#import "NumberFormatterManager.h"
#import "LocalStorageManager.h"

typedef NS_ENUM(NSInteger, ConverterSection) {
    ConverterSectionInput,
    ConverterSectionUnits,
    ConverterSectionResult,
    ConverterSectionAllUnits,
    ConverterSectionCount
};

static const NSTimeInterval kCommitDelay = 1.2;

@interface ConverterViewController () <UITextFieldDelegate>
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSArray<UnitDefinition *> *units;
@property (nonatomic, strong) UnitDefinition *fromUnit;
@property (nonatomic, strong) UnitDefinition *toUnit;
@property (nonatomic, copy) NSString *initialInput;
@property (nonatomic, strong) UITextField *inputField;
@property (nonatomic, strong) UILabel *errorLabel;
@property (nonatomic, strong) UILabel *fromSymbolLabel;
@property (nonatomic, strong) UITableViewCell *inputCellView;
@property (nonatomic, assign) double inputValue;
@property (nonatomic, assign) double resultValue;
@property (nonatomic, assign) BOOL hasResult;
/// Last committed conversion, so the same result is not saved / copied twice.
@property (nonatomic, copy) NSString *committedKey;
@end

@implementation ConverterViewController

- (instancetype)initWithCategory:(NSString *)category from:(NSString *)from to:(NSString *)to input:(NSString *)input {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) {
        _category = [category copy];
        _units = [UnitDefinition unitsForCategory:category];
        _fromUnit = (from ? [UnitDefinition unitWithSymbol:from category:category] : nil) ?: _units.firstObject;
        _toUnit = (to ? [UnitDefinition unitWithSymbol:to category:category] : nil)
            ?: (_units.count > 1 ? _units[1] : _units.firstObject);
        _initialInput = [input copy] ?: @"1";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = [UnitDefinition titleForCategory:self.category];
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self buildInputViews];
    [self updateFromSymbol];
    [self updateFavoriteButton];
    [self recalculate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Precision may have changed in Settings.
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(commitConversion) object:nil];
    [self commitConversion];
}

- (void)buildInputViews {
    self.inputField = [UITextField new];
    self.inputField.text = self.initialInput;
    self.inputField.placeholder = @"Enter value";
    self.inputField.font = [UIFont monospacedDigitSystemFontOfSize:28 weight:UIFontWeightSemibold];
    self.inputField.adjustsFontSizeToFitWidth = YES;
    self.inputField.minimumFontSize = 14;
    // Includes minus sign and "e" for scientific notation, unlike the decimal pad.
    self.inputField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    self.inputField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.inputField.returnKeyType = UIReturnKeyDone;
    self.inputField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.inputField.delegate = self;
    self.inputField.accessibilityLabel = @"Input value";
    self.fromSymbolLabel = [UILabel new];
    self.fromSymbolLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightMedium];
    self.fromSymbolLabel.textColor = [UIColor secondaryLabelColor];
    self.inputField.rightView = self.fromSymbolLabel;
    self.inputField.rightViewMode = UITextFieldViewModeAlways;
    [self.inputField addTarget:self action:@selector(inputChanged) forControlEvents:UIControlEventEditingChanged];

    self.errorLabel = [UILabel new];
    self.errorLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.errorLabel.adjustsFontForContentSizeCategory = YES;
    self.errorLabel.textColor = [UIColor systemRedColor];
    self.errorLabel.numberOfLines = 0;
}

#pragma mark - Calculation

- (void)inputChanged {
    [self recalculate];
    [self reloadResultSections];
}

- (void)recalculate {
    NSString *message = nil;
    double value = 0, result = 0;
    self.hasResult = [NumberFormatterManager parseInput:self.inputField.text value:&value error:&message] &&
                     [UnitConverter convertValue:value from:self.fromUnit to:self.toUnit result:&result error:&message];
    self.inputValue = value;
    self.resultValue = result;
    // An empty field is a normal state, not an error.
    BOOL empty = [self.inputField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet].length == 0;
    self.errorLabel.text = (self.hasResult || empty) ? nil : message;
    self.errorLabel.hidden = self.errorLabel.text == nil;

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(commitConversion) object:nil];
    if (self.hasResult) {
        [self performSelector:@selector(commitConversion) withObject:nil afterDelay:kCommitDelay];
    }
}

/// Saves the current valid conversion to history and, if enabled, copies it.
- (void)commitConversion {
    if (!self.hasResult) return;
    NSString *input = [self.inputField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    NSString *key = [NSString stringWithFormat:@"%@|%@|%@|%@", self.category, self.fromUnit.symbol, self.toUnit.symbol, input];
    if ([key isEqualToString:self.committedKey]) return;
    self.committedKey = key;
    LocalStorageManager *storage = [LocalStorageManager shared];
    [storage addHistoryWithCategory:self.category from:self.fromUnit.symbol to:self.toUnit.symbol
                              input:input result:self.resultValue];
    if (storage.autoCopy) {
        [UIPasteboard generalPasteboard].string = [self resultText];
    }
}

- (NSString *)resultText {
    NSString *number = [NumberFormatterManager stringFromValue:self.resultValue precision:[LocalStorageManager shared].precision];
    return [NSString stringWithFormat:@"%@ %@", number, self.toUnit.symbol];
}

- (void)reloadResultSections {
    [UIView performWithoutAnimation:^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(ConverterSectionResult, 2)]
                      withRowAnimation:UITableViewRowAnimationNone];
    }];
}

- (void)updateFromSymbol {
    self.fromSymbolLabel.text = [@" " stringByAppendingString:self.fromUnit.symbol];
    [self.fromSymbolLabel sizeToFit];
    self.inputField.rightView = self.fromSymbolLabel;
}

- (void)unitsChanged {
    [self updateFromSymbol];
    [self updateFavoriteButton];
    [self recalculate];
    [UIView performWithoutAnimation:^{
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(ConverterSectionUnits, 3)]
                      withRowAnimation:UITableViewRowAnimationNone];
    }];
}

#pragma mark - Actions

- (void)updateFavoriteButton {
    BOOL favorite = [[LocalStorageManager shared] isFavoriteCategory:self.category from:self.fromUnit.symbol to:self.toUnit.symbol];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:favorite ? @"star.fill" : @"star"]
                                                             style:UIBarButtonItemStylePlain
                                                            target:self action:@selector(toggleFavorite)];
    item.accessibilityLabel = favorite ? @"Remove from favorites" : @"Add to favorites";
    self.navigationItem.rightBarButtonItem = item;
}

- (void)toggleFavorite {
    BOOL now = [[LocalStorageManager shared] toggleFavoriteCategory:self.category from:self.fromUnit.symbol to:self.toUnit.symbol];
    [self updateFavoriteButton];
    [self showToast:now ? @"Added to Favorites" : @"Removed from Favorites"];
}

- (void)swapUnits {
    UnitDefinition *tmp = self.fromUnit;
    self.fromUnit = self.toUnit;
    self.toUnit = tmp;
    [self unitsChanged];
}

- (void)clearInput {
    self.inputField.text = @"";
    [self inputChanged];
    [self.inputField becomeFirstResponder];
}

- (void)copyResult {
    if (!self.hasResult) {
        [self showToast:@"No result to copy"];
        return;
    }
    [UIPasteboard generalPasteboard].string = [self resultText];
    [self showToast:@"Copied"];
}

- (void)pickUnitForSource:(BOOL)isSource sourceView:(UIView *)view {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:isSource ? @"From" : @"To"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    UnitDefinition *current = isSource ? self.fromUnit : self.toUnit;
    for (UnitDefinition *unit in self.units) {
        NSString *title = unit == current ? [unit.displayName stringByAppendingString:@"  ✓"] : unit.displayName;
        [sheet addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            if (isSource) self.fromUnit = unit; else self.toUnit = unit;
            [self unitsChanged];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = view;
    sheet.popoverPresentationController.sourceRect = view.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showToast:(NSString *)text {
    UIAlertController *toast = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [self presentViewController:toast animated:YES completion:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [toast dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(commitConversion) object:nil];
    [self commitConversion];
    return YES;
}

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ConverterSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case ConverterSectionInput: return 1;
        case ConverterSectionUnits: return 3;
        case ConverterSectionResult: return 3;
        default: return self.hasResult ? (NSInteger)self.units.count : 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ConverterSectionInput: return @"Value";
        case ConverterSectionUnits: return @"Units";
        case ConverterSectionResult: return @"Result";
        default: return self.hasResult ? @"All Units · tap to set as target" : nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ConverterSectionInput) {
        return [self inputCell];
    }
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    UIListContentConfiguration *config = [UIListContentConfiguration valueCellConfiguration];
    NSInteger precision = [LocalStorageManager shared].precision;

    if (indexPath.section == ConverterSectionUnits) {
        if (indexPath.row == 1) {
            config = [UIListContentConfiguration cellConfiguration];
            config.text = @"Swap Units";
            config.image = [UIImage systemImageNamed:@"arrow.up.arrow.down"];
            config.textProperties.color = self.view.tintColor;
        } else {
            config.text = indexPath.row == 0 ? @"From" : @"To";
            config.secondaryText = (indexPath.row == 0 ? self.fromUnit : self.toUnit).displayName;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (indexPath.section == ConverterSectionResult) {
        if (indexPath.row == 0) {
            config = [UIListContentConfiguration subtitleCellConfiguration];
            config.text = self.hasResult ? [self resultText] : @"—";
            config.textProperties.font = [UIFont monospacedDigitSystemFontOfSize:28 weight:UIFontWeightBold];
            config.textProperties.adjustsFontForContentSizeCategory = NO;
            config.secondaryText = self.toUnit.name;
            config.secondaryTextProperties.color = [UIColor secondaryLabelColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessibilityLabel = self.hasResult ? [NSString stringWithFormat:@"Result %@", [self resultText]] : @"No result";
        } else {
            config = [UIListContentConfiguration cellConfiguration];
            BOOL copy = indexPath.row == 1;
            config.text = copy ? @"Copy Result" : @"Clear Input";
            config.image = [UIImage systemImageNamed:copy ? @"doc.on.doc" : @"xmark.circle"];
            config.textProperties.color = copy ? self.view.tintColor : [UIColor systemRedColor];
            config.imageProperties.tintColor = config.textProperties.color;
        }
    } else {
        UnitDefinition *unit = self.units[indexPath.row];
        double value = 0;
        NSString *error = nil;
        BOOL ok = [UnitConverter convertValue:self.inputValue from:self.fromUnit to:unit result:&value error:&error];
        config.text = unit.name;
        config.secondaryText = ok ? [NSString stringWithFormat:@"%@ %@",
                                     [NumberFormatterManager stringFromValue:value precision:precision], unit.symbol] : @"—";
        config.secondaryTextProperties.font = [UIFont monospacedDigitSystemFontOfSize:15 weight:UIFontWeightRegular];
        cell.accessoryType = unit == self.toUnit ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    cell.contentConfiguration = config;
    return cell;
}

/// The input cell is created once and kept so the text field keeps focus across reloads.
- (UITableViewCell *)inputCell {
    if (self.inputCellView) return self.inputCellView;
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.inputField, self.errorLabel]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 4;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [cell.contentView addSubview:stack];
    UILayoutGuide *margins = cell.contentView.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
        [stack.topAnchor constraintEqualToAnchor:margins.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:margins.bottomAnchor],
        [self.inputField.heightAnchor constraintGreaterThanOrEqualToConstant:44],
    ]];
    self.inputCellView = cell;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIView *source = [tableView cellForRowAtIndexPath:indexPath] ?: tableView;
    if (indexPath.section == ConverterSectionUnits) {
        if (indexPath.row == 1) [self swapUnits];
        else [self pickUnitForSource:indexPath.row == 0 sourceView:source];
    } else if (indexPath.section == ConverterSectionResult) {
        if (indexPath.row == 1) [self copyResult];
        else if (indexPath.row == 2) [self clearInput];
    } else if (indexPath.section == ConverterSectionAllUnits) {
        self.toUnit = self.units[indexPath.row];
        [self unitsChanged];
    }
}

@end
