#pragma once

bool XAU_IsNewBar(const string symbol,const ENUM_TIMEFRAMES tf,datetime &last_time,datetime &new_bar_time)
  {
   datetime current=iTime(symbol,tf,0);
   if(current<=0)
      return(false);

   if(last_time==0)
     {
      last_time=current;
      return(false);
     }

   if(current!=last_time)
     {
      new_bar_time=current;
      last_time=current;
      return(true);
     }

   return(false);
  }

datetime XAU_BrokerDayStart(const datetime when)
  {
   MqlDateTime dt;
   TimeToStruct(when,dt);
   dt.hour=0;
   dt.min=0;
   dt.sec=0;
   return(StructToTime(dt));
  }

int XAU_BarsSinceTime(const string symbol,const ENUM_TIMEFRAMES tf,const datetime event_time)
  {
   if(event_time<=0)
      return(INT_MAX);
   int shift=iBarShift(symbol,tf,event_time,false);
   if(shift<0)
      return(INT_MAX);
   return(shift);
  }

double XAU_HighestHigh(const string symbol,const ENUM_TIMEFRAMES tf,const int start_shift,const int count)
  {
   int idx=iHighest(symbol,tf,MODE_HIGH,count,start_shift);
   if(idx<0)
      return(0.0);
   return(iHigh(symbol,tf,idx));
  }

double XAU_LowestLow(const string symbol,const ENUM_TIMEFRAMES tf,const int start_shift,const int count)
  {
   int idx=iLowest(symbol,tf,MODE_LOW,count,start_shift);
   if(idx<0)
      return(0.0);
   return(iLow(symbol,tf,idx));
  }

bool XAU_IsWithinRolloverWindow(const datetime now,const int start_hour,const int start_minute,const int end_hour,const int end_minute)
  {
   MqlDateTime dt;
   TimeToStruct(now,dt);
   const int current_minutes=dt.hour*60+dt.min;
   const int start_minutes=start_hour*60+start_minute;
   const int end_minutes=end_hour*60+end_minute;

   if(start_minutes<=end_minutes)
      return(current_minutes>=start_minutes && current_minutes<=end_minutes);

   return(current_minutes>=start_minutes || current_minutes<=end_minutes);
  }
