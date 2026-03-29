#pragma once

#include <Trade/Trade.mqh>

bool XAU_ResolveFillingType(const string symbol,ENUM_ORDER_TYPE_FILLING &filling)
  {
   long fill_flags=0;
   if(!SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE,fill_flags))
      return(false);

   if((fill_flags & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK)
     {
      filling=ORDER_FILLING_FOK;
      return(true);
     }
   if((fill_flags & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC)
     {
      filling=ORDER_FILLING_IOC;
      return(true);
     }
   filling=ORDER_FILLING_RETURN;
   return(true);
  }

void XAU_ConfigureTrade(CTrade &trade,const ulong magic,const int slippage_points,const string symbol)
  {
   trade.SetExpertMagicNumber(magic);
   trade.SetDeviationInPoints(slippage_points);
   trade.SetTypeFillingBySymbol(symbol);
   trade.SetAsyncMode(false);
  }

bool XAU_CheckStopDistance(const string symbol,const ENUM_ORDER_TYPE order_type,const double entry,const double stop,string &reason)
  {
   reason="";
   const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   const long stops_level=SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const double min_distance=stops_level*point;

   if(order_type==ORDER_TYPE_BUY)
     {
      if(stop<=0.0 || (entry-stop)<min_distance)
        {
         reason=StringFormat("Buy SL violates stop level (min_distance=%.5f)",min_distance);
         return(false);
        }
     }
   else if(order_type==ORDER_TYPE_SELL)
     {
      if(stop<=0.0 || (stop-entry)<min_distance)
        {
         reason=StringFormat("Sell SL violates stop level (min_distance=%.5f)",min_distance);
         return(false);
        }
     }

   return(true);
  }

bool XAU_IsStopModificationAllowed(const string symbol,
                                   const ENUM_POSITION_TYPE position_type,
                                   const double current_sl,
                                   const double proposed_sl,
                                   double &normalized_sl_out,
                                   string &reason)
  {
   reason="";
   normalized_sl_out=0.0;

   const int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   if(point<=0.0)
     {
      reason="Invalid symbol point";
      return(false);
     }

   const double normalized_sl=NormalizeDouble(proposed_sl,digits);
   normalized_sl_out=normalized_sl;
   const double normalized_current=NormalizeDouble(current_sl,digits);
   if(normalized_sl<=0.0)
     {
      reason="Proposed SL invalid";
      return(false);
     }

   if(MathAbs(normalized_sl-normalized_current)<(0.5*point))
     {
      reason="Proposed SL unchanged after normalization";
      return(false);
     }

   MqlTick tick;
   if(!SymbolInfoTick(symbol,tick))
     {
      reason="No tick for SL legality check";
      return(false);
     }

   const long stops_level=SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const long freeze_level=SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   const double min_stop_distance=stops_level*point;
   const double freeze_distance=freeze_level*point;

   if(position_type==POSITION_TYPE_BUY)
     {
      const double distance=tick.bid-normalized_sl;
      if(distance<min_stop_distance)
        {
         reason=StringFormat("Trailing SL skipped: below stops level distance %.5f",distance);
         return(false);
        }
      if(distance<freeze_distance)
        {
         reason=StringFormat("Trailing SL skipped: inside freeze level distance %.5f",distance);
         return(false);
        }
      if(normalized_current>0.0 && normalized_sl<=normalized_current)
        {
         reason="Trailing SL not favorable for long";
         return(false);
        }
     }
   else if(position_type==POSITION_TYPE_SELL)
     {
      const double distance=normalized_sl-tick.ask;
      if(distance<min_stop_distance)
        {
         reason=StringFormat("Trailing SL skipped: below stops level distance %.5f",distance);
         return(false);
        }
      if(distance<freeze_distance)
        {
         reason=StringFormat("Trailing SL skipped: inside freeze level distance %.5f",distance);
         return(false);
        }
      if(normalized_current>0.0 && normalized_sl>=normalized_current)
        {
         reason="Trailing SL not favorable for short";
         return(false);
        }
     }

   return(true);
  }

bool XAU_PreflightOrderCheck(const string symbol,
                             const ulong magic,
                             const ENUM_ORDER_TYPE order_type,
                             const double volume,
                             const double price,
                             const double stop,
                             const int deviation_points,
                             string &reason)
  {
   reason="";

   MqlTradeRequest req;
   MqlTradeCheckResult check;
   ZeroMemory(req);
   ZeroMemory(check);

   req.action=TRADE_ACTION_DEAL;
   req.symbol=symbol;
   req.magic=magic;
   req.volume=volume;
   req.type=order_type;
   req.price=price;
   req.sl=stop;
   req.tp=0.0;
   req.deviation=deviation_points;
   req.type_time=ORDER_TIME_GTC;

   ENUM_ORDER_TYPE_FILLING filling;
   if(!XAU_ResolveFillingType(symbol,filling))
     {
      reason="OrderCheck blocked: unable to resolve symbol filling mode";
      return(false);
     }
   req.type_filling=filling;

   if(!OrderCheck(req,check))
     {
      reason=StringFormat("OrderCheck call failed (%d)",GetLastError());
      return(false);
     }

   if(check.retcode!=TRADE_RETCODE_DONE && check.retcode!=TRADE_RETCODE_PLACED)
     {
      long fill_flags=0;
      long trade_mode=0;
      SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE,fill_flags);
      SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE,trade_mode);
      reason=StringFormat("OrderCheck blocked: ret=%d comment=%s req_fill=%d sym_fill_flags=%d sym_trade_mode=%d",
                          check.retcode,check.comment,req.type_filling,(int)fill_flags,(int)trade_mode);
      return(false);
     }

   return(true);
  }

bool XAU_OpenPosition(CTrade &trade,
                      const string symbol,
                      const ENUM_ORDER_TYPE order_type,
                      const double volume,
                      const double stop,
                      const string comment,
                      string &reason)
  {
   reason="";
   bool ok=false;

   if(order_type==ORDER_TYPE_BUY)
      ok=trade.Buy(volume,symbol,0.0,stop,0.0,comment);
   else
      ok=trade.Sell(volume,symbol,0.0,stop,0.0,comment);

   const uint retcode=trade.ResultRetcode();
   const string retmsg=trade.ResultRetcodeDescription();

   if(!ok || (retcode!=TRADE_RETCODE_DONE && retcode!=TRADE_RETCODE_PLACED))
     {
      reason=StringFormat("Order send failed retcode=%u msg=%s order=%I64u deal=%I64u",
                          retcode,retmsg,trade.ResultOrder(),trade.ResultDeal());
      return(false);
     }

   return(true);
  }

bool XAU_ModifyStop(CTrade &trade,const string symbol,const double new_sl,string &reason)
  {
   reason="";
   const bool ok=trade.PositionModify(symbol,new_sl,0.0);
   const uint retcode=trade.ResultRetcode();
   if(!ok || (retcode!=TRADE_RETCODE_DONE && retcode!=TRADE_RETCODE_PLACED))
     {
      reason=StringFormat("PositionModify failed retcode=%u msg=%s",retcode,trade.ResultRetcodeDescription());
      return(false);
     }
   return(true);
  }

bool XAU_ClosePosition(CTrade &trade,const string symbol,const int deviation_points,string &reason)
  {
   reason="";
   const bool ok=trade.PositionClose(symbol,deviation_points);
   const uint retcode=trade.ResultRetcode();
   if(!ok || (retcode!=TRADE_RETCODE_DONE && retcode!=TRADE_RETCODE_PLACED))
     {
      reason=StringFormat("PositionClose failed retcode=%u msg=%s",retcode,trade.ResultRetcodeDescription());
      return(false);
     }
   return(true);
  }
