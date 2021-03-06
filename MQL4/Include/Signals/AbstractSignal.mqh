//+------------------------------------------------------------------+
//|                                               AbstractSignal.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict

#include <Common\ValidationResult.mqh>
#include <Signals\SignalResult.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class AbstractSignal
  {
public:
   string            Symbol;
   ENUM_TIMEFRAMES   Timeframe;
   int               Period;
   int               Shift;
   SignalResult     *Signal;
   void              AbstractSignal();
   void             ~AbstractSignal();
   virtual bool      Validate(ValidationResult *validationResult)=0;
   virtual bool      Validate();
   virtual SignalResult *Analyze()=0;
   virtual SignalResult *Analyze(int shift)=0;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AbstractSignal::AbstractSignal()
  {
   this.Signal=new SignalResult();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void AbstractSignal::~AbstractSignal()
  {
   delete this.Signal;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool AbstractSignal::Validate()
  {
   ValidationResult *v=new ValidationResult();
   bool out=this.Validate(v);
   delete v;
   return out;
  }
//+------------------------------------------------------------------+
