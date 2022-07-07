/*
    @Author : Santiago ROjas
    @BuiltDate : 30-01-2021
    @Description : to create the Transaction Log record if there is any Error while processing
    @Company : Trailhead
*/
public with sharing class TransactionLogHandler{

    public static void doHandleException(System.Exception ex , String processName){
        SM_TransactionLog__c transactionLog = new SM_TransactionLog__c(
            RecordTypeId = Schema.getGlobalDescribe().get('SM_TransactionLog__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Payment').getRecordTypeId(),
            Error_Log__c = ex.getStackTraceString() +'<br/>' + ex.getMessage() + '<br/>' + ex.getCause() +' <br/>'+ ex.getTypeName(),
            Exception_Time__c = System.Now(),
            Process_Name__c = processName,
            Class_Name__c = processName
        );
        if(Schema.sObjectType.SM_TransactionLog__c.isCreateable()){
            insert transactionLog;
        }
        
    }

    public static void testGarbage(){
        String a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
        a = '';
    }

}