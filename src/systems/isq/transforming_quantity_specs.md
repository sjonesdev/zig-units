These quantity specs are based on those from the mp-units library, which themselves are (mostly) 1:1 with the definitions in the latest ISO-80000 standards.

Steps
1. Comment out dimensions
2. Change quantity specs to variable declarations
    - `QUANTITY_SPEC\((\w+)` -> `pub const $1 = qs.DerivedQuantitySpec("$1"`
    - `inline constexpr auto` -> `pub const`
3. Delete extra stuff
    - `isq::`
4. Convert identifiers to Pascal case
    - Use the following regex to select all identifiers: `(?<!pub |// ((\w|\s)+)?)(?<=\s|\()\w+(?=\s|\))`
    - Use `Alt`+`Enter` to select all text that matches the search in VSCode, and use the "Transform to Pascal Case" command
    - This will leave a few matches left, mainly aliases which can be matched via `(?<== )\w+(?=;)`
5. Add imports as necessary
```zig
const dim = @import("../../lib/dimension.zig");
const qs = @import("../../lib/quantity_spec.zig");
const base = @import("base.zig");
const em = @import("electromagnetism.zig");
const ist = @import("information_science_and_technology.zig");
const lr = @import("light_and_radiation.zig");
const mc = @import("mechanics.zig");
const si = @import("si_quantities.zig");
const st = @import("space_and_time.zig");
const th = @import("thermodynamics.zig");
```
6. Fix equations
    - Replace arithmetic operators with `.Times()` and `.Div()`
    - Replace `inverse\((\w+)\)` with `$1.Inverse()`
    - Replace `pow<...>()` with `...Pow()` manually
7. Fix references to external quantities (prefix with correct import, e.g. `Length` -> `base.Length`)
8. Fix incorrect usage of quantity spec (not everything will be a derived quantity spec), there are also
    - Derived quantity specs of character
    - Child quantity specs
    - Child quantity specs of character
    - Child quantity specs of character with equation
9. Fix quantity spec names
    - Replace `(?<="\w+)_(?=\w+")` with a space
10. Manually translate dimensions