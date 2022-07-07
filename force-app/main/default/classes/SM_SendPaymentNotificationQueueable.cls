/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * @group             :
 * @last modified on  : 06-13-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                Modification
 * 1.0   06-13-2021   Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com   Initial Version
**/
public class SM_SendPaymentNotificationQueueable implements Queueable{

    private String processToExecute;
    // private List<String> availablePaymentStatusToSendReceipt = System.label.AVAILABLE_PAYMENT_STATUS_TO_SEND_RECEIPT.split(',');
    private Map<Id, SObject> newRecordsMap;
    private List<SM_PaymentHelper.EmailWrapper> records;

    public SM_SendPaymentNotificationQueueable(String processToExecute, Map<Id, SObject> newRecordsMap, List<SM_PaymentHelper.EmailWrapper> records) {
        this.processToExecute = processToExecute;
        this.newRecordsMap = newRecordsMap;
        this.records = records;
    }

    public void execute(QueueableContext qc){
        switch on processToExecute {
            when 'sendEmail' {
                sendEmail();
            }
            when 'uploadDocument' {
                uploadDocument();
            }
            when else {
                System.debug('Option without implementation');
            }
        }
    }

    private void sendEmail() {
        Map<String, SM_Payment__c> paymentsReadOnly = new Map<String, SM_Payment__c>(
            [SELECT Id, Name, Payment_Status__c, SM_Contract__c, SM_Contract__r.ContractNumber, SM_Contract__r.SM_Email_to_send_contract__c, SM_Contract__r.SM_Opportunity__r.SM_Company_Setting__r.SM_Abbreviated_Company__c,
                    SM_Contract__r.SM_Account_Name__c
                    FROM SM_Payment__c WHERE Id IN :newRecordsMap.keySet()]
        );
        System.debug('paymentsReadOnly: ' + paymentsReadOnly);
        Map<String, String> emailByPaymentId = new Map<String, String>();
        // if (availablePaymentStatusToSendReceipt.isEmpty()) return;
        List<SM_PaymentHelper.EmailWrapper> recordsToProcess = new List<SM_PaymentHelper.EmailWrapper>();
        for (String paymentId : newRecordsMap.keySet()) {
            SM_Payment__c payment = (SM_Payment__c) newRecordsMap.get(paymentId);
            // if (availablePaymentStatusToSendReceipt.contains(payment.Payment_Status__c)) {
                String email = paymentsReadOnly.get(paymentId).SM_Contract__r.SM_Email_to_send_contract__c;
                String documentName = 'Payment Receipt - CT ' + paymentsReadOnly.get(paymentId).SM_Contract__r.ContractNumber + '-' + paymentsReadOnly.get(paymentId).Name + '.pdf';
                String subject = documentName;
                String body = String.format(System.label.EMAIL_BODY_PAYMENT_RECEIPT, new List<String>{paymentsReadOnly.get(paymentId).SM_Contract__r.SM_Account_Name__c});
                recordsToProcess.add(new SM_PaymentHelper.EmailWrapper(
                    email,
                    subject,
                    body,
                    'Payment Receipt',
                    documentName,
                    paymentId,
                    'Contract',
                    paymentsReadOnly.get(paymentId).SM_Contract__c,
                    true,
                    paymentsReadOnly.get(paymentId).SM_Contract__r.SM_Opportunity__r.SM_Company_Setting__r.SM_Abbreviated_Company__c
                ));
            // }
        }
        System.debug('recordsToProcess: ' + recordsToProcess);
        if (!recordsToProcess.isEmpty()) {
            // SM_PaymentHelper.sendPaymentReceipts(recordsToProcess);
            System.debug('Ready to execute future method - SM_PaymentHelper.sendPaymentReceipts');
            SM_PaymentHelper.sendPaymentReceipts(JSON.serialize(recordsToProcess));
        }
    }

    private void uploadDocument() {
        if (!records.isEmpty()) {
            System.debug('Ready to execute future method - SM_PaymentHelper.processRecordsAfterSendEmails');
            SM_PaymentHelper.processRecordsAfterSendEmails(JSON.serialize(records));
        }
    }
}