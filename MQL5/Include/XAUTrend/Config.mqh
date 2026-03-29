#ifndef __CONFIG_MQH__
#define __CONFIG_MQH__

input string InpSymbol = _Symbol;
input ulong  InpMagic = 26032026;
input bool   InpEnableLongs = true;
input bool   InpEnableShorts = true;
input bool   InpEnableChartPanel = true;
input bool   InpEnableFileLogs = true;
input int    InpSlippagePoints = 100;

input ENUM_TIMEFRAMES InpSignalTF = PERIOD_H1;
input ENUM_TIMEFRAMES InpRegimeTF = PERIOD_H4;

input int    InpRegimeEMAPeriod = 200;
input int    InpBreakoutLookback = 55;
input int    InpATRPeriod = 14;
input double InpBreakoutBufferATRFrac = 0.10;

input double InpInitialStopATR = 2.5;
input int    InpSwingStopLookback = 10;
input double InpStopBufferATRFrac = 0.20;
input double InpTrailATR = 3.0;
input bool   InpExitOnRegimeFlip = true;

input double InpRiskPct = 0.50;
input double InpMaxDailyLossPct = 2.0;
input bool   InpForceCloseOnDailyKill = true;

input double InpMaxSpreadATRFrac = 0.08;
input int    InpCooldownBarsAfterExit = 2;
input bool   InpUseRolloverBlock = false;
input int    InpRolloverStartHour = 22;
input int    InpRolloverStartMinute = 0;
input int    InpRolloverEndHour = 23;
input int    InpRolloverEndMinute = 5;

#endif // __CONFIG_MQH__
