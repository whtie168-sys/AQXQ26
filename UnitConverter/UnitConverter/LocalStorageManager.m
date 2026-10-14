#import "LocalStorageManager.h"
#import "UnitDefinition.h"

NSString * const UCKeyCategory = @"category";
NSString * const UCKeyFrom = @"from";
NSString * const UCKeyTo = @"to";
NSString * const UCKeyInput = @"input";
NSString * const UCKeyResult = @"result";
NSString * const UCKeyDate = @"date";

static NSString * const kPrecisionKey = @"uc.precision";
static NSString * const kAutoCopyKey = @"uc.autoCopy";
static NSString * const kHistoryKey = @"uc.history.v1";
static NSString * const kFavoritesKey = @"uc.favorites.v1";
static const NSUInteger kMaxHistory = 200;

@implementation LocalStorageManager

+ (instancetype)shared {
    static LocalStorageManager *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ shared = [LocalStorageManager new]; });
    return shared;
}

- (NSUserDefaults *)defaults {
    return [NSUserDefaults standardUserDefaults];
}

#pragma mark - Settings

- (NSInteger)precision {
    id stored = [self.defaults objectForKey:kPrecisionKey];
    if (![stored isKindOfClass:[NSNumber class]]) return 4;
    return MAX(0, MIN(10, [stored integerValue]));
}

- (void)setPrecision:(NSInteger)precision {
    [self.defaults setInteger:MAX(0, MIN(10, precision)) forKey:kPrecisionKey];
}

- (BOOL)autoCopy {
    return [self.defaults boolForKey:kAutoCopyKey];
}

- (void)setAutoCopy:(BOOL)autoCopy {
    [self.defaults setBool:autoCopy forKey:kAutoCopyKey];
}

#pragma mark - Validation

/// Drops corrupted or outdated entries (unknown units, wrong types) instead of failing the whole read.
- (NSArray<NSDictionary *> *)validEntriesForKey:(NSString *)key requiresResult:(BOOL)requiresResult {
    id raw = [self.defaults objectForKey:key];
    if (![raw isKindOfClass:[NSArray class]]) return @[];
    NSMutableArray *valid = [NSMutableArray array];
    for (id item in (NSArray *)raw) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *d = item;
        NSString *cat = d[UCKeyCategory];
        if (![UnitDefinition unitWithSymbol:d[UCKeyFrom] category:cat] ||
            ![UnitDefinition unitWithSymbol:d[UCKeyTo] category:cat]) continue;
        if (![d[UCKeyDate] isKindOfClass:[NSDate class]]) continue;
        if (requiresResult && (![d[UCKeyInput] isKindOfClass:[NSString class]] ||
                               ![d[UCKeyResult] isKindOfClass:[NSNumber class]])) continue;
        [valid addObject:d];
    }
    return valid;
}

#pragma mark - History

- (NSArray<NSDictionary *> *)history {
    return [self validEntriesForKey:kHistoryKey requiresResult:YES];
}

- (void)addHistoryWithCategory:(NSString *)category from:(NSString *)from to:(NSString *)to
                         input:(NSString *)input result:(double)result {
    if (!isfinite(result) || input.length == 0) return;
    NSMutableArray *list = [[self history] mutableCopy];
    NSDictionary *latest = list.firstObject;
    // Re-confirming the same conversion only refreshes its timestamp.
    if (latest && [latest[UCKeyCategory] isEqualToString:category] && [latest[UCKeyFrom] isEqualToString:from] &&
        [latest[UCKeyTo] isEqualToString:to] && [latest[UCKeyInput] isEqualToString:input]) {
        [list removeObjectAtIndex:0];
    }
    [list insertObject:@{UCKeyCategory: category, UCKeyFrom: from, UCKeyTo: to,
                         UCKeyInput: input, UCKeyResult: @(result), UCKeyDate: [NSDate date]} atIndex:0];
    if (list.count > kMaxHistory) {
        [list removeObjectsInRange:NSMakeRange(kMaxHistory, list.count - kMaxHistory)];
    }
    [self.defaults setObject:list forKey:kHistoryKey];
}

- (void)removeHistoryAtIndex:(NSUInteger)index {
    NSMutableArray *list = [[self history] mutableCopy];
    if (index >= list.count) return;
    [list removeObjectAtIndex:index];
    [self.defaults setObject:list forKey:kHistoryKey];
}

- (void)clearHistory {
    [self.defaults removeObjectForKey:kHistoryKey];
}

#pragma mark - Favorites

- (NSArray<NSDictionary *> *)favorites {
    return [self validEntriesForKey:kFavoritesKey requiresResult:NO];
}

- (NSInteger)indexOfFavorite:(NSArray *)list category:(NSString *)category from:(NSString *)from to:(NSString *)to {
    for (NSUInteger i = 0; i < list.count; i++) {
        NSDictionary *d = list[i];
        if ([d[UCKeyCategory] isEqualToString:category] && [d[UCKeyFrom] isEqualToString:from] &&
            [d[UCKeyTo] isEqualToString:to]) return (NSInteger)i;
    }
    return NSNotFound;
}

- (BOOL)isFavoriteCategory:(NSString *)category from:(NSString *)from to:(NSString *)to {
    return [self indexOfFavorite:[self favorites] category:category from:from to:to] != NSNotFound;
}

- (BOOL)toggleFavoriteCategory:(NSString *)category from:(NSString *)from to:(NSString *)to {
    NSMutableArray *list = [[self favorites] mutableCopy];
    NSInteger index = [self indexOfFavorite:list category:category from:from to:to];
    BOOL nowFavorite = (index == NSNotFound);
    if (nowFavorite) {
        [list insertObject:@{UCKeyCategory: category, UCKeyFrom: from, UCKeyTo: to, UCKeyDate: [NSDate date]} atIndex:0];
    } else {
        [list removeObjectAtIndex:(NSUInteger)index];
    }
    [self.defaults setObject:list forKey:kFavoritesKey];
    return nowFavorite;
}

- (void)removeFavoriteAtIndex:(NSUInteger)index {
    NSMutableArray *list = [[self favorites] mutableCopy];
    if (index >= list.count) return;
    [list removeObjectAtIndex:index];
    [self.defaults setObject:list forKey:kFavoritesKey];
}

@end
