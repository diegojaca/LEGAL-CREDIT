/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> diego.jacanamijoy@gmail.es
 * @group             : 
 * @last modified on  : 22/07/2021
 * @last modified by  : Diego Jacanamijoy -> diego.jacanamijoy@s4g.es
 * Modifications Log 
 * Ver   Date          Author                                            Modification
 * 1.0   16/07/2021g   Diego Jacanamijoy -> diego.jacanamijoy@gmail.es   Initial Version
**/
global without sharing class SM_TokenizationtBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful, Schedulable {
    
    global SM_Batch_panel__mdt batchPanel;
    global Integer batchSize;
    global Integer limitQuery;

    /**
    * @description Constructor
    * @author Diego Jacanamijoy -> diego.jacanamijoy@s4g.es | 22/07/2021 
    **/
    global SM_TokenizationtBatch(){

        batchPanel =[Select SM_BatchSize__c, SM_LimitQuery__c, SM_SendEmail__c 
                From SM_Batch_panel__mdt Where DeveloperName ='Tokenization' Limit 1];

        batchSize = Test.isRunningTest() ? 50 : Integer.valueOf(batchPanel.SM_BatchSize__c);
        limitQuery = Test.isRunningTest() ? 50 : Integer.valueOf(batchPanel.SM_LimitQuery__c);                
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 16/07/2021g 
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
        + ' FROM SM_Payment_Method__c WHERE SM_Tokenization_status__c = :tokenizationPending AND SM_Chargent_Order__c <> null LIMIT ' + limitQuery;

        return Database.getQueryLocator(query);
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 16/07/2021g 
    * @param bc 
    * @param scope 
    **/
    global void execute(Database.BatchableContext bc, List<SM_Payment_Method__c> scope) {

        SM_TokenizationHandler processHandler = new SM_TokenizationHandler(scope);
        processHandler.process();
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 16/07/2021g 
    * @param bc 
    **/
    global void finish(Database.BatchableContext bc){
        
        // Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        CronTrigger[] lastJobId = [SELECT CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name LIKE 'Tokenizationt Proccess%' ORDER BY CREATEDDATE ASC];

        //then use the active job id and abort it
        if(!lastJobId.isEmpty()){
            system.abortJob(lastJobId[0].Id);
        }
        
        //Set new Job if has more records and does not exceed the limit of apex jobs
        //cronjobDetail.JobType = '7' === Apex jobs
        Integer currentJobs = [SELECT Count() FROM Crontrigger WHERE cronjobDetail.JobType = '7' and State NOT IN ('DELETED','COMPLETE','ERROR')];

        //Get number of records proceced
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];

        Decimal totalrecords = job.TotalJobItems * batchSize;

        if(totalrecords >= limitQuery && currentJobs < 100) {

            SM_TokenizationtBatch tokenization = new SM_TokenizationtBatch();
            String sch = getNextCron();
            String batchJob = system.schedule('Tokenizationt Proccess ' + System.now().getTime(), sch, tokenization);
        }
        
    }

    /**
    * @description This method return next cron expresion to execute Job
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 16/07/2021g 
    * @return String 
    **/
    public String getNextCron() {

        Integer hour = Datetime.now().hour();
        Integer min = Datetime.now().minute() + 10; 
        String ss = String.valueOf(Datetime.now().second());

        //validate las minutes, if current minutes > 50, execute Job in 10 minutes of next hour
        if(min > 59) {
            min = 10;
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
        Database.executeBatch(new SM_TokenizationtBatch(), Integer.valueOf(batchSize));
    }
}