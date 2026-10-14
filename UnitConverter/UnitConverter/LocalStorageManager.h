#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Keys used in history / favorite dictionaries.
extern NSString * const UCKeyCategory;
extern NSString * const UCKeyFrom;
extern NSString * const UCKeyTo;
extern NSString * const UCKeyInput;
extern NSString * const UCKeyResult;
extern NSString * const UCKeyDate;

/// Unified local persistence (NSUserDefaults) for settings, history and favorites.
@interface LocalStorageManager : NSObject

+ (instancetype)shared;

@property (nonatomic, assign) NSInteger precision;   // 0–10, default 4
@property (nonatomic, assign) BOOL autoCopy;         // default NO

/// Newest first.
- (NSArray<NSDictionary *> *)history;
- (void)addHistoryWithCategory:(NSString *)category from:(NSString *)from to:(NSString *)to
                         input:(NSString *)input result:(double)result;
- (void)removeHistoryAtIndex:(NSUInteger)index;
- (void)clearHistory;

/// Newest first.
- (NSArray<NSDictionary *> *)favorites;
- (BOOL)isFavoriteCategory:(NSString *)category from:(NSString *)from to:(NSString *)to;
/// Returns the new favorite state.
- (BOOL)toggleFavoriteCategory:(NSString *)category from:(NSString *)from to:(NSString *)to;
- (void)removeFavoriteAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
