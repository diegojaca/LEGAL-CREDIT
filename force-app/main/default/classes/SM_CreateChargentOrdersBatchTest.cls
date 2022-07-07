/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * @group             : 
 * @last modified on  : 22/07/2021
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * Modifications Log 
 * Ver   Date         Author                                          Modification
 * 1.0   22/07/2021   Diego Jacanamijoy -> diego.jacanamijoy@s4g.es   Initial Version
**/
@IsTest
public with sharing class SM_CreateChargentOrdersBatchTest {
    
    static String CRON_EXP = '0 0 0 15 3 ? 2030';
    
    @TestSetup
    static void makeData(){
        ChargentBase__Gateway__c gateway = SM_TestSmartDataFactory.getGateway();
        insert gateway;
        Account account = SM_TestSmartDataFactory.getPersonAccount();
        account.PersonEmail = 'legal_credit@gmail.com.invalid';
        insert account;
        SM_Company_setting__c companySettingObj = SM_TestSmartDataFactory.getCompanySettingPMethod(gateway.Id);
        insert companySettingObj;
        Opportunity opp = SM_TestSmartDataFactory.getOpportunity();
        opp.AccountId = account.Id;
        opp.SM_Company_Setting__c = companySettingObj.Id;
        insert opp;
        Process_automation_by_product_family__c processautomationProductfamilyObj = SM_TestSmartDataFactory.getProcessautomationProductfamily(companySettingObj.id, null);
        insert processautomationProductfamilyObj;
        Contract contract = SM_TestSmartDataFactory.getContract(account.Id,processautomationProductfamilyObj.id);
        contract.SM_Opportunity__c = opp.Id;
        insert contract;
        Product2 prd2 = SM_TestSmartDataFactory.getproduct2NoInsert();
        prd2.SM_Way_to_pay__c = 'Fix Term';
        prd2.SM_Plan_Months__c = 7;
        insert prd2;
        Asset ast = SM_TestSmartDataFactory.getAsset(account.Id, contract.Id);
        ast.Product2Id = prd2.Id;
        ast.Price = 100;
        insert ast;

        insert new SM_Bypasser__c(SM_Disable_Validation_Rules__c = true, SetupOwnerId = UserInfo.getProfileId());

        ChargentOrders__ChargentOrder__c chargentOrder = SM_TestSmartDataFactory.getChargentorder(account.Id, contract, companySettingObj, 'AC');
        chargentOrder.ChargentOrders__Status__c = 'Initiated';
        chargentOrder.Contract__c = contract.Id;
        chargentOrder.SM_Purpose_of_Payment__c = 'Contract fee';
        chargentOrder.ChargentOrders__Billing_First_Name__c = 'Diego';
        chargentOrder.ChargentOrders__Billing_Last_Name__c = 'casas';
        chargentOrder.ChargentOrders__Billing_Address__c = 'diego.casas@monee.es';
        chargentOrder.ChargentOrders__Billing_City__c = 'SAN JUAN';
        chargentOrder.ChargentOrders__Billing_State__c = 'PR';
        chargentOrder.ChargentOrders__Billing_Zip_Postal__c = '00927';
        chargentOrder.ChargentOrders__Billing_Country__c = 'PUERTO RICO';
        insert chargentOrder;

        SM_Payment_Method__c paymentmethod = SM_TestSmartDataFactory.getPaymentMethod(account.Id, chargentOrder);
        paymentmethod.SM_Tokenization_status__c = SM_PaymentHelper.tokenizationStatus.PENDING;
        paymentmethod.SM_Chargent_Order__c = chargentOrder.Id;
        paymentMethod.SM_Credit_Card_expiration_month__c = '02';
        paymentMethod.SM_Credit_Card_expiration_year__c = '99';
        paymentMethod.SM_Credit_Card_Franchise__c = 'Visa';
        paymentMethod.SM_Credit_Card_Number__c = '4111111111111111';
        paymentMethod.SM_Payment_Type__c = 'Credit card';
        paymentMethod.SM_Credit_Card_CVV__c = '123';
        insert paymentmethod;

        contract.SM_Payment_Method__c = paymentmethod.Id;
        update contract;
    }

    @IsTest
    static void scheduleTest(){
        
        Test.startTest();
            SM_CreateChargentOrdersBatch createChargent = new SM_CreateChargentOrdersBatch();
            String jobID = system.schedule('Chargent creation Proccess', CRON_EXP, createChargent);
        Test.stopTest();
    }

    @IsTest
    static void emptyContractTest(){

        Account account = [SELECT Id FROM Account LIMIT 1];

        SM_Payment_Method__c payment = new SM_Payment_Method__c(
                SM_Account__c = account.Id,
                SM_Credit_Card_expiration_year__c = '25',
                SM_Credit_Card_expiration_month__c = '02',
                SM_Credit_Card_Number__c = '**** **** **** 1234',
                SM_Tokenization_status__c = SM_PaymentHelper.tokenizationStatus.PENDING        
            );
        insert payment;

        Test.startTest();
            SM_CreateChargentOrdersBatch createChargent = new SM_CreateChargentOrdersBatch();
            Id batchId = Database.executeBatch(createChargent);
        Test.stopTest();
        System.assertEquals(LABEL.EMPTY_RELATED_CONTRACTS_ERROR, [SELECT Tokenization_error_detail__c FROM SM_Payment_Method__c WHERE Id =: payment.Id LIMIT 1].Tokenization_error_detail__c, 'Must set error empty contract');
        System.assertEquals(SM_PaymentHelper.tokenizationStatus.ERROR, [SELECT SM_Tokenization_status__c FROM SM_Payment_Method__c WHERE Id =: payment.Id LIMIT 1].SM_Tokenization_status__c, 'Must set error status');
        
    }

    @IsTest
    static void crateChargentTest(){

        Account account = [SELECT Id FROM Account LIMIT 1];

        SM_Payment_Method__c payment = new SM_Payment_Method__c(
            SM_Account__c = account.Id,
            SM_Credit_Card_expiration_year__c = '99',
            SM_Credit_Card_expiration_month__c = '02',
            SM_Credit_Card_Number__c = '4111111111111111',
            SM_Payment_Type__c = 'Credit card',
            SM_Credit_Card_CVV__c = '123',
            SM_Credit_Card_Franchise__c = 'Visa',
            SM_Tokenization_status__c = SM_PaymentHelper.tokenizationStatus.PENDING        
            );
        insert payment;
        
        Contract contract = [SELECT Id FROM Contract LIMIT 1];
        contract.SM_Payment_Method__c = payment.Id;
        update contract;

        Test.startTest();
            SM_CreateChargentOrdersBatch createChargent = new SM_CreateChargentOrdersBatch();
            Id batchId = Database.executeBatch(createChargent);
        Test.stopTest();
        SM_Payment_Method__c paymentMethod = [SELECT SM_Tokenization_status__c, SM_Chargent_Order__c FROM SM_Payment_Method__c WHERE ID = :payment.Id LIMIT 1];
        System.assertEquals(SM_PaymentHelper.tokenizationStatus.PENDING, paymentMethod.SM_Tokenization_status__c, 'Must set tokenized');
        System.assertNotEquals(null, paymentMethod.SM_Chargent_Order__c, 'Must set related chargent order');
        
    }

    @IsTest
    static void crateChargentBullkTest(){

        Account account = [SELECT Id FROM Account LIMIT 1];
        Contract contract = [SELECT AccountId, Status, StartDate, ContractTerm, SM_Process_automation_by_product_family__c FROM Contract LIMIT 1];
        List<Contract> contracts = new List<Contract>();
        List<SM_Payment_Method__c> payments = new List<SM_Payment_Method__c>();
        for(Integer i = 0; i < 49; i++){
            payments.add(
                new SM_Payment_Method__c(
                    SM_Account__c = account.Id,
                    SM_Credit_Card_expiration_year__c = '99',
                    SM_Credit_Card_expiration_month__c = '02',
                    SM_Credit_Card_Number__c = '4111111111111111',
                    SM_Payment_Type__c = 'Credit card',
                    SM_Credit_Card_CVV__c = '123',
                    SM_Credit_Card_Franchise__c = 'Visa',
                    SM_Tokenization_status__c = SM_PaymentHelper.tokenizationStatus.PENDING        
                    )
            );
        }
        insert payments;

        //Relate contract
        for(SM_Payment_Method__c payment: payments){
            Contract newContract = contract.clone();
            newContract.SM_Payment_Method__c = payment.Id;
            contracts.add(newContract);
        }
        
        insert contracts;

        //System.assertEquals(50, [SELECT Count() FROM SM_Payment_Method__c WHERE SM_Chargent_Order__c = null] , 'Must be return 50');

        Test.startTest();
            SM_CreateChargentOrdersBatch createChargent = new SM_CreateChargentOrdersBatch();
            Id batchId = Database.executeBatch(createChargent, 50);
        Test.stopTest();
        System.assertEquals(50, [SELECT Count() FROM SM_Payment_Method__c WHERE SM_Chargent_Order__c <> null] , 'Must be return 50');
        
    }
}