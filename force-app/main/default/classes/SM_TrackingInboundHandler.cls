/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 04-05-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   04-01-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
public without sharing class SM_TrackingInboundHandler extends SM_TriggerHandler{

    public SM_TrackingInboundHandler(String triggerName){
        super(triggerName);
    }

    /************* Overwrite DML methods *************/
    override public void afterInsert(){
        try {
            updateContactAttemptInfo(Trigger.newMap);
        } catch (Exception e) {
            System.debug('An error occurred in afterInsert Tracking Inbound  '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }        
    }

    /************* Auxiliar methods *************/

    /**
    * @description This method update contact attempt info in Lead or Account related record
    * @author jpachon@legal-credit.com | 04-01-2020 
    * @param newRecordsMap 
    **/
    private void updateContactAttemptInfo(Map<Id, SObject> newRecordsMap) {
        Set<String> accountIds = new Set<String>();
        Set<String> leadIds = new Set<String>();
        Map<String, String> newRecordIdByRelatedObjId = new Map<String, String>();
        for (Id trackInId : (Set<Id>) newRecordsMap.keySet()) {
            SM_Tracking_Inbound__c trackIn = (SM_Tracking_Inbound__c)newRecordsMap.get(trackInId);
            if (String.isNotEmpty(trackIn.SM_AccountId__c)) {
                accountIds.add(trackIn.SM_AccountId__c);
                newRecordIdByRelatedObjId.put(trackIn.SM_AccountId__c, trackInId);
            } else if (String.isNotEmpty(trackIn.SM_LeadId__c)) {
                leadIds.add(trackIn.SM_LeadId__c);
                newRecordIdByRelatedObjId.put(trackIn.SM_LeadId__c, trackInId);
            }
        }
        String query = '';
        List<SObject> records = new List<SObject>();
        String fieldsStr = String.join(new List<String>{'Id','SM_Contact_Attempts_Quantity__c','SM_Last_Contact_Attempt_Date__c'}, ',');
        if (!accountIds.isEmpty()) {
            query = 'SELECT ' + fieldsStr + ' FROM Account WHERE Id IN (\'' + String.join(new List<String>(accountIds), '\',\'') + '\')';
            records.addAll(SM_AccountHelper.getAccountsByDinamicQuery(query));
        }
        if (!leadIds.isEmpty()) {
            query = 'SELECT ' + fieldsStr + ' FROM Lead WHERE Id IN (\'' + String.join(new List<String>(leadIds), '\',\'') + '\')';
            records.addAll(SM_LeadHelper.getLeasByDinamicQuery(query));
        }
        for (SObject record : records) {
            record.put('SM_Contact_Attempts_Quantity__c', record.get('SM_Contact_Attempts_Quantity__c') != null ? Integer.valueOf(record.get('SM_Contact_Attempts_Quantity__c')) + 1 : 1);
            // record.put('SM_Contact_Attempts_Quantity__c', newRecordsMap.get(newRecordIdByRelatedObjId.get((String)record.get('Id')).get('CreatedDate')));
            record.put('SM_Last_Contact_Attempt_Date__c', System.now());
        }
        if (!records.isEmpty()) {
            records.sort();
            Database.update(records);
        }
    }
    
}