//+------------------------------------------------------------------+
//|                                                    SignalSet.mqh |
//|                                 Copyright © 2017, Matthew Kastor |
//|                                 https://github.com/matthewkastor |
//+------------------------------------------------------------------+
#property copyright "Matthew Kastor"
#property link      "https://github.com/matthewkastor"
#property version   "1.00"
#property description "Signal collection."
#property strict

#include <Generic\LinkedList.mqh>
#include <Signals\AbstractSignal.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class SignalSet : public CLinkedList<AbstractSignal *>
  {
public:
   string            Name;
   SignalResult     *Signal;
   bool              DeleteSignalsOnClear;
   void              Clear(bool deleteSignals=true);
   bool              Validate(ValidationResult *v);
   void              Analyze();
   void              SignalSet();
   void             ~SignalSet();
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SignalSet::SignalSet():CLinkedList<AbstractSignal *>()
  {
   this.DeleteSignalsOnClear=true;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
SignalSet::~SignalSet()
  {
   this.Clear(this.DeleteSignalsOnClear);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SignalSet::Clear(bool deleteSignals=true)
  {
   if(deleteSignals && this.Count()>0)
     {
      CLinkedListNode<AbstractSignal*>*node=this.First();

      delete node.Value();

      do
        {
         node=node.Next();
         delete node.Value();
        }
      while(this.Last()!=node);
     }

   CLinkedList<AbstractSignal *>::Clear();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SignalSet::Validate(ValidationResult *v)
  {
   bool out=true;
   if(this.Count()>0)
     {
      CLinkedListNode<AbstractSignal *>*node=this.First();
      AbstractSignal *s=node.Value();
      out=out && s.Validate(v);

      while(this.Last()!=node)
        {
         node=node.Next();
         s=node.Value();
         out=out && s.Validate(v);
        }
     }
   return out;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SignalSet::Analyze()
  {
   this.Signal=NULL;
   if(this.Count()>0)
     {
      CLinkedListNode<AbstractSignal *>*node=this.First();
      AbstractSignal *s=node.Value();
      s.Analyze();
      if(s.Signal.orderType!=NULL)
        {
         this.Signal=s.Signal;
        }

      while(this.Last()!=node)
        {
         node=node.Next();
         s=node.Value();
         s.Analyze();
         if(s.Signal.orderType!=NULL)
           {
            this.Signal=s.Signal;
           }
        }
     }
  }
//+------------------------------------------------------------------+
