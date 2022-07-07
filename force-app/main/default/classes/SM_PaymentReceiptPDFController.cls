/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * @group             : 
 * @last modified on  : 06-15-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   05-01-2021   Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com   Initial Version
**/
public without sharing class SM_PaymentReceiptPDFController {

    public String id {get;set;}
    public SM_Payment__c payment {get;set;}
    public Boolean isCreditCard {get;set;}
    public String result {get;set;}
    public Map<String, String> statusByName = new Map<String, String>{
        SM_PaymentHelper.status.ACCEPTED => 'ACEPTADO',
        SM_PaymentHelper.status.REJECTED => 'RECHAZADO'
    };

    public SM_PaymentReceiptPDFController() {
        isCreditCard = false;
        System.debug('Executing SM_PaymentReceiptPDFController');
        id = ApexPages.currentPage().getParameters().get('id');
        // id = 'a041D000005A5JCQA0';
        System.debug('id: ' + id);
        payment = [SELECT Id, SM_Contract__c, SM_Amount__c, SM_Payment_Date__c, Payment_Status__c, SM_Contract__r.ContractNumber, SM_Contract__r.Account.Name, SM_Contract__r.SM_Email_to_send_contract__c,
                    SM_Payment_Method__r.SM_Payment_Type__c, SM_Payment_Method__r.RecordType.Name, SM_Payment_Method__r.SM_ACH_Account_Number__c, SM_Payment_Method__r.SM_Credit_Card_Number__c
                    FROM SM_Payment__c
                    WHERE Id = :id];
        if (payment.SM_Payment_Method__r.RecordType.Name == 'Credit Card') isCreditCard = true;
        result = statusByName.get(payment.Payment_Status__c);
        System.debug('payment: ' + payment);
    }
}