#import "UnitConverter.h"

static const double kAbsoluteZeroCelsius = -273.15;

@implementation UnitConverter

+ (BOOL)fail:(NSString *)message error:(NSString **)error {
    if (error) *error = message;
    return NO;
}

/// Celsius is used as the pivot so that common round trips (°C ↔ °F) stay exact.
+ (double)celsiusFrom:(double)v symbol:(NSString *)symbol {
    if ([symbol isEqualToString:@"°F"]) return (v - 32.0) * 5.0 / 9.0;
    if ([symbol isEqualToString:@"K"]) return v + kAbsoluteZeroCelsius;
    return v;
}

+ (double)celsius:(double)c to:(NSString *)symbol {
    if ([symbol isEqualToString:@"°F"]) return c * 9.0 / 5.0 + 32.0;
    if ([symbol isEqualToString:@"K"]) return c - kAbsoluteZeroCelsius;
    return c;
}

+ (BOOL)convertValue:(double)value from:(UnitDefinition *)from to:(UnitDefinition *)to
              result:(double *)result error:(NSString **)error {
    if (!from || !to || ![from.category isEqualToString:to.category]) {
        return [self fail:@"Invalid unit selection." error:error];
    }
    if (!isfinite(value)) {
        return [self fail:@"Number is out of range." error:error];
    }

    double output;
    if (from.isTemperature) {
        double c = [self celsiusFrom:value symbol:from.symbol];
        // Allow tiny floating noise around absolute zero.
        if (c < kAbsoluteZeroCelsius - 1e-9) {
            return [self fail:@"Temperature cannot be below absolute zero (0 K)." error:error];
        }
        output = [from.symbol isEqualToString:to.symbol] ? value : [self celsius:c to:to.symbol];
    } else {
        output = [from.symbol isEqualToString:to.symbol] ? value : value * (from.factor / to.factor);
    }

    if (!isfinite(output)) {
        return [self fail:@"Result is out of range." error:error];
    }
    if (result) *result = output;
    return YES;
}

@end
