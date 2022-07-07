/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 05-15-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   02-26-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
public without sharing class SM_AssetHelper {

    //Instances of enums
    public static StatusEnum status = new StatusEnum();

    /** This class represents Enum to attribute status (Developer name) */
    public class StatusEnum {
        public String NEW_STATUS = 'New';
        public String ACTIVATED = 'Activated';
        public String INACTIVATED = 'Inactivated';
        public String ON_HOLD = '	On Hold';
        public String CANCELLED = 'Cancelled';
    }

    public static Map<String, List<Asset>> getAssetsByContractIds(Set<String> contractIds) {
        Map<String, List<Asset>> assetsByContractId = new Map<String, List<Asset>>();
        for (Asset ast : [SELECT Id, Status, SM_Contract__c FROM Asset WHERE SM_Contract__c =: contractIds]) {
            if (!assetsByContractId.containsKey(ast.SM_Contract__c)) {
                assetsByContractId.put(ast.SM_Contract__c, new List<Asset>());
            }
            assetsByContractId.get(ast.SM_Contract__c).add(ast);
        }
        return assetsByContractId;
    }
}