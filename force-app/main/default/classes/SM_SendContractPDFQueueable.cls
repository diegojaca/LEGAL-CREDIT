/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             :
 * @last modified on  : 06-29-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   04-10-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
public class SM_SendContractPDFQueueable implements Queueable{

    private Map<String, Contract> contractsToProcess;
    // private Map<Id, APXTConga4__Conga_Solution__c> congaSolutionByContractId;

    public SM_SendContractPDFQueueable(Map<String, Contract> contractsToProcess) {
        this.contractsToProcess = contractsToProcess;
    }

    public void execute (QueueableContext qc) {
        System.debug('contractsToProcess: ' + JSON.serialize(contractsToProcess));
        Map<Id, APXTConga4__Conga_Solution__c> congaSolutionByContractId = SM_ContractHelper.getCongaSolutionSetupByContractId(contractsToProcess.keySet());

        SM_SendContractPDFBatch batch = new SM_SendContractPDFBatch();
        batch.contractsToProcess = contractsToProcess.values();
        batch.congaSolutionByContractId = congaSolutionByContractId;
        Database.executeBatch(batch);
    }
}