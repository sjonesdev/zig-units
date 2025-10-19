# zig-units
The goal of this library is to provide type safety when performing unit conversions and comparisons.

## Todo
- ISQ
- use better contracts with something like zimpl


### ISQ Todo
- finish listing out quantity specs
- make units
- make quantities instantiable
- implement first common kind function
- implement quantity addition/subtraction with check for quantities being of the same kind
- formalize composition of units (e.g. how does dividing a kilometer by an hour work)
- implement quantity multiplication/division
- implement ratio properly to allow numerical operations without change in underlying type
- implement equations properly
- implement ergonomic way to instantiate quantities
- implement ergonomic way to take quantities as parameters to functions (might have to refactor some stuff from types into normal structs for this)
- ensure consistent precision on numerical operations
- ensure all operations follow standard zig arithmetic and casting assumptions