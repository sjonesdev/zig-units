const qs = @import("../../lib/quantity_spec.zig");
const base = @import("base.zig");
const dim = @import("../../lib/dimension.zig");

const One = qs.BaseEquation;
// TODO include base units?

// space and time
pub const Width = qs.ChildQuantitySpec("width", base.Length);
pub const Breadth = Width;
pub const Radius = qs.ChildQuantitySpec("radius", Width);
pub const PathLength = qs.ChildQuantitySpec("path length", base.Length);
pub const ArcLength = PathLength;
pub const Area = qs.DerivedQuantitySpec("area", One.Times(base.Length).Times(base.Length));
pub const AngularMeasure = qs.DerivedQuantitySpec("angular measure", One.Times(ArcLength).Div(Radius)); // TODO how to handle is_kind? shouldn't this already make a kind?
pub const SolidAngularMeasure = qs.DerivedQuantitySpec("solid angular measure", One.Times(Area).Div(Radius).Div(Radius)); // TODO how to handle is_kind? shouldn't this already make a kind?
pub const PeriodDuration = qs.ChildQuantitySpec("period duration", base.Duration);
pub const Period = PeriodDuration;
pub const Frequency = qs.DerivedQuantitySpec("frequency", One.Div(PeriodDuration));

// mechanics
pub const Energy = qs.DerivedQuantitySpec("energy", One.Times(base.Mass).Times(base.Length).Times(base.Length).Div(base.Time).Div(base.Time)); // differs from ISO 80000 (defined in thermodynamics)

// atomic_and_nuclear_physics
pub const Activity = qs.DerivedQuantitySpec("activity", One.Div(base.Duration));
pub const AbsorbedDose = qs.DerivedQuantitySpec("absorbed dose", One.Times(Energy).Div(base.Mass));
pub const IonizingRadiationQualityFactor = qs.BaseQuantitySpec("ionizing radiation quality factor", dim.One);
pub const DoseEquivalent = qs.DerivedQuantitySpec("dose equivalent", One.Times(AbsorbedDose).Times(IonizingRadiationQualityFactor));
