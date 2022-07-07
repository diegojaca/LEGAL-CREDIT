/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * @group             :
 * @last modified on  : 07-24-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   04-08-2021   Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com   Initial Version
**/
@IsTest
public without sharing class SM_PaymentHandlerTest {

    @TestSetup
    static void makeData(){
        insert new SM_Bypasser__c(SM_Disable_Validation_Rules__c = false, SetupOwnerId = UserInfo.getProfileId());
        Account acc = SM_TestSmartDataFactory.getPersonAccount();
        insert new List<Account>{acc};
        SM_Company_setting__c companySettings = SM_TestSmartDataFactory.getCompanySetting();
        companySettings.SM_Late_payment_fee__c = 25;
        insert new List<SM_Company_setting__c>{companySettings};
        APXTConga4__Conga_Solution__c congaSolution = SM_TestSmartDataFactory.getConga4CongaSolutionObj();
        insert new List<APXTConga4__Conga_Solution__c>{congaSolution};
        Process_automation_by_product_family__c prdAutoByFamily = SM_TestSmartDataFactory.getProcessautomationProductfamily(companySettings.Id, congaSolution.Id);
        insert new List<Process_automation_by_product_family__c>{prdAutoByFamily};
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        opp.SM_Company_Setting__c = companySettings.Id;
        insert new List<Opportunity>{opp};
        Contract ct = SM_TestSmartDataFactory.getContract(acc.Id, prdAutoByFamily.Id);
        ct.SM_Opportunity__c = opp.Id;
        ct.SM_Email_to_send_contract__c = 'test@gmail.com';
        insert new List<Contract>{ct};
        SM_ACH_Order__c achOrd = SM_TestSmartDataFactory.getACHOrder(ct.Id);
        achOrd.SM_Next_Transaction_Date__c = System.today();
        achOrd.SM_Payment_Type__c = SM_ACHOrderHelper.paymentType.AC;
        achOrd.SM_Payment_Frequency__c = SM_ACHOrderHelper.paymentFrequency.ONCE;
        insert new List<SM_ACH_Order__c>{achOrd};
    }

    @IsTest
    static void testOncePaymentFrequency(){
        SM_ACH_Order__c achOrder = [SELECT Id, SM_Contract__c FROM SM_ACH_Order__c LIMIT 1];
        Test.startTest();
            SM_Payment__c newPayment = new SM_Payment__c(
                SM_ACH_Order__c = achOrder.Id,
                SM_Contract__c = achOrder.SM_Contract__c
            );
            insert newPayment;
        Test.stopTest();
        SM_ACH_Order__c updatedACHOrder = [SELECT Id, SM_Payment_Status__c, SM_Next_Transaction_Date__c FROM SM_ACH_Order__c WHERE Id = :achOrder.Id];
        System.assertEquals(SM_ACHOrderHelper.paymentStatus.COMPLETED, updatedACHOrder.SM_Payment_Status__c, 'The result is not the expected.');
        System.assertEquals(null, updatedACHOrder.SM_Next_Transaction_Date__c, 'The result is not the expected.');
    }

    @IsTest
    static void testMonthlyPaymentFrequency(){
        SM_ACH_Order__c achOrder = [SELECT Id, SM_Contract__c, SM_Quantity_of_scheduled_fees__c, SM_Payment_Frequency__c, SM_Next_Transaction_Date__c FROM SM_ACH_Order__c LIMIT 1];
        achOrder.SM_Payment_Frequency__c = SM_ACHOrderHelper.paymentFrequency.MONTHLY;
        achOrder.SM_Quantity_of_scheduled_fees__c = 2;
        update achOrder;
        Test.startTest();
            SM_Payment__c newPayment = new SM_Payment__c(
                SM_ACH_Order__c = achOrder.Id,
                SM_Contract__c = achOrder.SM_Contract__c
            );
            insert newPayment;
            SM_ACH_Order__c updatedACHOrder = [SELECT Id, SM_Payment_Status__c, SM_Next_Transaction_Date__c FROM SM_ACH_Order__c WHERE Id = :achOrder.Id];
            System.assertEquals(SM_ACHOrderHelper.paymentStatus.INITIATED, updatedACHOrder.SM_Payment_Status__c, 'The result is not the expected.');
            SM_Payment__c newPayment2 = new SM_Payment__c(
                SM_ACH_Order__c = achOrder.Id,
                SM_Contract__c = achOrder.SM_Contract__c
            );
            insert newPayment2;
            SM_ACH_Order__c updatedACHOrder2 = [SELECT Id, SM_Payment_Status__c, SM_Next_Transaction_Date__c FROM SM_ACH_Order__c WHERE Id = :achOrder.Id];
            System.assertEquals(SM_ACHOrderHelper.paymentStatus.COMPLETED, updatedACHOrder2.SM_Payment_Status__c, 'The result is not the expected.');
            System.assertEquals(null, updatedACHOrder2.SM_Next_Transaction_Date__c, 'The result is not the expected.');
        Test.stopTest();
    }

    @IsTest
    static void testSubscriptionPaymentType(){
        SM_ACH_Order__c achOrder = [SELECT Id, SM_Contract__c, SM_Payment_Type__c, SM_Next_Transaction_Date__c FROM SM_ACH_Order__c LIMIT 1];
        achOrder.SM_Payment_Type__c = SM_ACHOrderHelper.paymentType.SUBSCRIPTION;
        achOrder.SM_Payment_Frequency__c = SM_ACHOrderHelper.paymentFrequency.MONTHLY;
        update achOrder;
        Test.startTest();
            SM_Payment__c newPayment = new SM_Payment__c(
                SM_ACH_Order__c = achOrder.Id,
                SM_Contract__c = achOrder.SM_Contract__c
            );
            insert newPayment;
        Test.stopTest();
        SM_ACH_Order__c updatedACHOrder = [SELECT Id, SM_Payment_Status__c, SM_Next_Transaction_Date__c FROM SM_ACH_Order__c WHERE Id = :achOrder.Id];
        System.assertEquals(SM_ACHOrderHelper.paymentStatus.INITIATED, updatedACHOrder.SM_Payment_Status__c, 'The result is not the expected.');
    }

    @IsTest
    static void testAcceptedPayment(){
        SM_ACH_Order__c achOrder = [SELECT Id, SM_Contract__c, SM_Payment_Type__c, SM_Next_Transaction_Date__c FROM SM_ACH_Order__c LIMIT 1];
        SM_Payment__c newPayment = new SM_Payment__c(
            SM_ACH_Order__c = achOrder.Id,
            SM_Contract__c = achOrder.SM_Contract__c
        );
        insert newPayment;
        Test.startTest();
            newPayment.Payment_Status__c = 'ACCEPTED';
            update newPayment;
        Test.stopTest();
    }

    @IsTest
    static void testRejectedPayment(){
        SM_ACH_Order__c achOrder = [SELECT Id, SM_Contract__c, SM_Payment_Type__c, SM_Next_Transaction_Date__c FROM SM_ACH_Order__c LIMIT 1];
        SM_Payment__c newPayment = new SM_Payment__c(
            SM_ACH_Order__c = achOrder.Id,
            SM_Contract__c = achOrder.SM_Contract__c,
            SM_Amount__c = 69
        );
        insert newPayment;
        Test.startTest();
            newPayment.Payment_Status__c = 'REJECTED';
            update newPayment;
        Test.stopTest();
        SM_Company_setting__c settings = [SELECT Id, SM_Late_payment_fee__c FROM SM_Company_setting__c LIMIT 1];
        SM_ACH_Order__c newACHOrder = [SELECT Id, SM_Payment_Type__c, SM_Payment_Method__c, SM_Contract__c, SM_Payment_Frequency__c, SM_Payment_Status__c, SM_Fee_to_collect__c, SM_Total__c, SM_Penalty_value__c, SM_Penalty_date__c, SM_Apply_penalty__c, SM_User_who_applies_the_penalty__c, SM_Payment_Start_Date__c, SM_Payment_End_Date__c, SM_Next_Transaction_Date__c, SM_Payment_Condition__c, SM_Failed_payment__c  FROM SM_ACH_Order__c WHERE Id !=: achOrder.Id];
        System.assertEquals('Late payment fee', newACHOrder.SM_Payment_Type__c, 'The result is not the expected.');
        // System.assertEquals(newPayment.SM_Payment_Method__c, newACHOrder.SM_Payment_Method__c, 'The result is not the expected.');
        // System.assertEquals(newPayment.SM_Contract__c, newACHOrder.SM_Contract__c, 'The result is not the expected.');
        System.assertEquals('Once', newACHOrder.SM_Payment_Frequency__c, 'The payment frequency is not the expected.');
        System.assertEquals('Stopped', newACHOrder.SM_Payment_Status__c, 'The payment status is not the expected.');
        System.assertEquals(null, newACHOrder.SM_Fee_to_collect__c, 'The fee to collect is not the expected.');
        System.assertEquals(newPayment.SM_Amount__c + settings.SM_Late_payment_fee__c, newACHOrder.SM_Total__c, 'The total value is not the expected.');
        System.assertEquals(settings.SM_Late_payment_fee__c, newACHOrder.SM_Penalty_value__c, 'The penalty value is not the expected.');
        System.assertEquals(System.today(), newACHOrder.SM_Penalty_date__c, 'The penalty date is not the expected.');
        System.assertEquals(true, newACHOrder.SM_Apply_penalty__c, 'The apply penalty is not the expected.');
        System.assertEquals(UserInfo.getUserId(), newACHOrder.SM_User_who_applies_the_penalty__c, 'The user who applies the penaylty is not the expected.');
        //System.assertEquals(System.today(), newACHOrder.SM_Payment_Start_Date__c, 'The payment start date is not the expected.');
        //System.assertEquals(System.today(), newACHOrder.SM_Payment_End_Date__c, 'The payment end date is not the expected.');
        //System.assertEquals(System.today(), newACHOrder.SM_Next_Transaction_Date__c, 'The next transaction date is not the expected.');
        System.assertEquals('Fixed value', newACHOrder.SM_Payment_Condition__c, 'The payment condition is not the expected.');
        System.assertEquals(newPayment.Id, newACHOrder.SM_Failed_payment__c, 'The failed payment is not the expected.');
    }
}