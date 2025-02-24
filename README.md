## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```


# Deploy all contracts with Catapulta


## Testnet

```sh
catapulta script script/catapulta/DeployBitarenaBetaTester.s.sol:DeployBitarenaBetaTester --network sepolia --legacy --sender 0x10929b8bCbA7Eb9C193cDc2ED220aE39027E60Ec
```

## Generate coverage 

```sh
forge coverage --report lcov --report summary
```

With HTML format 

```sh
genhtml lcov.info --output-directory coverage-report
```


### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```


### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

