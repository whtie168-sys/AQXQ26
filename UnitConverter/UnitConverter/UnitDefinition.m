#import "UnitDefinition.h"

@interface UnitDefinition ()
@property (nonatomic, copy, readwrite) NSString *category;
@property (nonatomic, copy, readwrite) NSString *symbol;
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) double factor;
@property (nonatomic, assign, readwrite) BOOL isTemperature;
@end

@implementation UnitDefinition

+ (instancetype)unit:(NSString *)symbol name:(NSString *)name factor:(double)factor category:(NSString *)category {
    UnitDefinition *u = [UnitDefinition new];
    u.symbol = symbol;
    u.name = name;
    u.factor = factor;
    u.category = category;
    u.isTemperature = [category isEqualToString:@"temperature"];
    return u;
}

- (NSString *)displayName {
    return [NSString stringWithFormat:@"%@ (%@)", self.name, self.symbol];
}

+ (NSArray<NSString *> *)categoryKeys {
    return @[@"length", @"weight", @"area", @"volume", @"temperature", @"speed", @"time", @"data"];
}

+ (NSString *)titleForCategory:(NSString *)category {
    NSDictionary *titles = @{@"length": @"Length", @"weight": @"Weight", @"area": @"Area", @"volume": @"Volume",
                             @"temperature": @"Temperature", @"speed": @"Speed", @"time": @"Time", @"data": @"Data Storage"};
    return titles[category] ?: category;
}

+ (NSString *)iconForCategory:(NSString *)category {
    NSDictionary *icons = @{@"length": @"ruler", @"weight": @"scalemass", @"area": @"square.dashed", @"volume": @"drop",
                            @"temperature": @"thermometer", @"speed": @"speedometer", @"time": @"clock", @"data": @"internaldrive"};
    return icons[category] ?: @"questionmark.circle";
}

/// Single source of truth for all units.
/// Bases: length m, weight kg, area m², volume L, speed m/s, time s, data B. Exact definitions (NIST / IEC).
+ (NSDictionary<NSString *, NSArray<UnitDefinition *> *> *)registry {
    static NSDictionary *registry;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSArray *(^make)(NSString *, NSArray *) = ^NSArray *(NSString *cat, NSArray *rows) {
            NSMutableArray *list = [NSMutableArray array];
            for (NSArray *r in rows) {
                [list addObject:[UnitDefinition unit:r[0] name:r[1] factor:[r[2] doubleValue] category:cat]];
            }
            return list;
        };
        registry = @{
            @"length": make(@"length", @[@[@"mm", @"Millimeter", @0.001], @[@"cm", @"Centimeter", @0.01],
                                         @[@"m", @"Meter", @1], @[@"km", @"Kilometer", @1000],
                                         @[@"in", @"Inch", @0.0254], @[@"ft", @"Foot", @0.3048],
                                         @[@"yd", @"Yard", @0.9144], @[@"mi", @"Mile", @1609.344]]),
            @"weight": make(@"weight", @[@[@"mg", @"Milligram", @1e-6], @[@"g", @"Gram", @0.001],
                                         @[@"kg", @"Kilogram", @1], @[@"t", @"Metric Ton", @1000],
                                         @[@"oz", @"Ounce", @0.028349523125], @[@"lb", @"Pound", @0.45359237]]),
            @"area": make(@"area", @[@[@"cm²", @"Square Centimeter", @1e-4], @[@"m²", @"Square Meter", @1],
                                     @[@"km²", @"Square Kilometer", @1e6], @[@"ft²", @"Square Foot", @0.09290304],
                                     @[@"ac", @"Acre", @4046.8564224], @[@"ha", @"Hectare", @10000]]),
            @"volume": make(@"volume", @[@[@"mL", @"Milliliter", @0.001], @[@"L", @"Liter", @1],
                                         @[@"m³", @"Cubic Meter", @1000],
                                         @[@"tsp", @"US Teaspoon", @0.00492892159375],
                                         @[@"tbsp", @"US Tablespoon", @0.01478676478125],
                                         @[@"cup", @"US Cup", @0.2365882365],
                                         @[@"gal", @"US Gallon", @3.785411784]]),
            @"temperature": make(@"temperature", @[@[@"°C", @"Celsius", @1], @[@"°F", @"Fahrenheit", @1],
                                                   @[@"K", @"Kelvin", @1]]),
            @"speed": make(@"speed", @[@[@"m/s", @"Meter per Second", @1], @[@"km/h", @"Kilometer per Hour", @(1000.0 / 3600.0)],
                                       @[@"mph", @"Mile per Hour", @0.44704], @[@"kn", @"Knot", @(1852.0 / 3600.0)]]),
            @"time": make(@"time", @[@[@"ms", @"Millisecond", @0.001], @[@"s", @"Second", @1],
                                     @[@"min", @"Minute", @60], @[@"h", @"Hour", @3600],
                                     @[@"d", @"Day", @86400], @[@"wk", @"Week", @604800]]),
            @"data": make(@"data", @[@[@"bit", @"Bit", @0.125], @[@"B", @"Byte", @1],
                                     @[@"KB", @"Kilobyte", @1e3], @[@"MB", @"Megabyte", @1e6],
                                     @[@"GB", @"Gigabyte", @1e9], @[@"TB", @"Terabyte", @1e12],
                                     @[@"KiB", @"Kibibyte", @1024.0], @[@"MiB", @"Mebibyte", @1048576.0],
                                     @[@"GiB", @"Gibibyte", @1073741824.0], @[@"TiB", @"Tebibyte", @1099511627776.0]]),
        };
    });
    return registry;
}

+ (NSArray<UnitDefinition *> *)unitsForCategory:(NSString *)category {
    return [self registry][category] ?: @[];
}

+ (UnitDefinition *)unitWithSymbol:(NSString *)symbol category:(NSString *)category {
    if (![symbol isKindOfClass:[NSString class]] || ![category isKindOfClass:[NSString class]]) return nil;
    for (UnitDefinition *u in [self unitsForCategory:category]) {
        if ([u.symbol isEqualToString:symbol]) return u;
    }
    return nil;
}

@end
