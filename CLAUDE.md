# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

- `rake` / `rake test_units` — run the full test suite (Minitest, `test/*.rb`).
- `ruby -Ilib -Itest test/test_cashflow.rb` — run one test file.
- `ruby -Ilib -Itest test/test_cashflow.rb -n "/pattern/"` — filter by test name.
- `rake compile` — build the optional native extension into `lib/xirr/` (needs a C compiler).
- `ruby -Ilib benchmark/solvers.rb` — benchmark the solvers.

Requires Ruby `>= 3.1` and `activesupport >= 6.1, < 8`. There is no system Ruby on
the dev box used here; see the project memory for the asdf build recipe and the
`PATH` / `LD_LIBRARY_PATH` needed to run the suite.

## Architecture

The gem computes XIRR (the IRR of an irregularly-dated cashflow, like Excel's
XIRR) and carries a wider finance toolkit. Everything works in `Float` — there is
no `BigDecimal` dependency. Functions return plain numbers and raise
`ArgumentError` on inputs with no answer (no Elixir-style ok/error tuples).

### Cashflow and the solvers

- **`Xirr::Transaction`** (`transaction.rb`) — one dated amount (`Float`, `Date`).
- **`Xirr::Cashflow`** (`cashflow.rb`) — an `Array` subclass; the orchestrator and
  public entry point (`#xirr`, `#xirr!`, `#xnpv`, `#mirr`). It validates the flow,
  resolves options, compacts same-date transactions (`#compact_cf`), picks a
  solver, and delegates. It does no root-finding itself.
- **Solvers** all `include Xirr::Base` (`base.rb`), which supplies `xnpv`,
  `xnpv_derivative`, and the memoized `[years_from_start, amount]` `flows`:
  - **`RtSafe`** (`rtsafe.rb`) — safeguarded Newton (the classic *rtsafe*): bracket
    a sign change, then take a Newton step when it stays inside the bracket and a
    bisection step otherwise. **This is the default** (`config.default_method`).
  - **`RtSafeC`** (`rtsafe_c.rb` + `ext/xirr/xirr_native.c`) — the same algorithm
    in C. Optional: loaded only if compiled (`Xirr::NATIVE`); `method: :rtsafe_c`.
    **`rtsafe.rb` and `xirr_native.c` are meant to stay algorithmically identical —
    change them together and re-check parity.**
  - **`Brent`** (`brent.rb`) — derivative-free Brent's method over rtsafe's
    bracketing (`method: :brent`); as robust as rtsafe, cheaper per iteration but
    needs more of them, so it roughly ties rtsafe except on very large flows.
  - **`Bisection`, `NewtonMethod`** — legacy solvers kept for `method:` and the
    benchmark. rtsafe dominates both (faster and more robust).

### Control flow of `Cashflow#xirr`

1. `process_options` resolves `raise_exception` / `iteration_limit` / `period` in
   precedence order (call → cashflow → config) via `resolve_option`, and
   `switch_fallback` picks the method (an explicit `method:` turns fallback off).
2. Invalid flow (no sign change) → `config.replace_for_nil`, or raises if asked.
3. `compact_cf` merges same-date transactions; the chosen solver runs on it.
4. On non-convergence, if fallback is on and the method wasn't already rtsafe, it
   retries with `:rtsafe` (rtsafe is the safety net; nothing beats it, so it does
   not fall back to the weaker solvers).

### Key conventions

- **Sign is relative to the first transaction** (`first_transaction_direction`):
  `inflow`/`outflows` and validity are defined by each amount's sign times that
  direction, not by absolute positive/negative.
- **rtsafe does not depend on `irr_guess`** — it brackets independently and only
  uses a guess when it falls inside the bracket. `irr_guess` is a public
  convenience and the starting point for the fragile legacy Newton.
- **Precision & convergence** come from config: `eps` (tolerance on the *rate
  step/interval*, not on NPV), `precision` (rounding), `iteration_limit`, `period`
  (days/year).

### The other finance modules

Module functions (not on `Cashflow`), each in its own file: `Xirr::TVM`
(`fv`/`pv`/`pmt`/`ipmt`/`ppmt`/`nper`/`rate`/`amortization_schedule`),
`Xirr::Rates`, `Xirr::Bonds`, `Xirr::Depreciation`, `Xirr::Returns`, plus periodic
`Xirr.irr`/`npv`/`mirr` (`periodic.rb`). `TVM.rate` and `Bonds.ytm` reuse
`RtSafe.find`. These were ported from the `finance-elixir` library; its tests are
the source of the expected values in `test/`.

### Configuration

`config.rb` uses `ActiveSupport::Configurable`. Each default is both
`Xirr.config.<key>` and a frozen constant `Xirr::<KEY>` (the constant keeps the
original default after reconfiguration). Configure with `Xirr.configure { |c| ... }`.
