//+------------------------------------------------------------------+
//|                                                              MPC |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property description "Does Magic."
#property strict

#include <Common\Comparators.mqh>
#include <PLManager\PLManager.mqh>
#include <Schedule\ScheduleSet.mqh>
#include <Signals\SignalSet.mqh>
#include <Signals\ExtremeBreak.mqh>

input int ExtremeBreakPeriod=45;
input int ExtremeBreakShift=1;
input double Lots=0.04;
input double ProfitTarget=13; // Profit target in account currency
input double MaxLoss=9; // Maximum allowed loss in account currency
input int Slippage=10; // Allowed slippage
extern ENUM_DAY_OF_WEEK Start_Day=1;//Start Day
extern ENUM_DAY_OF_WEEK End_Day=5;//End Day
extern string   Start_Time="12:00";//Start Time
extern string   End_Time="15:00";//End Time
input bool ScheduleIsDaily=true;// Use start and stop times daily?
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MPC
  {
private:
   bool              deleteLogger;
public:
   SymbolSet        *allowedSymbols;
   ScheduleSet      *schedule;
   OrderManager     *orderManager;
   PLManager        *plmanager;
   SignalSet        *signalSet;
   BaseLogger       *logger;
   datetime          time;
   double            lotSize;
                     MPC(double lots,SymbolSet *aAllowedSymbolSet,ScheduleSet *aSchedule,OrderManager *aOrderManager,PLManager *aPlmanager,SignalSet *aSignalSet,BaseLogger *aLogger);
                    ~MPC();
   bool              Validate(ValidationResult *validationResult);
   bool              Validate();
   bool              ValidateAndLog();
   void              ExpertOnInit();
   void              ExpertOnTick();
   bool              CanTrade();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MPC::MPC(double lots,SymbolSet *aAllowedSymbolSet,ScheduleSet *aSchedule,OrderManager *aOrderManager,PLManager *aPlmanager,SignalSet *aSignalSet,BaseLogger *aLogger=NULL)
  {
   this.lotSize=lots;
   this.allowedSymbols=aAllowedSymbolSet;
   this.schedule=aSchedule;
   this.orderManager=aOrderManager;
   this.plmanager=aPlmanager;
   this.signalSet=aSignalSet;
   if(aLogger==NULL)
     {
      this.logger=new BaseLogger();
      this.deleteLogger=true;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
MPC::~MPC()
  {
   if(this.deleteLogger==true)
     {
      delete this.logger;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MPC::Validate()
  {
   ValidationResult *validationResult=new ValidationResult();
   return this.Validate(validationResult);
   delete validationResult;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MPC::Validate(ValidationResult *validationResult)
  {
   validationResult.Result=true;
   Comparators compare;

   bool omv=this.orderManager.Validate(validationResult);
   bool plv=this.plmanager.Validate(validationResult);
   bool sigv=this.signalSet.Validate(validationResult);

   validationResult.Result=(omv && plv && sigv);

   if(!compare.IsGreaterThan(this.lotSize,(double)0))
     {
      validationResult.AddMessage("Lots must be greater than zero.");
      validationResult.Result=false;
     }

   return validationResult.Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool MPC::ValidateAndLog()
  {
   string border[]=
     {
      "",
      "!~ !~ !~ !~ !~ User Settings validation failed ~! ~! ~! ~! ~!",
      ""
     };
   ValidationResult *v=new ValidationResult();
   bool out=mpc.Validate(v);
   if(out==false)
     {
      this.logger.Log(border);
      this.logger.Warn(v.Messages);
      this.logger.Log(border);
     }
   delete v;
   return out;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MPC::ExpertOnInit()
  {
   if(!this.ValidateAndLog())
     {
      ExpertRemove();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MPC::ExpertOnTick()
  {
   if(!this.CanTrade())
     {
      return;
     }
   if(Time[0]!=this.time)
     {
      this.time=Time[0];
      if(this.schedule.IsActive(TimeCurrent()))
        {
         this.signalSet.Analyze();
         if(this.signalSet.Signal!=NULL)
           {
            SignalResult *r=this.signalSet.Signal;
            if(r.orderType != NULL)
              {
               if(false==OrderSend(r.symbol,r.orderType,this.lotSize,r.price,this.orderManager.Slippage,r.stopLoss,r.takeProfit))
              {
               this.logger.Error("OrderSend : "+(string)GetLastError());
              }
           }
        }
     }
     }
   this.plmanager.Execute();
  }
//+------------------------------------------------------------------+
//|Rules to stop the bot from even trying to trade                   |
//+------------------------------------------------------------------+
bool MPC::CanTrade()
  {
   return this.plmanager.CanTrade();
  }

MPC *mpc;
SymbolSet *ss;
ScheduleSet *sched;
OrderManager *om;
PLManager *plman;
SignalSet *signalSet;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void deinit()
  {
   delete mpc;
   delete ss;
   delete sched;
   delete om;
   delete plman;
   delete signalSet;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void init()
  {
   string symbols=Symbol();
   ss=new SymbolSet();
   ss.AddSymbolsFromCsv(symbols);

   sched=new ScheduleSet();
   if(ScheduleIsDaily==true)
     {
      sched.AddWeek(Start_Time,End_Time,Start_Day,End_Day);
     }
   else
     {
      sched.Add(new Schedule(Start_Day,Start_Time,End_Day,End_Time));
     }

   om=new OrderManager();
   om.Slippage=Slippage;

   plman=new PLManager(ss,om);
   plman.ProfitTarget=ProfitTarget;
   plman.MaxLoss=MaxLoss;
   plman.MinAge=60;

   signalSet=new SignalSet();
   signalSet.Add(new ExtremeBreak(ExtremeBreakPeriod,symbols,(ENUM_TIMEFRAMES)Period(),ExtremeBreakShift));

   mpc=new MPC(Lots,ss,sched,om,plman,signalSet);

   mpc.ExpertOnInit();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   mpc.ExpertOnTick();
  }
//+------------------------------------------------------------------+
