/**
 * @description       : Opportunity Object Handler
 * @author            : jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 02-04-2021
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-27-2020   jpachon@legal-credit.com   Initial Version
 * 1.1   02-14-2021   cjimenez@legal-credit.com   Initial Version
**/
public without sharing class SM_OpportunityHandler extends SM_TriggerHandler{

    /* Static variables */
    private static String reminderIdRT = SM_Utils.getRecordTypeIdByDeveloperName('Task', SM_TaskHelper.recordType.reminder);

    public SM_OpportunityHandler(String triggerName){
        super(triggerName);
    }

    
    /************* Overwrite DML methods *************/
    override public void beforeInsert() {
        try {
           // SRQ - SFDCMP-177
            addPricebook2(Trigger.new);
            updateNameOpprtunity(Trigger.new);
        } catch (Exception e) {
            System.debug('An error occurred in afterInsert Opportunity  '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }

    /************* Overwrite DML methods *************/
    override public void afterInsert() {
        try {
            List<Opportunity> oppsToSend = getOpportunitiesToSendFive9(Trigger.newMap);
            if(!oppsToSend.isEmpty()) {
                five9ListAssignmentProcess(oppsToSend);
            }
        } catch (Exception e) {
            System.debug('An error occurred in afterInsert Opportunity  '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }

    override public void afterUpdate() {
        try {
            // JSPA - SFDCMP-63
            processChangesInStageOrDisposition(Trigger.new, Trigger.oldMap);
            //Call method to create contracts
            createContracts(Trigger.new, Trigger.oldMap);
        } catch (Exception e) {
            System.debug('An error occurred in afterUpdate Opportunity  '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }

    /************* Auxiliar methods *************/

    /**
    * @description This method calls five9 helper to assign records to a five9 list
    * @author jpachon@legal-credit.com | 11-28-2020
    * @param newLeads
    **/
    public static void five9ListAssignmentProcess(List<Opportunity> records) {
        System.debug('newOpps: ' + JSON.serialize(records));
         List<Opportunity> temNewOpportunity=new List<Opportunity>();
        // No se crean Five9List para registros creados por formulario New Lead  Camilo Jimenez 10/12/2020
        for (Opportunity opportunity : records) {
           if(!opportunity.SM_Call_Inbound__c){
             temNewOpportunity.add(opportunity);
           }
        }
        SM_Five9Helper.ResultWrapper result = SM_Five9Helper.getFive9ListByRecordId(temNewOpportunity);
        if (!result.errorMsgByRecordId.containsKey('Error')) {
            if (!result.recordsToInsert.isEmpty()) {
                insertFive9ListItems(result.recordsToInsert);
            }
            // TO DO - Confirmar como identificar si debe o no reportar el error presentado durante el proceso de asignacion de lista
        } 
        System.debug('result: ' + JSON.serialize(result));        
    }

    /**
    * @description Method to insert five9 list item records
    * @author jpachon@legal-credit.com | 11-28-2020
    * @param records List<Five9LSP__Five9_List_Item__c>
    **/
    public static void insertFive9ListItems(List<Five9LSP__Five9_List_Item__c> records) {
        List<Database.SaveResult> sr = Database.insert(records, false);
        System.debug('sr: ' + JSON.serialize(sr));
    }

    /**
    * @description Method to return what opportunity records will be sent to five9 process
    * @author jpachon@legal-credit.com | 11-28-2020
    * @param newRecords Map<Id, SObject>
    * @return List<Opportunity>
    **/
    public static List<Opportunity> getOpportunitiesToSendFive9(Map<Id, SObject> newRecords) {
        System.debug('----> ' + newRecords.size());
        Map<Id, Opportunity> newOpps = (Map<Id, Opportunity>)newRecords.clone();
        for (Opportunity record : newOpps.values()) {
            if (record.SM_Conversion_opportunity__c) {
                newOpps.remove(record.Id);
            }
        }
        System.debug('----> ' + newOpps.size());
        return (List<Opportunity>)newOpps.values();
    }

    /**
    * @description Method to process opportunities when have changed stage or disposition value
    * @author jpachon@legal-credit.com | 11-28-2020
    * @param newOpps List<Opportunity>
    * @param oldMap Map<Id, SObject>
    **/
    public static void processChangesInStageOrDisposition(List<Opportunity> newOpps, Map<Id, SObject> oldMap) {
        Map<String, Opportunity> oppsToProcessById = new Map<String, Opportunity>();
        for (Opportunity newOpp : newOpps) {
            Opportunity oldOpp = (Opportunity)oldMap.get(newOpp.Id);
            if (SM_Utils.isChangedField(newOpp, oldOpp, new String[]{'StageName', 'SM_Opportunity_Disposition__c'})) {
                oppsToProcessById.put(newOpp.Id, newOpp);
            }
        }
        if (!oppsToProcessById.isEmpty()) {
            // Its REQUIRED get related data before insert the new records.
            List<Opportunity> oppsWithRelatedData = [SELECT Id, Name, 
                                                (SELECT Id FROM Five9LSP__Five9_List_Items__r),
                                                (SELECT Id, Subject, ActivityDate FROM Tasks WHERE RecordTypeId =: reminderIdRT AND IsRecurrence = FALSE AND Status =: SM_TaskHelper.status.open)
                                                FROM Opportunity WHERE Id IN: oppsToProcessById.keySet()];
            SM_Five9Helper.ResultWrapper result = SM_Five9Helper.getFive9ListByRecordId(oppsToProcessById.values());
            System.debug('result: ' + JSON.serialize(result));
            if (!result.recordsToInsert.isEmpty()){
                List<Database.SaveResult> srLst = Database.insert(result.recordsToInsert, false);
                System.debug('srLst: ' + JSON.serialize(srLst));
            }            
            processOldRelatedData(oppsWithRelatedData);
        }
    }
    
    /**
    * @description Method to process old related data like five9 list items or reminders (tasks)
    * @author jpachon@legal-credit.com | 11-28-2020
    * @param oppsWithRelatedData List<Opportunity>
    **/
    public static void processOldRelatedData(List<Opportunity> oppsWithRelatedData) {
        System.debug('oppsWithRelatedData: ' + JSON.serialize(oppsWithRelatedData));
        List<SObject> sObjectsToDelete = new List<SObject>();
        List<Task> remindersToUpdate = new List<Task>();
        for (Opportunity opp : oppsWithRelatedData) {
            if (!opp.Five9LSP__Five9_List_Items__r.isEmpty()) {
                sObjectsToDelete.addAll(opp.Five9LSP__Five9_List_Items__r);
            }
            if (!opp.Tasks.isEmpty()) {
                remindersToUpdate.addAll(opp.Tasks);
            }
        }
        // JSPA - SFDCMP-49
        if (!remindersToUpdate.isEmpty()) {
            for (Task reminder : remindersToUpdate) {
                if (reminder.ActivityDate <= System.today()) {
                    reminder.Status = SM_TaskHelper.status.completed;
                } else if (reminder.ActivityDate > System.today()) {
                    sObjectsToDelete.add(reminder);
                }
            }
            Database.update(remindersToUpdate, false);
        }
        System.debug('sObjectsToDelete: ' + JSON.serialize(sObjectsToDelete));
        if (!sObjectsToDelete.isEmpty()) {
            sObjectsToDelete.sort();
            List<Database.DeleteResult> rs = Database.delete(sObjectsToDelete, true);
            System.debug('rs: ' + JSON.serialize(rs));
        }
    }

    /**
    * @description Method to validate if generate contract
    * @author diego.jacanamijoy@gmail.com | 02-04-2021 
    * @param newOpps 
    * @param oldMap 
    **/
    public void createContracts(List<Opportunity> newOpps, Map<Id, SObject> oldMap){
        List<String> oppIdsvalids = new List<String>();
        List<String> dispositionsValids = new List<String>{SM_OpportunityHelper.dispositions.sale, SM_OpportunityHelper.dispositions.salePtp};
        for (Opportunity newOpp : newOpps) {
            Opportunity oldOpp = (Opportunity)oldMap.get(newOpp.Id);
            if (SM_Utils.isChangedField(newOpp, oldOpp, new String[]{'StageName', 'SM_Opportunity_Disposition__c'}) 
                    && newOpp.StageName == SM_OpportunityHelper.stageName.oriented 
                    && dispositionsValids.contains(newOpp.SM_Opportunity_Disposition__c)) {
                        oppIdsvalids.add(newOpp.Id);
            }
        }
        if(!oppIdsvalids.isEmpty()){
            new SM_GenerateContractController(oppIdsvalids);
        }
    }

    /**
    * @description Method Update Pricebook2Id
    * @author  cjimenez@legal-credit.com | 14-02-2021
    * @param newMap
    **/
    public static void addPricebook2(List<Opportunity> newOpps) {
       Map<String, String> compSettiToProcessById = new Map<String, String>();
       Set<Id> compaSetids = new Set<Id>();
       for (Opportunity newOpp : newOpps) {
            compaSetids.add(newOpp.SM_Company_Setting__c);
        }

       if(!compaSetids.isEmpty()) {
        for(SM_Company_setting__c compSetti : [SELECT Id,SM_Pricebook2Id__c
                                           FROM SM_Company_setting__c WHERE Id IN: compaSetids]){
            compSettiToProcessById.put(compSetti.Id, compSetti.SM_Pricebook2Id__c);            
          }
       }
       if(!compaSetids.isEmpty()) {
        for (Opportunity newOpp : newOpps) {
            String key=newOpp.SM_Company_Setting__c;
            String pricebook2Id = compSettiToProcessById.containsKey(key) ? compSettiToProcessById.get(key) : null;
            newOpp.Pricebook2Id=pricebook2Id;
          }
       }
    }

      /**
    * @description This method update name opportunity
    * @author cjimenez@legal-credit.com | 22-02-2021
    * @param newOpportunityLineItems 
    **/
    public void updateNameOpprtunity(List<Opportunity> newOpps){

        Map<String, String> compSettiToProcessById = new Map<String, String>();
        Map<String, String> customerNumberByAcc = new Map<String, String>();
        Set<Id> compaSetIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity newOpp : newOpps) {
             compaSetids.add(newOpp.SM_Company_Setting__c);
             accountIds.add(newOpp.AccountId);
         }
 
        if(!compaSetids.isEmpty()) {
         for(SM_Company_setting__c compSetti : [SELECT Id,SM_Pricebook2Id__c,SM_Abbreviated_Company__c
                                                FROM SM_Company_setting__c WHERE Id IN: compaSetIds]){
             compSettiToProcessById.put(compSetti.Id, compSetti.SM_Abbreviated_Company__c);            
           }
        }
        if(!accountIds.isEmpty()) {
         for(Account account:[SELECT id,name,SM_Customer_Number__pc
                                    FROM Account
                                    WHERE ID IN :accountIds]){
            customerNumberByAcc.put(account.id,account.SM_Customer_Number__pc);
         }
       }
        Datetime currentDate =DateTime.now();
      if(!compSettiToProcessById.isEmpty()) {
        for (Opportunity newOpp : newOpps) {
            String keyComp=newOpp.SM_Company_Setting__c;
            String keyAcc=newOpp.AccountId;
            String abbreviatedCompany = compSettiToProcessById.containsKey(keyComp) ? compSettiToProcessById.get(keyComp) : null;
            String customerNumber = customerNumberByAcc.containsKey(keyAcc) ? customerNumberByAcc.get(keyAcc) : null;
            newOpp.name='OPT_'+abbreviatedCompany+'_'+customerNumber+'_'+currentDate.format('dd_MM_yyyy');         
          }
       }
       
    }
}