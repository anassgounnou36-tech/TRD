#ifndef __CHARTPANEL_MQH__
#define __CHARTPANEL_MQH__

#include "Types.mqh"
#include "Diagnostics.mqh"

void XAU_UpdateChartPanel(const bool enabled,
                          const string symbol,
                          const XAURuntimeState &state,
                          const double atr,
                          const double spread,
                          const double daily_dd)
  {
   if(!enabled)
      return;

   string lines="";
   lines+="XAU Trend Breakout EA\n";
   lines+=StringFormat("Symbol: %s\n",symbol);
   lines+=StringFormat("Regime: %s\n",XAU_RegimeToString(state.regime));
   lines+=StringFormat("OR Built: %s | OR High/Low: %.5f / %.5f\n",(state.or_built?"YES":"NO"),state.or_high,state.or_low);
   lines+=StringFormat("Setup Candidate: %s | Session Trades: %d\n",(state.setup_candidate==""?"none":state.setup_candidate),state.session_trades_used);
   lines+=StringFormat("Open Position: %s\n",(state.trade.has_position?XAU_SignalToString(state.trade.direction):"FLAT"));
   lines+=StringFormat("ATR: %.5f | Spread: %.5f\n",atr,spread);
   lines+=StringFormat("Day DD: %.2f%% | Daily Blocker: %s\n",daily_dd,(state.daily_blocker_reason==""?"none":state.daily_blocker_reason));
   lines+=StringFormat("Suspended: %s\n",(state.trading_suspended_for_day?"YES":"NO"));
   lines+=StringFormat("Blocker: %s",(state.blocker_reason==""?"none":state.blocker_reason));
   Comment(lines);
  }

#endif // __CHARTPANEL_MQH__
