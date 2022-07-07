/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             :
 * @last modified on  : 05-27-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   04-07-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
@SuppressWarnings('PMD.AvoidGlobalModifier')
global without sharing class SM_SendContractPDFBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    public List<Contract> contractsToProcess;
    public Map<Id, APXTConga4__Conga_Solution__c> congaSolutionByContractId;
    public List<SM_TransactionLog__c> logs = new List<SM_TransactionLog__c>();
    public List<Contract> contractsToUpdate = new List<Contract>();

    public List<Contract> start(Database.BatchableContext bc){
        return contractsToProcess;
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        System.debug('scope: ' + scope);

        Set<Id> pdfIds = new Set<Id>();
        for (Contract newCt : (List<Contract>) scope) {
            SM_ServiceInvokation requestSI = SM_ContractHelper.createRequestCongaAPI();
            SM_ServiceInvokation calloutService = new SM_ServiceInvokation(true);
            if(congaSolutionByContractId.containsKey(newCt.Id)) {
                APXTConga4__Conga_Solution__c congaSolution = congaSolutionByContractId.get(newCt.Id);
                SM_ContractHelper.addAdditionalParamsToURLCongaAPI(requestSI, newCt, congaSolution.APXTConga4__Composer_Parameters__c);
                calloutService = calloutService.callService(requestSI.endPoint, requestSI.method, requestSI.headers, requestSI.request, requestSI.timeout);
                logs.add(calloutService.crateTransactionLog(newCt.Id, requestSI.integrationName));
            }
            System.debug('callout: ' + calloutService);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('logs: ' + logs);
        System.debug('contractsToUpdate: ' + contractsToUpdate);
        List<Database.SaveResult> rs;
        if (!logs.isEmpty()) {
            rs = Database.insert(logs);
            System.debug('rs: ' + JSON.serialize(rs));
        }
    }


}