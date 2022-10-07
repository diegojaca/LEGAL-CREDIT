/**
 * @description       :
 * @author            : Diego Jacanamijoy -> djacanamijoy@legal-credit.com
 * @group             : LCS
 * @last modified on  : 07/10/2022
 * @last modified by  : Diego Jacanamijoy -> djacanamijoy@legal-credit.com
**/
public with sharing class SM_CancelContractHelper {

    /** This map contains the field and value by Sobject name, to update to cancel */
    private Map<String, List<String>> canceledDataByObjectType = new Map<String, List<String>>{
        'Asset' => new List<String>{'Status', 'Cancelled'},
        'SM_Dispute__c' => new List<String>{'SM_Status__c', 'Cancelled'},
        'SM_ACH_Order__c' => new List<String>{'SM_Payment_Status__c', 'Canceled'},
        'ChargentOrders__ChargentOrder__c' => new List<String>{'ChargentOrders__Status__c', 'Canceled'},
        'SM_Payment__c' => new List<String>{'Payment_Status__c', 'CANCELLED'},
        'Contract' => new List<String>{'Status', 'Cancelled'}
    };

    private Set<SObject> recordsToUpdate = new Set<SObject>();
    private Set<SObject> recordsToUpdate2 = new Set<SObject>();
    private List<SObject> recordsToInsert;

    // public static List<SM_Dispute__c> getDisputesByContract(Set<Id> contractIds){

    //     return [SELECT SM_Status__c, SM_Email_to_send_contract__c,
    //                     (SELECT Id FROM Tasks)
    //             FROM SM_Dispute__c];
    // }

    public List<Contract> getContractsData(Set<String> contractIds){

        return [SELECT
                    (SELECT Id FROM Assets__r),
                    (SELECT Id FROM Disputes__r),
                    (SELECT Id FROM ACH_Orders__r),
                    (SELECT Id FROM Chargent_Orders__r),
                    (SELECT Id FROM Payment_Data__r WHERE SM_ACH_Order__c <> null AND Payment_Status__c = 'ACH PENDING'),
                    (SELECT Id, RecordTypeId, WhoId, WhatId, Subject, ActivityDate, Status, Priority, OwnerId, Description, CallDurationInSeconds, CallType, CallDisposition,
                        CallObject, ReminderDateTime, IsReminderSet, RecurrenceStartDateOnly, RecurrenceEndDateOnly, RecurrenceTimeZoneSidKey, RecurrenceType, RecurrenceInterval,
                        RecurrenceDayOfWeekMask, RecurrenceDayOfMonth, RecurrenceInstance, RecurrenceMonthOfYear, RecurrenceRegeneratedType, Five9__Five9SessionId__c,
                        Five9__Five9TaskType__c, Five9ANI__c, Five9AgentExtension__c, Five9AgentName__c, Five9Agent__c, Five9CallType__c, Five9Campaign__c, Five9DNIS__c,
                        Five9HandleTime__c, Five9InteractionDuration__c, Five9WrapTime__c, SM_Description_Filter__c, SM_TextAssignedTo__c, SM_Id_Salesforce_LCS__c,
                        SM_Migration_Date__c, SM_Is_Migrated__c
                        FROM Tasks),
                    (SELECT OwnerId, Name, SM_Account__c, SM_Active__c, SM_Abbreviated_Company__c, SM_Extension__c, SM_File_Path__c, SM_Documet_Type__c, SM_Lead__c,
                        SM_Opportunity__c, SM_Contract__c
                        FROM SM_Cloud_Documents_Contract__r)
                FROM Contract
                WHERE Id IN: contractIds];
    }

    /**
    * @description This methos excecute de proccess to cancel dependent contracts and related records
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 07/10/2022 
    * @param contractIds 
    **/
    public void cancelDependentContracts(Set<String> contractIds) {
        
        Set<String> dependentContractIds = new Set<String>();

        for (Contract dependent : [SELECT Id FROM Contract WHERE Principal_Contract__c IN: contractIds]) {
            dependentContractIds.add(dependent.Id);
        }

        if (!dependentContractIds.isEmpty()) {
            /** Send records to cancel */
            cancelRecords(getContractsData(dependentContractIds), true);   
        }
    }

    public Set<String> getAvailableContractsToUpgrade(Map<String,String> opportunityIdsByContractId, Map<String,Opportunity> updatedOpportunityByContractIds) {
        Set<String> availableContractToUpgradeIds = new Set<String>();
        for (String  ctId : opportunityIdsByContractId.keySet()) {
            if (updatedOpportunityByContractIds.containsKey(ctId)) {
                Opportunity opp = updatedOpportunityByContractIds.get(ctId);
                if (opp.SM_MeetsUpgradeConditions__c == 'You can Upgrade') {
                    availableContractToUpgradeIds.add(ctId);
                } else {
                    String description = System.label.SM_ERROR_CANCEL_UPGRADED_CONTRACT_PROCESS;
                    String errorDetail = 'Meets Upgrade Condition: ' + opp.SM_MeetsUpgradeConditions__c + ' - Upgraded Process Detail: ' + opp.SM_UpgradeProcessDetail__c;
                    description = String.format(description, new List<String>{ctId, errorDetail});
                    TransactionLogHandler.doHandleException(description, 'CancelUpgradedContract', ctId);
                    SM_TaskHelper.createTaskToValidateErrorInUpgradedContract(description, ctId);
                }
            }
        }
        return availableContractToUpgradeIds;
    }

    public void cancelRecords(List<Contract> upgradedContracts, Boolean cancelContract){

        
        Map<String,SM_ACH_Order__c> ordersToProcess = new Map<String,SM_ACH_Order__c>();

        /** Check related lists by contract, to update to cancel */
        for (Contract upgradedContract : upgradedContracts) {

            if (!upgradedContract.Assets__r.isEmpty()) {
                setCanceledStatusByObject(upgradedContract.Assets__r);
            }

            if (!upgradedContract.Disputes__r.isEmpty()) {
                setCanceledStatusByObject(upgradedContract.Disputes__r);
            }

            if (!upgradedContract.Chargent_Orders__r.isEmpty()) {
                setCanceledStatusByObject(upgradedContract.Chargent_Orders__r);
            }

            if (!upgradedContract.Payment_Data__r.isEmpty()) {
                setCanceledStatusByObject(upgradedContract.Payment_Data__r);
            }

            // ordersToProcess.putAll(upgradedContract.ACH_Orders__r);
            if (!upgradedContract.ACH_Orders__r.isEmpty()) {
                validateACHOrders(upgradedContract.ACH_Orders__r);
                // setCanceledStatusByObject(upgradedContract.ACH_Orders__r);
            }

            if (cancelContract) {
                setCanceledStatusByObject(new List<SObject>{upgradedContract});
            }
        }
        // cancelAndStopACHOrders(ordersToProcess);

        /** Update records */
        //updateRecords();
    }

    private void validateACHOrders(List<SM_ACH_Order__c> achOrders) {
        Map<String,SM_ACH_Order__c> achOrdersById = new Map<String,SM_ACH_Order__c>(achOrders);
        List<SM_ACH_Order__c> achOrdersRO = [SELECT Id, (SELECT Id FROM Payments__r WHERE Payment_Status__c =: SM_PaymentHelper.status.ACH_PENDING)
                                                FROM SM_ACH_Order__c
                                                WHERE Id IN: achOrdersById.keySet()
                                                AND SM_Payment_Status__c !=: SM_ACHOrderHelper.paymentStatus.COMPLETED];
        System.debug('achOrdersRO: ' + JSON.serialize(achOrdersRO));
        List<SM_Payment__c> paymentsToCancel = new List<SM_Payment__c>();
        List<SM_ACH_Order__c> achOrdersWithPaymentToCancel = new List<SM_ACH_Order__c>();
        List<SM_ACH_Order__c> achOrdersWithoutPaymentToCancel = new List<SM_ACH_Order__c>();
        for(SM_ACH_Order__c achOrder : achOrdersRO) {
            if(!achOrder.Payments__r.isEmpty()) {
                paymentsToCancel.addAll(achOrder.Payments__r);
                achOrdersWithPaymentToCancel.add(achOrder);
            } else {
                achOrdersWithoutPaymentToCancel.add(achOrder);
            }
        }
        if(!paymentsToCancel.isEmpty()) {
            setCanceledStatusByObject(paymentsToCancel);
        }
        if(!achOrdersWithoutPaymentToCancel.isEmpty()) {
            setCanceledStatusByObject(achOrdersWithoutPaymentToCancel);
        }
        if(!achOrdersWithPaymentToCancel.isEmpty()) {
            setCanceledStatusByObject2(achOrdersWithPaymentToCancel);
        }
    }

    // private static void cancelAndStopACHOrders(Map<String,SM_ACH_Order__c> ordersToProcess) {
    //     Set<String> orderIds = new Set<String>();
    //     List<SM_ACH_Order__c> ordersToCancel = new List<SM_ACH_Order__c>();
    //     List<SM_ACH_Order__c> ordersToStop = new List<SM_ACH_Order__c>();
    //     Set<String> paymentId = new Set<String>();
    //     List<String> lstStatusPayment = new List<String>{SM_PaymentHelper.status.ACH_PENDING,SM_PaymentHelper.status.ACH_TRANSMITTED};
    //     for (SM_ACH_Order__c achOrder : [SELECT Id, (SELECT Id FROM Payments__r WHERE Payment_Status__c IN: lstStatusPayment) FROM SM_ACH_Order__c WHERE Id =: ordersToProcess.keySet()]) {
    //         if (achOrder.Payments__r.size() > 0) {
    //             ordersToStop.add(achOrder);
    //         } else {
    //             ordersToCancel.add(achOrder);
    //         }
    //     }
    //     setCanceledStatusByObject(ordersToCancel, 'SM_Payment_Status__c', 'Canceled');
    //     setCanceledStatusByObject(ordersToStop, 'SM_Payment_Status__c', 'Stopped');
    // }


    public void setCanceledStatusByObject(List<SObject> sobjects){
        String sobjectName = SM_Utils.getSObjectNameById((Id)sobjects[0].get('Id'));
        List<String> cancelData = canceledDataByObjectType.get(sobjectName);
        for (SObject so : sobjects) {
            so.put(cancelData[0], cancelData[1]);
            recordsToUpdate.add(so);
        }
    }

    public void setCanceledStatusByObject2(List<SObject> sobjects){
        String sobjectName = SM_Utils.getSObjectNameById((Id)sobjects[0].get('Id'));
        List<String> cancelData = canceledDataByObjectType.get(sobjectName);
        for (SObject so : sobjects) {
            so.put(cancelData[0], cancelData[1]);
            recordsToUpdate2.add(so);
        }
    }

    // private static void setCanceledStatusByObject(List<SObject> sObjectsToUpdate, String field, String value){

    //     for(SObject so: sObjectsToUpdate){
    //         so.put(field, value);
    //         recordsToUpdate2.add(so);
    //     }
    // }

    public void cloneRecords(List<Contract> upgradedContracts, Map<String,String> newContractByUpgraded){

        recordsToInsert = new List<SObject>();

        for (Contract upgradedContract : upgradedContracts) {
            /** Clone tasks */
            for (Task task : upgradedContract.Tasks) {
                Task clonedTask = task.clone(false, true, true, false);
                clonedTask.WhatId = newContractByUpgraded.get(upgradedContract.Id);
                recordsToInsert.add(clonedTask);
            }

            /** Clone cloud documents */
            for (SM_Cloud_Document__c cloudDocument : upgradedContract.SM_Cloud_Documents_Contract__r) {
                SM_Cloud_Document__c cloneCloudDocument = cloudDocument.clone();
                cloneCloudDocument.SM_Contract__c = newContractByUpgraded.get(upgradedContract.Id);
                recordsToInsert.add(cloneCloudDocument);
            }
        }
    }

    public void updateRecords(){

        if (!recordsToUpdate.isEmpty()) {
            //List aux to short and update unique records
            List<SObject> auxListToUpdate = new List<SObject>(recordsToUpdate);
            auxListToUpdate.sort();
            SM_TriggerHandler.avoidAllHandlerExcecution = true;
            update auxListToUpdate;
            SM_TriggerHandler.avoidAllHandlerExcecution = false;
        }
        if (!recordsToUpdate2.isEmpty()) {
            //List aux to short and update unique records
            List<SObject> auxListToUpdate = new List<SObject>(recordsToUpdate2);
            auxListToUpdate.sort();
            update auxListToUpdate;
        }
    }

    public void insertRecords(){

        if(!recordsToInsert.isEmpty()){
            recordsToInsert.sort();
            insert recordsToInsert;
        }
    }

}