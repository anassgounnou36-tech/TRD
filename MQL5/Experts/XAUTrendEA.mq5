#property strict
#property version   "1.00"
#property description "XAU Trend Breakout EA"

#include <Trade/Trade.mqh>

#include "../Include/XAUTrend/Config.mqh"
#include "../Include/XAUTrend/Types.mqh"
#include "../Include/XAUTrend/BarUtils.mqh"
#include "../Include/XAUTrend/IndicatorEngine.mqh"
#include "../Include/XAUTrend/RegimeFilter.mqh"
#include "../Include/XAUTrend/BreakoutSignal.mqh"
#include "../Include/XAUTrend/RiskModel.mqh"
#include "../Include/XAUTrend/ExecutionEngine.mqh"
#include "../Include/XAUTrend/PositionManager.mqh"
#include "../Include/XAUTrend/Diagnostics.mqh"
#include "../Include/XAUTrend/Journal.mqh"
#include "../Include/XAUTrend/ChartPanel.mqh"

CTrade            g_trade;
XAURuntimeState   g_state;
XAUIndicatorState g_indicators;
string            g_symbol;
const int         XAU_MIN_HISTORY_BUFFER=20;

void ResetRuntimeState()
  {
   g_state.last_h1_bar_time=0;
   g_state.last_h4_bar_time=0;
   g_state.last_signal_bar_time=0;
   g_state.last_exit_bar_time=0;
   g_state.day_start_time=0;
   g_state.day_start_equity=0.0;
   g_state.trading_suspended_for_day=false;
   g_state.regime=XAU_REGIME_NEUTRAL;
   g_state.blocker_reason="";
   XAU_ClearTradeState(g_state.trade);
  }

int OnInit()
  {
   ResetRuntimeState();
   g_symbol=(InpSymbol=="" ? _Symbol : InpSymbol);

   if(!XAUJournal::Init(InpEnableFileLogs,g_symbol,InpMagic))
      return(INIT_FAILED);

   XAUJournal::Log("INFO",StringFormat("Initializing on chart=%s trade_symbol=%s",_Symbol,g_symbol));

   if(Bars(g_symbol,InpSignalTF)<(InpBreakoutLookback+XAU_MIN_HISTORY_BUFFER) || Bars(g_symbol,InpRegimeTF)<(InpRegimeEMAPeriod+XAU_MIN_HISTORY_BUFFER))
     {
      XAUJournal::Log("ERROR","Insufficient history for strategy startup");
      return(INIT_FAILED);
     }

   string err="";
   if(!XAU_IndicatorInit(g_symbol,InpRegimeTF,InpRegimeEMAPeriod,InpSignalTF,InpATRPeriod,g_indicators,err))
     {
      XAUJournal::Log("ERROR",err);
      return(INIT_FAILED);
     }

   XAU_ConfigureTrade(g_trade,InpMagic,InpSlippagePoints,g_symbol);

   XAUPositionSnapshot snap;
   XAU_FindOpenPosition(g_symbol,InpMagic,snap);
   if(snap.found)
     {
      XAU_RebuildTradeStateFromPosition(g_symbol,InpSignalTF,snap,g_state.trade);
      XAUJournal::Log("INFO",StringFormat("Recovered live position ticket=%I64u direction=%s",
                                            snap.ticket,
                                            XAU_SignalToString(g_state.trade.direction)));
     }

   const datetime now=TimeTradeServer();
   XAU_ResetDayIfNeeded(g_state,now);
   g_state.last_h1_bar_time=iTime(g_symbol,InpSignalTF,0);
   g_state.last_h4_bar_time=iTime(g_symbol,InpRegimeTF,0);

   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(InpEnableChartPanel)
      Comment("");
   XAU_IndicatorRelease(g_indicators);
   XAUJournal::Shutdown();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,const MqlTradeResult &result)
  {
   if(trans.symbol!=g_symbol)
      return;

   XAUJournal::Log("INFO",StringFormat("Trade transaction type=%d order=%I64u deal=%I64u retcode=%u",
                                         trans.type,result.order,result.deal,result.retcode));
  }

void ProcessBar()
  {
   g_state.blocker_reason="";
   const datetime now=TimeTradeServer();
   XAU_ResetDayIfNeeded(g_state,now);

   string env_reason="";
   if(!XAU_IsTradeEnvironmentReady(g_symbol,env_reason))
     {
      g_state.blocker_reason=env_reason;
      XAUJournal::Log("WARN",env_reason);
      return;
     }

   double atr1=0.0;
   if(!XAU_GetATR(g_indicators,1,atr1) || atr1<=0.0)
     {
      g_state.blocker_reason="ATR invalid";
      XAUJournal::Log("WARN","ATR invalid or unavailable");
      return;
     }

   string regime_reason="";
   g_state.regime=XAU_ComputeRegime(g_symbol,InpRegimeTF,g_indicators,regime_reason);

   double dd_pct=0.0;
   const bool daily_kill=XAU_IsDailyKillTriggered(g_state,InpMaxDailyLossPct,dd_pct);

   XAUPositionSnapshot snap;
   XAU_FindOpenPosition(g_symbol,InpMagic,snap);
   g_state.trade.has_position=snap.found;
   if(snap.found)
      XAU_RebuildTradeStateFromPosition(g_symbol,InpSignalTF,snap,g_state.trade);

   bool exited_this_cycle=false;
   if(g_state.trade.has_position)
     {
      if(daily_kill && InpForceCloseOnDailyKill)
        {
         string close_reason="";
         if(XAU_ClosePosition(g_trade,g_symbol,InpSlippagePoints,close_reason))
           {
            XAUJournal::Log("WARN",StringFormat("Daily kill close executed: day_dd=%.2f%%",dd_pct));
            g_state.last_exit_bar_time=iTime(g_symbol,InpSignalTF,0);
            XAU_ClearTradeState(g_state.trade);
            exited_this_cycle=true;
           }
         else
            XAUJournal::Log("ERROR",StringFormat("Daily kill close failed: %s",close_reason));
        }

      if(!exited_this_cycle && InpExitOnRegimeFlip)
        {
         const bool long_flip=(g_state.trade.direction==XAU_SIGNAL_LONG && g_state.regime==XAU_REGIME_SHORT);
         const bool short_flip=(g_state.trade.direction==XAU_SIGNAL_SHORT && g_state.regime==XAU_REGIME_LONG);
         if(long_flip || short_flip)
           {
            string close_reason="";
            if(XAU_ClosePosition(g_trade,g_symbol,InpSlippagePoints,close_reason))
              {
               XAUJournal::Log("INFO",StringFormat("Closed on regime flip (%s)",XAU_RegimeToString(g_state.regime)));
               g_state.last_exit_bar_time=iTime(g_symbol,InpSignalTF,0);
               XAU_ClearTradeState(g_state.trade);
               exited_this_cycle=true;
              }
            else
               XAUJournal::Log("ERROR",StringFormat("Regime flip close failed: %s",close_reason));
           }
        }

      if(!exited_this_cycle)
        {
         XAU_UpdateExtremesFromClosedBar(g_symbol,InpSignalTF,g_state.trade);
         const double trail_stop=XAU_ComputeTrailingStop(g_symbol,g_state.trade.direction,g_state.trade,atr1,InpTrailATR);
         double target_sl=g_state.trade.stop_loss;

         if(g_state.trade.direction==XAU_SIGNAL_LONG)
            target_sl=MathMax(g_state.trade.stop_loss,trail_stop);
         else if(g_state.trade.direction==XAU_SIGNAL_SHORT)
            target_sl=(g_state.trade.stop_loss==0.0 ? trail_stop : MathMin(g_state.trade.stop_loss,trail_stop));

         if(target_sl>0.0 && target_sl!=g_state.trade.stop_loss)
           {
            string sl_reason="";
            if(XAU_ModifyStop(g_trade,g_symbol,target_sl,sl_reason))
              {
               g_state.trade.stop_loss=target_sl;
               XAUJournal::Log("INFO",StringFormat("Trailing SL updated to %.5f",target_sl));
              }
            else
               XAUJournal::Log("ERROR",StringFormat("Trailing modify failed: %s",sl_reason));
           }
        }
     }

   if(exited_this_cycle)
      return;

   if(g_state.trade.has_position)
      return;

   if(daily_kill || g_state.trading_suspended_for_day)
     {
      g_state.blocker_reason=StringFormat("Daily kill active (dd=%.2f%%)",dd_pct);
      return;
     }

   if(InpUseRolloverBlock && XAU_IsWithinRolloverWindow(now,InpRolloverStartHour,InpRolloverStartMinute,InpRolloverEndHour,InpRolloverEndMinute))
     {
      g_state.blocker_reason="Rollover block active";
      return;
     }

   if(XAU_IsCooldownActive(g_symbol,InpSignalTF,g_state.last_exit_bar_time,InpCooldownBarsAfterExit))
     {
      g_state.blocker_reason="Cooldown active";
      return;
     }

   double spread=0.0;
   if(!XAU_IsSpreadAcceptable(g_symbol,atr1,InpMaxSpreadATRFrac,spread))
     {
      g_state.blocker_reason=StringFormat("Spread too high %.5f",spread);
      return;
     }

   XAUSignalDecision sig=XAU_EvaluateBreakoutSignal(g_symbol,InpSignalTF,g_state.regime,InpBreakoutLookback,atr1,InpBreakoutBufferATRFrac);
   if(sig.signal==XAU_SIGNAL_NONE)
     {
      g_state.blocker_reason="No breakout signal";
      return;
     }

   if((sig.signal==XAU_SIGNAL_LONG && !InpEnableLongs) || (sig.signal==XAU_SIGNAL_SHORT && !InpEnableShorts))
     {
      g_state.blocker_reason="Direction disabled by input";
      return;
     }

   const datetime signal_bar_time=iTime(g_symbol,InpSignalTF,1);
   if(g_state.last_signal_bar_time==signal_bar_time)
     {
      g_state.blocker_reason="Signal already traded this bar";
      return;
     }

   MqlTick tick;
   if(!SymbolInfoTick(g_symbol,tick))
     {
      g_state.blocker_reason="No live tick";
      return;
     }

   const ENUM_ORDER_TYPE order_type=(sig.signal==XAU_SIGNAL_LONG ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   const double entry_price=(order_type==ORDER_TYPE_BUY ? tick.ask : tick.bid);
   const double stop_price=XAU_ComputeInitialStop(g_symbol,InpSignalTF,sig.signal,entry_price,atr1,InpInitialStopATR,InpSwingStopLookback,InpStopBufferATRFrac);

   string stop_reason="";
   if(!XAU_CheckStopDistance(g_symbol,order_type,entry_price,stop_price,stop_reason))
     {
      g_state.blocker_reason=stop_reason;
      XAUJournal::Log("WARN",stop_reason);
      return;
     }

   double risk_per_lot=0.0;
   double risk_target=0.0;
   string vol_reason="";
   const double volume=XAU_ComputeRiskVolume(g_symbol,order_type,entry_price,stop_price,InpRiskPct,vol_reason,risk_per_lot,risk_target);
   if(volume<=0.0)
     {
      g_state.blocker_reason=vol_reason;
      XAUJournal::Log("WARN",StringFormat("Volume blocked: %s",vol_reason));
      return;
     }

   string check_reason="";
   if(!XAU_PreflightOrderCheck(g_symbol,InpMagic,order_type,volume,entry_price,stop_price,InpSlippagePoints,check_reason))
     {
      g_state.blocker_reason=check_reason;
      XAUJournal::Log("WARN",check_reason);
      return;
     }

   XAUJournal::Log("INFO",StringFormat("Entry setup signal=%s regime=%s close1=%.5f breakoutH=%.5f breakoutL=%.5f atr=%.5f stop=%.5f vol=%.2f riskCash=%.2f",
                                         XAU_SignalToString(sig.signal),XAU_RegimeToString(g_state.regime),
                                         sig.signal_close,sig.breakout_high,sig.breakout_low,atr1,stop_price,volume,risk_target));

   string open_reason="";
   if(!XAU_OpenPosition(g_trade,g_symbol,order_type,volume,stop_price,"XAUTrend",open_reason))
     {
      XAUJournal::Log("ERROR",open_reason);
      g_state.blocker_reason=open_reason;
      return;
     }

   XAU_FindOpenPosition(g_symbol,InpMagic,snap);
   if(snap.found)
      XAU_RebuildTradeStateFromPosition(g_symbol,InpSignalTF,snap,g_state.trade);

   g_state.last_signal_bar_time=signal_bar_time;
   g_state.blocker_reason="";
  }

void OnTick()
  {
   datetime new_h1_bar=0;
   if(!XAU_IsNewBar(g_symbol,InpSignalTF,g_state.last_h1_bar_time,new_h1_bar))
      return;

   ProcessBar();

   double atr=0.0;
   double spread=0.0;
   double dd=0.0;
   XAU_GetATR(g_indicators,1,atr);
   XAU_IsSpreadAcceptable(g_symbol,MathMax(atr,0.00001),InpMaxSpreadATRFrac,spread);
   dd=XAU_DailyDrawdownPct(g_state);
   XAU_UpdateChartPanel(InpEnableChartPanel,g_symbol,g_state,atr,spread,dd);
  }
