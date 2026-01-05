const qs = @import("../../lib/quantity_spec.zig");
const base = @import("base.zig");
const si = @import("si_quantities.zig");
// TODO include si quantities?

pub const Height = qs.ChildQuantitySpec("height", base.Length);
pub const Depth = Height;
pub const Altitude = Height;
pub const Thickness = qs.ChildQuantitySpec("thickness", si.Width);
pub const Diameter = qs.ChildQuantitySpec("diameter", si.Width);
pub const Distance = qs.ChildQuantitySpec("distance", si.PathLength);
pub const RadialDistance = qs.ChildQuantitySpec("radial distance", Distance);
pub const Displacement = qs.ChildQuantitySpecOfCharacter(
    "displacement",
    base.Length,
    qs.QuantityCharacter.vector,
);
pub const PositionVector = qs.ChildQuantitySpecOfCharacter(
    "position vector",
    Displacement,
    qs.QuantityCharacter.vector,
);
pub const RadiusOfCurvature = qs.ChildQuantitySpec("radius of curvature", si.Radius);
pub const Curvature = qs.DerivedQuantitySpec("curvature", RadiusOfCurvature.Inverse("curvature"));
pub const Volume = qs.DerivedQuantitySpec("volume", base.Length.Pow("volume", 3));
// first one is the parent, second one is derivation or something, maybe kinda like this "quantity character"
// should be of "kind" angular_measure with equation path_length / radius
// TODO figure out the casting semantics of this
pub const RotationalDisplacement = qs.ChildQuantitySpecWithEquation(
    "rotational displacement",
    si.AngularMeasure,
    si.PathLength.Div(si.Radius),
);
pub const AngularDisplacement = RotationalDisplacement;
pub const PhaseAngle = qs.ChildQuantitySpec("phase angle", si.AngularMeasure);
pub const Speed = qs.DerivedQuantitySpec("speed", base.Length.Div(base.Time)); // differs from ISO 80000
pub const Velocity = qs.ChildQuantitySpecWithEquation(
    "velocity",
    Speed,
    Displacement.Div(base.Duration),
); // TODO make sure is vector  // differs from ISO 80000
pub const Acceleration = qs.DerivedQuantitySpec("acceleration", Velocity.Div(base.Duration)); // TODO make sure is vector
pub const AccelerationOfFreeFall = qs.ChildQuantitySpec("acceleration of free fall", Acceleration); // not in ISO 80000
pub const AngularVelocity = qs.DerivedQuantitySpecOfCharacter(
    "angular velocity",
    AngularDisplacement.Div(base.Duration),
    qs.QuantityCharacter.vector,
);
pub const AngularAcceleration = qs.DerivedQuantitySpec("angular acceleration", AngularVelocity.Div(base.Duration));
pub const TimeConstant = qs.ChildQuantitySpec("time constant", base.Duration);
pub const Rotation = qs.BaseQuantitySpec("rotation", base.Dimensionless);
pub const RotationFrequency = qs.DerivedQuantitySpec("rotational frequency", Rotation.Div(base.Duration));
pub const AngularFrequency = qs.DerivedQuantitySpec("angular frequency", PhaseAngle.Div(base.Duration));
pub const Wavelength = qs.ChildQuantitySpec("wavelength", base.Length);
pub const Repetency = qs.DerivedQuantitySpec("repetency", Wavelength.Inverse());
pub const Wavenumber = Repetency;
pub const WaveVector = qs.ChildQuantitySpecOfCharacter(
    "wave vector",
    Repetency,
    qs.QuantityCharacter.vector,
);
pub const AngularRepetency = qs.DerivedQuantitySpec("angular repetency", Wavelength.Inverse());
pub const AngularWavenumber = AngularRepetency;
pub const PhaseSpeed = qs.DerivedQuantitySpec("phase speed", AngularFrequency.Div(AngularRepetency));
pub const GroupSpeed = qs.DerivedQuantitySpec("group speed", AngularFrequency.Div(AngularRepetency));
pub const DampingCoefficient = qs.DerivedQuantitySpec("damping coefficient", TimeConstant.Inverse());
pub const LogarithmicDecrement = qs.ChildQuantitySpecWithEquation(
    "logarithmic decrement",
    base.Dimensionless,
    DampingCoefficient.Div(si.PeriodDuration),
);
pub const Attenuation = qs.DerivedQuantitySpec("attenuation", Distance.Inverse());
pub const Extinction = Attenuation;
pub const PhaseCoefficient = qs.DerivedQuantitySpec("phase coefficient", PhaseAngle.Div(si.PathLength));

/// γ = α + iβ where α denotes attenuation
/// and β the phase coefficient of a plane wave
pub const PropogationCoefficient = qs.DerivedQuantitySpec("propogation coefficient", base.Length.Inverse());
