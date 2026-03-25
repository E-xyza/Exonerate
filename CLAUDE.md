# Exonerate

JSONSchema to Elixir compiler that generates compile-time validated functions from JSONSchema definitions.

## Quick Reference

```bash
# Install dependencies
mix deps.get

# Run tests
mix test

# Run specific test categories
mix test --include tutorial

# Compile with warnings as errors
mix compile --warnings-as-errors

# Format code
mix format

# Generate docs
mix docs
```

## Architecture

### Core Compilation Pipeline

1. **Schema Ingestion** (`Schema.ingest`) - Parse JSON/YAML into Elixir maps
2. **Draft Detection** (`Draft.set_opts`) - Identify JSONSchema version (4, 6, 7, 2019-09, 2020-12)
3. **Canonicalization** (`Degeneracy.canonicalize`) - Normalize schema representations
4. **ID Resolution** (`Id.prescan`) - Extract and catalog schema identifiers
5. **Reference Walking** (`Schema.ref_prescan`) - Traverse `$ref` chains
6. **Cache Storage** (`Cache`) - ETS-based compilation-time registry
7. **Code Generation** (`Context.filter`) - Build Elixir functions via macros

### Key Directories

- `lib/exonerate/` - Core library
  - `filter/` - 31+ JSONSchema validation filter modules (properties, items, etc.)
  - `combining/` - 8 schema composition modules (allOf, anyOf, oneOf, if/then/else, not, $ref)
  - `type/` - 7 JSON type validators (string, integer, number, array, object, boolean, null)
  - `formats/` - 14 format validators (date-time, email, uri, etc.)
- `test/` - Test suite
  - `tutorial/` - Educational examples
  - `_draft*/` - Official JSONSchema test suites per draft
  - `support/` - Test infrastructure (Automate, FilePlug, etc.)

### Entry Points

Three main macros in `lib/exonerate.ex`:
- `function_from_string/4` - Inline schema strings
- `function_from_file/4` - Schemas from files
- `function_from_resource/4` - Reusable registered schemas

## Coding Conventions

### Error Format

Errors return structured tuples with JSON pointer locations:
```elixir
{:error, error_value: value, instance_location: "/path", absolute_keyword_location: "#/type"}
```

### Macro Patterns

- Use `Tools.mismatch` macro for consistent error formatting
- Code generation uses `quote` blocks with context-aware JSON pointer locations
- `Macro.expand_literals()` for compile-time literal expansion

### Testing

- Tests use ExUnit with Bandit HTTP server (port 1234) for remote ref testing
- Official JSONSchema test suites are in `test/_draft*/` directories
- Test helper generates automated tests from JSON test suite files

## Dependencies

### Required
- `json_ptr` - JSON pointer handling
- `jason` - JSON parsing
- `match_spec` - Pattern matching utilities

### Optional
- `pegasus` - Parsing (for format validators)
- `req`/`finch` - HTTP client (for remote schemas)
- `yaml_elixir` - YAML support
- `idna` - IDN hostname validation

## Common Tasks

### Adding a New Filter

1. Create module in `lib/exonerate/filter/`
2. Implement `filter/2` macro callback
3. Optionally implement `accessories/2` for helper functions
4. Register in appropriate type module(s)

### Adding Format Validator

1. Create module in `lib/exonerate/formats/`
2. Implement validation logic
3. Register in `lib/exonerate/filter/format.ex`

## Known Limitations (By Design)

- No `multipleOf` for floats (IEEE 754 precision issues)
- No ID fields with URI fragments
- No dynamic references/anchors
- No content media type/encoding validation
- All strings validated as UTF-8 (use `{"format": "binary"}` for raw binary)
