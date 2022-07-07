/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * @group             :
 * @last modified on  : 07-08-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   05-26-2021   Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com   Initial Version
**/
public class SM_UpdateACHOrderInfoQueueable implements Queueable{

    // JSPA - PENDING TO DELETE THIS CLASS IF THE TESTS OF ACH ORDER VALUES AND SET PAYMENT CONDITION WORK FINE FROM ACH ORDER HANDLER - 07/08/2021

    private String processToExecute;
    private Map<String, Decimal> amountAssetsFeeByACHOrderId;
    private Map<String, String> contractIdByACHOrderId;

    public SM_UpdateACHOrderInfoQueueable(String processToExecute, Map<String, Decimal> amountAssetsFeeByACHOrderId, Map<String, String> contractIdByACHOrderId) {
        this.processToExecute = processToExecute;
        this.amountAssetsFeeByACHOrderId = amountAssetsFeeByACHOrderId;
        this.contractIdByACHOrderId = contractIdByACHOrderId;
    }

    public void execute(QueueableContext qc) {
        switch on processToExecute {
            // when 'TotalAmount' {
            //     updateACHOrderValues();
            // }
            // when 'PaymentCondition' {
            //     setPaymentCondition();
            // }
            when else {
                System.debug('Option without implementation');
            }
        }
    }

    // private static void updateACHOrderValues(Map<String, Decimal> amountAssetsFeeByACHOrderId, Map<String, String> contractIdByACHOrderId) {
    // private void updateACHOrderValues() {
    //     System.debug('Executing updateACHOrderValues');
    //     System.debug('amountAssetsFeeByACHOrderId: ' + amountAssetsFeeByACHOrderId);
    //     System.debug('contractIdByACHOrderId: ' + contractIdByACHOrderId);
    //     System.debug('processToExecute: ' + processToExecute);
    //     List<SM_ACH_Order__c> achOrdersToUpdate = new List<SM_ACH_Order__c>();
    //     for (String achOrderId : amountAssetsFeeByACHOrderId.keySet()) {
    //         SM_ACH_Order__c achOrderToUpdate = new SM_ACH_Order__c(
    //             Id = achOrderId,
    //             SM_Total__c = amountAssetsFeeByACHOrderId.get(achOrderId)
    //             );
    //         achOrdersToUpdate.add(achOrderToUpdate);
    //     }
    //     if (!achOrdersToUpdate.isEmpty()) {
    //         List<Database.SaveResult> sr = Database.update(achOrdersToUpdate);
    //         System.debug('sr: ' + JSON.serialize(sr));
    //     }
    // }

    // private void setPaymentCondition() {
    //     System.debug('Executing setPaymentCondition');
    //     System.debug('amountAssetsFeeByACHOrderId: ' + amountAssetsFeeByACHOrderId);
    //     System.debug('contractIdByACHOrderId: ' + contractIdByACHOrderId);
    //     System.debug('processToExecute: ' + processToExecute);
    //     List<Contract> contractsToValidate = [SELECT Id, (SELECT Id, Product2.SM_Way_to_pay__c  FROM Assets__r) FROM Contract WHERE Id IN :contractIdByACHOrderId.values()];
    //     Map<String, Boolean> onlySuscriptionAssetsByContractId = new Map<String, Boolean>();
    //     for (Contract ct : contractsToValidate) {
    //         Boolean thisContractOnlyHasSuscriptionAssets = true;
    //         for (Asset asset : ct.Assets__r) {
    //             if (asset.Product2.SM_Way_to_pay__c != 'Subscription') {
    //                 thisContractOnlyHasSuscriptionAssets = false;
    //             }
    //         }
    //         onlySuscriptionAssetsByContractId.put(ct.Id, thisContractOnlyHasSuscriptionAssets);
    //     }
    //     List<SM_ACH_Order__c> achOrdersToUpdate = new List<SM_ACH_Order__c>();
    //     for (String achOrderId : contractIdByACHOrderId.keySet()) {
    //         String contractId = contractIdByACHOrderId.get(achOrderId);
    //         Boolean onlySuscriptionAssets = onlySuscriptionAssetsByContractId.get(contractId);
    //         String paymentCondition = onlySuscriptionAssets ? 'Fixed value' : 'Dynamic';
    //         SM_ACH_Order__c achOrderToUpdate = new SM_ACH_Order__c(
    //             Id = achOrderId,
    //             SM_Payment_Condition__c = paymentCondition
    //         );
    //         achOrdersToUpdate.add(achOrderToUpdate);
    //     }
    //     if (!achOrdersToUpdate.isEmpty()) {
    //         List<Database.SaveResult> sr = Database.update(achOrdersToUpdate);
    //         System.debug('sr: ' + JSON.serialize(sr));
    //     }
    // }
}