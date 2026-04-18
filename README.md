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
4. This project includes [`DeploySimpleHook.s.sol`](/script/DeploySimpleHook.s.sol), which finds a valid salt with `HookMiner`.

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

## How to run a deployment script

This repository now avoids third-party local deployment helpers and keeps deployment scripts minimal.
The script expects an existing Uniswap v4 `PoolManager` address in the environment:

```bash
export POOL_MANAGER=<POOL_MANAGER_ADDRESS>

forge script script/DeploySimpleHook.s.sol \
  --rpc-url <RPC_URL> \
  --private-key <PRIVATE_KEY> \
  --broadcast
```

```bash
source .env
forge script script/DeploySimpleHook.s.sol --rpc-url local --broadcast
```

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
