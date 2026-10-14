#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Parses user input and formats results. Rounding happens only here, at display time.
@interface NumberFormatterManager : NSObject

/// Accepts decimals, negatives and scientific notation (e.g. "-1.5e3"). Returns NO with a message for invalid input.
+ (BOOL)parseInput:(NSString *)text value:(double *)value error:(NSString * _Nullable * _Nullable)error;

+ (NSString *)stringFromValue:(double)value precision:(NSInteger)precision;

@end

NS_ASSUME_NONNULL_END
