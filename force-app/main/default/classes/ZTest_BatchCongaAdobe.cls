/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 04-10-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   04-07-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
global without sharing class ZTest_BatchCongaAdobe implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext BC){
        String idStr = '8000100000038GKAAY';
        String query = 'SELECT Id, SM_Payment_Received__c FROM Contract WHERE ID =: idStr';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope){
        System.debug('scope: ' + scope);
        Request info = Request.getCurrent();
        Quiddity q = info.getQuiddity();
        System.debug('Quiddity: ' + q);
        for (Contract ct : (List<Contract>)scope) {
            ct.SM_Payment_Received__c = true;            
        }
        update scope;        
    }

    public void finish(Database.BatchableContext BC){

    }
}