# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Build
forge build

# Run all forge tests
forge test

# Run a single suite
forge test --match-contract TaxpayerTest -vvv

# Run a single test
forge test --match-test test_invariant_age -vvvv

# Re-run only last failed tests
forge test --rerun

# Fuzz config: 100000 runs, fail_on_revert=false (set in foundry.toml)

# Halmos symbolic tests
halmos --loop 10 --solver-threads 16

# Halmos on specific contract
halmos --match-contract TaxpayerTest --loop 10

# Echidna (property-based fuzzer)
echidna . --contract TaxpayerTest --config echidna.yaml
```

## Project Structure

```
src/
  State.sol      — Central registry. Owns Lottery, tracks taxpayers via mapping.
                     Creates both Lottery and Taxpayer contracts. Access control via onlyOwner.
  Taxpayer.sol   — Taxpayer account. Marriage, divorce, tax allowances, lottery participation.
  Lottery.sol    — Lottery rounds. Commit-reveal pattern, single winner per round.
  Time.sol       — Test helper contract (TimeTest) for block.timestamp manipulation.
  ERC165.sol     — ERC-165 interface detection via staticcall.

test/
  Taxpayer.t.sol — Fuzz + symbolic (halmos) tests for Taxpayer invariants.
  Lottery.t.sol  — Fuzz + symbolic (halmos) tests for Lottery invariants.

lib/
  forge-std/     — Foundry standard library
  openzeppelin-contracts-upgradeable/
  halmos-cheatcodes/  — SymTest base for symbolic tests
```

## Architecture

### Contract Relationships

```
State (owner = deployer)
  ├── creates Lottery in constructor (Lottery.owner = State)
  ├── creates Taxpayer via addTaxpayer() (Taxpayer.state = State)
  ├── proxy_startlottery() → calls Lottery.startLottery()
  └── proxy_endlottery() → calls Lottery.endLottery()

Taxpayer (state = State)
  ├── marry() / divorce() / transferAllowance() / raiseOwnAllowance()
  ├── joinLottery() → gets Lottery address from State, calls commit()
  └── wonLottery() — called by Lottery, increments lottery_wins

Lottery (owner = State)
  ├── startLottery() / commit() / endLottery()
  ├── commit() checks isTaxpayerValid via State(owner)
  └── endLottery() picks random winner, calls wonLottery()
```

### Immutable References — Halmos Limitation

`State.lottery` is `private immutable`. Halmos cannot resolve immutable storage for cross-contract calls in symbolic execution. Lottery symbolic tests work around this by testing Lottery in isolation (test contract as owner) or using bounded action patterns that avoid calling State proxy functions.

### Access Control

- `State.addTaxporter()` — `onlyOwner` (deployer = test contract)
- `State.proxy_startlottery()` / `proxy_endlottery()` — `onlyOwner`
- `Lottery.startLottery()` / `endLottery()` — `onlyBy(owner)` where owner = State
- `Taxpayer.marry()` — requires `msg.sender == address(this)` (self-call via vm.prank)
- `Taxpayer.divorce()` — requires `msg.sender == spouse`
- `Taxpayer.wonLottery()` — requires `msg.sender == lottery`

## Testing Patterns

### Fuzz Tests (`test_` prefix)
Used for property-based testing with random concrete values. 100000 runs per test.

```solidity
function test_invariant_both_married() public {
    forEach(checkMarried);  // iterates over all 3 taxpayers
}
```

### Symbolic Tests (`check_` prefix, Halmos)
Used for bounded verification. Parameters are symbolic (ALL values). Use `assert()` not `assertEq()`.

```solidity
function check_SystemInvariants(TaxAction[6] memory actions) public {
    for (uint256 i = 0; i < actions.length; i++) {
        vm.assume(actions[i].actionType <= 4);  // prune symbolic paths
        // execute action, then assert invariants
        _assertInvariants();
    }
}
```

### Bounded Action Pattern
Both Taxpayer and Lottery tests use a bounded action sequence pattern:
1. Define an `enum ActionType` and `struct Action`
2. Execute actions in a fixed-size array loop
3. Check invariants after each step
4. Halmos: `vm.assume` for bounds; Foundry: `bound()` + `_test_` variants with `expectRevert`

### Echidna (commented out)
Older Echidna-style property tests remain in comments for reference.

### setUp
- Creates `State` (which creates `Lottery` + `TimeTest` in constructor)
- Adds 3 taxpayers via `State.addTaxpayer()` (test contract is owner)
- Taxpayer DoBs: 0, 0, -1265385612 (~40 years old at current timestamp)
