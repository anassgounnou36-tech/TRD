# Runbook

## Installation
1. Copy files into MT5 data folder:
   - `MQL5/Experts/XAUTrendEA.mq5`
   - `MQL5/Include/XAUTrend/*`
   - `MQL5/Scripts/*`
2. Open MetaEditor and compile EA and scripts.

## Attach EA
1. Open XAUUSD H1 chart
2. Drag `XAUTrendEA` onto chart
3. Load desired preset (`sets/*.set`)
4. Enable Algo Trading

## Interpreting outputs
- Journal logs include blocker reasons, order-check failures, trade and SL lifecycle
- Optional chart panel shows regime, spread/ATR, daily DD, and active blocker

## Restart behavior
- On init, EA checks existing live position for symbol+magic
- If found, runtime trade state is reconstructed from live position and history
- Daily protection state resets automatically on broker day rollover
