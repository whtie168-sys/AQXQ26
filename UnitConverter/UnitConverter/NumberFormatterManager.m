#import "NumberFormatterManager.h"
#include <errno.h>

@implementation NumberFormatterManager

+ (BOOL)parseInput:(NSString *)text value:(double *)value error:(NSString **)error {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    // Accept a comma as decimal separator for locales that use one.
    trimmed = [trimmed stringByReplacingOccurrencesOfString:@"," withString:@"."];
    if (trimmed.length == 0) {
        if (error) *error = @"Enter a value.";
        return NO;
    }
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:@"0123456789.-+eE"];
    if ([trimmed rangeOfCharacterFromSet:allowed.invertedSet].location != NSNotFound) {
        if (error) *error = @"Invalid number.";
        return NO;
    }
    const char *cstr = trimmed.UTF8String;
    char *end = NULL;
    errno = 0;
    double v = strtod(cstr, &end);
    if (end == cstr || *end != '\0') {
        if (error) *error = @"Invalid number.";
        return NO;
    }
    if (errno == ERANGE && !isfinite(v)) {
        if (error) *error = @"Number is too large.";
        return NO;
    }
    if (!isfinite(v)) {
        if (error) *error = @"Invalid number.";
        return NO;
    }
    if (value) *value = v;
    return YES;
}

+ (NSString *)stringFromValue:(double)value precision:(NSInteger)precision {
    if (!isfinite(value)) return @"—";
    precision = MAX(0, MIN(10, precision));
    double magnitude = fabs(value);
    double smallest = pow(10.0, -(double)precision);

    // Very large values, or tiny non-zero values that would round to 0, use scientific notation.
    if (magnitude >= 1e15 || (magnitude > 0 && magnitude < smallest / 2.0)) {
        return [NSString stringWithFormat:@"%.*e", (int)MAX(precision, 2), value];
    }

    static NSNumberFormatter *formatter;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
        formatter.roundingMode = NSNumberFormatterRoundHalfUp;
        formatter.minimumFractionDigits = 0;
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.usesGroupingSeparator = YES;
        formatter.groupingSeparator = @",";
        formatter.groupingSize = 3;
    });
    NSString *text;
    @synchronized (formatter) {
        formatter.maximumFractionDigits = precision;
        text = [formatter stringFromNumber:@(value)];
    }
    if ([text isEqualToString:@"-0"]) text = @"0";
    return text ?: @"—";
}

@end
