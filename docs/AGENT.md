# Coding Standard & Guidelines

These guidelines define the coding standards, libraries, and architectural preferences for the project. 

## Python Code Style
- **Python Version**: Use typed, idiomatic Python 3.11+. 
- **Type Hinting**: Use modern union syntax (`X | Y`), not deprecated forms like `typing.Optional`, `typing.Dict`, or `typing.List`.
- **String Enums**: Use `StrEnum` or `Literal` instead of bare strings.
- **Paths**: Always use `pathlib.Path` instead of `os.path`.
- **Formatting & Linting**: Rely on `ruff` for linting and auto-formatting. Do not fix ruff errors manually if an auto-fixer can handle them.

## Physics & Orbital Dynamics
- **Constants & Frames**: Use **`astropy`** for astronomical constants, time system conversions, and coordinate frame transformations.
- **Orbital Propagator**: Use **`bsk`** (Basilisk) for multi-body Sun-Earth dynamics around the Sun-Earth Lagrange points and for cannonball solar radiation pressure modelling via `radiationPressure.RadiationPressure`. Tudatpy was evaluated and dropped because it is not friendly to the project's `uv` package management workflow.
- **System Optimization (MDO)**: Use a small in-house optimizer built on **`scipy.optimize`** (typically `SLSQP` for bounded, constrained problems) plus a manual fixed-point loop for the mass / power feedback paths. OpenMDAO was considered but rejected for this preliminary 12U project because its scaffolding overhead outweighs the benefits at this design-space size and would be hard to defend as non-AI-generated work in the final presentation.

## CLI & Output 
- **Argument Parsing**: Prefer **`typer`** over `argparse` for all CLI entrypoints. Reuse shared `Annotated` type aliases for common options when possible.
- **Type Annotations for CLI/API**: Use `: Annotated[T, typer.XXX(...)]` rather than `: T = typer.XXX(...)` (applies equally to FastAPI `Depends` and Pydantic).
- **Terminal Output**: Prefer **`rich`** (`rich.console.Console` and `rich.table.Table`) for terminal output instead of standard `print()` or `PrettyTable`.
- **Logging**: Use standard `logging` configured with `rich.logging.RichHandler` for structured and readable log output.

## Data & Serialization
- **DataFrames**: Prefer `polars` over `pandas`.
- **Tabular Storage**: Prefer `parquet` over `CSV`.
- **Data Models**: Prefer standard `dataclasses`, `TypedDict`, and `namedtuples` over Pydantic `BaseModel`s for internal models. When validation is needed for external data (YAML/JSON), use Pydantic's `TypeAdapter`.
- **JSON Serialization**: Prefer adjacently tagged enums (e.g., `{"kind": ..., "value": ...}`), avoiding externally or internally tagged structures.

## Code Structure & Architecture
- **Composition over Inheritance**: Avoid inheritance. Use composition or Rust-like `typing.Protocol`s. Strive for pure functions where possible.
- **Nesting**: Avoid deeply nested code (keep to a max of ~3 levels). Use early returns, guard clauses, or split into helper functions.
- **State**: Make invalid states unrepresentable. Prefer explicit data flow over "god objects".
- **Return Types**: Prefer returning `Generators` and accepting `Iterators` instead of lists. Never return bare tuples in functions; create plain old data (dataclasses/namedtuples) instead.
- **Simplicity**: Always decrease the entropy of the system. Strive for absolute minimalism. Keep functions under ~60 lines.

## Docstrings & Comments
- **Style**: Use Sphinx-style docstrings (`:param name:`, `:return:`), instead of Google-style `Args:` / `Returns:`.
- **Content**: Docstrings should never state the obvious or repeat what the code does, nor should they duplicate type annotations.
- **Transparency**: Transparently comment down any assumptions you are making, what you found confusing, and potential hacks (e.g., "HACK: ...", "we should do X when Y is unblocked"). Reserve comments for explaining unclear motivations, purpose, pitfalls, and edge cases.
