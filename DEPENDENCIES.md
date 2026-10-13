# Vendored dependencies

All required Solidity dependency sources are delivered as ordinary files under `lib/`.
No submodules, package-manager downloads, or external link placeholders are needed.
Upstream files are unmodified; licenses are included beside each package. These versions
are explicit build inputs, not floating references to the newest releases.

| Package | Version | Delivered files | License |
| --- | --- | --- | --- |
| [OpenZeppelin Contracts](https://github.com/OpenZeppelin/openzeppelin-contracts/tree/v5.0.2) | `v5.0.2` | ERC20, IERC20, IERC20Metadata, IERC20Errors (draft-IERC6093), Context | [MIT](lib/openzeppelin-contracts/LICENSE) |
| [forge-std](https://github.com/foundry-rs/forge-std/tree/v1.9.7) | `v1.9.7` | Complete upstream `src/` directory, for tests only | [MIT](lib/forge-std/LICENSE-MIT) / [Apache-2.0](lib/forge-std/LICENSE-APACHE) |

Source archives used during preparation:

- OpenZeppelin: `https://codeload.github.com/OpenZeppelin/openzeppelin-contracts/tar.gz/refs/tags/v5.0.2`
  — SHA-256 `18c7b7e949b9a82dcd8cd394426c9c2636dfc263aa2317d4749dbfa0c7b3925a`.
- forge-std: `https://codeload.github.com/foundry-rs/forge-std/tar.gz/refs/tags/v1.9.7`
  — SHA-256 `45157353ab49eab01d294565866731e599b32401757229689ee459aa26b7ee94`.

`DEPENDENCIES.sha256` records the hashes of the delivered files. Verify them locally with:

```sh
sha256sum --check DEPENDENCIES.sha256
```

Neither archive nor any compiler binary is needed in this repository. The verifier provides
the compiler version pinned in `foundry.toml`.
