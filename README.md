# Personality.md (PMD)

`src/PersonalityToken.sol:PersonalityToken` is an immutable ERC-20 token. Its constructor
mints the entire supply once to `msg.sender`, the immediate deployer.

| Parameter | Value |
| --- | --- |
| Solidity contract | `PersonalityToken` |
| Token name | `Personality.md` |
| Symbol | `PMD` |
| Decimals | `18` |
| Supply in whole tokens | `1,000,000,000 PMD` |
| Supply in smallest units | `1000000000000000000000000000` (`10^27`) |
| Constructor arguments | None (`[]`) |
| Constructor ETH value | `0` |
| Initial recipient | Constructor caller (`msg.sender`) |
| Intended launch chain | Ethereum, chain ID `1` |

## Behavior and assumptions

The brief specifies a fixed supply token, so ordinary ERC-20 transfer and approval behavior
is used. There are no transfer fees, burns, rebases, limits, allowlists, owner roles, pause
controls, upgrade mechanisms, or external mint entrypoints. The deployer has the same
permissions as every other holder after receiving the supply. There are no external calls
in construction or token operations, and no linked library addresses to configure.

Successful `transfer`, `approve`, and `transferFrom` return `true`; invalid operations revert
with ERC-20 custom errors. Transfers deliver the exact specified amount. Zero amount transfers
between nonzero addresses are valid and emit `Transfer`; self transfers preserve balances.
Transfers to the zero address and approvals to a zero spender revert.

`approve` replaces the spender's allowance. A finite allowance decreases on `transferFrom`;
`type(uint256).max` is treated as unlimited and stays unchanged. A reverted transfer leaves
balances and allowances unchanged. Explicit approvals emit `Approval`; spending an allowance
does not emit a separate `Approval` event, so integrations should query `allowance` for its
current value. These semantics follow the vendored [OpenZeppelin ERC20 implementation](lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol).

## Build and checks

Run from this repository's root with Foundry and Solidity **0.8.26** installed:

```sh
forge build
forge test
forge fmt --check
```

`foundry.toml` pins Solidity 0.8.26, the Cancun EVM target, optimizer runs at 200, and
`bytecode_hash = "none"`. Dependencies are ordinary source files in `lib/`; no installation,
RPC endpoint, API key, environment variables, network access, FFI, or filesystem cheatcode
permissions are needed for the build or tests once the compiler is installed. Vendored
versions, upstream links, and checksums are in [DEPENDENCIES.md](DEPENDENCIES.md).

The tests cover metadata, the single mint event, CREATE2 factory receipt instead of
transaction-origin receipt, full and zero amount transfers, self transfers, events, finite
and unlimited allowances, revocation, insufficient balances and approvals, rejected zero
addresses, rollback on failure, and absence of common administrative entrypoints.
Four fuzz tests run 512 cases each. Two invariants check constant supply and aggregate
balances over 128 sequences of 64 randomized transfers, approvals, and delegated transfers;
the handler also checks exact balance and allowance changes after each successful operation.
Each test starts from a fresh deployment and is independent of test ordering.

The local launch-flow test models the factory/distributor/pool token-transfer legs and their
exact amounts. It does not deploy Uniswap or claim to test real swaps. The supplied protected
launch harness depends on separate launch contracts and manifest-resolved inputs; the network's
independent verifier runs that integration after acceptance.

## Deployment handoff

Build the artifact `out/PersonalityToken.sol/PersonalityToken.json`. The launch system should
deploy its **creation bytecode** with no appended constructor arguments and no ETH. Do not use
a proxy or an initializer. When the factory executes CREATE/CREATE2, that factory receives all
`10^27` units, rather than the externally owned account that submitted the transaction. A direct
deployment instead assigns the supply to its direct deployer. Choose the creation caller
accordingly; there is no later mint or recovery operation.

The token constructor makes no chain-specific calls and requires no pre-existing contracts.
The launch factory is responsible for subsequent distribution, including its swarm allocation,
pool seeding, and forwarding the remainder under the supplied launch policy. None of these
allocations occurs in the token constructor. No application contracts are required by this task.
The separate manifest step supplies `launch.json`; this project does not generate a manifest
or execute deployment transactions.

## After launch

There are no owner-settable values, initialization calls, keepers, or administrative keys for
the token. The launch operator is responsible for deploying the reviewed artifact, recording
its address and transaction, verifying source with the pinned compiler settings, checking the
constructor's `Transfer` event and metadata, and confirming the factory's final allocations.
Because allocation can happen in the same transaction, the factory need not retain the entire
supply at the end of that transaction.

Holders are responsible for their keys, destination addresses, and spender approvals. Prefer
bounded approvals; when changing a nonzero allowance, revoke it and wait for confirmation
before setting a replacement to reduce the usual ERC-20 approval race. Tokens sent to a
contract that cannot return them (including this token contract) cannot be recovered by an
administrator. The token does not accept ordinary ETH transfers or provide an asset rescue
function.

## Review scope

The supplied security reference was considered for access control, external calls, supply
arithmetic, events, input validation, and deployment behavior. Token amounts use integer units;
the only mint call is in the constructor. All later balance changes require a holder transfer
or an allowance. The contract has no oracle, signatures, callback, proxy, or arbitrary execution
surface. The runtime test checks for forbidden DELEGATECALL, CALLCODE, and SELFDESTRUCT opcodes.

Local validation uses Foundry unit tests, fuzzing, invariants, build checks, and formatting.
Slither and Mythril were not run. This implementation and local review are not an independent
security audit; the launch's separate adversarial review and deployed-source verification remain
the release operators' responsibilities.
