#import "HomeViewController.h"
#import "ConverterViewController.h"
#import "UnitDefinition.h"

static NSString * const kCellId = @"category";

@implementation HomeViewController

- (instancetype)init {
    UICollectionLayoutListConfiguration *list =
        [[UICollectionLayoutListConfiguration alloc] initWithAppearance:UICollectionLayoutListAppearanceInsetGrouped];
    return [super initWithCollectionViewLayout:[UICollectionViewCompositionalLayout layoutWithListConfiguration:list]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView registerClass:[UICollectionViewListCell class] forCellWithReuseIdentifier:kCellId];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return (NSInteger)[UnitDefinition categoryKeys].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewListCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kCellId forIndexPath:indexPath];
    NSString *key = [UnitDefinition categoryKeys][indexPath.item];
    NSArray<UnitDefinition *> *units = [UnitDefinition unitsForCategory:key];
    UIListContentConfiguration *config = [UIListContentConfiguration subtitleCellConfiguration];
    config.text = [UnitDefinition titleForCategory:key];
    config.secondaryText = [[units valueForKey:@"symbol"] componentsJoinedByString:@" · "];
    config.secondaryTextProperties.color = [UIColor secondaryLabelColor];
    config.image = [UIImage systemImageNamed:[UnitDefinition iconForCategory:key]];
    cell.contentConfiguration = config;
    cell.accessories = @[[UICellAccessoryDisclosureIndicator new]];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    NSString *key = [UnitDefinition categoryKeys][indexPath.item];
    ConverterViewController *vc = [[ConverterViewController alloc] initWithCategory:key from:nil to:nil input:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
