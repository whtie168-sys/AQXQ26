#import <Foundation/Foundation.h>
#import "UnitDefinition.h"

NS_ASSUME_NONNULL_BEGIN

/// Unified conversion engine. Linear units go through the category base unit; temperature uses dedicated formulas.
@interface UnitConverter : NSObject

/// Returns NO and sets `error` (a user-facing message) when the input or result is invalid.
+ (BOOL)convertValue:(double)value
                from:(UnitDefinition *)from
                  to:(UnitDefinition *)to
              result:(double *)result
               error:(NSString * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
