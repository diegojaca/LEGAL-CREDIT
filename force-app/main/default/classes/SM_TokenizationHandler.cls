/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@gmail.es
 * @group             : 
 * @last modified on  : 24/07/2021
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@gmail.es
 * Modifications Log 
 * Ver   Date          Author                                            Modification
 * 1.0   19/07/2021g   Diego Jacanamijoy -> diego.jacanamijoy@gmail.es   Initial Version
**/
public without sharing class SM_TokenizationHandler {

    private List<SM_Payment_Method__c> paymentMethods;
    List<ChargentOrders__ChargentOrder__c> newChargentOrders = new List<ChargentOrders__ChargentOrder__c>();
    List<SM_Payment_Method__c> paymentMethodsToProcess = new List<SM_Payment_Method__c>();
    List<SObject> recordsToUpdate = new List<SObject>();

    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 19/07/2021g 
    * @param paymentMethods 
    **/
    public SM_TokenizationHandler(List<SM_Payment_Method__c> paymentMethods) {
        this.paymentMethods = paymentMethods;
    }

    /**
    * @description Method to create and related chargent record to payment
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 22/07/2021 
    **/
    public void createChargents(){

        //Validate Payment method without chargent order
        for(SM_Payment_Method__c paymentMethod: paymentMethods) {

            ChargentOrders__ChargentOrder__c newChargent = SM_ChargentOrderHelper.createChargentOrder(paymentMethod);

            if(newChargent != null){
                newChargentOrders.add(newChargent);
                paymentMethod.SM_Chargent_order__r = newChargent;
            }else{
                paymentMethod.Tokenization_error_detail__c = LABEL.EMPTY_RELATED_CONTRACTS_ERROR;
                paymentMethod.SM_Tokenization_status__c = SM_PaymentHelper.tokenizationStatus.ERROR;
            }
        }

        //Validate if has chargents to insert
        if(!newChargentOrders.isEmpty()) {
            insert newChargentOrders;

            //Related new chargent to payment method
            for(SM_Payment_Method__c paymentMethod: paymentMethods) {
                paymentMethod.SM_Chargent_order__c = paymentMethod.SM_Chargent_order__r?.Id;
            }
        }

        //Validate records to update
        if(!paymentMethods.isEmpty()) {
            update paymentMethods;
        }
    }

    /**
    * @description This method excecute tokenized process
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 19/07/2021g 
    **/
    public void process(){

        Map<Id,SM_Payment_Method__c> paymentMethodById = new Map<Id,SM_Payment_Method__c>();

        //Iterate Payments to call WS
        for(SM_Payment_Method__c paymentMethod: paymentMethods) {

            try {
                //Build wrraper by send to ws
                SM_ChargentOrderHelper.ChargentWrapper chargentWrraper = new SM_ChargentOrderHelper.ChargentWrapper(paymentMethod);

                //call ws tokenization
                ChargentOrders.tChargentOperations.AuthorizeOrder_ClickJSON(JSON.Serialize(chargentWrraper));
                paymentMethod.SM_Tokenization_status__c = SM_PaymentHelper.tokenizationStatus.TOKENIZED;
                paymentMethod.SM_Chargent_order__c = paymentMethod.SM_Chargent_order__c <> null ? paymentMethod.SM_Chargent_order__c : paymentMethod.SM_Chargent_order__r?.Id;
                paymentMethod.Tokenization_error_detail__c = '';
                paymentMethodById.put(paymentMethod.Id, paymentMethod);
            } catch (Exception e) {
                //Update error and status in payment method record
                paymentMethod.Tokenization_error_detail__c = e.getMessage() + ' -- ' + e.getStackTraceString();
                paymentMethod.SM_Tokenization_status__c = SM_PaymentHelper.tokenizationStatus.ERROR;
                recordsToUpdate.add(paymentMethod);
            }
        }

        recordsToUpdate.addAll(updateChargetOrders(paymentMethodById));        

        //Validate if has records to update
        if(!recordsToUpdate.isEmpty()) {
            recordsToUpdate.sort();
            update recordsToUpdate;
        }
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 19/07/2021g 
    * @param paymentMethodIds 
    * @return List<ChargentOrders__ChargentOrder__c> 
    **/
    private List<SObject> updateChargetOrders(Map<Id,SM_Payment_Method__c> paymentMethodById){

        List<SObject> recordsToUpdate = new List<SObject>();

        Map<Id,List<ChargentOrders__ChargentOrder__c>> chargentOrdersByPayment = getChargentOrdersByPaymenth(paymentMethodById.keySet());
        Map<Id,SM_Payment_Method__c> tokenizedDataByPayment = getTokenizedDataByPayment(paymentMethodById.keySet());

        //Clone data from tokenized chargent
        for(Id paymentMethodId: chargentOrdersByPayment.keySet()){

            ChargentOrders__ChargentOrder__c tokenizedChargent = tokenizedDataByPayment.get(paymentMethodId).SM_Chargent_order__r;//Get Chargent tokenized

            for(ChargentOrders__ChargentOrder__c chargentOrder: chargentOrdersByPayment.get(paymentMethodId)){

                chargentOrder.ChargentOrders__Tokenization__c = tokenizedChargent.ChargentOrders__Tokenization__c;
                chargentOrder.ChargentOrders__Card_Expiration_Month__c = tokenizedChargent.ChargentOrders__Card_Expiration_Month__c; 
                chargentOrder.ChargentOrders__Card_Expiration_Year__c = tokenizedChargent.ChargentOrders__Card_Expiration_Year__c;
                chargentOrder.ChargentOrders__Card_Last_4__c = tokenizedChargent.ChargentOrders__Card_Last_4__c; 
                chargentOrder.ChargentOrders__Card_Month_Indicator__c = tokenizedChargent.ChargentOrders__Card_Month_Indicator__c;
                chargentOrder.ChargentOrders__Card_Number__c = tokenizedChargent.ChargentOrders__Card_Number__c;
                chargentOrder.ChargentOrders__Card_Type__c = tokenizedChargent.ChargentOrders__Card_Type__c;
                chargentOrder.ChargentOrders__Card_Year_Indicator__c = tokenizedChargent.ChargentOrders__Card_Year_Indicator__c;
                chargentOrder.ChargentOrders__Gateway__c = tokenizedChargent.ChargentOrders__Gateway__c;
                chargentOrder.SM_IsRegisterToken__c =true;

                recordsToUpdate.add(chargentOrder);
            }

            //set tokrn in payment method
            paymentMethodById.get(paymentMethodId).SM_Card_Token__c = tokenizedChargent.ChargentOrders__Tokenization__c;
            recordsToUpdate.add(paymentMethodById.get(paymentMethodId));
        }

        return recordsToUpdate;
    }
    
    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 19/07/2021g 
    * @param paymentMethodIds 
    * @return Map<Id, List<ChargentOrders__ChargentOrder__c>> 
    **/
    private Map<Id,List<ChargentOrders__ChargentOrder__c>> getChargentOrdersByPaymenth(Set<Id> paymentMethodIds){

        Map<Id,List<ChargentOrders__ChargentOrder__c>> chargentOrdersByPaymenth = new Map<Id,List<ChargentOrders__ChargentOrder__c>>();

        for(Contract contract: [SELECT SM_Payment_Method__c, (SELECT Id FROM Chargent_Orders__r) FROM Contract WHERE SM_Payment_Method__c IN :paymentMethodIds]){
            if(!chargentOrdersByPaymenth.containsKey(contract.SM_Payment_Method__c)){
                chargentOrdersByPaymenth.put(contract.SM_Payment_Method__c, new List<ChargentOrders__ChargentOrder__c>());
            }
            chargentOrdersByPaymenth.get(contract.SM_Payment_Method__c).addAll(contract.Chargent_Orders__r);
        }

        return chargentOrdersByPaymenth;
    }
    
    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 19/07/2021g 
    * @param paymentMethodIds 
    * @return Map<Id, SM_Payment_Method__c> 
    **/
    private Map<Id, SM_Payment_Method__c> getTokenizedDataByPayment(Set<Id> paymentMethodIds){
        
        return new Map<Id, SM_Payment_Method__c>([SELECT  
                                                    SM_Chargent_order__r.ChargentOrders__Last_Transaction__c, SM_Chargent_order__r.ChargentOrders__Gateway__c,
                                                    SM_Chargent_order__r.ChargentOrders__Tokenization__c, SM_Chargent_order__r.ChargentOrders__Card_Expiration_Month__c, 
                                                    SM_Chargent_order__r.ChargentOrders__Card_Expiration_Year__c, SM_Chargent_order__r.ChargentOrders__Card_Last_4__c, 
                                                    SM_Chargent_order__r.ChargentOrders__Card_Month_Indicator__c, SM_Chargent_order__r.ChargentOrders__Card_Number__c,
                                                    SM_Chargent_order__r.ChargentOrders__Card_Type__c, SM_Chargent_order__r.ChargentOrders__Card_Year_Indicator__c,
                                                    SM_Chargent_order__r.SM_IsRegisterToken__c
                                                FROM SM_Payment_Method__c WHERE Id IN :paymentMethodIds]);
    }

}