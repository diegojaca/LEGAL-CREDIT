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
global without sharing class SM_CreateChargentOrdersBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable{

    global SM_Batch_panel__mdt batchPanel;
    global Integer batchSize;
    global Integer limitQuery;

    /**
    * @description Constructor
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 22/07/2021 
    **/
    global SM_CreateChargentOrdersBatch(){

        batchPanel =[Select SM_BatchSize__c, SM_LimitQuery__c, SM_SendEmail__c 
                From SM_Batch_panel__mdt Where DeveloperName ='CreateChargent' Limit 1];
        batchSize = Test.isRunningTest() ? 50 : Integer.valueOf(batchPanel.SM_BatchSize__c);
        limitQuery = Test.isRunningTest() ? 50 : Integer.valueOf(batchPanel.SM_LimitQuery__c);        
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 22/07/2021 
    * @param bc 
    * @return Database.QueryLocator 
    **/
    global Database.QueryLocator start(Database.BatchableContext bc){

        String tokenizationPending = SM_PaymentHelper.tokenizationStatus.PENDING;

        String query = 'SELECT (SELECT AccountId, SM_Opportunity__r.SM_Company_Setting__r.SM_Gateway__c, SM_Billing_Address__r.PostalCode, SM_Billing_Address__r.Country,'
        + ' SM_Billing_Address__r.State, SM_Billing_Address__r.City, SM_Billing_Address__r.Street FROM Contracts__r),'
        + ' SM_Chargent_Order__c, SM_Payment_Type__c, SM_Credit_Card_expiration_month__c, SM_Credit_Card_expiration_year__c,'
        + ' SM_Credit_Card_Franchise__c, SM_Credit_Card_Number__c, SM_Account__r.FirstName, SM_Account__r.LastName, SM_Credit_Card_CVV__c,'
        + ' SM_Chargent_Order__r.ChargentOrders__Billing_First_Name__c, SM_Chargent_Order__r.ChargentOrders__Billing_Last_Name__c, SM_Chargent_Order__r.ChargentOrders__Billing_Address__c,'
        + ' SM_Chargent_Order__r.ChargentOrders__Billing_City__c, SM_Chargent_Order__r.ChargentOrders__Billing_State__c, SM_Chargent_Order__r.ChargentOrders__Billing_Zip_Postal__c,'
        + ' SM_Chargent_Order__r.ChargentOrders__Billing_Country__c, SM_Chargent_Order__r.ChargentOrders__Charge_Amount__c'
        + ' FROM SM_Payment_Method__c WHERE SM_Tokenization_status__c = :tokenizationPending AND SM_Chargent_Order__c = null LIMIT ' + limitQuery;

        return Database.getQueryLocator(query);
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 22/07/2021 
    * @param bc 
    * @param scope 
    **/
    global void execute(Database.BatchableContext bc, List<SM_Payment_Method__c> scope) {

        SM_TokenizationHandler processHandler = new SM_TokenizationHandler(scope);
        processHandler.createChargents();
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 22/07/2021 
    * @param bc 
    **/
    global void finish(Database.BatchableContext bc){
        
        // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        CronTrigger[] lastJobId = [SELECT CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name LIKE 'Chargent creation Proccess%' ORDER BY CREATEDDATE ASC];

        //then use the active job id and abort it
        if(!lastJobId.isEmpty()){
            system.abortJob(lastJobId[0].Id);
        }
        
        //Excecute tokenization batch
        SM_TokenizationtBatch tokenization = new SM_TokenizationtBatch();
        String sch = getNextCron();
        String batchJob = system.schedule('Tokenizationt Proccess1', sch, tokenization);
        
    }

    /**
    * @description This method return next cron expresion to execute Job
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 16/07/2021g 
    * @return String 
    **/
    public String getNextCron() {

        Integer hour = Datetime.now().hour();
        Integer min = Datetime.now().minute() + 2; 
        String ss = String.valueOf(Datetime.now().second());

        //validate las minutes, if current minutes > 59, execute Job in 1 minutes of next hour
        if(min > 59) {
            min = 02;
            hour ++;
        }

        //parse to cron expression
        return ss + ' ' + String.valueOf(min) + ' ' + String.valueOf(hour) + ' * * ?';
    }

    /**
    * @description Method to program batch
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 16/07/2021g 
    * @param sc 
    **/
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SM_CreateChargentOrdersBatch(), batchSize);
    }
}