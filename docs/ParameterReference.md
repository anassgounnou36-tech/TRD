# Parameter Reference

## General
- `InpSymbol` (default `"XAUUSD"`): trade symbol
- `InpMagic` (26032026): EA magic number
- `InpEnableLongs` (true): allow long entries
- `InpEnableShorts` (true): allow short entries
- `InpEnableChartPanel` (true): show chart status panel
- `InpEnableFileLogs` (true): write CSV logs in common files
- `InpSlippagePoints` (100): max deviation in points

## Timeframes
- `InpSignalTF` (`PERIOD_H1`): execution timeframe
- `InpRegimeTF` (`PERIOD_H4`): regime timeframe

## Trend / Signal
- `InpRegimeEMAPeriod` (200)
- `InpSessionStartHour` (8)
- `InpSessionStartMinute` (0)
- `InpOpeningRangeMinutes` (60)
- `InpATRPeriod` (14)
- `InpBreakoutBufferATRFrac` (0.10)

## Stops / Exits
- `InpInitialStopATR` (2.5)
- `InpSwingStopLookback` (10)
- `InpStopBufferATRFrac` (0.20)
- `InpTrailATRFrac` (3.0)
- `InpExitOnRegimeFlip` (true)

## Risk
- `InpRiskPct` (0.50)
- `InpMaxDailyLossPct` (2.0)
- `InpAllowMinVolumeOverride` (false)
- `InpDailyLossUseEquity` (true)
- `InpForceCloseOnDailyKill` (true)
- `InpMaxSessionTrades` (1)

## Filters
- `InpMaxSpreadATRFrac` (0.08)
- `InpCooldownBarsAfterExit` (2)
- `InpUseRolloverBlock` (false)
- `InpRolloverStartHour` (22)
- `InpRolloverStartMinute` (0)
- `InpRolloverEndHour` (23)
- `InpRolloverEndMinute` (5)
