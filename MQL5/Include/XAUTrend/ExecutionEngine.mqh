#pragma once

#include <Trade/Trade.mqh>

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

   if(!OrderCheck(req,check))
     {
      reason=StringFormat("OrderCheck call failed (%d)",GetLastError());
      return(false);
     }

   if(check.retcode!=TRADE_RETCODE_DONE && check.retcode!=TRADE_RETCODE_PLACED)
     {
      reason=StringFormat("OrderCheck blocked: %d %s",check.retcode,check.comment);
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
