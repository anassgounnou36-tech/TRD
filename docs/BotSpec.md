# XAU Trend Breakout EA Spec

## Strategy summary
A single-strategy, pure MQL5 trend-following EA for gold symbols (default chart symbol via `_Symbol`).

- Regime filter: H4 close vs EMA(200) with EMA slope confirmation
- Trigger: H1 breakout on completed bars only
- Position sizing: fixed-fractional with `OrderCalcProfit` cash-risk estimation
- Exits: ATR/structure initial stop + Chandelier-style trailing stop + optional hard regime-flip exit
- Protection: spread filter, cooldown, optional rollover block, daily loss kill-switch

## Entry logic
- Long regime: `H4 close[1] > EMA200[1]` and `EMA200[1] > EMA200[2]`
- Short regime: `H4 close[1] < EMA200[1]` and `EMA200[1] < EMA200[2]`
- Long signal: `H1 Close[1] > highest(H1 High[2..N+1]) + 0.10*ATR[1]`
- Short signal: `H1 Close[1] < lowest(H1 Low[2..N+1]) - 0.10*ATR[1]`

## Exit logic
- No fixed TP
- Initial SL uses farther of ATR or structure candidate
- Trailing SL updates once per new H1 bar in favorable direction only
- Optional hard close on opposite regime flip

## Risk and protections
- One position max for this EA/symbol
- Risk per trade based on equity percent
- Daily drawdown suspension with optional forced flattening
- Trade blocked if spread is high or constraints/checks fail

## Assumptions
- Intended first deployment: XAUUSD H1 chart
- Broker symbol suffixes supported by using configurable symbol defaulting to chart symbol

## Known limitations
- Chart panel is informational only and not required for strategy logic
