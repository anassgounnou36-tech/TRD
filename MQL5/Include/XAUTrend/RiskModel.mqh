#ifndef __RISKMODEL_MQH__
#define __RISKMODEL_MQH__

#include "Types.mqh"
#include "BarUtils.mqh"

const double XAU_VOLUME_STEP_TOLERANCE=1e-9;

void XAU_ResetDayIfNeeded(XAURuntimeState &state,const datetime now)
  {
   const datetime day_start=XAU_BrokerDayStart(now);
   if(state.day_start_time!=day_start || state.day_start_equity<=0.0)
     {
      state.day_start_time=day_start;
      state.day_start_equity=AccountInfoDouble(ACCOUNT_EQUITY);
      state.day_start_balance=AccountInfoDouble(ACCOUNT_BALANCE);
      state.trading_suspended_for_day=false;
     }
  }

double XAU_DailyDrawdownPct(const XAURuntimeState &state,const bool use_equity)
  {
   const double day_start=(use_equity ? state.day_start_equity : state.day_start_balance);
   if(day_start<=0.0)
      return(0.0);
   const double current=(use_equity ? AccountInfoDouble(ACCOUNT_EQUITY) : AccountInfoDouble(ACCOUNT_BALANCE));
   return((day_start-current)/day_start*100.0);
  }

bool XAU_IsDailyKillTriggered(XAURuntimeState &state,const double max_daily_loss_pct,const bool use_equity,double &dd_pct)
  {
   dd_pct=XAU_DailyDrawdownPct(state,use_equity);
   if(dd_pct>=max_daily_loss_pct)
     {
      state.trading_suspended_for_day=true;
      return(true);
     }
   return(false);
  }

bool XAU_IsSpreadAcceptable(const string symbol,const double atr_value,const double max_spread_atr_frac,double &spread_price)
  {
   spread_price=0.0;
   MqlTick tick;
   if(!SymbolInfoTick(symbol,tick))
      return(false);

   spread_price=tick.ask-tick.bid;
   if(atr_value<=0.0)
      return(false);

   return(spread_price<=(max_spread_atr_frac*atr_value));
  }

bool XAU_IsCooldownActive(const string symbol,const ENUM_TIMEFRAMES tf,const datetime last_exit_bar,const int cooldown_bars)
  {
   if(cooldown_bars<=0 || last_exit_bar<=0)
      return(false);
   const int bars_since_exit=XAU_BarsSinceTime(symbol,tf,last_exit_bar);
   return(bars_since_exit<=cooldown_bars);
  }

double XAU_NormalizeVolumeDown(const string symbol,const double raw)
  {
   const double vmin=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   const double vmax=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   const double step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
   if(vmin<=0.0 || vmax<=0.0 || step<=0.0)
      return(0.0);

   if(raw<vmin)
      return(0.0);

   const double capped=MathMin(raw,vmax);
   const double steps=MathFloor((capped-vmin)/step+XAU_VOLUME_STEP_TOLERANCE);
   double volume=vmin+steps*step;
   volume=MathMax(vmin,MathMin(vmax,volume));

   int digits=0;
   double tmp=step;
   while(digits<8 && MathRound(tmp)!=tmp)
     {
      tmp*=10.0;
      digits++;
     }

   return(NormalizeDouble(volume,digits));
  }

double XAU_ComputeRiskVolume(const string symbol,
                             const ENUM_ORDER_TYPE order_type,
                             const double entry_price,
                             const double stop_price,
                             const double risk_pct,
                             const bool allow_min_override,
                             string &reason,
                             double &risk_per_lot_cash,
                             double &risk_cash_target)
  {
   reason="";
   risk_per_lot_cash=0.0;
   risk_cash_target=0.0;

   const double equity=AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity<=0.0 || risk_pct<=0.0)
     {
      reason="Invalid equity or risk percent";
      return(0.0);
     }

   double profit_for_one_lot=0.0;
   if(!OrderCalcProfit(order_type,symbol,1.0,entry_price,stop_price,profit_for_one_lot))
     {
      reason=StringFormat("OrderCalcProfit failed (%d)",GetLastError());
      return(0.0);
     }

   risk_per_lot_cash=MathAbs(profit_for_one_lot);
   if(risk_per_lot_cash<=0.0)
     {
      reason="Calculated risk per lot is zero";
      return(0.0);
     }

    risk_cash_target=equity*risk_pct/100.0;
   const double raw_volume=risk_cash_target/risk_per_lot_cash;
   const double vmin=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   if(vmin>0.0 && raw_volume<vmin)
     {
      if(!allow_min_override)
        {
         reason=StringFormat("Raw volume below symbol minimum (raw=%.6f min=%.6f)",raw_volume,vmin);
         return(0.0);
        }
      reason=StringFormat("WARNING: min-volume override active (raw=%.6f min=%.6f)",raw_volume,vmin);
     }
   const double volume=XAU_NormalizeVolumeDown(symbol,raw_volume);

   if(volume<=0.0)
      reason=StringFormat("Normalized volume below min (raw=%.6f)",raw_volume);

   return(volume);
  }

#endif // __RISKMODEL_MQH__
