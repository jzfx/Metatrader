//+------------------------------------------------------------------+
//|                                                 ExtremeBreak.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict

#include <Common\Comparators.mqh>
#include <Signals\AbstractSignal.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class ExtremeBreak : public AbstractSignal
  {
private:
   Comparators       compare;
public:
   double            Low;
   double            High;
   double            Open;
                     ExtremeBreak(int period,string symbol,ENUM_TIMEFRAMES timeframe,int shift);
   bool              Validate(ValidationResult *v);
   SignalResult     *Analyze();
   SignalResult     *Analyze(int shift);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
ExtremeBreak::ExtremeBreak(int period,string symbol,ENUM_TIMEFRAMES timeframe,int shift=2)
  {
   this.Period=period;
   this.Symbol=symbol;
   this.Timeframe=timeframe;
   this.Shift=shift;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SignalResult *ExtremeBreak::Analyze()
  {
   this.Analyze(this.Shift);
   return this.Signal;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ExtremeBreak::Validate(ValidationResult *v)
  {
   v.Result=true;

   if(!compare.IsNotBelow(this.Period,1))
     {
      v.Result=false;
      v.AddMessage("Period must be 1 or greater.");
     }

   if(!compare.IsNotBelow(this.Shift,0))
     {
      v.Result=false;
      v.AddMessage("Shift must be 0 or greater.");
     }

   return v.Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SignalResult *ExtremeBreak::Analyze(int shift)
  {
   this.Signal.Reset();
   this.Low  = iLow(this.Symbol, this.Timeframe, iLowest(this.Symbol,this.Timeframe,MODE_LOW,this.Period,shift));
   this.High = iHigh(this.Symbol, this.Timeframe, iHighest(this.Symbol,this.Timeframe,MODE_HIGH,this.Period,shift));
   this.Open = iOpen(this.Symbol, this.Timeframe, 0);

   MqlTick tick;
   bool gotTick=SymbolInfoTick(this.Symbol,tick);
   if(gotTick)
     {
   if(this.Open<this.Low)
     {
         this.Signal.orderType=OP_SELL;
         this.Signal.price=tick.bid;
         this.Signal.symbol=this.Symbol;
         this.Signal.time=tick.time;
     }
   if(this.Open>this.High)
     {
         this.Signal.orderType=OP_BUY;
         this.Signal.price=tick.ask;
         this.Signal.symbol=this.Symbol;
         this.Signal.time=tick.time;
        }
     }
   return this.Signal;
  }
//+------------------------------------------------------------------+
