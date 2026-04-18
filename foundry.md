# Foundry Quick Start for This Project

This note is a practical introduction to Foundry for working in this repository.

It explains:

- how to start a local node
- how to deploy contracts to it
- how this differs for a Uniswap v4 hook
- whether a local node can include the Uniswap ecosystem

## 1. Start a local node

Foundry's local node is called `anvil`.

Run:

```bash
anvil
```

By default, Anvil starts:

- a local EVM chain on `http://127.0.0.1:8545`
- a set of pre-funded test accounts
- deterministic private keys for those test accounts

You can verify the node is running:

```bash
cast block-number --rpc-url http://127.0.0.1:8545
```

If Anvil is working, this command returns the current local block number.

## 2. Fresh local chain vs forked chain

This is the most important Foundry concept for practical work.

### Fresh local chain

If you run:

```bash
anvil
```

you get an empty local blockchain.

That means:

- there is no Uniswap deployed by default
- there are no pools by default
- there are no ERC-20 tokens by default
- there is no existing onchain liquidity

This mode is great when you want to:

- learn the basics
- deploy everything yourself
- run isolated tests
- debug your own contracts in a clean environment

### Forked chain

If you run:

```bash
anvil --fork-url https://mainnet.unichain.org
```

Anvil creates a local fork of a real network.

That means:

- you get real deployed contracts from that network
- you can interact with existing protocol state locally
- you can test against existing Uniswap deployments and liquidity
- your transactions are still local unless you broadcast to a real chain separately

This is the easiest way to work with an existing DeFi ecosystem locally.

## 3. Can a local Anvil node have the Uniswap ecosystem?

Yes, but there are two different meanings of that.

### Option A: Deploy Uniswap yourself on a fresh local chain

Yes, you can deploy the contracts you need onto a fresh Anvil chain.

In that setup, the "Uniswap ecosystem" is only what you deploy yourself:

- PoolManager
- routers
- Permit2
- position manager
- tokens
- pools
- liquidity

This gives you full control, but it takes more setup.

### Option B: Fork a real chain

Yes, and this is usually the easier path.

If you fork a network that already has the contracts and state you need, your local Anvil node effectively behaves like a local copy of that ecosystem for testing.

For learning and debugging, this is often the best choice.

## 4. How to deploy a contract to a local node

There are two common ways in Foundry:

- `forge create`
- `forge script`

### A. Deploy a normal contract with `forge create`

For a regular Solidity contract, the simplest deployment pattern is:

```bash
forge create <path>:<ContractName> \
  --rpc-url http://127.0.0.1:8545 \
  --private-key <ANVIL_PRIVATE_KEY>
```

Example shape:

```bash
forge create src/MyContract.sol:MyContract \
  --rpc-url http://127.0.0.1:8545 \
  --private-key <ANVIL_PRIVATE_KEY>
```

If the constructor takes arguments:

```bash
forge create src/MyContract.sol:MyContract \
  --rpc-url http://127.0.0.1:8545 \
  --private-key <ANVIL_PRIVATE_KEY> \
  --constructor-args arg1 arg2
```

### B. Deploy with a script

For more complex deployments, Foundry scripts are better:

```bash
forge script script/SomeScript.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --private-key <ANVIL_PRIVATE_KEY> \
  --broadcast
```

This is the normal pattern when:

- deployment has multiple steps
- you need setup logic
- you want repeatable deployment workflows
- you need CREATE2

## 5. How deployment works in this repository

This repository is not a generic Solidity project.
It is a Uniswap v4 hook project.

That matters because a v4 hook is special:

- it is not enough to deploy the contract to any random address
- the deployed address must contain the correct hook permission bits
- that is why this repository uses `HookMiner`

## 6. Using `.env` for deployment

Yes, this repository can now read deployment values from `.env`.

Start by copying the example file:

```bash
cp .env.example .env
```

Then fill it with your values:

```bash
ETH_RPC_URL=http://127.0.0.1:8545
PRIVATE_KEY=<YOUR_PRIVATE_KEY>
POOL_MANAGER=<POOL_MANAGER_ADDRESS>
```

In this repository:

- `POOL_MANAGER` is read inside the script with `vm.envAddress("POOL_MANAGER")`
- `PRIVATE_KEY` is read inside the script with `vm.envUint("PRIVATE_KEY")`
- `ETH_RPC_URL` is mapped to the named Foundry RPC endpoint `local`

Then run:

```bash
source .env
forge script script/01_DeploySimpleHook.s.sol \
  --rpc-url local \
  --broadcast
```

That means you no longer need to pass `--private-key` on the command line for this script, and you do not need to type the raw RPC URL either.

## 7. Local CREATE2 note

Uniswap v4 hooks are usually deployed with CREATE2.

Some chains already expose the canonical CREATE2 deployer at:

```text
0x4e59b44847b379578588920cA78FbF26c0B4956C
```

But a fresh local Anvil node may not have that deployer available.

This repository handles that automatically:

- if the canonical CREATE2 deployer exists, the script uses it
- if it does not exist, the script deploys a small local CREATE2 factory and uses that instead

So the same script works more reliably on local Anvil.

## 8. Important note: a Uniswap v4 hook is not deployed like a normal contract

For a normal contract, `forge create` is often enough.

For a v4 hook, that is usually not enough.

Why:

1. Uniswap v4 encodes hook permissions in the contract address.
2. If the address bits do not match the permissions returned by the hook, the hook will not work correctly.
3. Because of that, a hook is usually deployed through a CREATE2 flow that first finds a valid salt.

That is exactly what [`script/01_DeploySimpleHook.s.sol`](/script/01_DeploySimpleHook.s.sol) does.

## 9. The easiest learning flows

### Easiest Foundry-only flow

Use tests first:

```bash
forge build
forge test -vvv
```

This is the fastest way to learn because the test environment already creates what the hook needs.

### Easiest local ecosystem flow

Use a fork:

```bash
anvil --fork-url <RPC_URL>

anvil --fork-url https://mainnet.unichain.org
```

## 10. Demo pool scripts in this repository

After you deploy `SimpleHook`, this repository now has four follow-up scripts for a full local learning flow:

1. Create a demo pool that uses the latest deployed hook
2. Add or remove liquidity
3. Execute a swap
4. Read the hook's stored state

They share state through:

```text
deployments/<chainId>/demo-pool.json
```

This file is generated locally and ignored by git.

### A. Create the demo pool

This script:

- reads the latest hook address from `broadcast/01_DeploySimpleHook.s.sol/<chainId>/run-latest.json`
- deploys two local mock ERC-20 tokens
- deploys helper router contracts for liquidity and swaps
- initializes a pool that points at your hook
- writes all important addresses to `deployments/<chainId>/demo-pool.json`

Run:

```bash
source .env
forge script script/02_CreateDemoPool.s.sol \
  --rpc-url local \
  --broadcast
```

Optional environment overrides:

```bash
HOOK_ADDRESS=<hook address>
POOL_FEE=3000
TICK_SPACING=60
SQRT_PRICE_X96=79228162514264337593543950336
```

### B. Add liquidity

Run:

```bash
source .env
forge script script/03_ModifyLiquidity.s.sol \
  --rpc-url local \
  --broadcast
```

Defaults:

- `LIQUIDITY_DELTA=1000000000000000000` adds liquidity
- `TICK_LOWER=-120`
- `TICK_UPPER=120`

To remove liquidity instead, use a negative delta:

```bash
source .env
LIQUIDITY_DELTA=-1000000000000000000 \
forge script script/03_ModifyLiquidity.s.sol \
  --rpc-url local \
  --broadcast
```

### C. Swap

Run:

```bash
source .env
forge script script/04_Swap.s.sol \
  --rpc-url local \
  --broadcast
```

Defaults:

- `ZERO_FOR_ONE=true`
- `SWAP_AMOUNT=1000000000000000000`

Example for swapping token1 to token0:

```bash
source .env
ZERO_FOR_ONE=false \
SWAP_AMOUNT=500000000000000000 \
forge script script/04_Swap.s.sol \
  --rpc-url local \
  --broadcast
```

### D. Read hook info

Run:

```bash
source .env
forge script script/05_ReadHookInfo.s.sol \
  --rpc-url local
```

This prints:

- the hook address
- the pool manager address
- the pool id
- `swapCount(poolId)`
- `lastRouter(poolId)`

### E. Important learning note

The demo liquidity position belongs to the saved helper router contract from `demo-pool.json`.

That is why:

- you should create the pool first
- then modify liquidity using the saved router
- and not replace `deployments/<chainId>/demo-pool.json` in the middle of the flow unless you intentionally want a new setup

## 11. Resetting local state after restarting Anvil

When you restart `anvil`, deployed contracts on the local chain disappear, but your local project files still remain.

That means old files such as:

- `deployments/<chainId>/demo-pool.json`
- `broadcast/.../run-latest.json`

may point to contracts that no longer exist on the new local chain.

This repository includes a helper script:

```bash
./reset-local.sh
```

Default behavior:

- removes `deployments/`
- keeps `broadcast/`
- keeps build artifacts

For a full reset:

```bash
./reset-local.sh --full
```

Full mode also removes:

- `broadcast/`
- `cache/`
- `out/`

This is useful when you want to start a completely fresh local learning cycle.

````

Then run scripts against the fork.

### Easiest clean-room flow

Use a fresh local node:

```bash
anvil
````

Then deploy every dependency yourself.

This is more educational, but also more work.

## 10. Recommended `.env` workflow for this repo

1. Start Anvil:

```bash
anvil
```

2. Copy the example env file:

```bash
cp .env.example .env
```

3. Put your local values into `.env`

For a local Anvil deployment, that usually means:

- `ETH_RPC_URL=http://127.0.0.1:8545`
- `PRIVATE_KEY=<one of Anvil's test private keys>`
- `POOL_MANAGER=<an already deployed PoolManager address>`

4. Load the variables:

```bash
source .env
```

5. Run the script:

```bash
forge script script/01_DeploySimpleHook.s.sol \
  --rpc-url local \
  --broadcast
```

For a real network, prefer a keystore over a raw private key in `.env`.

## 11. If you see stale artifact warnings

If Foundry says artifacts were built from files that no longer exist, run:

```bash
forge clean
```

Then rebuild or rerun the script:

```bash
forge build
```

This often happens after removing files or dependencies from the repository.

## 12. Useful commands to remember

### Start local node

```bash
anvil
```

### Start forked local node

```bash
anvil --fork-url <RPC_URL>
```

### Check the node

```bash
cast block-number --rpc-url http://127.0.0.1:8545
```

### Build

```bash
forge build
```

### Run tests

```bash
forge test -vvv
```

### Deploy with a script

```bash
source .env
forge script script/01_DeploySimpleHook.s.sol \
  --rpc-url local \
  --broadcast
```

## 13. Recommended next step

If you are new to Foundry, the best next step in this repository is:

1. run `anvil` in one terminal
2. run `forge test -vvv` in another terminal
3. read `test/SimpleHook.t.sol`
4. then we can add one more tiny hook feature and test it together

## 14. Short answer

Yes, a local Foundry node can be used with the Uniswap ecosystem.

You have two choices:

- create a fresh local chain and deploy the Uniswap pieces yourself
- fork a real chain and reuse the existing ecosystem locally

For most learning and debugging tasks, a fork is the easier option.
