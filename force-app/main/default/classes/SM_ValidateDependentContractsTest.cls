/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> djacanamijoy@legal-credit.com
 * @group             : 
 * @last modified on  : 22/07/2022
 * @last modified by  : Diego Jacanamijoy -> djacanamijoy@legal-credit.com
**/
@IsTest
public with sharing class SM_ValidateDependentContractsTest {
    
    @TestSetup
    static void makeData(){

        /** Insert Account */
        Account account = SM_TestSmartDataFactory.getPersonAccount();
            account.PersonEmail='legal_credit@gmail.com.invalid';
            insert account;

        //List of contracts to insert
        List<Contract> contractsToInsert = new List<Contract>();

        /** Create master contract */
        Contract master = new Contract(
            AccountId = account.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 8,
            Contract_Type__c = 'Master',
            Collection_Main_Contract__c = 'Pending data capture'
        );
        insert master;

        /** Add dependent contracts */
        for(Integer i = 0; i < 5; i++){

            contractsToInsert.add(new Contract(
                AccountId = account.Id,
                Status = 'Draft',
                StartDate = Date.today(),
                ContractTerm = 8,
                Contract_Type__c = 'Dependent',
                Principal_Contract__c = master.Id,
                Collection_Main_Contract__c = 'Ready for collection',
                Contract_activation_form__c = 'Immediate activation	',
                SM_Requires_AC_Payment__c = true,
                SM_Payment_day__c = 5,
                SM_Frecuency__c = 'Monthly'
            ));
        }

        insert contractsToInsert;
        
    }

    @IsTest
    static void notUpdateMaster(){

        /** Get master */
        Contract master = [SELECT AccountId FROM Contract WHERE Contract_Type__c = 'Master' LIMIT 1];
        
        /** Create new master with don´t valida data */
        Contract dependent = new Contract(
                AccountId = master.AccountId,
                Status = 'Draft',
                StartDate = Date.today(),
                ContractTerm = 8,
                Contract_Type__c = 'Dependent',
                Principal_Contract__c = master.Id,
                Collection_Main_Contract__c = 'Pending data capture',
                Contract_activation_form__c = 'Immediate activation	',
                SM_Requires_AC_Payment__c = true
        );
        insert dependent;
        
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{dependent.Id => dependent};//Map old values
        /** Update value simulated trigger handler */
        dependent.Collection_Main_Contract__c = 'Ready for collection';
        /** List with new values */
        List<Contract> newRecords = new List<Contract>{dependent};

        Test.startTest();
            SM_ValidateDependentContracts.checkReadyForCollectionContracts(newRecords, oldRecordsMap);
        Test.stopTest();

        System.assertEquals('Pending data capture', [SELECT Collection_Main_Contract__c FROM Contract WHERE Contract_Type__c = 'Master' LIMIT 1].Collection_Main_Contract__c, 'Master should not be updated');
    }

    @IsTest
    static void acStarDateBlankError(){

        /** Get one dependent contract */
        Contract dependent = [SELECT Collection_Main_Contract__c, Contract_Type__c, Principal_Contract__c, SM_Requires_AC_Payment__c FROM Contract WHERE Contract_Type__c = 'Dependent' LIMIT 1];
        
        /** List with new values */
        List<Contract> newRecords = new List<Contract>{dependent};

        /** Simulate update record value */
        Contract dependeClone = dependent.clone();
        dependeClone.Collection_Main_Contract__c = 'Pending data capture';

        //Map old values
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{dependent.Id => dependeClone};

        Test.startTest();
            try {
                SM_ValidateDependentContracts.checkReadyForCollectionContracts(newRecords, oldRecordsMap);    
            } catch (Exception e) {
                System.assertEquals(true, e.getMessage().contains('Please verify that AC start date dates'));
            }
            
        Test.stopTest();

        System.assertEquals(true, newRecords[0].getErrors()[0].getMessage().contains('Please verify that AC start date dates'));
        System.assertEquals('Pending data capture', [SELECT Collection_Main_Contract__c FROM Contract WHERE Contract_Type__c = 'Master' LIMIT 1].Collection_Main_Contract__c, 'Master should not be updated');
    }

    @IsTest
    static void acStarDateLessError(){

        /** Set AC start date to dependent contracts */
        List<Contract> dependents = [SELECT Collection_Main_Contract__c, Contract_Type__c, Principal_Contract__c, SM_Requires_AC_Payment__c FROM Contract WHERE Contract_Type__c = 'Dependent'];
        for(Contract dependent: dependents){
            dependent.SM_AC_start_date__c = System.today().addDays(1);
        }

        /** Set one record with less today */
        dependents[0].SM_AC_start_date__c = System.today().addDays(-1);

        /** Update contracts */
        update dependents;
        
        /** List with new values */
        List<Contract> newRecords = new List<Contract>{dependents[0]};

        /** Simulate update record value */
        Contract dependeClone = dependents[0].clone();
        dependeClone.Collection_Main_Contract__c = 'Pending data capture';

        //Map old values
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{dependents[0].Id => dependeClone};

        Test.startTest();
            SM_ValidateDependentContracts.checkReadyForCollectionContracts(newRecords, oldRecordsMap);
        Test.stopTest();

        System.assertEquals(true, newRecords[0].getErrors()[0].getMessage().contains('Please verify that AC start date dates'));
        System.assertEquals('Pending data capture', [SELECT Collection_Main_Contract__c FROM Contract WHERE Contract_Type__c = 'Master' LIMIT 1].Collection_Main_Contract__c, 'Master should not be updated');
    }

    @IsTest
    static void acStarDateLessOk(){

        Integer plantMonthAux = 1;
        Date startDateAux = System.today();

        /** Set AC start date to dependent contracts */
        List<Contract> dependents = [SELECT Collection_Main_Contract__c, Contract_Type__c, Principal_Contract__c, SM_Requires_AC_Payment__c FROM Contract WHERE Contract_Type__c = 'Dependent'];
        for(Contract dependent: dependents){
            dependent.SM_AC_start_date__c = System.today().addDays(1);
            dependent.SM_Plan_Months__c = plantMonthAux;
            dependent.SM_Start_date__c = startDateAux;
            plantMonthAux ++;
            startDateAux.addDays(plantMonthAux);
        }

        /** Update contracts */
        update dependents;


        /** Update one record with fields to validate by lastmodifieddate */
        dependents[0].SM_Payment_day__c = 10;
        dependents[0].SM_Frecuency__c = 'Anual';
        update dependents[0];
        
        /** List with new values */
        List<Contract> newRecords = new List<Contract>{dependents[0]};

        /** Simulate update record value */
        Contract dependeClone = dependents[0].clone();
        dependeClone.Collection_Main_Contract__c = 'Pending data capture';

        //Map old values
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{dependents[0].Id => dependeClone};

        Test.startTest();
            SM_ValidateDependentContracts.checkReadyForCollectionContracts(newRecords, oldRecordsMap);
        Test.stopTest();

        /** Get master data  */
        Contract master = [SELECT Collection_Main_Contract__c, SM_Requires_AC_Payment__c, SM_AC_start_date__c, SM_Plan_Months__c, SM_Start_date__c, SM_Payment_day__c, SM_Frecuency__c FROM Contract WHERE Contract_Type__c = 'Master' LIMIT 1];

        System.assertEquals('Ready for collection', master.Collection_Main_Contract__c, 'Master should be updated');
        System.assertEquals(true, master.SM_Requires_AC_Payment__c, 'Master should be updated SM_Requires_AC_Payment__c field');
        System.assertEquals(System.today().addDays(1), master.SM_AC_start_date__c, 'Master should be updated SM_AC_start_date__c field');
        System.assertEquals(plantMonthAux - 1, master.SM_Plan_Months__c, 'Master should be updated SM_Plan_Months__c field');
        System.assertEquals(10, master.SM_Payment_day__c, 'Master should be updated SM_Payment_day__c field');
        System.assertEquals('Anual', master.SM_Frecuency__c, 'Master should be updated SM_Frecuency__c field');
    }

    @IsTest
    static void billingDataError(){

        /** Set SM_Payment_methods__c to dependent contracts */
        List<Contract> dependents = [SELECT Collection_Main_Contract__c, Contract_Type__c, Principal_Contract__c, SM_Requires_AC_Payment__c FROM Contract WHERE Contract_Type__c = 'Dependent'];
        for(Contract dependent: dependents){
            dependent.SM_Payment_methods__c = 'ACH';
            dependent.SM_Requires_AC_Payment__c = false;
        }

        /** Set one record with different value */
        dependents[0].SM_Payment_methods__c = 'Credit Card';

        /** Update contracts */
        update dependents;
        
        /** List with new values */
        List<Contract> newRecords = new List<Contract>{dependents[0]};

        /** Simulate update record value */
        Contract dependeClone = dependents[0].clone();
        dependeClone.Collection_Main_Contract__c = 'Pending data capture';

        //Map old values
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{dependents[0].Id => dependeClone};

        Test.startTest();
            SM_ValidateDependentContracts.checkReadyForCollectionContracts(newRecords, oldRecordsMap);
        Test.stopTest();

        System.assertEquals(true, newRecords[0].getErrors()[0].getMessage().contains('All dependent contracts should have the same billing data'));
        System.assertEquals('Pending data capture', [SELECT Collection_Main_Contract__c FROM Contract WHERE Contract_Type__c = 'Master' LIMIT 1].Collection_Main_Contract__c, 'Master should not be updated');
    }

    @IsTest
    static void billingDataOk(){

        /** Set SM_Payment_methods__c to dependent contracts */
        List<Contract> dependents = [SELECT Collection_Main_Contract__c, Contract_Type__c, Principal_Contract__c, SM_Requires_AC_Payment__c FROM Contract WHERE Contract_Type__c = 'Dependent'];
        for(Contract dependent: dependents){
            dependent.SM_Payment_methods__c = 'ACH';
            dependent.SM_Requires_AC_Payment__c = false;
        }

        /** Update contracts */
        update dependents;
        
        /** List with new values */
        List<Contract> newRecords = new List<Contract>{dependents[0]};

        /** Simulate update record value */
        Contract dependeClone = dependents[0].clone();
        dependeClone.Collection_Main_Contract__c = 'Pending data capture';

        //Map old values
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{dependents[0].Id => dependeClone};

        Test.startTest();
            SM_ValidateDependentContracts.checkReadyForCollectionContracts(newRecords, oldRecordsMap);
        Test.stopTest();

        System.assertEquals('Ready for collection', [SELECT Collection_Main_Contract__c FROM Contract WHERE Contract_Type__c = 'Master' LIMIT 1].Collection_Main_Contract__c, 'Master should not be updated');
    }

    @IsTest
    static void masterUpdatesOk(){

        /** Set SM_Payment_methods__c to dependent contracts */
        List<Contract> dependents = [SELECT Collection_Main_Contract__c, Contract_Type__c, Principal_Contract__c, SM_Requires_AC_Payment__c FROM Contract WHERE Contract_Type__c = 'Dependent'];
        for(Contract dependent: dependents){
            dependent.SM_Payment_methods__c = 'ACH';
            dependent.SM_Requires_AC_Payment__c = false;
        }

        /** Update contracts */
        update dependents;
        
        /** List with new values */
        List<Contract> newRecords = new List<Contract>{dependents[0]};

        /** Simulate update record value */
        Contract dependeClone = dependents[0].clone();
        dependeClone.Collection_Main_Contract__c = 'Pending data capture';

        //Map old values
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{dependents[0].Id => dependeClone};

        Test.startTest();
            SM_ValidateDependentContracts.checkReadyForCollectionContracts(newRecords, oldRecordsMap);
        Test.stopTest();

        System.assertEquals('Ready for collection', [SELECT Collection_Main_Contract__c FROM Contract WHERE Contract_Type__c = 'Master' LIMIT 1].Collection_Main_Contract__c, 'Master should not be updated');
    }

    @IsTest
    static void masterSumAssetDataOk(){

        /** Get master */
        Contract master = [SELECT Collection_Main_Contract__c, accountId FROM Contract WHERE Contract_Type__c = 'Master' LIMIT 1];

        List<Asset> assetsToInsert = new List<Asset>();

        /** Create Asset relates to master */
        for(Integer i = 0; i < 5; i++){

            Asset toMaster = SM_TestSmartDataFactory.getAsset(master.accountId, master.Id);
            toMaster.Contract_activation_form__c = 'Immediate activation';
            toMaster.AC_Price__c = 20;
            toMaster.Price = 20;

            /** Add to list to create */
            assetsToInsert.add(toMaster);
        }

        /** Set SM_Payment_methods__c to dependent contracts */
        List<Contract> dependents = [SELECT Collection_Main_Contract__c, Contract_Type__c, Principal_Contract__c, SM_Requires_AC_Payment__c FROM Contract WHERE Contract_Type__c = 'Dependent'];
        
        Integer auxCounter = 0;//Count total assets
        for(Contract dependent: dependents){
            dependent.SM_Requires_AC_Payment__c = false;

            /** Create Asset relates to dependet and master */
            for(Integer i = 0; i < 2; i++){

                Asset toDependent = SM_TestSmartDataFactory.getAsset(master.accountId, dependent.Id);
                toDependent.Principal_Contract__c = master.Id;
                toDependent.Contract_activation_form__c = 'Immediate activation';
                toDependent.AC_Price__c = 20;
                toDependent.Price = 20;

                auxCounter ++;

                /** Add to list to create */
                assetsToInsert.add(toDependent);
            }
        }

        /** Insert assets */
        insert assetsToInsert;

        /** Update contracts */
        update dependents;
        
        /** List with new values */
        List<Contract> newRecords = new List<Contract>{dependents[0]};

        /** Simulate update record value */
        Contract dependeClone = dependents[0].clone();
        dependeClone.Collection_Main_Contract__c = 'Pending data capture';

        //Map old values
        Map<Id, SObject> oldRecordsMap = new Map<Id, SObject>{dependents[0].Id => dependeClone};

        Test.startTest();
            SM_ValidateDependentContracts.checkReadyForCollectionContracts(newRecords, oldRecordsMap);
        Test.stopTest();

        master = [SELECT Collection_Main_Contract__c, SM_Total_ac__c, SM_Monthly_offer__c FROM Contract WHERE Contract_Type__c = 'Master' LIMIT 1];
        System.assertEquals('Ready for collection', master.Collection_Main_Contract__c, 'Master should  be updated');
        System.assertEquals(auxCounter * 20, master.SM_Total_ac__c, 'Master should  be updated SM_Total_ac__c field');
        System.assertEquals(auxCounter * 20, master.SM_Monthly_offer__c, 'Master should  be updated SM_Monthly_offer__c field');

    }
}
