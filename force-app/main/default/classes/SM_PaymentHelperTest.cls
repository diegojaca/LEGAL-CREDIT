/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             :
 * @last modified on  : 22/08/2022
 * @last modified by  : Diego Jacanamijoy -> djacanamijoy@legal-credit.com
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   03-27-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
@IsTest
public without sharing class SM_PaymentHelperTest {

    @TestSetup
    static void makeData(){
        
        insert new SM_Bypasser__c(SM_Disable_Validation_Rules__c = false, SetupOwnerId = UserInfo.getProfileId());

        Account account = SM_TestSmartDataFactory.getPersonAccount();
        account.PersonEmail='legal_credit@gmail.com.invalid';
        insert account;
        ChargentBase__Gateway__c Gt = SM_TestSmartDataFactory.getGateway();
        insert Gt;
        SM_Company_setting__c companySettingObj = SM_TestSmartDataFactory.getCompanySettingPMethod(Gt.Id);
        companySettingObj.SM_Abbreviated_Company__c = 'LCS';
        insert companySettingObj;
        APXTConga4__Conga_Solution__c conga4CongaSolutionObj = SM_TestSmartDataFactory.getConga4CongaSolutionObj();
        insert conga4CongaSolutionObj;
        Process_automation_by_product_family__c processautomationProductfamilyObj = SM_TestSmartDataFactory.getProcessautomationProductfamily(companySettingObj.id,conga4CongaSolutionObj.id);
        processautomationProductfamilyObj.SM_Generates_dispute__c = true;
        insert processautomationProductfamilyObj;
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        opp.SM_Company_Setting__c = companySettingObj.Id;
        insert opp;
        Contract contract = SM_TestSmartDataFactory.getContract(account.Id,processautomationProductfamilyObj.id);
        contract.SM_Email_to_send_contract__c = 'test@yopmail.com';
        contract.SM_Opportunity__c = opp.Id;
        insert contract;
        SM_Payment__c payment  = SM_TestSmartDataFactory.getPayment(contract.Id);
        insert payment;
    }

    @IsTest
    static void testDoNothing(){
        Test.startTest();
        String status = SM_PaymentHelper.status.ACCEPTED;
        Test.stopTest();
    }

    @IsTest
    static void testSendPaymentReceipt(){
        Contract ct = [SELECT Id FROM Contract];
        Test.startTest();
            SM_Payment__c payment  = SM_TestSmartDataFactory.getPayment(ct.Id);
            payment.Payment_Status__c = 'ACCEPTED';
            insert payment;
        Test.stopTest();
    }

    @IsTest
    static void setFeeToCollectFromFailetPaymentACHOk() {

        /** Insert Account */
        Account account = SM_TestSmartDataFactory.getPersonAccount();
            account.PersonEmail='legal_credit@gmail.com.invalid';
            insert account;

        /** Create master contract */
        Contract master = new Contract(
            AccountId = account.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 8,
            Contract_Type__c = 'Master',
            Collection_Main_Contract__c = 'Pending data capture',
            SM_Total_ac__c = 45.68
        );
        insert master;

        /** Create payment to master */
        SM_Payment__c masterPayment = new SM_Payment__c(
            SM_Contract__c = master.Id,
            SM_Amount__c = 35,
            SM_Penalty_value__c = 10.68,
            SM_Fee_value__c = 10.68,
            Installment_number__c = 2,
            Payment_Status__c = 'ACH PENDING'
        );
        insert masterPayment;

        /** Create ACH order */
        SM_ACH_Order__c achOrder = new SM_ACH_Order__c(
            SM_Payment_Type__c = SM_ACHOrderHelper.paymentType.LATE_PAYMENT_TYPE,
            SM_Next_Transaction_Date__c = System.toDay(),
            SM_Penalty_date__c = System.toDay().addDays(4),
            SM_Payment_Start_Date__c = System.toDay().addDays(2),
            SM_Apply_penalty__c = true,
            SM_Reason_to_approve_exoneration__c = 'Family Emergency',
            SM_Failed_Payment__c = masterPayment.Id
        );

        Test.startTest();
            SM_PaymentHelper.setFeeToCollectFromFailetPayment(new List<SObject>{achOrder});
        Test.stopTest();

        System.assertEquals(2, achOrder.SM_Fee_to_collect__c, 'SM_Fee_to_collect__c don´t updated');
    }

    @IsTest
    static void setFeeToCollectFromFailetPaymentChargentOk() {

        /** Insert Account */
        Account account = SM_TestSmartDataFactory.getPersonAccount();
            account.PersonEmail='legal_credit@gmail.com.invalid';
            insert account;

        /** Create master contract */
        Contract master = new Contract(
            AccountId = account.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 8,
            Contract_Type__c = 'Master',
            Collection_Main_Contract__c = 'Pending data capture',
            SM_Total_ac__c = 45.68
        );
        insert master;

        /** Create payment to master */
        SM_Payment__c masterPayment = new SM_Payment__c(
            SM_Contract__c = master.Id,
            SM_Amount__c = 35,
            SM_Penalty_value__c = 10.68,
            SM_Fee_value__c = 10.68,
            Installment_number__c = 3,
            Payment_Status__c = 'ACH PENDING'
        );
        insert masterPayment;

        /** Create chargent */
        ChargentOrders__ChargentOrder__c chargent = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Payment_Frequency__c = 'Once',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Tokenization__c = '1929826725-1841993424',
            SM_Payment_Type__c = SM_ACHOrderHelper.paymentType.LATE_PAYMENT_TYPE,
            Contract__c = master.Id,
            SM_Failed_Payment__c = masterPayment.Id
        );
        insert chargent;

        Test.startTest();
            SM_PaymentHelper.setFeeToCollectFromFailetPayment(new List<SObject>{chargent});
        Test.stopTest();

        System.assertEquals(3, chargent.SM_Fee_to_collect__c, 'SM_Fee_to_collect__c don´t updated');
    }

    @IsTest
    static void testUpdatePaymentStatus(){
        // Test.startTest();
        //     SM_Payment__c payment = [SELECT Id FROM SM_Payment__c];
        //     payment.Payment_Status__c = SM_PaymentHelper.status.ACH_TRANSMITTED;
        //     update payment;
        //     payment.Payment_Status__c = SM_PaymentHelper.status.ACCEPTED;
        //     update payment;
        //     payment.Payment_Status__c = SM_PaymentHelper.status.REJECTED;
        //     update payment;
        // Test.stopTest();
    }
}