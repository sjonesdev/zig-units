const AbsolutePointOriginContainer = struct { QuantitySpec: type };
pub fn AbsolutePointOrigin(QuantitySpec: type) AbsolutePointOriginContainer {
    // TODO do we need to register this on the quantity spec somehow?
    return AbsolutePointOriginContainer{ .QuantitySpec = QuantitySpec };
}
