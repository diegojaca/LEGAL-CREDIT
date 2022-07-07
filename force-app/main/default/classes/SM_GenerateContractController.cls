/**
* @description       :
* @author            : diego.jacanamijoy@gmail.com
* @group             :
* @last modified on  : 06-12-2021
* @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
* Modifications Log
* Ver   Date         Author                        Modification
* 1.0   02-04-2021   diego.jacanamijoy@gmail.com   Initial Version
**/
public with sharing class SM_GenerateContractController {

    private List<String> oppsIds;
    private static Set<String> accountIds;

    /**Constructor */
    public SM_GenerateContractController(List<String> oppIdsvalids){
        oppsIds = oppIdsvalids;
        generateContracts();
    }

    /**
    * @description Main method to generate contract
    * @author diego.jacanamijoy@gmail.com | 02-04-2021
    **/
    public void generateContracts(){
        try {
            validateOpportunityLineItems(getOpportunities());
        } catch (Exception e) {
            throw new SM_CustomException('An error occurred creating contracts '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }

    /**
    * @description This method get opportunities
    * @author diego.jacanamijoy@gmail.com | 02-04-2021
    * @return List<Opportunity>
    **/
    public List<Opportunity> getOpportunities(){
        String idsFormated = '(\'';
        idsFormated += String.join(oppsIds, '\',\'');
        idsFormated += '\')';
        String query = 'SELECT AccountId,Account.PersonEmail, SM_Opportunity_Disposition__c, SM_Company_Setting__r.SM_IVU_State_Amount__c, SM_Company_Setting__r.SM_IVU_Municipal_Amount__c, (SELECT OpportunityId, Product2.SM_Way_to_pay__c, Product2.SM_Plan_Months__c, Product2.Id, Product2Id, Product2.Name, Product2.SM_Requires_AC__c,Product2.SM_Requires_RC__c,Product2.SM_Full_Payment__c,Product2.SM_Monthly_Offer__c, Product2.SM_AC_value__c, Product2.SM_RC_value__c, ';
        query += ' Product2.Process_automation_by_product_family__c, Product2.Process_automation_by_product_family__r.SM_Generates_dispute__c, Product2.Process_automation_by_product_family__r.SM_Type_of_contract__c ';
        query += ' FROM OpportunityLineItems) FROM Opportunity WHERE Id In ' + idsFormated ;
        return SM_OpportunityHelper.getOpportunitiesByDinamicQuery(query);
    }

    /**
    * @description This method build maps to create records
    * @author diego.jacanamijoy@gmail.com | 11/02/2021
    * @param opps
    **/
    public static void validateOpportunityLineItems(List<Opportunity> opps){
        Map<String, Contract> contractByOppAndProccessAut = new Map<String, Contract>();
        Map<String, List<Asset>> assetsByOppAndProccessAut = new Map<String, List<Asset>>();
        accountIds = new Set<String>();
        /**Iterate opps */
        for(Opportunity opp: opps){
            // SFDCMP-201 - JSPA
            accountIds.add(opp.AccountId);
            /**Map of assets by proccess automation */
            Map<String, List<Asset>> assetsByAutomation = new Map<String, List<Asset>>();
            /** Iterate oppItems */
            for(OpportunityLineItem oppItem: opp.OpportunityLineItems){
                /**Key for maps  oppId + ProccessAutomId */
                String key = oppItem.OpportunityId + '-' + oppItem.Product2.Process_automation_by_product_family__c;
                /**Validate keys of maps */
                if(!contractByOppAndProccessAut.containsKey(key)){
                    /**New contract */
                    String wayOfACPayment = '';
                    String acFrequency = '';
                    Integer numberOfACFees = 0;
                    if (opp.SM_Opportunity_Disposition__c == SM_OpportunityHelper.dispositions.sale) {
                        wayOfACPayment = SM_ContractHelper.wayOfACPayment.ONE_PAYMENT;
                        numberOfACFees = Integer.valueOf(System.label.NUMBER_OF_AC_FEES_BY_SALE);
                    } else if (opp.SM_Opportunity_Disposition__c == SM_OpportunityHelper.dispositions.salePtp) {
                        wayOfACPayment = SM_ContractHelper.wayOfACPayment.FEES;
                        acFrequency = SM_ContractHelper.acFrequency.MONTHLY;
                        numberOfACFees = Integer.valueOf(System.label.NUMBER_OF_AC_FEES_BY_SALE_PTP);
                    }
                    acFrequency = opp.SM_Opportunity_Disposition__c == SM_OpportunityHelper.dispositions.salePtp ? SM_ContractHelper.acFrequency.MONTHLY : '';
                    //  SFDCMP-303 - JSPA
                    //  SFDCMP-325 - JSPA - Added SM_IVU_State__c & SM_IVU_Municipal__c fields to the creation of contract
                    String recordTypeIdStr = SM_Utils.getRecordTypeIdByDeveloperName('Contract', oppItem.Product2.Process_automation_by_product_family__r.SM_Type_of_contract__c);
                    Contract contract = new Contract(AccountId = opp.AccountId,
                                                     SM_Opportunity__c = opp.Id,
                                                     SM_Email_to_send_contract__c = opp.Account.PersonEmail,
                                                     SM_Process_automation_by_product_family__c = oppItem.Product2.Process_automation_by_product_family__c,
                                                     SM_Generates_dispute__c = oppItem.Product2.Process_automation_by_product_family__r.SM_Generates_dispute__c,
                                                     RecordTypeId = recordTypeIdStr,
                                                     SM_Way_of_AC_Payment__c = wayOfACPayment,
                                                     SM_Number_of_AC_Fees__c = numberOfACFees,
                                                     SM_IVU_State__c = opp.SM_Company_Setting__r.SM_IVU_State_Amount__c,
                                                     SM_IVU_Municipal__c = opp.SM_Company_Setting__r.SM_IVU_Municipal_Amount__c);
                    /**Instance of map */
                    contractByOppAndProccessAut.put(key, contract);
                }
                /**Create Asset by OpportunityLineItem */
                Asset asset = new Asset(AccountId = opp.AccountId, Product2 = oppItem.Product2, Product2Id = oppItem.Product2Id, Status = 'New', Name = oppItem.Product2.Name, Price = oppItem.Product2.SM_Monthly_Offer__c);
                if(!assetsByOppAndProccessAut.containsKey(key)){
                    assetsByOppAndProccessAut.put(key, new List<Asset>{asset});
                }else{
                    assetsByOppAndProccessAut.get(key).add(asset);
                }
            }
        }
        /**Cal method to create records */
        buildDataToCreate(contractByOppAndProccessAut, assetsByOppAndProccessAut);
    }

    /**
    * @description This methos buikd data to create
    * @author diego.jacanamijoy@gmail.com | 11/02/2021
    * @param contractByOppAndProccessAut
    * @param assetsByOppAndProccessAut
    **/
    public static void buildDataToCreate(Map<String, Contract> contractByOppAndProccessAut, Map<String, List<Asset>> assetsByOppAndProccessAut){
        // SFDCMP-201 - JSPA
        Map<String, String> addressIdByKeys;
        if (!accountIds.isEmpty()) {
            addressIdByKeys = getAccountAddresses();
        }
        /**Iterate map by keys => oppId + ProccAut Id*/
        for(String key: contractByOppAndProccessAut.keySet()){
            Decimal monOffer = 0;
            Decimal acValue = 0;
            Boolean isAc = false;
            Boolean isRc = false;
            String wayOfContract = '';
            Decimal planMonths = 0;
            // SFDCMP-211
            // Boolean isfP = false;
            /**Iterate map assets by automations*/
            for(Asset asset: assetsByOppAndProccessAut.get(key)){
                acValue = asset.Product2.SM_AC_value__c <> null ? acValue += asset.Product2.SM_AC_value__c : acValue;
                monOffer = asset.Product2.SM_Monthly_Offer__c <> null ? monOffer += asset.Product2.SM_Monthly_Offer__c : monOffer;
                isAc = asset.Product2.SM_Requires_AC__c ? asset.Product2.SM_Requires_AC__c : isAc;
                isRc = asset.Product2.SM_Requires_RC__c ? asset.Product2.SM_Requires_RC__c : isRc;
                // SFDCMP-211
                wayOfContract = asset.Product2.SM_Way_to_pay__c;
                planMonths = asset.Product2.SM_Plan_Months__c > planMonths ? asset.Product2.SM_Plan_Months__c : planMonths;
                // SFDCMP-211
                // isfP = asset.Product2.SM_Requires_RC__c ? asset.Product2.SM_Full_Payment__c : isfP;
            }

            /**Updater data in contract */
            Contract contract = contractByOppAndProccessAut.get(key);
            // SFDCMP-201 - JSPA
            String postalAddressKey = contract.AccountId + ' - ' + SM_ContactPointAddressHelper.type.POSTAL_ADDRESS;
            String physicalAddressKey = contract.AccountId + ' - ' + SM_ContactPointAddressHelper.type.PHYSICAL_ADDRESS;
            String otherBillingAddressKey = contract.AccountId + ' - ' + SM_ContactPointAddressHelper.type.BILLING_ADDRESS;
            contract.SM_Postal_address__c = addressIdByKeys.containsKey(postalAddressKey) ? addressIdByKeys.get(postalAddressKey) : null;
            contract.SM_Physical_address__c = addressIdByKeys.containsKey(physicalAddressKey) ? addressIdByKeys.get(physicalAddressKey) : null;
            contract.SM_Billing_Address__c = addressIdByKeys.containsKey(otherBillingAddressKey) ? addressIdByKeys.get(otherBillingAddressKey) : null;
            contract.SM_Way_of_Contract_Payment__c = wayOfContract;
            contract.SM_Requires_AC_Payment__c = isAc;
            contract.SM_Requires_RC_Payment__c = isRc;
            // SFDCMP-211
            // contract.SM_Full_Payment__c = isfP;
            contract.SM_Total_ac__c = acValue;
            contract.SM_Monthly_Offer__c = monOffer;
            // contract.SM_Way_of_Contract_Payment__c= isRc && !isfP ? SM_ContractHelper.wayOfContract.SUSCRIPTION : isRc && isfP ? SM_ContractHelper.wayOfContract.FEES : SM_ContractHelper.wayOfContract.NA;
            // contract.SM_Plan_Months__c=contract.SM_Way_of_Contract_Payment__c == SM_ContractHelper.wayOfContract.FEES ? 1 : NULL;
            contract.SM_Plan_Months__c = planMonths;
            contractByOppAndProccessAut.put(key, contract);
        }
        /**Create contracts */
        insert contractByOppAndProccessAut.values();

        /**Iterate assets map for related contractId */
        List<Asset> assetsToInsert = new List<Asset>();
        for(String key: assetsByOppAndProccessAut.keySet()){
            for(Asset asset: assetsByOppAndProccessAut.get(key)){
                asset.SM_Contract__c = contractByOppAndProccessAut.get(key).Id;
                // JSPA - SFDCMP-239
                asset.SM_Email_to_send_contract__c = contractByOppAndProccessAut.get(key).SM_Email_to_send_contract__c;
                assetsToInsert.add(asset);
            }
        }
        /**Create assets */
        insert assetsToInsert;
        // SFDCMP-294 - JSPA - Move this code to SM_ACHOrderHandler
        // List<SM_Asset_Fee__c> assetsFeeToInsert = new List<SM_Asset_Fee__c>();
        // SM_Asset_Fee__c assetFee;
        // for (Asset asset : assetsToInsert) {
        //     Decimal qtyOfAssetsFeeToCreate = 0;
        //     String assetFeeType = '';
        //     if (asset.Product2.SM_Way_to_pay__c == 'Subscription') {
        //         qtyOfAssetsFeeToCreate = 1;
        //         assetFeeType = 'Subscription';
        //     }
        //     if (asset.Product2.SM_Way_to_pay__c == 'Fix Term') {
        //         qtyOfAssetsFeeToCreate = asset.Product2.SM_Plan_Months__c;
        //         assetFeeType = 'Fee';
        //     }
        //     for (Decimal i = 0; i < qtyOfAssetsFeeToCreate; i++) {
        //         assetFee = new SM_Asset_Fee__c(
        //             SM_Asset__c = asset.Id,
        //             SM_Position__c = i + 1,
        //             SM_Type__c = assetFeeType,
        //             SM_Amount__c = asset.Product2.SM_Monthly_Offer__c,
        //             SM_Contract__c = asset.SM_Contract__c,
        //             SM_Status__c = 'Scheduled',
        //             Name = assetFeeType + '-' + (i + 1)
        //         );
        //         assetsFeeToInsert.add(assetFee);
        //     }
        // }
        // if (!assetsFeeToInsert.isEmpty()) {
        //     List<Database.SaveResult> sr = Database.insert(assetsFeeToInsert);
        // }
    }

    /**
    * @description Method to get contact point addresses related to contract account
    * @author jpachon@legal-credit.com | 03-11-2021
    * @return addressIdByKeys | Map<String, String>
    **/
    public static Map<String, String> getAccountAddresses(){
        // Key => Account Id + AddressType
        Map<String, String> addressIdByKeys = new Map<String, String>();
        List<ContactPointAddress> accountAddresses = SM_ContactPointAddressHelper.getAddressesByParentIds(accountIds);
        if (!accountAddresses.isEmpty()) {
            for (ContactPointAddress cpa : accountAddresses) {
                String key = cpa.ParentId + ' - ' + cpa.SM_Type__c;
                if (!addressIdByKeys.containsKey(key)) {
                    addressIdByKeys.put(key, cpa.Id);
                }
            }
        }
        return addressIdByKeys;
    }
}