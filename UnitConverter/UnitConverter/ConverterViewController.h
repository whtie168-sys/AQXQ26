#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// Converts a value within one category and lists results for every other unit.
@interface ConverterViewController : UITableViewController

/// Unknown symbols fall back to the category's default pair.
- (instancetype)initWithCategory:(NSString *)category
                            from:(nullable NSString *)from
                              to:(nullable NSString *)to
                           input:(nullable NSString *)input;

@end

NS_ASSUME_NONNULL_END
