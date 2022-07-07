/**
 * @description       : Helper class of Five9 
 * @author            : jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 08-26-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-23-2020   jpachon@legal-credit.com   Initial Version
**/
@SuppressWarnings('PMD.ExcessiveParameterList,PMD.ApexCRUDViolation')
public without sharing class SM_Five9Helper {

    private static ResultWrapper result;
    private static Map<String, Five9_List_Assigment_Setting__mdt> settingBySObjectName;
    private static Map<String, SM_Setup_calls_distribute__c> setupCallDistributeByKey;
    private static Map<String, String> fieldNameBySObjectReference;


    private static final String FIVE9_LIST_OBJECT_NAME = 'Five9LSP__Five9_List__c';
    private static final String FIVE9_LIST_ITEM_OBJECT_NAME = 'Five9LSP__Five9_List_Item__c';
    private static final String COMPANY_SETTING_OBJECT_NAME = 'SM_Company_setting__c';
    private static final String TASK_OBJECT_NAME = 'Task';
    private static Map<String, ResultWrapper> responseById;
    private static String five9ListSetupCallsRT = SM_Utils.getRecordTypeIdByDeveloperName('SM_Setup_calls_distribute__c', SM_SetupCallsDistributeHelper.recordType.five9List);
    private static String reminderSetupCallsRT = SM_Utils.getRecordTypeIdByDeveloperName('SM_Setup_calls_distribute__c', SM_SetupCallsDistributeHelper.recordType.reminder);
    private static String reminderTaskRT = SM_Utils.getRecordTypeIdByDeveloperName('Task', SM_TaskHelper.recordType.reminder);

    /**
    * @description main method to process records to send to five9 or create reminders
    * @author jpachon@legal-credit.com | 01-18-2021
    * @param records List<SObject>
    * @return result ResultWrapper
    **/
    public static ResultWrapper getFive9ListByRecordId(List<SObject> records){
        result = new ResultWrapper();        
        getMetadata();
        getSetupCallDistribute();
        getFieldsF9LITToSetValue();
        if (validateRequiredData()) {
            for (SObject record : records) {
                processRecord(record);
            }
        }
        System.debug('result--> ' + JSON.serialize(result));
        return result;
    }

    /**
    * @description this method allows getting configuration to five9 list assigment
    * @author jpachon@legal-credit.com | 01-18-2021
    **/
    private static void getMetadata() {
        settingBySObjectName = new Map<String, Five9_List_Assigment_Setting__mdt>();
        List<Five9_List_Assigment_Setting__mdt> settings = [SELECT SM_SObject_Name__c, SM_Company_Setting_Field_Name__c, SM_Stage_or_Status_Field_Name__c, SM_Disposition_Field_Name__c 
                                                        FROM Five9_List_Assigment_Setting__mdt 
                                                        WHERE SM_Active__c =: TRUE];
        if(!settings.isEmpty()){
            for (Five9_List_Assigment_Setting__mdt mdtRecord : settings) {
                settingBySObjectName.put(mdtRecord.SM_SObject_Name__c, mdtRecord);
            }
        }
        System.debug('settingBySObjectName--> ' + JSON.serialize(settingBySObjectName));
    }

    /**
    * @description this method allows getting setup calls distribute records 
    * @author jpachon@legal-credit.com | 01-18-2021
    **/
    public static void getSetupCallDistribute() {        
        setupCallDistributeByKey = new Map<String, SM_Setup_calls_distribute__c>();
        List<SM_Setup_calls_distribute__c> setupCallDistribute = [SELECT Id, Name, RecordTypeId, SM_Five9_List__c, SM_Object__c, SM_Administration_Company__c, 
                                                        SM_Stage_or_Status__c, SM_Disposition__c, SM_Recurrence_Type__c, SM_Quantity_Daily_Reminders__c, SM_Reminder_Hour__c
                                                        FROM SM_Setup_calls_distribute__c 
                                                        WHERE SM_Active__c = true];
        if (!setupCallDistribute.isEmpty()) {
            for (SM_Setup_calls_distribute__c record : setupCallDistribute) {
                String key = record.SM_Administration_Company__c + '_' + record.SM_Object__c + '_' + record.SM_Stage_or_Status__c + '_' + record.SM_Disposition__c;
                setupCallDistributeByKey.put(key, record);
            }
        }
        System.debug('setupCallDistributeByKey--> ' + JSON.serialize(setupCallDistributeByKey));
    }
    
    /**
    * @description this method allows getting fields name from five list item object
    * @author jpachon@legal-credit.com | 01-18-2021
    **/
    public static void getFieldsF9LITToSetValue(){
        fieldNameBySObjectReference = new Map<String, String>();
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(FIVE9_LIST_ITEM_OBJECT_NAME).getDescribe().fields.getMap();
        for (String fieldName: fieldMap.keySet()) {
            Schema.DisplayType fieldDataType = fieldMap.get(fieldName).getDescribe().getType();
            if(fieldDataType == Schema.DisplayType.REFERENCE){
                String fieldLabel = fieldMap.get(fieldName).getDescribe().getLabel();
                String fieldReferenceTo =  String.valueOf(fieldMap.get(fieldName).getDescribe().getReferenceTo()[0]);
                if (fieldReferenceTo != 'User') {
                    fieldNameBySObjectReference.put(fieldReferenceTo, fieldName);
                }
            }
        }
        System.debug('fieldNameBySObjectReference--> ' + JSON.serialize(fieldNameBySObjectReference));
    }

    /**
    * @description atomic method to process each of one record
    * @author jpachon@legal-credit.com | 01-18-2021
    * @param record SObject 
    **/
    private static void processRecord(SObject record) {
        String recordId = (String)record.get('Id');
        String ownerId = (String)record.get('OwnerId');
        String sObjectName = SM_Utils.getSObjectNameById((Id)recordId);
        if (!settingBySObjectName.containsKey(sObjectName)) {
            result.errorMsgByRecordId.put(recordId, String.format('No existe configuracion para el tipo de objeto {0} en Five9_List_Assigment_Setting__mdt. Consulte con su administrador.', new List<String>{sObjectName}));
            return;
        }
        String companySettingId = (String)record.get(settingBySObjectName.get(sObjectName).SM_Company_Setting_Field_Name__c);
        String stageOrStatus = (String)record.get(settingBySObjectName.get(sObjectName).SM_Stage_or_Status_Field_Name__c);
        String disposition = (String)record.get(settingBySObjectName.get(sObjectName).SM_Disposition_Field_Name__c);
        if (String.isNotBlank(companySettingId) && String.isNotBlank(stageOrStatus) && String.isNotBlank(disposition)) {
            String keyToSearch = companySettingId + '_' + sObjectName + '_' + stageOrStatus + '_' + disposition;
            if (setupCallDistributeByKey.containsKey(keyToSearch)) {
                // JSPA - SFDCMP-75
                SM_Setup_calls_distribute__c confRecord = setupCallDistributeByKey.get(keyToSearch);
                if (confRecord.RecordTypeId == five9ListSetupCallsRT) {
                    String f9ListId = confRecord.SM_Five9_List__c;
                    createF9ListItemRecord(recordId, sObjectName, f9ListId);    
                } else if (confRecord.RecordTypeId == reminderSetupCallsRT) {
                    // JSPA - SFDCMP-75
                    createReminderTaskRecord(recordId, ownerId, sObjectName, confRecord);
                }
            } else {
                result.errorMsgByRecordId.put(recordId, 'No se encontro una lista con las condiciones necesarias para enviar este registro');
            }
        } else {
            result.errorMsgByRecordId.put(recordId, 'No tiene los campos requeridos para realizar el proceso de asignacion a lista de five9');
        }
    }

    /**
    * @description method to create a wrapper of five9 list item
    * @author jpachon@legal-credit.com | 01-18-2021
    * @param sObjectId String 
    * @param sObjectName String 
    * @param f9ListId String 
    **/
    private static void createF9ListItemRecord(String sObjectId, String sObjectName, String f9ListId){
        try {
            SObject sObj = SM_Utils.createSObject(FIVE9_LIST_ITEM_OBJECT_NAME);
            String fieldName = fieldNameBySObjectReference.get(sObjectName);
            sObj.put(fieldName, sObjectId);
            sObj.put(FIVE9_LIST_OBJECT_NAME, f9ListId);
            System.debug('sObj--> ' + JSON.serialize(sObj));
            result.recordsToInsert.add(sObj);
            // Database.SaveResult sr = Database.insert(sObj);
        } catch (Exception ex) {
            throw new SM_CustomException(ex.getMessage());
        }
    }

    /**
    * @description method to create a wrapper of reminder (task)
    * @author jpachon@legal-credit.com | 01-18-2021
    * @param sObjectId String 
    * @param ownerId String 
    * @param sObjectName String 
    * @param confRecord SM_Setup_calls_distribute__c 
    **/
    private static void createReminderTaskRecord(String sObjectId, String ownerId, String sObjectName, SM_Setup_calls_distribute__c confRecord) {
        System.debug('Executing createReminderTaskRecord');
        try {
            SObject sObj = SM_Utils.createSObject(TASK_OBJECT_NAME);
            // sObj.put('OwnerId', String.isNotBlank(ownerId) ? ownerId : UserInfo.getUserId());
            sObj.put('OwnerId', UserInfo.getUserId()); // JSPA - 08/26/2021
            sObj.put('Status', SM_TaskHelper.status.open);
            sObj.put('RecordTypeId', reminderTaskRT);
            sObj.put('Subject', 'Reminder to call back');
            sObj.put('IsRecurrence', true);
            sObj.put('IsReminderSet', true);
            sObj.put('ReminderDateTime', Datetime.newInstance(System.today().addDays(1), confRecord.SM_Reminder_Hour__c));
            sObj.put('RecurrenceType', confRecord.SM_Recurrence_Type__c);
            sObj.put('RecurrenceInterval', 1);
            sObj.put('RecurrenceStartDateOnly', System.today().addDays(1));
            sObj.put('RecurrenceEndDateOnly', System.today().addDays(Integer.valueOf(confRecord.SM_Quantity_Daily_Reminders__c)));

            if (sObjectName.equalsIgnoreCase('Lead')) {
                sObj.put('WhoId', sObjectId);                
            } else if (sObjectName.equalsIgnoreCase('Opportunity')) {
                sObj.put('WhatId', sObjectId);
            }
            System.debug('sObj--> ' + JSON.serialize(sObj));
            result.recordsToInsert.add(sObj);
        } catch (Exception ex) {
            throw new SM_CustomException(ex.getMessage());
        }
    }

    /**
    * @description method to validate required data
    * @author jpachon@legal-credit.com | 01-18-2021 
    * @return areThereConfData Boolean
    **/
    private static Boolean validateRequiredData() {
        Boolean areThereConfData = true;
        if (settingBySObjectName.isEmpty()) {
            result.errorMsgByRecordId.put('Error', 'No existe configuracion en el objeto Five9_List_Assigment_Setting__mdt');
            areThereConfData = false;
        } else if (setupCallDistributeByKey.isEmpty()) {
            result.errorMsgByRecordId.put('Error', 'No existe configuracion en el objeto SM_Setup_calls_distribute__c');
            areThereConfData = false;
        }
        return areThereConfData;
    }

    // Wrapper class to return all records to insert or handling custom errors
    public class ResultWrapper {
        public Map<String, String> errorMsgByRecordId {get; set;}
        public List<SObject> recordsToInsert {get;set;}

        public ResultWrapper() {
            this.errorMsgByRecordId = new Map<String, String>();
            this.recordsToInsert = new List<SObject>();
        }
    }

}