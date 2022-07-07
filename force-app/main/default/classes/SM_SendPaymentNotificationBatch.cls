/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * @group             :
 * @last modified on  : 07-09-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                Modification
 * 1.0   07-09-2021   Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com   Initial Version
**/
global without sharing class SM_SendPaymentNotificationBatch implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{

    private static String query;
    private static String PENDING_TO_SEND = SM_PaymentHelper.receiptStatus.PENDING_TO_SEND;
    private static String SENT = SM_PaymentHelper.receiptStatus.SENT;
    private String process;
    private Boolean isSuccess = false;
    private List<SM_Payment__c> paymentsToUpdate = new List<SM_Payment__c>();
    private Map<String, SM_PaymentHelper.EmailWrapper> recordsToProcess;

    public SM_SendPaymentNotificationBatch(String process, Map<String, SM_PaymentHelper.EmailWrapper> recordsToProcess) {
        this.process = process;
        this.recordsToProcess = recordsToProcess != null ? recordsToProcess : new Map<String, SM_PaymentHelper.EmailWrapper>();
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        switch on process {
            when 'sendEmail' {
                query = 'SELECT Id, Name, Payment_Status__c, SM_Contract__c, SM_Contract__r.ContractNumber, SM_Contract__r.SM_Email_to_send_contract__c, ' +
                'SM_Contract__r.SM_Opportunity__r.SM_Company_Setting__r.SM_Abbreviated_Company__c, SM_Contract__r.SM_Account_Name__c ' +
                'FROM SM_Payment__c WHERE SM_Receipt_Status__c = :PENDING_TO_SEND';
            }
            when 'uploadDocument'{
                query = 'SELECT Id, Name, Payment_Status__c, SM_Contract__c, SM_Contract__r.ContractNumber, SM_Contract__r.SM_Email_to_send_contract__c, ' +
                'SM_Contract__r.SM_Opportunity__r.SM_Company_Setting__r.SM_Abbreviated_Company__c, SM_Contract__r.SM_Account_Name__c ' +
                'FROM SM_Payment__c WHERE SM_Receipt_Status__c = :SENT';
            }
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SM_Payment__c> scope) {
        switch on process {
            when 'sendEmail' {
                sendPaymentReceipts(scope);
            }
            when 'uploadDocument' {
                uploadDocuments(scope);
            }
            when else {
                System.debug('Process is unavailable');
            }
        }

    }

    public void finish(Database.BatchableContext bc) {
        if (isSuccess) {
            Database.executeBatch(new SM_SendPaymentNotificationBatch('uploadDocument', recordsToProcess), 10);
        }
    }

    /************* Auxiliar methods *************/
    private void sendPaymentReceipts(List<SM_Payment__c> payments) {
        for (SM_Payment__c payment : payments) {
            String email = payment.SM_Contract__r.SM_Email_to_send_contract__c;
            String documentName = 'Payment Receipt - CT ' + payment.SM_Contract__r.ContractNumber + '-' + payment.Name + '.pdf';
            String subject = documentName;
            String body = String.format(System.label.EMAIL_BODY_PAYMENT_RECEIPT, new List<String>{payment.SM_Contract__r.SM_Account_Name__c});
            recordsToProcess.put(payment.Id, new SM_PaymentHelper.EmailWrapper(
                email,
                subject,
                body,
                'Payment Receipt',
                documentName,
                payment.Id,
                'Contract',
                payment.SM_Contract__c,
                true,
                payment.SM_Contract__r.SM_Opportunity__r.SM_Company_Setting__r.SM_Abbreviated_Company__c
            ));
            paymentsToUpdate.add(new SM_Payment__c(Id = payment.Id, SM_Receipt_Status__c = SM_PaymentHelper.receiptStatus.SENT));
        }
        Blob pdfBlob;
        List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage message;
        for (SM_PaymentHelper.EmailWrapper record : recordsToProcess.values()) {
            if(record.hasAttachment) pdfBlob = SM_PaymentHelper.getBlobFromPDF(record.sObjectId, record.sourceObject);
            if (pdfBlob == null) continue;
            record.documentBlob = pdfBlob;
            message = SM_PaymentHelper.buildSingleMessage(record);
            messages.add(message);
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        System.debug('results: ' + results);
        if (!paymentsToUpdate.isEmpty()) Database.update(paymentsToUpdate);
        // processRecordsAfterSendEmails(recordsToProcess);
        isSuccess = true;
    }

    private void uploadDocuments(List<SM_Payment__c> payments) {
        paymentsToUpdate = new List<SM_Payment__c>();
        System.debug('Executing SM_PaymentHelper.processRecordsAfterSendEmails');
        // List<EmailWrapper> records = (List<EmailWrapper>)JSON.deserialize(wrapperJSON, List<EmailWrapper>.class);
        SM_CloudDocumentPath cloudDocumentPath = new SM_CloudDocumentPath();
        List<SM_Cloud_Document__c> lstCloudDocumentInser = new List<SM_Cloud_Document__c>();
        for (SM_Payment__c payment : payments) {
            SM_PaymentHelper.EmailWrapper record = recordsToProcess.get(payment.Id);
            System.debug('record: ' + record);
            SM_Cloud_Document__c cloudDocument = SM_PaymentHelper.createCloudDocument(cloudDocumentPath, record);
            if(cloudDocument != null) lstCloudDocumentInser.add(cloudDocument);
            paymentsToUpdate.add(new SM_Payment__c(Id = record.sObjectId, SM_Receipt_Status__c = SM_PaymentHelper.receiptStatus.UPLOADED_TO_S3));
        }
        List<Database.SaveResult> sr;
        System.debug('lstCloudDocumentInser: ' + lstCloudDocumentInser);
        System.debug('lstCloudDocumentInser: ' + lstCloudDocumentInser.size());
        if(!lstCloudDocumentInser.isEmpty()){
            sr = Database.insert(lstCloudDocumentInser);
            System.debug('lstCloudDocumentInser - sr: ' + sr);
            if (!paymentsToUpdate.isEmpty()) Database.update(paymentsToUpdate);
        }
    }
}