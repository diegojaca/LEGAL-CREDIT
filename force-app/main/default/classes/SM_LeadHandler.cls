/**
 * @description       :
 * @author            : diego.jacanamijoy@gmail.com
 * @group             :
 * @last modified on  : 06-09-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                        Modification
 * 1.0   11-19-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
public without sharing class SM_LeadHandler extends SM_TriggerHandler{

    /* Static variables*/
    private static String reminderIdRT = SM_Utils.getRecordTypeIdByDeveloperName('Task', SM_TaskHelper.recordType.reminder);
    public static Map<Lead, Lead[]> leadsDuplicatesByLead;
    public static Map<Lead, Set<Account>> accountsDuplicatesByLead;
    private static Lead[] leadsWithoutDuplicates;
    private  Map<String, SM_Company_setting__c> companySettingsByName {
        get {
            if(companySettingsByName == null){
                companySettingsByName = SM_CompanySettingHelper.getMapCompanysSettingsByNames();
            }
            return companySettingsByName;
        }

        set { return; }
    }

    public SM_LeadHandler(String triggerName){
        super(triggerName);
    }

    /************* Overwrite DML methods *************/
    override public void beforeInsert(){
        try {
            formatFields(Trigger.new);
            prePopulateFields(Trigger.new);
            validateRequiredFields(Trigger.new);
            System.debug('------> ' + Trigger.new);
            System.debug('------> ' + JSON.serialize(Trigger.New));
        } catch (Exception e) {
            System.debug('An error occurred in beforeInsert Lead  '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }

    override public void asyncAfterInsert(){
        try {
            // JSPA - 06/01/2021 -  This conditional statement is temp during the migration
            Lead ld = (Lead)Trigger.new[0];
            if(ld.SM_Is_migrated__c) {
                five9ListAssignmentProcess(Trigger.new);
            } else {
                System.debug('Ready to execute future method - searchDuplicatesAsync');
                searchDuplicatesAsync(JSON.serialize(Trigger.new));
            }
            // JSPA - 06/01/2021 -  This conditional statement is temp during the migration

            // searchDuplicatesAsync(JSON.serialize(Trigger.new));
        } catch (Exception e) {
            System.debug('An error occurred in asyncAfterInsert Lead  '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }

    override public void beforeUpdate(){
        try {
            formatFields(Trigger.new, Trigger.oldMap);
            prePopulateFields(Trigger.new, Trigger.oldMap);
            validateKeysChanged(Trigger.new, Trigger.oldMap);
        } catch (Exception e) {
            System.debug('An error occurred in beforeUpdate Lead  '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }

    override public void afterUpdate() {
        try {
            // JSPA - SFDCMP-75
            processChangesInStageOrDisposition(Trigger.new, Trigger.oldMap);
        } catch (Exception e) {
            System.debug('An error occurred in beforeUpdate Lead  '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }

    /************* Auxiliar methods *************/

    /**
    * @description this method validate required fields
    * @author diego.jacanamijoy@gmail.com | 11-24-2020
    * @param newLeads
    **/
    public void validateRequiredFields(Lead[] newLeads){
        //Iterate new leads
        for(Lead lead: newLeads){
            if(companySettingsByName.containsKey(lead.SM_Destination_business_unit__c)){
                //set companysetting to Lead
                SM_Company_setting__c companySetting = companySettingsByName.get(lead.SM_Destination_business_unit__c);
                lead.SM_Company_Setting__c = companySetting.Id;
                if (!lead.SM_Is_migrated__c || (lead.SM_Is_migrated__c && String.isBlank(lead.Status))) {
                    List<String> fields1 = companySetting.SM_Fields_to_validate_duplicates__c <> null ?
                    companySetting.SM_Fields_to_validate_duplicates__c.split(';') : new List<String>();
                    List<String> fields2 = companySetting.SM_Fields_to_validate_duplicates2__c <> null ?
                    companySetting.SM_Fields_to_validate_duplicates2__c.split(';') : new List<String>();
                    String key1 = '';
                    String key2 = '';
                    //validate fields1
                    key1 = validateLeadFields(lead, fields1);
                    //validate fields2
                    key2 = validateLeadFields(lead, fields2);
                    //Validates if the two keys are empty, to mark as Not Qualified
                    if(String.isEmpty(key1) && String.isEmpty(key2)){
                        lead.status = SM_LeadHelper.leadStatusEnum.UNQUALIFIED;
                    }else{
                        lead.status = SM_LeadHelper.leadStatusEnum.NEW_STATUS;
                        lead.SM_key_for_duplicates__c = !String.isEmpty(key1) ? key1.removeEnd('-') : '';
                        lead.SM_key_for_duplicates_2__c = !String.isEmpty(key2) ? key2.removeEnd('-') : '';
                    }
                }
            }
        }
    }

    /**
    * @description this method validate if this lead contains data in required fields
    * @author diego.jacanamijoy@gmail.com | 11-24-2020
    * @param lead
    * @param fields
    **/
    public static String validateLeadFields(Lead lead, String[] fields){
        String key = '';
        for(String field: fields){
            if(lead.get(field) <> null){
                key += lead.get(field) + '-';
            }else{
                key = '';
                break;
            }
        }
        return key;
    }

    /**
    * @description this method call controller of search duplicates ashyncronous
    * @author diego.jacanamijoy@gmail.com | 11-24-2020
    * @param newLeadsJSON
    **/
    @Future
    public static void searchDuplicatesAsync(String newLeadsJSON){
        //Deserialze JSON
        Lead[] newLeads = (List<Lead>) JSON.deserialize(newLeadsJSON, List<Lead>.class);
        //if don´t manually created call method searchDuplicates from ashyncronous context
        Boolean manuallyCreated = newLeads[0].SM_ManuallyCreated__c;
        if(!manuallyCreated){
            leadsWithoutDuplicates = new List<Lead>();
            List<lead> leadsToDelete = searchDuplicates(newLeads, manuallyCreated);
            //Call method to update old records
            updateOldData(newLeads);
            //Call method to delete records with duplicates
            deleteRecordsWithDuplicates(leadsToDelete);
            //Call five9 method, with leads without duplicates
            five9ListAssignmentProcess(leadsWithoutDuplicates);
        }
    }

    /**
    * @description this method call controller of search duplicates
    * @author diego.jacanamijoy@gmail.com | 11-24-2020
    * @param newLeads
    **/
    public static Lead[] searchDuplicates(Lead[] newLeads, Boolean isManuallyCreated){
        //First search duplicates accounts
        searchAccountDuplicates(newLeads, isManuallyCreated);
        //validate records to search duplicates leads, and delete
        Lead[] leadsToSearchleads = new List<Lead>();
        List<lead> leadsToDelete = new List<Lead>();//Leads with duplicates, to delete
        for(Lead lead: accountsDuplicatesByLead.keySet()){
            if(accountsDuplicatesByLead.get(lead).size()>0){
                leadsToDelete.add(lead);
            }else{
                leadsToSearchleads.add(lead);
            }
        }
        //If no duplicate accounts, search duplicates leads
        if(!leadsToSearchleads.isEmpty()){
            searchLeadDuplicates(leadsToSearchleads);
        }
        //validate leads with duplicates leads
        if(leadsDuplicatesByLead <> null){
            for(Lead lead: leadsDuplicatesByLead.keySet()){
                if(leadsDuplicatesByLead.get(lead).size()>0){
                    leadsToDelete.add(lead);
                }else if(leadsWithoutDuplicates <> null){
                    leadsWithoutDuplicates.add(lead);
                }
            }
        }else{
            leadsDuplicatesByLead = new Map<Lead,List<Lead>>();
        }

        return leadsToDelete;
    }

    /**
    * @description This method search duplicates leads
    * @author diego.jacanamijoy@gmail.com | 12-06-2020
    * @param newLeads
    **/
    public static void searchLeadDuplicates(Lead[] newLeads){
        //Create instance of class by controll of leads duplicates
        SM_LeadDuplicateController leadDuplicateController = new SM_LeadDuplicateController(newLeads);
        leadsDuplicatesByLead = leadDuplicateController.initProcessing();
    }

    /**
    * @description This method search duplicates accounts
    * @author diego.jacanamijoy@gmail.com | 12-06-2020
    * @param newLeads
    **/
    public static void searchAccountDuplicates(Lead[] newLeads, Boolean isManuallyCreated){
        //Create instance of class by controll of accounts duplicates
        SM_AccountDuplicateController accountDuplicateController = new SM_AccountDuplicateController();
        accountsDuplicatesByLead = accountDuplicateController.getDuplicatesAccountsByLead(newLeads);
        if(!isManuallyCreated){
            accountDuplicateController.actionsForDuplicates(accountsDuplicatesByLead);
        }
    }

    /**
    * @description This method update old duplicate record
    * @author diego.jacanamijoy@gmail.com | 12-07-2020
    * @param newLeads
    **/
    public static void updateOldData(Lead[] newLeads){
        Set<SObject> sobjectToUpdate = new Set<SObject>();//Account or Leads to update
        //Iterate leads by search accounts or leads duplicates
        for(Lead lead: newLeads){
            //validate Accounts to update, or Leads to update
            if(accountsDuplicatesByLead.containsKey(lead) && accountsDuplicatesByLead.get(lead).size() > 0){
                List<Account> accountsAux = new List<Account>(accountsDuplicatesByLead.get(lead));
                sobjectToUpdate.add(SM_LeadHelper.updateOldRecord(lead, accountsAux[0]));
            }else if(leadsDuplicatesByLead.containsKey(lead) && leadsDuplicatesByLead.get(lead).size() > 0){
                sobjectToUpdate.add(SM_LeadHelper.updateOldRecord(lead, leadsDuplicatesByLead.get(lead)[0]));
            }
        }
        if(!sobjectToUpdate.isEmpty()){
            List<SObject> lstAux = new List<SObject>(sobjectToUpdate);
            lstAux.sort();
            update lstAux;
        }
    }

    /**
    * @description This method delete leads with duplicates
    * @author diego.jacanamijoy@gmail.com | 12-07-2020
    * @param leadsToDelete
    **/
    public static void deleteRecordsWithDuplicates(Lead[] leadsToDelete){
        //Validate if exist records to delete
        if(!leadsToDelete.isEmpty()){
            //Se comenta temporalmente para no afectar los formularios de creacion de Lead
            delete leadsToDelete;
        }
    }

    /**
    * @description This method calls five9 helper to assign records to a five9 list
    * @author jpachon@legal-credit.com | 11-27-2020
    * @param newLeads
    **/
    public static void five9ListAssignmentProcess(List<Lead> newLeads){
        System.debug('newLeads: ' + JSON.serialize(newLeads));
        List<Lead> temNewLeads=new List<Lead>();
        // No se crean Five9List para registros creados por formulario New Lead  Camilo Jimenez 08/12/2020
        for(Lead lead : newLeads){
            if(!lead.SM_Call_Inbound__c){
                temNewLeads.add(lead);
            }
        }
        if(!temNewLeads.isEmpty()){
            SM_Five9Helper.ResultWrapper result = SM_Five9Helper.getFive9ListByRecordId(temNewLeads);
            if (!result.recordsToInsert.isEmpty()){
                    insertFive9ListItems(result.recordsToInsert);
            // TO DO - Confirmar como identificar si debe o no reportar el error presentado durante el proceso de asignacion de lista
            }
            System.debug('result: ' + JSON.serialize(result));
        }
    }

    public static void insertFive9ListItems(List<Five9LSP__Five9_List_Item__c> records) {
        List<Database.SaveResult> srLst = Database.insert(records, false);
        System.debug('srLst: ' + JSON.serialize(srLst));
    }

    /**
    * @description This method update keys if is changed data
    * @author diego.jacanamijoy@gmail.com | 12-04-2020
    * @param newLead
    * @param oldLead
    **/
    public void validateKeysChanged(List<Lead> newsLeads, Map<Id, SObject> oldLeadMap){
        for(Lead newLead: newsLeads){
            Lead oldLead = (Lead) oldLeadMap.get(newLead.Id);
            if(companySettingsByName.containsKey(newLead.SM_Destination_business_unit__c)){
                SM_Company_setting__c companySetting = companySettingsByName.get(newLead.SM_Destination_business_unit__c);
                List<String> fieldsKey1 = companySetting.SM_Fields_to_validate_duplicates__c <> null ?
                                                                companySetting.SM_Fields_to_validate_duplicates__c.split(';') :
                                                                new List<String>();
                List<String> fieldsKey2 = companySetting.SM_Fields_to_validate_duplicates2__c <> null ?
                                                                companySetting.SM_Fields_to_validate_duplicates2__c.split(';') :
                                                                new List<String>();

                if(SM_Utils.isChangedField(newLead, oldLead, fieldsKey1)){
                    //validate fields1
                    String key1 = validateLeadFields(newLead, fieldsKey1);
                    if(String.isNotBlank(key1)){
                        newLead.SM_key_for_duplicates__c = key1.removeEnd('-');
                    }
                }

                if(SM_Utils.isChangedField(newLead, oldLead, fieldsKey2)){
                    //validate fields2
                    String key2 = validateLeadFields(newLead, fieldsKey2);
                    if(String.isNotBlank(key2)){
                        newLead.SM_key_for_duplicates_2__c = key2.removeEnd('-');
                    }
                }
            }
        }
    }

    /**
    * @description This method format data from update leads
    * @author diego.jacanamijoy@gmail.com | 01-18-2021
    * @param newsLeads
    * @param oldLeadMap
    **/
    public static void formatFields(List<Lead> newsLeads, Map<Id, SObject> oldLeadMap){
        for(Lead newLead: newsLeads){
            Lead oldLead = (Lead) oldLeadMap.get(newLead.Id);
            //Validate if change data
            if(SM_Utils.isChangedField(newLead, oldLead, 'Phone') && String.isNotBlank(newLead.Phone)){
                newLead.Phone = SM_Utils.formatPhone(newLead.Phone);
            }
        }
    }

    /**
    * @description This method format data from new leads
    * @author diego.jacanamijoy@gmail.com | 01-18-2021
    * @param newsLeads
    **/
    public static void formatFields(List<Lead> newsLeads){
        for(Lead newLead: newsLeads){
            if(String.isNotBlank(newLead.Phone)){
                newLead.Phone = SM_Utils.formatPhone(newLead.Phone);
            }
        }
    }

    /**
    * @description This method prepopulate fields, if changes data
    * @author diego.jacanamijoy@gmail.com | 12-17-2020
    * @param newsLeads
    * @param oldLeadMap
    **/
    public static void prePopulateFields(List<Lead> newsLeads, Map<Id, SObject> oldLeadMap){
        for(Lead newLead: newsLeads){
            Lead oldLead = (Lead) oldLeadMap.get(newLead.Id);
            //Populate SM_Terms_and_conditions_acceptance_date__c
            if(SM_Utils.isChangedField(newLead, oldLead, 'SM_Accept_Terms_and_conditions__c') && newLead.SM_Accept_Terms_and_conditions__c){
                newLead.SM_Terms_and_conditions_acceptance_date__c = System.now();
            }
        }
    }

    /**
    * @description This method prepopulate fields, if new data
    * @author diego.jacanamijoy@gmail.com | 12-23-2020
    * @param newsLeads
    **/
    public static void prePopulateFields(List<Lead> newsLeads){
        for(Lead newLead: newsLeads){
            //Populate SM_Terms_and_conditions_acceptance_date__c
            if(newLead.SM_Accept_Terms_and_conditions__c){
                newLead.SM_Terms_and_conditions_acceptance_date__c = System.now();
            }
        }
    }

    /**
    * @description Method to process leads when have changed status or disposition value
    * @author jpachon@legal-credit.com | 01-18-2021
    * @param newsLeads List<Lead>
    * @param oldMap Map<Id, SObject>
    **/
    public static void processChangesInStageOrDisposition(List<Lead> newLeads, Map<Id, SObject> oldMap) {
        Map<String, Lead> leadsToProcessById = new Map<String, Lead>();
        for (Lead newLead : newLeads) {
            Lead oldLead = (Lead)oldMap.get(newLead.Id);
            if (SM_Utils.isChangedField(newLead, oldLead, new String[]{'Status', 'SM_Lead_Disposition__c'})) {
                leadsToProcessById.put(newLead.Id, newLead);
            }
        }
        if (!leadsToProcessById.isEmpty()) {
            // Its REQUIRED get related data before insert the new records.
            List<Lead> leadsWithRelatedData = [SELECT Id, Name,
                                                (SELECT Id FROM Five9LSP__Five9_List_Items__r),
                                                (SELECT Id, Subject, ActivityDate FROM Tasks WHERE RecordTypeId =: reminderIdRT AND IsRecurrence = FALSE AND Status =: SM_TaskHelper.status.open)
                                                FROM Lead WHERE Id IN: leadsToProcessById.keySet()];
            SM_Five9Helper.ResultWrapper result = SM_Five9Helper.getFive9ListByRecordId(leadsToProcessById.values());
            System.debug('result: ' + JSON.serialize(result));
            if (!result.recordsToInsert.isEmpty()){
                List<Database.SaveResult> srLst = Database.insert(result.recordsToInsert, false);
                System.debug('srLst: ' + JSON.serialize(srLst));
            }
            processOldRelatedData(leadsWithRelatedData);
        }
    }

    /**
    * @description Method to process old related data like five9 list items or reminders (tasks)
    * @author jpachon@legal-credit.com | 01-18-2021
    * @param leadsWithRelatedData List<Lead>
    **/
    public static void processOldRelatedData(List<Lead> leadsWithRelatedData) {
        System.debug('leadsWithRelatedData: ' + JSON.serialize(leadsWithRelatedData));
        List<SObject> sObjectsToDelete = new List<SObject>();
        // List<Five9LSP__Five9_List_Item__c> f9ListItemsToDelete = new List<Five9LSP__Five9_List_Item__c>();
        List<Task> remindersToUpdate = new List<Task>();
        for (Lead ld : leadsWithRelatedData) {
            if (!ld.Five9LSP__Five9_List_Items__r.isEmpty()) {
                sObjectsToDelete.addAll(ld.Five9LSP__Five9_List_Items__r);
            }
            if (!ld.Tasks.isEmpty()) {
                remindersToUpdate.addAll(ld.Tasks);
            }
        }
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
        if (!sObjectsToDelete.isEmpty()) {
            sObjectsToDelete.sort();
            Database.delete(sObjectsToDelete, false);
        }
    }
}