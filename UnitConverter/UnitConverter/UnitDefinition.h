#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A single measurement unit. Linear units convert via `factor` (amount of the category base unit per 1 unit).
/// Temperature units have `isTemperature` set and are handled by dedicated formulas in UnitConverter.
@interface UnitDefinition : NSObject

@property (nonatomic, copy, readonly) NSString *category;
@property (nonatomic, copy, readonly) NSString *symbol;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, assign, readonly) double factor;
@property (nonatomic, assign, readonly) BOOL isTemperature;

/// "Name (symbol)" for display.
@property (nonatomic, copy, readonly) NSString *displayName;

/// Ordered category keys: length, weight, area, volume, temperature, speed, time, data.
+ (NSArray<NSString *> *)categoryKeys;
+ (NSString *)titleForCategory:(NSString *)category;
+ (NSString *)iconForCategory:(NSString *)category;
+ (NSArray<UnitDefinition *> *)unitsForCategory:(NSString *)category;
+ (nullable UnitDefinition *)unitWithSymbol:(NSString *)symbol category:(NSString *)category;

@end

NS_ASSUME_NONNULL_END
