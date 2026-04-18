# Uniswap v4 Hook Playground

This repository contains a minimal Foundry-based learning project for getting started with Uniswap v4 hooks.

The first hook in the project is [`SimpleHook.sol`](/src/SimpleHook.sol).

What it does:

- listens only to `afterSwap`
- counts swaps for each pool
- stores the router address that triggered the swap
- does not change price, fees, or deltas, so it is a safe starting point

## What matters about v4 hooks

1. A hook is a regular smart contract, but Uniswap v4 calls its callbacks at specific points in the pool lifecycle.
2. Which callbacks can be called is encoded in the contract address itself.
3. Because of that, you cannot deploy a hook to just any address and expect `afterSwap` to work.
4. This project includes [`01_DeploySimpleHook.s.sol`](/script/01_DeploySimpleHook.s.sol), which finds a valid salt with `HookMiner`.

## Quick start

You already have Foundry installed, so the basic workflow is:

```bash
forge build
forge test -vv
```

If you want more detail:

```bash
forge test --match-contract SimpleHookTest -vvvv
```

## Environment setup

Copy the example environment file:

```bash
cp .env.example .env
```

Then fill in:

```bash
ETH_RPC_URL=http://127.0.0.1:8545
PRIVATE_KEY=<YOUR_PRIVATE_KEY>
POOL_MANAGER=<POOL_MANAGER_ADDRESS>
```

This project maps `ETH_RPC_URL` to the named Foundry RPC endpoint `local`, so the scripts below can be run with:

```bash
source .env
```

## Script flow

These scripts are meant to be run in order.

### 1. Deploy the hook

This deploys `SimpleHook` with the correct Uniswap v4 hook permission bits:

```bash
source .env
forge script script/01_DeploySimpleHook.s.sol --rpc-url local --broadcast
```

The latest hook deployment is written to:

```text
broadcast/01_DeploySimpleHook.s.sol/<chainId>/run-latest.json
```

### 2. Create a demo pool

This script:

- reads the latest hook address from the last hook deployment
- deploys two local mock ERC-20 tokens
- deploys helper router contracts for liquidity and swaps
- initializes a demo pool that uses your hook
- writes all state to `deployments/<chainId>/demo-pool.json`

Run:

```bash
source .env
forge script script/02_CreateDemoPool.s.sol --rpc-url local --broadcast
```

Optional overrides:

```bash
HOOK_ADDRESS=<hook address>
POOL_FEE=3000
TICK_SPACING=60
SQRT_PRICE_X96=79228162514264337593543950336
```

If `HOOK_ADDRESS` is not set, the script uses the most recent hook deployment automatically.

### 3. Add liquidity

By default, this adds `1e18` liquidity to the demo pool:

```bash
source .env
forge script script/03_ModifyLiquidity.s.sol --rpc-url local --broadcast
```

Useful overrides:

```bash
LIQUIDITY_DELTA=1000000000000000000
TICK_LOWER=-120
TICK_UPPER=120
```

To remove liquidity instead, use a negative delta:

```bash
source .env
LIQUIDITY_DELTA=-1000000000000000000 \
forge script script/03_ModifyLiquidity.s.sol --rpc-url local --broadcast
```

### 4. Execute a swap

By default, this performs an exact-input swap from token0 to token1:

```bash
source .env
forge script script/04_Swap.s.sol --rpc-url local --broadcast
```

Useful overrides:

```bash
ZERO_FOR_ONE=true
SWAP_AMOUNT=1000000000000000000
```

Example for swapping token1 to token0:

```bash
source .env
ZERO_FOR_ONE=false \
SWAP_AMOUNT=500000000000000000 \
forge script script/04_Swap.s.sol --rpc-url local --broadcast
```

### 5. Read hook state

This prints the stored information for the saved demo pool:

```bash
source .env
forge script script/05_ReadHookInfo.s.sol --rpc-url local
```

You will see:

- the hook address
- the pool manager address
- the pool id
- `swapCount(poolId)`
- `lastRouter(poolId)`

## Reset local state

If you restart `anvil`, your local chain state is gone, but local files like `broadcast/` and `deployments/` may still point to old addresses.

This repository includes a small reset script:

```bash
./reset-local.sh
```

Default behavior:

- removes `deployments/`
- keeps `broadcast/` history
- keeps build artifacts

For a full local reset:

```bash
./reset-local.sh --full
```

Full mode also removes:

- `broadcast/`
- `cache/`
- `out/`

## How to read this project

1. Start with [`SimpleHook.sol`](/src/SimpleHook.sol).
2. Then open [`SimpleHook.t.sol`](/test/SimpleHook.t.sol).
3. Inside the test, focus on these four steps: bootstrapping the local Uniswap v4 stack, creating a pool, adding liquidity, and executing a swap.
4. Look at how the test verifies that `afterSwap` was actually called.
5. After that, run the tests and start changing the hook yourself.
6. First, try adding a new event.
7. Then try storing the last `amountSpecified`.
8. After that, enable `beforeSwap`.

## Mini Foundry cheat sheet

- `foundryup`: install or update the stable versions of `forge`, `cast`, `anvil`, and `chisel`
- `foundryup -U`: update the `foundryup` installer itself
- `foundryup -l`: list installed versions
- `foundryup -i nightly`: install the nightly build if you want to compare it with stable
- `forge build`: compile the project
- `forge test -vv`: run the tests
- `forge script ... --broadcast`: execute a deployment or script
- `anvil`: start a local EVM network
- `cast`: CLI for reading chain state, calling contracts, and working with wallets

## Why there is no `hookmate`

This project intentionally avoids the `hookmate` dependency.
The hook itself depends only on official Uniswap/OpenZeppelin libraries, and the tests use official Uniswap v4 test utilities.

## Next step

Once this project feels clear, a good learning path is:

1. `beforeSwap`
2. `beforeAddLiquidity` / `beforeRemoveLiquidity`
3. `HookMiner` and address flags
4. `hookData`
5. only then hooks with delta accounting
