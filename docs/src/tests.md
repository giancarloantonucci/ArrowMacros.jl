# Tests

## Unpacking with `@↓`

```julia
using UnPack, ExtractMacro
using BenchmarkTools
s = A(1, [2, 3], B(4, [5, 6]))
v = [s]
```

1. Unpacking a field from a struct:

```julia
julia> @btime @extract s : a
29.122 ns (0 allocations: 0 bytes)

julia> @btime @unpack a = s
18.967 ns (0 allocations: 0 bytes)

julia> @btime @↓ a = s
19.619 ns (0 allocations: 0 bytes)
```

2. Unpacking a field from a vector of structs:

```julia
julia> @btime @extract v[1] : a
45.981 ns (0 allocations: 0 bytes)

julia> @btime @unpack a = v[1]
36.982 ns (0 allocations: 0 bytes)

julia> @btime @↓ a = v[1]
35.256 ns (0 allocations: 0 bytes)
```

3. Unpacking more than one fields from a struct:

```julia
julia> @btime @extract s : a b
57.859 ns (0 allocations: 0 bytes)

julia> @btime @unpack a, b = s
37.299 ns (0 allocations: 0 bytes)

julia> @btime @↓ a, b = s
37.149 ns (0 allocations: 0 bytes)
```

4. Unpacking whilst doing some basic maths:

```julia
julia> @btime @extract s : a = 2a
47.218 ns (0 allocations: 0 bytes)

julia> @btime @↓ a ← 2a = s
59.135 ns (0 allocations: 0 bytes)
```

5. Unpacking into differently named variables:

```julia
julia> @btime @extract s : a = b .+ 1 b
552.968 ns (3 allocations: 160 bytes)

julia> foo() = @↓ a ← b .+ 1, b = s
julia> @btime foo()
569.386 ns (3 allocations: 160 bytes)
```

6. Unpacking from nested structs:

```julia
julia> @btime @extract s.c : d e
115.139 ns (0 allocations: 0 bytes)

julia> @btime @unpack d, e = s.c
71.929 ns (0 allocations: 0 bytes)

julia> @btime @↓ d, e = s.c
67.673 ns (0 allocations: 0 bytes)
```

## Packing with `@↑`

1. Packing a variable into a struct:

```julia
julia> @btime @pack! s = a
62.497 ns (1 allocation: 16 bytes)

julia> @btime @↑ s = a
21.954 ns (0 allocations: 0 bytes)
```

2. Packing a variable into a vector of structs:

```julia
julia> @btime @pack! v[1] = a
80.517 ns (1 allocation: 16 bytes)

julia> @btime @↑ v[1] = a
39.042 ns (0 allocations: 0 bytes)
```

3. Packing more than one variables into a struct:

```julia
julia> @btime @pack! s = a, b
93.617 ns (1 allocation: 32 bytes)

julia> @btime @↑ s = a, b
38.943 ns (0 allocations: 0 bytes)
```

4. Packing into nested structs:

```julia
julia> @btime @pack! s.c = d, e
135.453 ns (1 allocation: 32 bytes)

julia> @btime @↑ s.c = d, e
70.029 ns (0 allocations: 0 bytes)
```
