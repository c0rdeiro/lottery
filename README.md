# Foundry Smart Contract Lottery

This is a section of the Cyfrin Foundry Solidity Course.

- [Foundry Smart Contract Lottery](#foundry-smart-contract-lottery)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
- [Usage](#usage)
  - [Start a local node](#start-a-local-node)
  - [Library](#library)
  - [Deploy](#deploy)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
- [Deployment to a testnet or mainnet](#deployment-to-a-testnet-or-mainnet)
  - [Scripts](#scripts)
  - [Estimate gas](#estimate-gas)
- [Formatting](#formatting)
- [What I've Leaned](#what-ive-learned)

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - You'll know you did it right if you can run `git --version` and you see a response like `git version x.x.x`
- [foundry](https://getfoundry.sh/)
  - You'll know you did it right if you can run `forge --version` and you see a response like `forge 0.2.0 (816e00b 2023-03-16T00:05:26.396218Z)`

# Usage

## Start a local node

```
make anvil
```

## Library

If you're having a hard time installing the chainlink library, you can optionally run this command.

```
forge install smartcontractkit/chainlink-brownie-contracts@0.6.1
```

## Deploy

This will default to your local node. You need to have it running in another terminal in order for it to deploy.

```
make deploy-local
```

## Testing

```
forge test
```

or

```
forge test --fork-url $SEPOLIA_RPC_URL
```

### Test Coverage

```
forge coverage
```

# Deployment to a testnet or mainnet

1. Setup environment variables

You'll want to set your `SEPOLIA_RPC_URL` as environment variables. You can add them to a `.env` file

- `SEPOLIA_RPC_URL`: This is url of the sepolia testnet node you're working with. You can get setup with one for free from [Alchemy](https://alchemy.com/?a=673c802981)

Optionally, add your `SEPOLIA_ETHERSCAN_API_KEY` if you want to verify your contract on [Etherscan](https://etherscan.io/).

You should set an account with (replacing example with the name you want to use, be sure that in makefile the account matches the one you want to use)

```
cast wallet import **example** --interactive
```

1. Get testnet ETH

Head over to [faucets.chain.link](https://faucets.chain.link/) and get some testnet ETH. You should see the ETH show up in your metamask.

2. Deploy

```
make deploy-sepolia
```

This will setup a ChainlinkVRF Subscription for you. If you already have one, update it in the `scripts/HelperConfig.s.sol` file. It will also automatically add your contract as a consumer.

3. Register a Chainlink Automation Upkeep

[You can follow the documentation if you get lost.](https://docs.chain.link/chainlink-automation/compatible-contracts)

Go to [automation.chain.link](https://automation.chain.link/new) and register a new upkeep. Choose `Custom logic` as your trigger mechanism for automation. Your UI will look something like this once completed:

## Scripts

After deploying to a testnet or local net, you can run the scripts.

Using cast deployed locally example:

```
cast send <RAFFLE_CONTRACT_ADDRESS> "enterRaffle()" --value 0.1ether --private-key <PRIVATE_KEY> --rpc-url $SEPOLIA_RPC_URL
```

or, to create a ChainlinkVRF Subscription:

```
make createSubscription ARGS="--network sepolia"
```

## Estimate gas

You can estimate how much gas things cost by running:

```
forge snapshot
```

And you'll see an output file called `.gas-snapshot`

# Formatting

To run code formatting:

```
forge fmt
```

# What I've learned

- CEI methodology (Checks-Effects-Interactions pattern)
- Custom gas-efficient errors with multiple parameters
- Enums and type declarations as unsigned integers
- Private state variables and getter functions
- Verbose constructors for multi-chain deployment
- Network configuration for different blockchain networks
- Chainlink VRF integration for verifiable randomness
- Chainlink Automation for automatic smart contract execution
- Event emissions for frontend indexing and migrations
- Mock contracts for testing blockchain interactions
- Broadcasting and deploying contracts from command line
- Programmatic VRF consumer management
- Interaction scripts for subscription and consumer management
- Comprehensive unit testing strategies
- Event capture and reuse patterns in tests
- Testing with mock Chainlink tokens
- Modifiers and expected revert testing
- ABI encoder patterns and debugging
- Testnet deployment with live Chainlink services
- LINK token funding for VRF and automation subscriptions
- Advanced scripting and deployment methodologies
- Fuzz testing
