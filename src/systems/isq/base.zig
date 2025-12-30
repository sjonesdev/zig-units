const qs = @import("../../lib/quantity_spec.zig");
const dim = @import("../../lib/dimension.zig");

// Base Dimensions
pub const DimTime = dim.BaseDimension('T');
pub const DimLength = dim.BaseDimension('L');
pub const DimMass = dim.BaseDimension('M');
pub const DimCurrent = dim.BaseDimension('I'); // TODO should this be ElectricCurrent?
pub const DimTemperature = dim.BaseDimension('Θ'); // TODO should this be ThermodynamicTemperature?
pub const DimAmount = dim.BaseDimension('N'); // TODO should this be AmountOfSubstance?
pub const DimLuminosity = dim.BaseDimension('J'); // TODO should this be LuminousIntensity?
pub const DimAngle = dim.BaseDimension('R'); // TODO move this to angular system?

pub const Time = qs.BaseQuantitySpec("time", DimTime);
pub const Duration = Time;
pub const Length = qs.BaseQuantitySpec("length", DimLength);
pub const Mass = qs.BaseQuantitySpec("mass", DimMass);
pub const ElectricCurrent = qs.BaseQuantitySpec("electric current", DimCurrent);
pub const ThermodynamicTemperature = qs.BaseQuantitySpec("thermodynamic temperature", DimTemperature);
pub const AmountOfSubstance = qs.BaseQuantitySpec("amount of substance", DimAmount);
pub const LuminousIntensity = qs.BaseQuantitySpec("luminous intensity", DimLuminosity);

// can implicitly convert up a quantity kind tree
// can explicitly convert down a quantity kind tree
// e.g. width -> length is implicitly convertible, but not length -> width

// can cast between branches of a quantity kind tree
// e.g. height can be casted to width and vice versa

// different quantity kind trees cannot be converted between
// e.g. time cannot be converted to length

// quantities under the same tree are comparable and addable/subtractable as long as the underlying dimensions are the same
// e.g. width and height are mutually comparable, addable, and subtractable

// the result of addition or subtraction between quantity kinds is the first common parent node between them
// e.g. a width + a height => a length

// in mp-units, a kind_of<quantity_type> refers to a family of quantity kinds
// and so a value of this type is implicitly convertible to any quantity kind within it's tree
// e.g. kind_of<length> is implicitly convertible to both width and height

// arithmetic on quantity kinds results in quantity kinds
// e.g. kind_of<length> / kind_of<time> => kind_of<length/time>

// arithmetic between quantity kinds and non-quantity kinds converts all quantity kinds to the
// root nodes of their hierarchy
// e.g. kind_of<length> / time => length / time
