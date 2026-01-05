const dim = @import("../../lib/dimension.zig");
const qs = @import("../../lib/quantity_spec.zig");
const base = @import("base.zig");
const mc = @import("mechanics.zig");
const si = @import("si_quantities.zig");

// dimensions of base quantities
pub const DimTrafficIntensity = dim.BaseDimension('A');

// quantities
pub const TrafficIntensity = qs.BaseQuantitySpec("traffic_intensity", DimTrafficIntensity);
pub const TrafficOfferedIntensity = qs.ChildQuantitySpec("traffic_offered_intensity", TrafficIntensity);
pub const TrafficCarriedIntensity = qs.ChildQuantitySpec("traffic_carried_intensity", TrafficIntensity);
pub const TrafficLoad = TrafficCarriedIntensity;
pub const MeanQueueLength = qs.ChildQuantitySpec("mean_queue_length", base.Dimensionless);
pub const LossProbability = qs.ChildQuantitySpec("loss_probability", base.Dimensionless);
pub const WaitingProbability = qs.ChildQuantitySpec("waiting_probability", base.Dimensionless);
pub const CallIntensity = qs.DerivedQuantitySpec("call_intensity", base.Duration.Inverse());
pub const CallingRate = CallIntensity;
pub const CompletedCallIntensity = qs.ChildQuantitySpec("completed_call_intensity", CallIntensity);
pub const StorageCapacity = qs.BaseQuantitySpec("storage_capacity", dim.One); // TODO how to handle is_kind? I think this should work
pub const StorageSize = StorageCapacity;
pub const EquivalentBinaryStorageCapacity = qs.DerivedQuantitySpec("equivalent_binary_storage_capacity", StorageCapacity);
pub const TransferRate = qs.DerivedQuantitySpec("transfer_rate", StorageCapacity.Div(base.Duration));
pub const PeriodOfDataElements = qs.DerivedQuantitySpec("period_of_data_elements", si.Period, TransferRate.Inverse());
pub const BinaryDigitRate = qs.DerivedQuantitySpec("binary_digit_rate", TransferRate);
pub const BitRate = BinaryDigitRate;
pub const PeriodOfBinaryDigits = qs.ChildQuantitySpecWithEquation("period_of_binary_digits", si.Period, BinaryDigitRate.Inverse());
pub const BitPeriod = PeriodOfBinaryDigits;
pub const EquivalentBinaryDigitRate = qs.DerivedQuantitySpec("equivalent_binary_digit_rate", BinaryDigitRate);
pub const EquivalentBitRate = BitRate;
pub const ModulationRate = qs.DerivedQuantitySpec("modulation_rate", base.Duration.Inverse());
pub const LineDigitRate = ModulationRate;
pub const QuantizingDistortionPower = qs.DerivedQuantitySpec("quantizing_distortion_power", mc.Power);
pub const CarrierPower = qs.DerivedQuantitySpec("carrier_power", mc.Power);
pub const SignalEnergyPerBinaryDigit = qs.DerivedQuantitySpec("signal_energy_per_binary_digit", CarrierPower.Times(PeriodOfBinaryDigits));
pub const ErrorProbability = qs.DerivedQuantitySpec("error_probability", base.Dimensionless);
pub const HammingDistance = qs.DerivedQuantitySpec("Hamming_distance", base.Dimensionless);
pub const ClockFrequency = qs.DerivedQuantitySpec("clock_frequency", si.Frequency);
pub const ClockRate = ClockFrequency;
pub const DecisionContent = qs.DerivedQuantitySpec("decision_content", base.Dimensionless);

// TODO how to model InformationContent and the following quantities???
// pub const InformationContent = qs.DerivedQuantitySpec("information content", ...);
