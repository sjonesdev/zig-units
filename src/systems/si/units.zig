const unit = @import("../../lib/unit.zig");
const q = @import("../../lib/quantity.zig");
const qp = @import("../../lib/quantity_point.zig");
const isq = @import("../isq.zig");

const Unit = unit.Unit;
const Kilo = unit.Kilo;

pub const Unitless = Unit("", "", q.KindOf(isq.base.Scalar));

// base units
// inline constexpr struct second final : named_unit<"s", kind_of<isq::time>> {} second;
pub const Second = unit.Named("second", "s", q.KindOf(isq.base.Time));
// inline constexpr struct metre final : named_unit<"m", kind_of<isq::length>> {} metre;
pub const Meter = unit.Named("meter", "m", q.KindOf(isq.base.Length));
// inline constexpr struct gram final : named_unit<"g", kind_of<isq::mass>> {} gram;
pub const Gram = unit.Named("gram", "g", q.KindOf(isq.base.Mass));

// inline constexpr auto kilogram = kilo<gram>;
pub const Kilogram = unit.Kilo(Gram);
// inline constexpr struct ampere final : named_unit<"A", kind_of<isq::electric_current>> {} ampere;
pub const Ampere = unit.Named("ampere", "A", q.KindOf(isq.base.ElectricCurrent));

// inline constexpr struct absolute_zero final : absolute_point_origin<isq::thermodynamic_temperature> {} absolute_zero;
pub const AbsoluteZero = qp.AbsolutePointOrigin(isq.base.ThermodynamicTemperature);
// inline constexpr auto zeroth_kelvin  = absolute_zero;
pub const ZerothKelvin = AbsoluteZero;
// inline constexpr struct kelvin final : named_unit<"K", kind_of<isq::thermodynamic_temperature>, zeroth_kelvin> {} kelvin;
pub const Kelvin = unit.NamedWithOrigin("kelvin", "K", q.KindOf(isq.base.ThermodynamicTemperature), ZerothKelvin);

// inline constexpr struct mole final : named_unit<"mol", kind_of<isq::amount_of_substance>> {} mole;
pub const Mole = unit.Named("mole", "mol", q.KindOf(isq.base.AmountOfSubstance));
// inline constexpr struct candela final : named_unit<"cd", kind_of<isq::luminous_intensity>> {} candela;
pub const Candela = unit.Named("candela", "cd", q.KindOf(isq.base.LuminousIntensity));

// // derived named units
// inline constexpr struct radian final : named_unit<"rad", metre / metre, kind_of<isq::angular_measure>> {} radian;
pub const Radian = unit.Named("radian", "rad", q.KindOf(isq.si.AngularMeasure));
// inline constexpr struct steradian final : named_unit<"sr", square(metre) / square(metre), kind_of<isq::solid_angular_measure>> {} steradian;
pub const Hertz = unit.NamedWithEquation("hertz", "Hz", Meter, q.KindOf(isq.si.Frequency));
// inline constexpr struct hertz final : named_unit<"Hz", one / second, kind_of<isq::frequency>> {} hertz;
// inline constexpr struct newton final : named_unit<"N", kilogram * metre / square(second)> {} newton;
// #ifdef pascal
// #pragma push_macro("pascal")
// #undef pascal
// #define MP_UNITS_REDEFINE_PASCAL
// #endif
// inline constexpr struct pascal final : named_unit<"Pa", newton / square(metre)> {} pascal;
// #ifdef MP_UNITS_REDEFINE_PASCAL
// #pragma pop_macro("pascal")
// #undef MP_UNITS_REDEFINE_PASCAL
// #endif
// inline constexpr struct joule final : named_unit<"J", newton * metre> {} joule;
// inline constexpr struct watt final : named_unit<"W", joule / second> {} watt;
// inline constexpr struct coulomb final : named_unit<"C", ampere * second> {} coulomb;
// inline constexpr struct volt final : named_unit<"V", watt / ampere> {} volt;
// inline constexpr struct farad final : named_unit<"F", coulomb / volt> {} farad;
// inline constexpr struct ohm final : named_unit<symbol_text{u8"Ω", "ohm"}, volt / ampere> {} ohm;
// inline constexpr struct siemens final : named_unit<"S", one / ohm> {} siemens;
// inline constexpr struct weber final : named_unit<"Wb", volt * second> {} weber;
// inline constexpr struct tesla final : named_unit<"T", weber / square(metre)> {} tesla;
// inline constexpr struct henry final : named_unit<"H", weber / ampere> {} henry;

// inline constexpr struct ice_point final : relative_point_origin<::mp_units::point<milli<kelvin>>(273'150)> {} ice_point;
// inline constexpr auto zeroth_degree_Celsius = ice_point;
// inline constexpr struct degree_Celsius final : named_unit<symbol_text{u8"℃", "`C"}, kelvin, zeroth_degree_Celsius> {} degree_Celsius;

// inline constexpr struct lumen final : named_unit<"lm", candela * steradian> {} lumen;
// inline constexpr struct lux final : named_unit<"lx", lumen / square(metre)> {} lux;
// inline constexpr struct becquerel final : named_unit<"Bq", one / second, kind_of<isq::activity>> {} becquerel;
// inline constexpr struct gray final : named_unit<"Gy", joule / kilogram, kind_of<isq::absorbed_dose>> {} gray;
// inline constexpr struct sievert final : named_unit<"Sv", joule / kilogram, kind_of<isq::dose_equivalent>> {} sievert;
// inline constexpr struct katal final : named_unit<"kat", mole / second> {} katal;
// // clang-format on

// }  // namespace si

// namespace non_si {

// // clang-format off
// // non-SI units accepted for use with the SI
// inline constexpr struct minute final : named_unit<"min", mag<60> * si::second> {} minute;
// inline constexpr struct hour final : named_unit<"h", mag<60> * minute> {} hour;
// inline constexpr struct day final : named_unit<"d", mag<24> * hour> {} day;
// inline constexpr struct astronomical_unit final : named_unit<"au", mag<149'597'870'700> * si::metre> {} astronomical_unit;
// inline constexpr struct degree final : named_unit<symbol_text{u8"°", "deg"}, mag<π> / mag<180> * si::radian> {} degree;
// inline constexpr struct arcminute final : named_unit<symbol_text{u8"′", "'"}, mag_ratio<1, 60> * degree> {} arcminute;
// inline constexpr struct arcsecond final : named_unit<symbol_text{u8"″", "''"}, mag_ratio<1, 60> * arcminute> {} arcsecond;
// inline constexpr struct are final : named_unit<"a", square(si::deca<si::metre>)> {} are;
// inline constexpr auto hectare = si::hecto<are>;
// inline constexpr struct litre final : named_unit<"L", cubic(si::deci<si::metre>)> {} litre;
// inline constexpr struct tonne final : named_unit<"t", mag<1000> * si::kilogram> {} tonne;
// inline constexpr struct dalton final : named_unit<"Da", mag_ratio<16'605'390'666'050, 10'000'000'000'000> * mag_power<10, -27> * si::kilogram> {} dalton;
// // TODO A different value is provided in the SI Brochure and different in the ISO 80000
// inline constexpr struct electronvolt final : named_unit<"eV", mag_ratio<1'602'176'634, 1'000'000'000> * mag_power<10, -19> * si::joule> {} electronvolt;
// // TODO the below are logarithmic units - how to support those?
// // neper
// // bel
// // decibel
// // clang-format on

// }  // namespace non_si

// namespace si {

// // Non-SI units are accepted for use with SI
// using namespace non_si;

// }  // namespace si

// template<>
// MP_UNITS_INLINE constexpr bool space_before_unit_symbol<non_si::degree> = false;
// template<>
// MP_UNITS_INLINE constexpr bool space_before_unit_symbol<non_si::arcminute> = false;
// template<>
// MP_UNITS_INLINE constexpr bool space_before_unit_symbol<non_si::arcsecond> = false;

// }  // namespace mp_units
