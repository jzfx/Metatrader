//+------------------------------------------------------------------+
//|                                                    PLManager.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property strict

#include <Common\OrderManager.mqh>
#include <Common\Comparators.mqh>
#include <PLManager\BasketProfitScanner.mqh>
// Closes all positions on watched pairs when net profit or loss hits the target.
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class PLManager
  {
private:
   Comparators       compare;
   OrderManager     *_orderManager;
   SimpleParsers     simpleParsers;
   BasketProfitScanner *_basketProfitScanner;
public:
   double            ProfitTarget; // Profit target in account currency
   double            MaxLoss; // Maximum allowed loss in account currency
   int               MinAge; // Minimum age of order in seconds
   BaseLogger        Logger;
                     PLManager(SymbolSet *aSymbolSet,OrderManager *aOrderManager);
                    ~PLManager();
   bool              Validate(ValidationResult *validationResult);
   bool              Validate();
   bool              CanTrade();
   double            GetNetProfit(bool sendComment=false);
   void              CloseAllAtProfitTarget(double netProfit);
   void              CloseAllAtMaxLoss(double netProfit);
   void              Execute();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PLManager::PLManager(SymbolSet *aSymbolSet,OrderManager *aOrderManager)
  {
   this._basketProfitScanner=new BasketProfitScanner(aSymbolSet);
   this._orderManager=aOrderManager;
   this.ProfitTarget=0;
   this.MaxLoss=0;
   this.MinAge=60;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
PLManager::~PLManager()
  {
   delete this._basketProfitScanner;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PLManager::Validate()
  {
   ValidationResult *v=new ValidationResult();
   bool out=this.Validate(v);
   delete v;
   return out;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PLManager::Validate(ValidationResult *validationResult)
  {
   validationResult.Result=true;

   if(this._basketProfitScanner.symbolSet.Symbols.Count()==0)
     {
      validationResult.AddMessage("Your watched pairs is empty, using current symbol only.");
      this._basketProfitScanner.symbolSet.Symbols.Add(Symbol());
     }
   if(!this._basketProfitScanner.symbolSet.ValidateSymbolsExist())
     {
      validationResult.AddMessage("One of your watched symbols could not be found on the server.");
      validationResult.Result=false;
     }
   if(compare.IsLessThan(this.ProfitTarget,(double)0))
     {
      validationResult.AddMessage("The ProfitTarget must be greater than or equal to zero.");
      validationResult.Result=false;
     }
   if(compare.IsLessThan(this.MaxLoss,(double)0))
     {
      validationResult.AddMessage("The MaxLoss must be greater than or equal to zero.");
      validationResult.Result=false;
     }
   if(compare.IsLessThan(this.MinAge,(int)0))
     {
      validationResult.AddMessage("The MinAge must be greater than or equal to zero.");
      validationResult.Result=false;
     }
     
   validationResult.Result = validationResult.Result && this._orderManager.Validate(validationResult);

   return validationResult.Result;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PLManager::CanTrade()
  {
   int k=this._basketProfitScanner.symbolSet.Symbols.Count();
   int i= 0;

   string symbol;
   if(k>0)
     {
      for(i=0;i<k;i++)
        {
         if(!(this._basketProfitScanner.symbolSet.Symbols.TryGetValue(i,symbol)))
           {
            return false;
           }

         if(!(this._orderManager.CanTrade(symbol,TimeCurrent())))
           {
            return false;
           }
        }
     }

   return true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double PLManager::GetNetProfit(bool sendComment=false)
  {
   this._basketProfitScanner.Scan();
   if(sendComment==true)
     {
      this.Logger.Comment(this._basketProfitScanner.Comments);
     }
   return this._basketProfitScanner.NetProfit;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PLManager::CloseAllAtProfitTarget(double netProfit)
  {
   if(compare.IsNotAbove(this.ProfitTarget,(double)0.0)) return;

   bool profitIsAtOrAboveTarget=compare.IsNotBelow(netProfit,this.ProfitTarget);

   if(profitIsAtOrAboveTarget)
     {
      this.Logger.Log("Profit target reached, closing orders.");
      int k=this._basketProfitScanner.symbolSet.Symbols.Count();
      string symbol="";
      int j;
      for(j=0;j<k;j++)
        {
         symbol="";
         if(this._basketProfitScanner.symbolSet.Symbols.TryGetValue(j,symbol))
           {
            this._orderManager.CloseOrders(symbol,((datetime)TimeCurrent()-this.MinAge));
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PLManager::CloseAllAtMaxLoss(double netProfit)
  {
   if(compare.IsNotAbove(this.MaxLoss,(double)0.0)) return;

   double maximumLoss=this.MaxLoss *(-1);

   bool lossExceedsMaximum=compare.IsNotAbove(netProfit,maximumLoss);

   if(lossExceedsMaximum)
     {
      this.Logger.Warn("Maximum loss reached, closing orders.");
      int k=this._basketProfitScanner.symbolSet.Symbols.Count();
      string symbol="";
      for(int j=0;j<k;j++)
        {
         symbol="";
         if(this._basketProfitScanner.symbolSet.Symbols.TryGetValue(j,symbol))
           {
            this._orderManager.CloseOrders(symbol,((datetime)TimeCurrent()-this.MinAge));
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Executes the Profit and Loss management.                         |
//+------------------------------------------------------------------+
void PLManager::Execute()
  {
   if(!(this.Validate() && this.CanTrade()))
     {
      return;
     }

   double netProfit=GetNetProfit(true);

   if(netProfit>0)
     {
      this.CloseAllAtProfitTarget(netProfit);
     }
   if(netProfit<0)
     {
      this.CloseAllAtMaxLoss(netProfit);
     }
  }
//+------------------------------------------------------------------+
