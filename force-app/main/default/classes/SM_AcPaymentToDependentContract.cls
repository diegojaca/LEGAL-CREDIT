/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> djacanamijoy@legal-credit.com
 * @group             : 
 * @last modified on  : 05/08/2022
 * @last modified by  : Diego Jacanamijoy -> djacanamijoy@legal-credit.com
**/
public with sharing class SM_AcPaymentToDependentContract {
    
    private Map<Id, Contract> masterById = new Map<Id, Contract>();
    private Map<Id, SM_Payment__c> paymentByMasterId = new Map<Id, SM_Payment__c>();

    /**
    * @description Constructor
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 03/08/2022 
    * @param object SM_ACH_Order__c or ChargentOrders__ChargentOrder__c
    **/
    public SM_AcPaymentToDependentContract(SObject[] sobjects) {

        getRelatedPayment(sobjects);
    }

    /**
    * @description This method query related payment by pased object
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 05/08/2022 
    * @param so 
    **/
    private void getRelatedPayment(SObject[] sobjects){

        /** get all editable fields of payment object */
        String allEditablePaymentFields = String.join(SM_Utils.getAllEditableFieldsBySObject(SM_Payment__c.getSObjectType().getDescribe().getName()), ',');
        Set<Id> contractIds = new Set<Id>();

        /** Check sobject type passed */
        if(SM_Utils.getSObjectNameById((Id)sobjects[0].get('Id')) == SM_ACH_Order__c.getSObjectType().getDescribe().getName()){

            Set<Id> achIds = new Set<Id>();
            
            for (SObject achOrder: sobjects) {
                achIds.add((Id)achOrder.get('Id'));
                contractIds.add((Id)achorder.get('SM_Contract__c'));
            }
            
            
            /** Get related contracts */
            buildMasterContractMap(contractIds);
            
            /** get related payment with all editable fields */
            String paymentQuery = 'SELECT SM_Contract__c, {0} FROM SM_Payment__c WHERE SM_ACH_Order__c IN: achIds ORDER BY Createddate DESC';

            /** Build payment by master map */
            for (SM_Payment__c payment : Database.query(String.format(paymentQuery, new List<String>{allEditablePaymentFields}))) {

                if (masterById.containsKey(payment.SM_Contract__c)) {
                    paymentByMasterId.put(payment.SM_Contract__c, payment);    
                }
                
            }

        }else if(SM_Utils.getSObjectNameById((Id)sobjects[0].get('Id')) == ChargentOrders__ChargentOrder__c.getSObjectType().getDescribe().getName()){

            Set<Id> chargenIds = new Set<Id>();
            
            for (SObject chargen: sobjects) {
                chargenIds.add((Id)chargen.get('Id'));
                contractIds.add((Id)chargen.get('Contract__c'));
            }

            /** Get related contracts */
            buildMasterContractMap(contractIds);

            /** get related payment with all editable fields */
            String chargenTransactionQuery = 'SELECT Contract__c, (SELECT SM_Contract__c, {0} FROM Payments__r ORDER BY Createddate DESC) FROM ChargentOrders__Transaction__c WHERE ChargentOrders__Order__c IN: chargenIds';

            for (ChargentOrders__Transaction__c chargTransaction : Database.query(String.format(chargenTransactionQuery, new List<String>{allEditablePaymentFields}))) {
                
                if (masterById.containsKey(chargTransaction.Contract__c)) {
                    paymentByMasterId.put(chargTransaction.Contract__c, chargTransaction.Payments__r[0]);
                }
            }
        }

        /** Check related payment to continue proccess */
        if (!paymentByMasterId.isEmpty()) {
            validateAndClonePayment();   
        }
    }

    /**
    * @description This method get master contracts and build map
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 05/08/2022 
    * @param masterIds 
    **/
    private void buildMasterContractMap(Set<Id> masterIds){

        /** Get related contracts */
        for (Contract relatedContract : [SELECT 
                                            Contract_Type__c, SM_Total_ac__c
                                            , (SELECT 
                                                    Id 
                                                FROM Contracts1__r
                                                WHERE Collection_Main_Contract__c =: SM_ContractHelper.collectionMain.READY_FOR_COLLECTION
                                                AND SM_Requires_AC_Payment__c = true) 
                                        FROM Contract 
                                        WHERE Id IN: masterIds
                                        AND Contract_Type__c =: SM_ContractHelper.contractType.MASTER]) 
        {

            masterById.put(relatedContract.Id, relatedContract);
        }
    }

    /**
    * @description This method get dependent contracts and clone payment, to related with contracts
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 05/08/2022 
    **/
    private void validateAndClonePayment(){

        /** Payment list to clone */
        List<SM_Payment__c> clonedPayments = new List<SM_Payment__c>();

        for (Contract master : masterById.values()) {

            /** Check if the amount of cuote is less or  greater of ttal AC of contract*/
            //if (master.SM_Total_ac__c > payment.SM_Amount__c) {
                
                /** get AC dependent contracts and iterate them */
                List<Contract> dependentContracts = masterById.get(master.Id).Contracts1__r;

                SM_Payment__c payment = paymentByMasterId.get(master.Id);

                if (payment == null) {
                    continue;
                }

                /** values to cloned payments */
                Decimal amountToDependent = dependentContracts.size() > 0 ? (payment.SM_Amount__c / dependentContracts.size()).setScale(2) : 0;
                Decimal penaltyValueToDependent = dependentContracts.size() > 0 ? (payment.SM_Penalty_value__c / dependentContracts.size()).setScale(2) : 0;
                Decimal feeValueToDependent = dependentContracts.size() > 0 ? (payment.SM_Fee_value__c / dependentContracts.size()).setScale(2) : 0;
                

                for (Contract dependent : dependentContracts) {
                    
                    /** Clone payment from master, overrite amounts and related with dependent cntract*/
                    SM_Payment__c clonedPayment = payment.clone();
                    clonedPayment.SM_Amount__c = amountToDependent;
                    clonedPayment.SM_Contract__c = dependent.Id;
                    clonedPayment.SM_Penalty_value__c = penaltyValueToDependent;
                    clonedPayment.SM_Fee_value__c = feeValueToDependent;

                    /** Add clne to list to insert */
                    clonedPayments.add(clonedPayment);
                }
            //}   
        }

        /** Insert cloned payments */
        if (!clonedPayments.isEmpty()) {
            insert clonedPayments;
        }
    }
}
