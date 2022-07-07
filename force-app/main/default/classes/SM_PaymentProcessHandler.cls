public with sharing class SM_PaymentProcessHandler {
    /**
    * @description This method will create the required payment records based on the properties AC/RC
    * @author srojas@legal-credit | 05-02-2021
    * @param newItems 
    * @param oldItems 
    **/
    public static void validatePayments(Map<Id,SObject> newItems, Map<Id,SObject> oldItems){
        /* Vilidates the Creation of a Chargent Order if it doesn't exit already */
        List<Contract> contractsToUpdateList = new List<Contract>();
        List<Object> pmToValidate = new List<Object>();
        List<Object> chargentPTypes = new List<Object>();
        Try{
            List<String> ACids = new List<String>();
            List<String> SusId = new List<String>();
            List<String> ACHACids = new List<String>();
            List<String> ACHSusId = new List<String>();
            for(String id: newItems.keySet()){
                Contract ctr = (Contract)newItems.get(id);
                System.debug(ctr.SM_Requires_AC_Payment__c);
                if(ctr.SM_Requires_AC_Payment__c){
                    System.debug(ctr.SM_Requires_AC_Payment__c);
                    if(ctr.SM_Payment_methods__c == 'Credit Card'){
                        if(ctr.SM_Way_of_AC_Payment__c != null && ctr.SM_Way_of_AC_Payment__c == 'One payment'){
                            pmToValidate.add('AC - Full Payment');
                        }
                        else{
                            pmToValidate.add('AC - Fees');
                        }
                        chargentPTypes.add('AC');
                    }
                    else if(ctr.SM_Payment_methods__c == 'ACH'){
                        if(ctr.SM_Way_of_AC_Payment__c != null && ctr.SM_Way_of_AC_Payment__c == 'One payment'){
                            pmToValidate.add('AC - Full Payment');
                        }
                        else{
                            pmToValidate.add('AC - Fees');
                        }
                        chargentPTypes.add('AC');
                    }

                }
                if(ctr.SM_Requires_RC_Payment__c){
                    if(ctr.SM_Payment_methods__c == 'Credit Card'){
                        if(ctr.SM_Way_of_Contract_Payment__c != null && ctr.SM_Way_of_Contract_Payment__c == 'Fix Term'){
                            pmToValidate.add('RC - Fees');
                        }
                        else{
                            pmToValidate.add('Subscription');
                        }
                        chargentPTypes.add('Subscription');
                    }
                    else if(ctr.SM_Payment_methods__c == 'ACH'){
                        if(ctr.SM_Way_of_Contract_Payment__c != null && ctr.SM_Way_of_Contract_Payment__c == 'Fix Term'){
                            pmToValidate.add('RC - Fees');
                        }
                        else{
                            pmToValidate.add('Subscription');
                        }
                        chargentPTypes.add('Subscription');
                    }
                }
                if(ctr.Status != oldItems.get(id).get('Status') && ctr.Status =='Complete information'){
                    if(ctr.SM_Requires_AC_Payment__c && ctr.SM_Payment_methods__c == 'Credit Card'){  
                        ACids.add(id);
                    }
                    else if(ctr.SM_Requires_RC_Payment__c && ctr.SM_Payment_methods__c == 'Credit Card'){
                        SusId.add(id);
                    }
                    else if(ctr.SM_Requires_AC_Payment__c && ctr.SM_Payment_methods__c == 'ACH'){
                        ACHACids.add(id);
                    }
                    else if(ctr.SM_Requires_RC_Payment__c && ctr.SM_Payment_methods__c == 'ACH'){
                        ACHSusId.add(id);
                    }
                }
                if(ctr.SM_Requires_AC_Payment__c && ctr.SM_AC_collected__c &&
                    ctr.SM_Requires_RC_Payment__c && Boolean.ValueOf(ctr.SM_AC_collected__c) && ctr.Status =='Activated'
                    && oldItems.get(id).get('Status') != ctr.Status &&  ctr.SM_Payment_methods__c == 'Credit Card'){
                    SusId.add(id);
                }   
                if(ctr.SM_Requires_AC_Payment__c && ctr.SM_AC_collected__c &&
                    ctr.SM_Requires_RC_Payment__c && Boolean.ValueOf(ctr.SM_AC_collected__c) && ctr.Status =='Activated'
                    && oldItems.get(id).get('Status') != ctr.Status && ctr.SM_Payment_methods__c == 'ACH'){
                        ACHSusId.add(id);
                }     
            }
            System.debug('ACids '+ACids);
            if(ACids.size()>0){
                System.debug('ACids '+ACids);
                SM_ChargentPaymentProcessHandler.CreateACOrderRecordsChargent(ACids,pmToValidate,chargentPTypes);
            }
            if(SusId.size()>0){ 
               System.debug('SusId '+SusId);
               SM_ChargentPaymentProcessHandler.CreateSubscriptionOrderRecordsChargent(SusId);
            }
            if(ACHACids.size()>0){
                System.debug('ACHACids '+ACHACids);
                SM_ACHPaymentProcessHandler.CreateACOrderRecordsACH(ACHACids,pmToValidate,chargentPTypes);
            }
            if(ACHSusId.size()>0){
                System.debug('ACHSusId '+ACHSusId);
                SM_ACHPaymentProcessHandler.CreateSubscriptionOrderRecordsACH(ACHSusId);
            }
        }Catch(System.Exception ex){
            /* Call the TransactionLogHandler class method to create a log 
               parameters need to pass in the method are System.Exception and the Handler ClassName
            */
            System.debug(ex.getStackTraceString() +'<br/>' + ex.getMessage() + '<br/>' + ex.getCause() +' <br/>'+ ex.getTypeName());
            TransactionLogHandler.doHandleException(ex , 'contractTGRController');
        }
    }
}