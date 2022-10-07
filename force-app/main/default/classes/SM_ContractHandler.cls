/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             :
 * @last modified on  : 07/10/2022
 * @last modified by  : Diego Jacanamijoy -> djacanamijoy@legal-credit.com
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 1.0   01-28-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
 * 2.0   02-05-2021   Santiago Rojas Q -> srojas@legal-credit.com            Chargent Logic added
**/
public without sharing class SM_ContractHandler extends SM_TriggerHandler {

    /************* Static Variables *************/
    // Set<Id> contractByIds;
    public static List<Contract> globalOrders {get;set;}

    public SM_ContractHandler(String triggerName){
        super(triggerName);
        // contractByIds = new Set<Id>();
    }

    /************* Overwrite DML methods *************/
    override public void afterUpdate() {
        // JSPA - SFDCMP-73
        processChangesToSendContract(Trigger.new, Trigger.oldMap);
        // SRQ - SFDCMP-147
        SM_PaymentProcessHandler.validatePayments(Trigger.newMap, Trigger.oldMap);
        // SRQ - SFDCMP-147
        //updateChargentValue(Trigger.newMap,Trigger.oldMap);
        // SRQ - SFDCMP-293
        createBillingContractFromBillingAddress(Trigger.newMap, Trigger.oldMap, false);
        // createDisputeByContract(JSON.serialize(Trigger.new),JSON.serialize(Trigger.oldMap));
        updateDisputeStatusByContract(JSON.serialize(Trigger.new),JSON.serialize(Trigger.oldMap));
        // JSPA - SFDCMP-152
        updateStageOpportunity(Trigger.new, Trigger.oldMap);
        // JSPA - SFDCMP-158
        processAssetsByContractStatusChange(Trigger.new, Trigger.oldMap);
        // JSPA - SFDCMP-344 - Pending to delete because this logic was moved to SM_PaymentProcessController
        //updatePaymentMethodInChildRecords(Trigger.new, Trigger.oldMap);
        // JSPA - SFDCMP-340
        updateNextTransactionDayInACHOrderAndChargentOrder(Trigger.newMap, Trigger.oldMap);
        // JSPA - SFDCMP-358
        processPaymentMethodChanges(Trigger.new, Trigger.oldMap);
        // SRQ - SFDCMP-297
        findPaymentCondition(Trigger.newMap, Trigger.oldMap);
        // SRQ - SFDCMP-301
        validatContractChangeEmail(Trigger.new, Trigger.oldMap);
        // SRQ - SFDCMP-368
        updatePaymentMethodsTypeRelatedRecords(Trigger.new, Trigger.oldMap);
        // SMMCI-16
        SM_ValidateDependentContracts.checkReadyForCollectionContracts(Trigger.new, Trigger.oldMap);
        // SMMCI-28
        checkUpdateMasterStatus(Trigger.new, Trigger.oldMap);
        // CJ 14/08/2022 SMMCI-28 
        updateContractFutureActivation(Trigger.new, Trigger.oldMap);

    }

    override public void beforeUpdate() {
        // JSPA - SFDCMP-172
        validateRequiredFieldsByProcess(Trigger.newMap, Trigger.oldMap);
        // JSPA - SFDCMP-273
        processACChanges(Trigger.new, Trigger.oldMap);
        // JSPA - SFDCMP-384
        validateIfHasPendingApprovalChargentOrders(Trigger.new, Trigger.oldMap);
        //DAJC SMMCI-14
        updateCollectionMain(Trigger.new, Trigger.oldMap);
        // SMMCI-18
        checkContractFutureActivationType(Trigger.new, Trigger.oldMap); 
    }


    override public void asyncAfterInsert(){
        // SRQ - SFDCMP-293
        createBillingContractFromBillingAddress(Trigger.newMap, Trigger.oldMap,true);
        // SFDCMP-215 - JSPA
        System.debug('Ready to execute future method - createDisputeByContract');
        createDisputeByContract(JSON.serialize(Trigger.new));
    }

    override public void asyncAfterUpdate(){
        //DAJC 12/05/2021
        validatContractChangeStatus(Trigger.new, Trigger.oldMap);
        // SMCCI-52
        processRecordsToCancelUpgradedContracts(Trigger.new, Trigger.oldMap);
    }

    /************* Auxiliar methods *************/

    /**
    * @description This method fills the contact field in the contract for the payment Console
    * @author srojas@legal-credit.com | 05-26-2021
    * @param newContracts
    * @param oldContractsMap
    **/
    public void createBillingContractFromBillingAddress(Map<Id, SObject> newContracts, Map<Id, SObject> oldContractsMap, Boolean isInsert) {
        Map<String, Contract> contractsByIds = new Map<String, Contract>();
        List<Contract> contractsToUpdate = new List<Contract>();
        Map<Id,Contact> contactsToInsertPerContract = new Map<Id,Contact>();
        List<String> lstIdsContract = new List<String>();
        // CJ 24/08/2022 error 101 querys
        for(Contract newContract : (List<Contract>)newContracts.values()) {
            if(!isInsert &&  SM_Utils.isChangedField(newContract, (Contract)oldContractsMap.get(newContract.Id), 'SM_Billing_Address__c') &&
            newContract.SM_Billing_Address__c!= Null
            || isInsert && newContract.SM_Billing_Address__c!= Null) {
                lstIdsContract.add(newContract.id);
            }
        }
        Map<Id,Contract> contractsAddressInfo = null;
        if(!lstIdsContract.isEmpty()){
            contractsAddressInfo = new Map<Id,Contract>(
                [
                    SELECT Id, SM_Billing_Address__r.Address,SM_Billing_Address__r.City,
                        SM_Billing_Address__r.Country,SM_Billing_Address__r.PostalCode,
                        SM_Billing_Address__r.State,SM_Email_to_send_contract__c,
                        Account.FirstName,Account.LastName,SM_Billing_Address__r.Street,
                        Billing_Contact__c
                    FROM Contract
                    WHERE Id in: lstIdsContract
                ]
            );
        }
        for(Contract newContract : (List<Contract>)newContracts.values()) {
            if (!isInsert &&
                    SM_Utils.isChangedField(newContract, (Contract)oldContractsMap.get(newContract.Id), 'SM_Billing_Address__c') &&
                    newContract.SM_Billing_Address__c!= Null
                || isInsert && newContract.SM_Billing_Address__c!= Null) {
                Contract ContractBillingInfo = contractsAddressInfo.get(newContract.Id);
                contactsToInsertPerContract.put(newContract.Id,
                    new Contact(
                        MailingCity=ContractBillingInfo.SM_Billing_Address__r.City,
                        MailingCountry=ContractBillingInfo.SM_Billing_Address__r.Country,
                        MailingPostalCode = ContractBillingInfo.SM_Billing_Address__r.PostalCode,
                        MailingState = ContractBillingInfo.SM_Billing_Address__r.State,
                        Email= ContractBillingInfo.SM_Email_to_send_contract__c,
                        MailingStreet = ContractBillingInfo.SM_Billing_Address__r.Street,
                        FirstName = ContractBillingInfo.Account.FirstName,
                        LastName = ContractBillingInfo.Account.LastName
                    )
                );
                if(newContract.Billing_Contact__c != null){
                    contactsToInsertPerContract.get(newContract.Id).Id = newContract.Billing_Contact__c;
                }
            }
        }
        if(!contactsToInsertPerContract.isEmpty()){
            upsert contactsToInsertPerContract.values();
            for(Id contractId : newContracts.keySet()){

                contractsToUpdate.add( new Contract(
                    Id=contractId,
                    Billing_Contact__c=contactsToInsertPerContract.get(contractId).Id,
                    BillingCity = contactsToInsertPerContract.get(contractId).MailingCity
                ));
            }
            update contractsToUpdate;
        }
     }

    public static void updateChargentValue(map<Id,sObject> contracts,map<Id,sObject> oldContracts){
        Set<Id> toProcess = new Set<Id>();
        for(Id ctrId: contracts.keySet()){
            if(SM_Utils.isChangedField(contracts.get(ctrId), oldContracts.get(ctrId), 'SM_Charged_SB_Fees__c')){
                toProcess.add(ctrId);
            }
        }
        if(toProcess.size()>0){
            System.debug('Ready to execute future method - updateContractsAmounts');
            updateContractsAmounts(toProcess);
        }
    }


    @future
    public static void updateContractsAmounts(Set<Id> contractIds){
        System.debug('Entered TO the recalculation for the chargent Order');
        set<Id> contractsToProcess = new set<Id>();
        for(Id ctr: contractIds){
            contractsToProcess.add(ctr);
        }
        List<ChargentOrders__ChargentOrder__c> orders = new List<ChargentOrders__ChargentOrder__c>();
        for(ChargentOrders__ChargentOrder__c order: [
                SELECT ID,contract__r.sm_plan_months__c,contract__r.SM_Charged_SB_Fees__c,sm_fee_to_collect__c, ChargentOrders__Subtotal__c,
                    SM_IVU_Municipal_Amount__c,SM_IVU_State_Amount__c
                FROM ChargentOrders__ChargentOrder__c WHERE contract__c in:contractsToProcess AND SM_Payment_Type__c ='Fee'
            ]
        ){
            order.ChargentOrders__Charge_Amount__c = order.ChargentOrders__Subtotal__c+
                order.SM_IVU_Municipal_Amount__c + order.SM_IVU_State_Amount__c;
            order.ChargentOrders__Tax__c = order.SM_IVU_Municipal_Amount__c + order.SM_IVU_State_Amount__c;
            if(order.contract__r.sm_plan_months__c == order.contract__r.SM_Charged_SB_Fees__c){
                order.ChargentOrders__Payment_Status__c = 'Stopped';
            }
            orders.add(order);
        }
        if(orders.size()>0){
            database.updateAsync((List<SObject>)orders);
        }
    }

    /**
    * @description This method process the contracts to create pdf and send via Adobe Sign
    * @author jpachon@legal-credit.com | 02-02-2021
    * @param newContracts
    * @param oldContractsMap
    **/
    public void processChangesToSendContract(List<Contract> newContracts, Map<Id, SObject> oldContractsMap) {

        Map<String, Contract> contractsByIds = new Map<String, Contract>();
        Map<String, String> disputeStatusByContractId = new  Map<String, String>();

        /** Valid status to send dependent contracts */
        List<String> validStatusToSendPDF = new List<String>{SM_ContractHelper.status.ACTIVATED, SM_ContractHelper.status.PAYMENT_PROCESS};

        for (Contract newContract : newContracts) {

              Contract oldContract = (contract) oldContractsMap.get(newContract.Id);

              Boolean isChangeSendAgreement = (SM_Utils.isChangedField(newContract, oldContract, 'SM_Send_Agreement__c') && newContract.SM_Send_Agreement__c );
              Boolean isChangePaymentReceived = (SM_Utils.isChangedField(newContract, oldContract, 'SM_Payment_Received__c') && newContract.SM_Payment_Received__c );
              Boolean isChangeStatus = (SM_Utils.isChangedField(newContract, oldContract, 'Status') && validStatusToSendPDF.contains(newContract.Status));

            /** FIX: Dependent contracts send PDF when change status, other contracts send with old validations */
            if((newContract.SM_Agreement_Status__c == null && (isChangeSendAgreement || isChangePaymentReceived) && newContract.Contract_Type__c <> SM_ContractHelper.contractType.DEPENDENT)
                || (isChangeStatus && newContract.Contract_Type__c == SM_ContractHelper.contractType.DEPENDENT && String.isBlank(newContract.SM_Agreement_Status__c))) 
            {

                contractsByIds.put(newContract.Id, newContract);
                disputeStatusByContractId.put(newContract.Id, SM_DisputeHelper.status.PENDING);
            }
        }

        if (!contractsByIds.isEmpty()) {
            System.debug('SM_SendContractPDFQueueable - contractsByIds:  ' + contractsByIds);
            System.debug('Ready to execute queueable - SM_SendContractPDFQueueable');
            System.enqueueJob(new SM_SendContractPDFQueueable(contractsByIds));
        }

        /*if (!disputeStatusByContractId.isEmpty()) {
              updateDisputeStatus(disputeStatusByContractId);
        }*/
    }

    /**
    * @description This method to create dispute
    * @author cjimenez@legal-credit.com | 07-02-2021
    */
    public static void createDisputeByContract(String newContractsJSON){
        System.debug('newContracts: ' + JSON.serialize(newContractsJSON));
        List<Contract> newContracts = (List<Contract>) JSON.deserialize(newContractsJSON, List<Contract>.class);
        Set<Id> contraIds = new Set<Id>();
        // SFDCMP-215 - JSPA
        for(Contract newContract: newContracts){
            if(newContract.SM_Generates_dispute__c){
                contraIds.add(newContract.ID);
            }
        }
        if (!contraIds.isEmpty()) {
            createDispute(contraIds);
        }

    }


    public static void findPaymentCondition(Map<Id, SObject> newContractsMap,Map<Id, SObject> oldContractsMap){
        Set<Id> contractsToQuery = new Set<Id>();
        List<Contract> contractsToUpdate = new List<Contract>();
        for(Contract contract: (List<Contract>)newContractsMap.values()){
            if(SM_Utils.isChangedField(contract, oldContractsMap.get(contract.Id), 'Status') && contract.Status == 'Activated'){
                contractsToQuery.add(contract.Id);
            }
        }
        // CJ 24/08/2022 error 101 querys
        if(!contractsToQuery.isEmpty()){
            AggregateResult[] assetPayemntTypesPerContract = [
                SELECT Product2.SM_Way_to_pay__c WayToPay,SM_Contract__c Contract
                FROM Asset
                WHERE SM_Contract__c in:contractsToQuery
                GROUP BY Product2.SM_Way_to_pay__c,SM_Contract__c
            ];
            Map<Id,Set<String>> waysToPayPerContract = new Map<Id,Set<String>>();
            for(AggregateResult contractAmount: assetPayemntTypesPerContract){
                String wayToPay = String.valueOf(contractAmount.get('WayToPay'));
                Id ContractId = Id.valueOf(String.valueOf(contractAmount.get('Contract')));
                if(waysToPayPerContract.containsKey(ContractId)){
                    waysToPayPerContract.get(ContractId).add(wayToPay);
                }
                else{
                    waysToPayPerContract.put(ContractId, new Set<String> {wayToPay});
                }
            }

            for(Id contractId : waysToPayPerContract.keySet()){
                String paymentTypeTMP = waysToPayPerContract.get(contractId).iterator().next();
                String FinalPaymentTYpe = paymentTypeTMP=='Fix Term'?'Dynamic':'Fixed';
                String PaymentCondition = waysToPayPerContract.get(contractId).size()>1?'Dynamic':FinalPaymentTYpe;
                contractsToUpdate.add(new Contract(Id=contractId,SM_Payment_Condition__c=PaymentCondition));
            }
        }
          if(!contractsToUpdate.isEmpty())
             update contractsToUpdate;
    }
    /**
     * @description This method to create dispute
     * @author cjimenez@legal-credit.com | 07-02-2021
     */
     public static void createDispute(Set<Id> contraIds){
        List<SM_Dispute__c> newDisputes = new List<SM_Dispute__c>();
        String[] dateValue = Datetime.now().format('YYYY/MM/dd').split('/');
        List<Contract> contractsToUpdate = new List<Contract>();
        for (Contract contr: [SELECT AccountId, Id,SM_Email_to_send_contract__c, SM_Opportunity__r.SM_Company_Setting__r.SM_Abbreviated_Company__c, SM_Dispute_Number__c, (SELECT ID,Status FROM Assets__r ORDER BY CreatedDate DESC) FROM Contract WHERE ID IN :contraIds]) {
                String contractId =contr.id;
                //String assetId= contr.Assets__r.get(0).id;
                String disputeName = contr.SM_Opportunity__r?.SM_Company_Setting__r?.SM_Abbreviated_Company__c + dateValue[0] + '-' + dateValue[1] + dateValue[2] + contr.SM_Dispute_Number__c;
                newDisputes.add(new SM_Dispute__c(
                    Name = disputeName,
                    SM_Account__c = contr.AccountId,
                    //SM_Asset__c = assetId,
                    SM_Contract__c= contractId,
                    SM_Status__c = SM_DisputeHelper.status.DRAFT,
                    SM_Email_to_send_contract__c = contr.SM_Email_to_send_contract__c,
                    SM_Case_Id__c = disputeName	
                ));
                contractsToUpdate.add(new Contract(Id = contr.Id, SM_Dispute_Name__c = disputeName));
        }

        if(!newDisputes.isEmpty()){
            insert newDisputes;
        }
        if (!contractsToUpdate.isEmpty()) {
            update contractsToUpdate;
        }
    }


      /**
     * @description This method to update  dispute Status
     * @author cjimenez@legal-credit.com | 07-02-2021
     */
    public void updateDisputeStatusByContract (String newContractsJSON, String oldContractsJSON){

        Contract[] newContracts = (List<Contract>) JSON.deserialize(newContractsJSON, List<Contract>.class);
        Map<Id, SObject> oldContracts = (Map<Id, SObject>) JSON.deserialize(oldContractsJSON, Map<Id, SObject>.class);
        Set<Id> contraIds = new Set<Id>();
        Map<String, String> disputeStatusByContractId = new  Map<String, String>();
        for(Contract newContract: newContracts){
            Contract oldContraItem = (contract) oldContracts.get(newContract.Id);
            if(SM_Utils.isChangedField(newContract, oldContraItem, 'Status') && newContract.SM_Generates_dispute__c ) {
                if ((oldContraItem.Status == SM_ContractHelper.status.CANCELED && newContract.Status == SM_ContractHelper.status.ACTIVATED)) {
                    disputeStatusByContractId.put(newContract.Id, SM_DisputeHelper.status.CASE_ON_HOLD);
                } else if( newContract.Status == SM_ContractHelper.status.CANCELED ) {
                    disputeStatusByContractId.put(newContract.Id, SM_DisputeHelper.status.CANCELLED);
                }
            }
        }
        if (!disputeStatusByContractId.isEmpty()) {
            updateDisputeStatus(disputeStatusByContractId);
        }
    }

    /**
    * @description This method update disputes related to contracts
    * @author cjimenez@legal-credit.com | 02-07-2021
    * @param disputeStatusByContractId | Map<String,String>
    **/
    public static void updateDisputeStatus(Map<String,String> disputeStatusByContractId){
        List<SM_Dispute__c> updateDisputes = new List<SM_Dispute__c>();
        for (SM_Dispute__c disp : [SELECT Id, SM_Status__c, SM_Contract__c FROM  SM_Dispute__c WHERE SM_Contract__c IN :disputeStatusByContractId.keySet()]) {
            String status = disputeStatusByContractId.get(disp.SM_Contract__c);
            updateDisputes.add(new SM_Dispute__c(
                ID = disp.ID,
                SM_Status__c = status
            ));
        }
        if(!updateDisputes.isEmpty()){
            update updateDisputes;
        }
    }

    /**
    * @description This method update related opportunity when all contracts are active
    * @author jpachon@legal-credit.com | 02-13-2021
    * @param newContracts | List<Contract>
    * @param oldContractsMap | Map<Id, SObject>
    **/
    public static void updateStageOpportunity(List<Contract> newContracts, Map<Id, SObject> oldContractsMap) {
        Set<String> oppIds = new Set<String>();
        for (Contract newCt : newContracts) {
            if (SM_Utils.isChangedField(newCt, (Contract)oldContractsMap.get(newCt.Id), 'Status') && newCt.Status == SM_ContractHelper.status.ACTIVATED && String.isNotBlank(newCt.SM_Opportunity__c)) {
                oppIds.add(newCt.SM_Opportunity__c);
            }
        }
        Map<String, List<Contract>> contractsByOppId = SM_ContractHelper.getContractsByOppId(oppIds);
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (String oppId : contractsByOppId.keySet()) {
            Boolean updateOpp = true;
            for (Contract ct : contractsByOppId.get(oppId)) {
                if (ct.Status != SM_ContractHelper.status.ACTIVATED) {
                    updateOpp = false;
                }
            }
            if (updateOpp) {
                oppsToUpdate.add(new Opportunity(Id = oppId, StageName = 'Closed Won', CloseDate = System.today()));
            }
        }
        System.debug('oppIdsToUpdate: ' + JSON.serialize(oppsToUpdate));
        if (!oppsToUpdate.isEmpty()) {
            List<Database.SaveResult> sr = Database.update(oppsToUpdate, false);
            System.debug('sr: ' + JSON.serialize(sr));
        }
    }

    public static void validateRequiredFieldsByProcess(Map<Id, SObject> newContractsMap, Map<Id, SObject> oldContractsMap) {
        Set<String> contractIdsToValidateInfo = new Set<String>();
        Set<String> companySettingIds = new Set<String>();
        for (Contract newCt : (List<Contract>)newContractsMap.values()) {
            if (SM_Utils.isChangedField(newCt, (Contract)oldContractsMap.get(newCt.Id), 'Status') && newCt.Status == SM_ContractHelper.status.COMPLETE_INFORMATION) {
                contractIdsToValidateInfo.add(newCt.Id);
                companySettingIds.add(newCt.SM_Company_Setting__c);
            }
        }
        if (!contractIdsToValidateInfo.isEmpty()) {
            Map<String, Set<String>> requiredFieldsByCompanySetting = SM_Utils.getRequiredFieldsByProcess('Contract', companySettingIds, new Set<String>{'Conga', 'Adobe Sign'});
            if (!requiredFieldsByCompanySetting.isEmpty()) {
                for (String ctId : contractIdsToValidateInfo) {
                    SObject newCt = newContractsMap.get(ctId);
                    for (String requiredField : requiredFieldsByCompanySetting.get((String)newCt.get('SM_Company_Setting__c'))) {
                        if (newCt.get(requiredField) == null || newCt.get(requiredField) == '') {
                            System.debug('requiredField: ' + requiredField);
                            newCt.addError(requiredField, System.label.REQUIRED_FIELD_INFO_MESSAGE);
                        }
                    }
                }
            }
        }
    }

    /**
    * @description This method process assets according with the contract status changes
    * @author jpachon@legal-credit.com | 02-26-2021
    * @param newContracts | List<Contract>
    * @param oldContractsMap | Map<Id, SObject>
    **/
    public static void processAssetsByContractStatusChange(List<Contract> newContracts, Map<Id, SObject> oldContractsMap) {
        Set<String> statusToUpdateAssets = new Set<String>{SM_ContractHelper.status.ACTIVATED, SM_ContractHelper.status.CANCELED, SM_ContractHelper.status.FINALIZED};
        Map<String, String> contractStatusById = new Map<String, String>();
        for (Contract newContract : newContracts) {
            if (SM_Utils.isChangedField(newContract, (Contract)oldContractsMap.get(newContract.Id), 'Status') && statusToUpdateAssets.contains(newContract.Status)) {
                
                /** Add validation when change to Activate status */
                //if(newContract.Status <> SM_ContractHelper.status.ACTIVATED 
                  //  || (newContract.Status == SM_ContractHelper.status.ACTIVATED && newContract.Collection_Main_Contract__c == SM_ContractHelper.collectionMain.READY_FOR_COLLECTION))
                //{
                    contractStatusById.put(newContract.Id, newContract.Status);
                //}
            }
        }
        if(!contractStatusById.isEmpty()){
            Map<String, List<Asset>> assetsByContractId = SM_AssetHelper.getAssetsByContractIds(contractStatusById.keySet());
            if (!assetsByContractId.isEmpty()) {
                updateAssetsByContract(contractStatusById, assetsByContractId);
            }
        }
    }

    /**
    * @description This method update related assets according with the contract status
    * @author jpachon@legal-credit.com | 02-26-2021
    * @param newContracts | List<Contract>
    * @param oldContractsMap | Map<Id, SObject>
    **/
    private static void updateAssetsByContract(Map<String, String> contractStatusById, Map<String, List<Asset>> assetsByContractId){
        Map<String, String> assetStatusByContractStatus = new Map<String, String>{
            SM_ContractHelper.status.ACTIVATED => SM_AssetHelper.status.ACTIVATED,
            SM_ContractHelper.status.CANCELED => SM_AssetHelper.status.CANCELLED,
            SM_ContractHelper.status.FINALIZED => SM_AssetHelper.status.INACTIVATED
        };
        List<Asset> assetsToUpdate = new List<Asset>();
        for (String contractId : assetsByContractId.keySet()) {
            if (contractStatusById.containsKey(contractId) && assetStatusByContractStatus.containsKey(contractStatusById.get(contractId))) {
                String newAssetStatus = assetStatusByContractStatus.get(contractStatusById.get(contractId));
                for (Asset ast : assetsByContractId.get(contractId)) {
                    assetsToUpdate.add(new Asset(Id = ast.Id, Status = newAssetStatus));
                }
            }
        }
        if (!assetsToUpdate.isEmpty()) {
            List<Database.SaveResult> sr = Database.update(assetsToUpdate);
            System.debug('sr: ' + JSON.serialize(sr));
        }
    }
    /**
    * @description This method process changes in AC
    * @author jpachon@legal-credit.com | 04-13-2021
    * @param newContracts | List<Contract>
    * @param oldContractsMap | Map<Id, SObject>
    **/
    private static void processACChanges(List<Contract> newRecords, Map<Id, SObject> oldRecordsMap) {
        for (Contract newCt : newRecords) {
            Contract oldCt = (Contract) oldRecordsMap.get(newCt.Id);
            if (SM_Utils.isChangedField(newCt, oldCt, 'SM_Charged_AC_Amount__c') && newCt.SM_Charged_AC_Amount__c == newCt.SM_Total_ac__c) {
                newCt.SM_AC_collected__c = true;
            }
        }
    }

    /**
    * @description
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.com | 12/05/2021
    * @param newRecords
    * @param oldRecordsMap
    * @ModificationLog Add validation to finalized contract
    **/
    private static void validatContractChangeStatus(List<Contract> newRecords, Map<Id, SObject> oldRecordsMap){
        List<String> status = new List<String>{ SM_ContractHelper.status.CANCELED, SM_ContractHelper.status.PAYMENT_REJECTION };
        List<String> oldStatus = new List<String>{ SM_ContractHelper.status.DRAFT, SM_ContractHelper.status.COMPLETE_INFORMATION, SM_ContractHelper.status.PAYMENT_PROCESS };

        Set<String> canceledContraIds = new Set<String>();
        Set<String> finalizedContraIds = new Set<String>();

        List<Opportunity> oppsToUpdate = new List<Opportunity>();

        for (Contract newCt : newRecords) {
            Contract oldCt = (Contract) oldRecordsMap.get(newCt.Id);
            //Validate if change status
            if (SM_Utils.isChangedField(newCt, oldCt, 'Status')) {

                if(status.contains(newCt.Status)){
                    canceledContraIds.add(newCt.Id);
                    //Validate opportunities to update
                    if(oldStatus.contains(oldCt.Status)){
                        oppsToUpdate.add(new Opportunity(Id = newCt.SM_Opportunity__c, StageName = SM_OpportunityHelper.stageName.closedLost, Loss_Reason__c = 'Service cancellation'));
                    }
                }else if(newCt.Status == SM_ContractHelper.status.FINALIZED){
                    finalizedContraIds.add(newCt.Id);
                }
            }
        }
        //send canceled contracts to update
        if (!canceledContraIds.isEmpty()) {
            System.debug('Ready to execute future method - cancelContractRelatedRecords');
            cancelContractRelatedRecords(canceledContraIds);
        }
        //send finalized contracts to update
        if (!finalizedContraIds.isEmpty()) {
            System.debug('Ready to execute future method - finalizedContractRelatedRecords');
            finalizedContractRelatedRecords(finalizedContraIds);
        }
        //Update opps
        if(!oppsToUpdate.isEmpty()){
            update oppsToUpdate;
        }
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 10/07/2021g 
    * @param contractsIds 
    * @return List<Contract> 
    **/
    private static List<Contract> getContractsById(Set<String> contractsIds){
        // SMPII-141 Subquery in ACH order modified to get Stopped records
        return [SELECT Id, SM_Opportunity__c,
                    (SELECT Id FROM Assets__r WHERE Status != 'Cancelled'),
                    (SELECT Id FROM Disputes__r WHERE SM_Status__c != 'Cancelled'),
                    (SELECT Id FROM Chargent_Orders__r WHERE ChargentOrders__Payment_Status__c = 'Recurring'),
                    (SELECT Id FROM ACH_Orders__r   WHERE SM_Payment_Status__c IN ('Initiated','Pending','Created','Stopped')),
                    (SELECT Id FROM Assets_Fee__r WHERE SM_Status__c != 'Canceled'),
                    (SELECT Id FROM echosign_dev1__R00N70000001hM2JEAU__r)
                    FROM Contract WHERE Id IN :contractsIds];
    }

    /**
    * @description
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.com | 12/05/2021
    * @param contractsIds
    **/
    private static void cancelContractRelatedRecords(Set<String> contractsIds){
        List<SObject> sobjectsUpate = new List<SObject>();
        Map<String,SM_ACH_Order__c> ordersToProcess = new Map<String,SM_ACH_Order__c>();

        for(Contract contract: getContractsById(contractsIds)){

            //Manage assets
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.Assets__r, 'Status', 'Cancelled'));

            //Manage Disputes
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.Disputes__r, 'SM_Status__c', 'Cancelled'));

            //manage Chargent orders
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.Chargent_Orders__r, 'ChargentOrders__Payment_Status__c', 'Stopped'));

            //Manage ACH orders
            // sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.ACH_Orders__r, 'SM_Payment_Status__c', 'Canceled'));
            ordersToProcess.putAll(contract.ACH_Orders__r);

            //Manage Asset fee
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.Assets_Fee__r, 'SM_Status__c', 'Canceled'));

            //Manage Agreements
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.echosign_dev1__R00N70000001hM2JEAU__r, 'echosign_dev1__Status__c', 'Cancelled / Declined'));
        }
        // SMPII-141
        cancelAndStopACHOrders(sobjectsUpate, ordersToProcess);

        //Update lists
        if(!sobjectsUpate.isEmpty()){
            sobjectsUpate.sort();
            update sobjectsUpate;
        }
    }

    /**
    * @description SMPII-141
    * @author Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com | 05-23-2022
    * @param List<SObject> sobjectsUpate
    * @param Map<String SM_ACH_Order__c> ordersToProcess
    **/
    private static void cancelAndStopACHOrders(List<SObject> sobjectsUpate, Map<String,SM_ACH_Order__c> ordersToProcess) {
        Set<String> orderIds = new Set<String>();
        List<SM_ACH_Order__c> ordersToCancel = new List<SM_ACH_Order__c>();
        List<SM_ACH_Order__c> ordersToStop = new List<SM_ACH_Order__c>();
        Set<String> paymentId = new Set<String>();
        for (SM_ACH_Order__c achOrder : [SELECT Id, (SELECT Id FROM Payments__r WHERE Payment_Status__c =: SM_PaymentHelper.status.ACH_TRANSMITTED) FROM SM_ACH_Order__c WHERE Id =: ordersToProcess.keySet()]) {
            if (achOrder.Payments__r.size() > 0) {
                ordersToStop.add(achOrder);
            } else {
                ordersToCancel.add(achOrder);
            }
        }
        sobjectsUpate.addAll(updateSobjectByFieldAndValue(ordersToCancel, 'SM_Payment_Status__c', 'Canceled'));
        sobjectsUpate.addAll(updateSobjectByFieldAndValue(ordersToStop, 'SM_Payment_Status__c', 'Stopped'));
    }

    /**
    * @description
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.com | 29/05/2021
    * @param contractsIds
    **/
    @Future
    private static void finalizedContractRelatedRecords(Set<String> contractsIds){
        List<SObject> sobjectsUpate = new List<SObject>();

        for(Contract contract: getContractsById(contractsIds)){

            //Manage assets
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.Assets__r, 'Status', 'Inactivated'));

            //Manage Disputes
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.Disputes__r, 'SM_Status__c', 'Finish'));

            //manage Chargent orders
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.Chargent_Orders__r, 'ChargentOrders__Payment_Status__c', 'Stopped'));

            //Manage ACH orders
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.ACH_Orders__r, 'SM_Payment_Status__c', 'Completed'));

            //Manage Asset fee
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.Assets_Fee__r, 'SM_Status__c', 'Inactivated'));
        }

        //Update lists
        if(!sobjectsUpate.isEmpty()){
            sobjectsUpate.sort();
            update sobjectsUpate;
        }
    }

    /**
    * @description
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 28/05/2021
    * @param sObjectsToUpdate
    * @param field
    * @param value
    * @return List<SObject>
    **/
    private static List<SObject> updateSobjectByFieldAndValue(List<SObject> sObjectsToUpdate, String field, String value){

        for(SObject so: sObjectsToUpdate){
            so.put(field, value);
        }

        return sObjectsToUpdate;
    }

    /**
    * @description This method update the payment day from Contract
    * @author jpachon@legal-credit.com | 05-22-2021
    * @param newRecords | List<Contract>
    * @param oldRecordsMap | Map<Id, SObject>
    **/
    private void updateNextTransactionDayInACHOrderAndChargentOrder(Map<Id, SObject> newRecords, Map<Id, SObject> oldRecordsMap) {
        List<String> paymentTypes = new List<String>{
            SM_ChargentOrderHelper.paymentType.SUBSCRIPTION,
            SM_ChargentOrderHelper.paymentType.FEE
        };
        String contractFee = SM_ChargentOrderHelper.purposeOfPayment.CONTRACT_FEE;
        Map<String, Contract> contractsToProcess = new Map<String, Contract>();
        for (Contract newCt : (List<Contract>)newRecords.values()) {
            Contract oldCt = (Contract) oldRecordsMap.get(newCt.Id);
            if (SM_Utils.isChangedField(newCt, oldCt, 'SM_Payment_day__c') && newCt.SM_Payment_day__c != null) contractsToProcess.put(newCt.Id, newCt);
        }
        if (!contractsToProcess.isEmpty()) {
            List<SM_ACH_Order__c> achOrdersToProcess = new List<SM_ACH_Order__c>();
            List<ChargentOrders__ChargentOrder__c> chargentOrdersToProcess = new List<ChargentOrders__ChargentOrder__c>();
            for (Contract ct : [SELECT Id, SM_Payment_methods__c,
                                (SELECT Id, SM_Contract__c, SM_Next_Transaction_Date__c
                                    FROM ACH_Orders__r
                                    WHERE SM_Payment_Type__c != 'AC'
                                    AND SM_Next_Transaction_Date__c != null),
                                (SELECT Id, Contract__c, ChargentOrders__Next_Transaction_Date__c, ChargentOrders__Payment_Start_Date__c, ChargentOrders__Charge_Date__c
                                    FROM Chargent_Orders__r
                                    WHERE SM_Payment_Type__c IN :paymentTypes
                                    AND SM_Purpose_of_Payment__c =: contractFee)
                                FROM Contract WHERE Id IN :contractsToProcess.keySet()]) {
                if (ct.SM_Payment_methods__c == 'ACH') {
                    achOrdersToProcess.addAll(ct.ACH_Orders__r);
                } else if (ct.SM_Payment_methods__c == 'Credit Card') {
                    chargentOrdersToProcess.addAll(ct.Chargent_Orders__r);
                }
            }
            Integer currentDay = System.today().day();
            Integer currentMonth = System.today().month();
            Integer newPaymentDay;
            Set<String> recordIdsToAvoid = new Set<String>();
            List<SM_ACH_Order__c> achOrdersToUpdate;
            if (!achOrdersToProcess.isEmpty()) {
                achOrdersToUpdate = new List<SM_ACH_Order__c>();
                for (SM_ACH_Order__c achOrder : achOrdersToProcess) {
                    newPaymentDay = Integer.valueOf(newRecords.get(achOrder.SM_Contract__c).get('SM_Payment_day__c'));
                    Integer dayTheNextTransactionDate = achOrder.SM_Next_Transaction_Date__c.day();
                    Integer monthOfTheNextTransactionDate = achOrder.SM_Next_Transaction_Date__c.month();
                    Integer yearOfTheNextTransactionDate = achOrder.SM_Next_Transaction_Date__c.year();
                    if (newPaymentDay < currentDay && monthOfTheNextTransactionDate == currentMonth && dayTheNextTransactionDate >= currentDay) {
                        System.debug('This record has a payment in progress to this month');
                    } else {
                        if (newPaymentDay >= 29) {
                            // newPaymentDay = Date.daysInMonth(achOrder.SM_Next_Transaction_Date__c.year(), achOrder.SM_Next_Transaction_Date__c.month());
                            // JSPA - 08/18/2021
                            Integer lastDayOfMonth = Date.daysInMonth(achOrder.SM_Next_Transaction_Date__c.year(), achOrder.SM_Next_Transaction_Date__c.month());
                            if(newPaymentDay > lastDayOfMonth) {
                                newPaymentDay = lastDayOfMonth;
                            }
                        }
                        achOrdersToUpdate.add(
                            new SM_ACH_Order__c(
                                Id = achOrder.Id,
                                SM_Next_Transaction_Date__c = Date.newInstance(yearOfTheNextTransactionDate, monthOfTheNextTransactionDate, newPaymentDay)
                            )
                        );
                    }
                }
            }
            List<ChargentOrders__ChargentOrder__c> chargentOrdersToUpdate;
            if (!chargentOrdersToProcess.isEmpty()) {
                chargentOrdersToUpdate = new List<ChargentOrders__ChargentOrder__c>();
                for (ChargentOrders__ChargentOrder__c chargentOrder : chargentOrdersToProcess) {
                    newPaymentDay = Integer.valueOf(newRecords.get(chargentOrder.Contract__c).get('SM_Payment_day__c'));
                    ChargentOrders__ChargentOrder__c chargentOrderToUpdate = new ChargentOrders__ChargentOrder__c(Id = chargentOrder.Id);
                    if (chargentOrder.ChargentOrders__Payment_Start_Date__c != null && chargentOrder.ChargentOrders__Payment_Start_Date__c > System.today()) {
                        chargentOrderToUpdate.ChargentOrders__Payment_Start_Date__c = Date.newInstance(chargentOrder.ChargentOrders__Payment_Start_Date__c.year(), chargentOrder.ChargentOrders__Payment_Start_Date__c.month(), newPaymentDay);
                        chargentOrderToUpdate.ChargentOrders__Charge_Date__c = String.valueOf(newPaymentDay);
                    } else if (chargentOrder.ChargentOrders__Payment_Start_Date__c != null && chargentOrder.ChargentOrders__Payment_Start_Date__c <= System.today() && chargentOrder.ChargentOrders__Next_Transaction_Date__c != null) {
                        Integer dayTheNextTransactionDate = chargentOrder.ChargentOrders__Next_Transaction_Date__c.day();
                        Integer monthOfTheNextTransactionDate = chargentOrder.ChargentOrders__Next_Transaction_Date__c.month();
                        Integer yearOfTheNextTransactionDate = chargentOrder.ChargentOrders__Next_Transaction_Date__c.year();
                        if (newPaymentDay < currentDay && monthOfTheNextTransactionDate == currentMonth && dayTheNextTransactionDate >= currentDay) {
                            System.debug('This record has a payment in progress to this month');
                        } else {
                            if (newPaymentDay >= 29) {
                                // newPaymentDay = Date.daysInMonth(chargentOrder.ChargentOrders__Next_Transaction_Date__c.year(), chargentOrder.ChargentOrders__Next_Transaction_Date__c.month());
                                // JSPA - 08/18/2021
                                Integer lastDayOfMonth = Date.daysInMonth(chargentOrder.ChargentOrders__Next_Transaction_Date__c.year(), chargentOrder.ChargentOrders__Next_Transaction_Date__c.month());
                                if(newPaymentDay > lastDayOfMonth) {
                                    newPaymentDay = lastDayOfMonth;
                                }
                            }
                            chargentOrderToUpdate.ChargentOrders__Charge_Date__c = String.valueOf(newPaymentDay);
                            chargentOrderToUpdate.ChargentOrders__Next_Transaction_Date__c = Date.newInstance(chargentOrder.ChargentOrders__Next_Transaction_Date__c.year(), chargentOrder.ChargentOrders__Next_Transaction_Date__c.month(), newPaymentDay);
                        }
                    }
                    chargentOrdersToUpdate.add(chargentOrderToUpdate);
                }
            }
            List<Database.SaveResult> sr;
            if (achOrdersToUpdate != null && !achOrdersToUpdate.isEmpty()) {
                sr = Database.update(achOrdersToUpdate);
                System.debug('sr: ' + JSON.serialize(sr));
            }
            if (chargentOrdersToUpdate != null && !chargentOrdersToUpdate.isEmpty()) {
                sr = Database.update(chargentOrdersToUpdate);
                System.debug('sr: ' + JSON.serialize(sr));
            }
        }
    }

    /**
    * @description This method validate what contracts are changing their payment method and send them to SM_PaymentProcessController to process records
    * @author jpachon@legal-credit.com | 06-18-2021
    * @param newRecords | List<Contract>
    * @param oldRecordsMap | Map<Id, SObject>
    **/
    private void processPaymentMethodChanges(List<Contract> newRecords, Map<Id, SObject> oldRecordsMap) {
        Map<String, Contract> newRecordsMapToProcess = new Map<String, Contract>();
        Map<String, Contract> oldRecordsMapToProcess = new Map<String, Contract>();
        Set<String> paymentMethodIds = new Set<String>();
        List<String> statusToAvoid = new List<String>{
            SM_ContractHelper.status.FINALIZED,
            SM_ContractHelper.status.CANCELED,
            SM_ContractHelper.status.PAYMENT_REJECTION
        };
        for (Contract newRecord : newRecords) {
            Contract oldRecord = (Contract)oldRecordsMap.get(newRecord.Id);
            if (SM_Utils.isChangedField(newRecord, oldRecord, 'SM_Payment_Method__c') && oldRecord.SM_Payment_Method__c != null && newRecord.SM_Payment_Method__c != null && !statusToAvoid.contains(newRecord.Status)) {
                newRecordsMapToProcess.put(newRecord.Id, newRecord);
                oldRecordsMapToProcess.put(oldRecord.Id, oldRecord);
                paymentMethodIds.add(oldRecord.SM_Payment_Method__c);
                paymentMethodIds.add(newRecord.SM_Payment_Method__c);
            }
        }
        if (!newRecordsMapToProcess.isEmpty() || !oldRecordsMapToProcess.isEmpty()) {
            SM_PaymentProcessController paymentProcessController = new SM_PaymentProcessController(newRecordsMapToProcess, oldRecordsMapToProcess, paymentMethodIds);
            paymentProcessController.processRecords();
        }
    }

    /**
    * @description This method validate if contract has any chargent order in approval pending status to avoid payment method changes
    * @author jpachon@legal-credit.com | 07-28-2021
    * @param newRecords | List<Contract>
    * @param oldRecordsMap | Map<Id, SObject>
    **/
    private void validateIfHasPendingApprovalChargentOrders(List<Contract> newRecords, Map<Id, SObject> oldRecordsMap) {
        Map<String,Contract> contractsByIds = SM_ContractHelper.getContractWithOrders(oldRecordsMap.keySet());
        for (Contract newRecord : newRecords) {
            Contract oldRecord = (Contract)oldRecordsMap.get(newRecord.Id);
            if (SM_Utils.isChangedField(newRecord, oldRecord, 'SM_Payment_Method__c') && oldRecord.SM_Payment_Method__c != null && newRecord.SM_Payment_Method__c != null
                && contractsByIds.containsKey(newRecord.Id) && (contractsByIds.get(newRecord.Id).ACH_Orders__r.size() > 0 || contractsByIds.get(newRecord.Id).Chargent_Orders__r.size() > 0)) {
                newRecord.addError(System.label.DONT_ALLOW_PAYMENT_METHOD_CHANGES_MESSAGE);
            }
        }
    }

    /**
    * @description Check update Collection_Main_Contract__c field
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 11/07/2022 
    * @param newRecords 
    * @param oldRecordsMap 
    **/
    private void updateCollectionMain(List<Contract> newRecords, Map<Id, SObject> oldRecordsMap){

        List<Contract> contractsWithChangeStatus = new List<Contract>();
        Set<String> procesAutmIds = new Set<String>();

        for (Contract newRecord : newRecords) {
            Contract oldRecord = (Contract)oldRecordsMap.get(newRecord.Id);
            if (SM_Utils.isChangedField(newRecord, oldRecord, 'Status') && newRecord.Collection_Main_Contract__c == SM_ContractHelper.collectionMain.PENDING_DATA_CAPTURE){
                procesAutmIds.add(newRecord.SM_Process_automation_by_product_family__c);
                contractsWithChangeStatus.add(newRecord);
            }
        }

        if(!procesAutmIds.isEmpty()){
            Map<Id,Process_automation_by_product_family__c> procesAutomById = getProcesAutomations(procesAutmIds);
            //Check new status of contracts
            for(Contract contract: contractsWithChangeStatus){
                if(contract.Status == procesAutomById.get(contract.SM_Process_automation_by_product_family__c)?.Ready_for_collection_in__c){
                    contract.Collection_Main_Contract__c = SM_ContractHelper.collectionMain.READY_FOR_COLLECTION;
                }
            }
        }
    }

    /**
    * @description Get proces automations by id
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 11/07/2022 
    * @param procesAutmIds 
    * @return Map<Id, Process_automation_by_product_family__c> 
    **/
    private Map<Id,Process_automation_by_product_family__c> getProcesAutomations(Set<String> procesAutmIds){
        return new Map<Id,Process_automation_by_product_family__c>([SELECT Ready_for_collection_in__c FROM Process_automation_by_product_family__c WHERE Id IN: procesAutmIds]);
    }


    /**
    * @description
    * @author Camilo Jimenez -> Cjimenez@legal-credit.com | 09/07/2021
    * @param newRecords
    * @param oldRecordsMap
    * @ModificationLog Add validation to finalized contract
    **/
    private static void validatContractChangeEmail(List<Contract> newRecords, Map<Id, SObject> oldRecordsMap){
        Set<String> contraIds = new Set<String>();
      
     for (Contract newCt : newRecords) {
          Contract oldCt = (Contract) oldRecordsMap.get(newCt.Id);
          //Validate if change SM_Email_to_send_contract__c
            if (SM_Utils.isChangedField(newCt, oldCt, 'SM_Email_to_send_contract__c')) {
                contraIds.add(newCt.Id);
            }
        }
       //update EmailRelated Records
         if (!contraIds.isEmpty()) {
            updateEmailRelatedRecords(contraIds);
        }
    }
  /**
    * @description
    * @author Camilo Jimenez -> Cjimenez@legal-credit.com | 09/07/2021
    * @param newRecords
    * @param oldRecordsMap
    * @ModificationLog Add validation to finalized contract
    **/
    private static void updateEmailRelatedRecords(Set<String> contractsIds){
        List<SObject> sobjectsUpate = new List<SObject>();

        for(Contract contract: [SELECT Id, SM_Opportunity__c,SM_Email_to_send_contract__c,
                                        (SELECT Id FROM Assets__r),
                                        (SELECT Id FROM Disputes__r),
                                        (SELECT Id FROM Chargent_Orders__r),
                                        (SELECT Id FROM ACH_Orders__r )
                                        FROM Contract WHERE Id IN :contractsIds]){

            //Manage assets
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.Assets__r, 'SM_Email_to_send_contract__c',contract.SM_Email_to_send_contract__c));

            //Manage Disputes
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.Disputes__r, 'SM_Email_to_send_contract__c', contract.SM_Email_to_send_contract__c));
            //manage Chargent orders
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.Chargent_Orders__r, 'ChargentOrders__Billing_Email__c', contract.SM_Email_to_send_contract__c));

            //Manage ACH orders
            sobjectsUpate.addAll(updateSobjectByFieldAndValue(contract.ACH_Orders__r, 'SM_Billing_Email__c', contract.SM_Email_to_send_contract__c));
        }

         //Update lists
     if(!sobjectsUpate.isEmpty()){
         sobjectsUpate.sort();
         update sobjectsUpate;
       }
   }
 /**
    * @description
    * @author Camilo Jimenez -> Cjimenez@legal-credit.com | 09/07/2021
    * @param newRecords
    * @param oldRecordsMap
    * @ModificationLog Add validation to finalized contract
    **/
  private static void updatePaymentMethodsTypeRelatedRecords(List<Contract> newRecords, Map<Id, SObject> oldRecordsMap){
       List<Contract> contractUpdate = new List<Contract>();
        Set<String> contractsIds = new Set<String>();
      
        for (Contract newCt : newRecords) {
             Contract oldCt = (Contract) oldRecordsMap.get(newCt.Id);
             //Validate if change SM_Email_to_send_contract__c
               if (SM_Utils.isChangedField(newCt, oldCt, 'SM_Payment_Method__c')) {
                 //  newCt.SM_Payment_methods__c='';
                   contractsIds.add(newCt.Id);
               }
           }

        for(Contract contract: [SELECT Id,SM_Payment_methods__c,SM_Payment_Method__c,SM_Payment_Method__r.RecordType.Name,
                                (SELECT Id FROM Assets__r),
                                (SELECT Id FROM Disputes__r)
                                FROM Contract WHERE Id IN :contractsIds]){ 
          
           contract.SM_Payment_methods__c=String.isNotBlank(contract.SM_Payment_Method__c) ? contract.SM_Payment_Method__r.RecordType.Name : '';
           contractUpdate.add(contract);
          }   
          
             //Update lists
        if(!contractUpdate.isEmpty()){
            update contractUpdate;
        } 
     }

    /**
    * @description 
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 27/07/2022 
    * @param newRecords 
    * @param oldRecordsMap 
    **/
    public static void checkContractFutureActivationType(List<Contract> newRecords, Map<Id, SObject> oldRecordsMap){

        for (Contract newCt : newRecords) {
            Contract oldCt = (Contract) oldRecordsMap.get(newCt.Id);
            /** Validate if change Status */
            if (SM_Utils.isChangedField(newCt, oldCt, 'Status') 
                && newCt.Status == SM_ContractHelper.status.COMPLETE_INFORMATION
                && newCt.Contract_activation_form__c == SM_ContractHelper.collectionActivationForm.FUTURE_ACTIVATION)
            {
                /** Chek valid data to update status */
                if (newCt.Expected_date_for_contract_activation__c > System.today()
                    || newCt.Validation_of_conditions__c <> SM_ContractHelper.collectionValidationsConditions.MEETS_THE_CONDITIONS
                    || newCt.Start_assets_in_fee_number__c == null)
                {
                    /** Set user error */
                    newCt.addError(Label.FUTURE_ACTIVATION_WITH_CONDITIONS_ERROR_MESSAGE);
                }
            }
        }
    }
    /**
    * @description 
    * @author Camilo jimenez -> cjimenez@legal-credit.com | 14/08/2022 
    * @param newRecords 
    * @param oldRecordsMap 
    **/
    public static void updateContractFutureActivation(List<Contract> newRecords, Map<Id, SObject> oldRecordsMap){
        List<Contract> lstUpdateContract = new List<Contract>();
        for (Contract newCt : newRecords) {
            Contract oldCt = (Contract) oldRecordsMap.get(newCt.Id);
            /** Validate if change Status */
            if (SM_Utils.isChangedField(newCt, oldCt, 'Status') 
                && newCt.Status == SM_ContractHelper.status.COMPLETE_INFORMATION
                && newCt.Contract_activation_form__c == SM_ContractHelper.collectionActivationForm.FUTURE_ACTIVATION)
            {
                lstUpdateContract.add(new Contract(id = newCt.id, Status = SM_ContractHelper.status.ACTIVATED,
                                                    SM_Send_Agreement__c = true ));
            }
        }
        if(!lstUpdateContract.isEmpty()){
           SM_BypassManager.disableValidationRules();
           List<Database.SaveResult> sr = Database.update(lstUpdateContract);
           SM_BypassManager.enableValidationRules();
           system.debug('sr'+sr);
        }
    }

    /**
    * @description This method validate change status of master contracts, to update dependets
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 01/08/2022 
    * @param newRecords 
    * @param oldRecordsMap 
    **/
    public static void checkUpdateMasterStatus(List<Contract> newRecords, Map<Id, SObject> oldRecordsMap){

        Set<Id> masterContractIds = new Set<Id>();
        Set<Id> masterCanceledContractIds = new Set<Id>();

        List<String> validValuesToUpdate = new List<String>{SM_ContractHelper.status.ACTIVATED, SM_ContractHelper.status.PAYMENT_PROCESS, SM_ContractHelper.status.CANCELED, SM_ContractHelper.status.FINALIZED};

        for (Contract newCt : newRecords) {
            Contract oldCt = (Contract) oldRecordsMap.get(newCt.Id);
            /** Validate if change Status */
            if (SM_Utils.isChangedField(newCt, oldCt, 'Status') 
                && newCt.Contract_Type__c == SM_ContractHelper.contractType.MASTER
                && validValuesToUpdate.contains(newCt.Status))
            {
                /** When change to Cancelled, call other procces */
                if (newCt.Status == SM_ContractHelper.status.CANCELED) {
                    masterCanceledContractIds.add(newCt.Id);
                } else {
                    masterContractIds.add(newCt.Id);   
                }
            }
        }

        if(!masterCanceledContractIds.isEmpty()) {
            System.enqueueJob(new SM_CancelMasterContractController(masterCanceledContractIds));
        }

        /** Get dependent contracts by master ids */
        List<Contract> dependentContracts = [SELECT 
                                                Principal_Contract__r.Status 
                                            FROM Contract 
                                            WHERE Principal_Contract__c IN: masterContractIds 
                                            AND Contract_Type__c =: SM_ContractHelper.contractType.DEPENDENT
                                            AND Collection_Main_Contract__c =: SM_ContractHelper.collectionMain.READY_FOR_COLLECTION];

        for(Contract dependent: dependentContracts){
            dependent.Status = dependent.Principal_Contract__r.Status;
        }

        /** Update dependent contracts */
        if(!dependentContracts.isEmpty()){
            
            /** Disable validation rules to dependent contracts */
            SM_BypassManager.disableValidationRules();
            update dependentContracts;
            SM_BypassManager.enableValidationRules();
        }
    }

    public static void processRecordsToCancelUpgradedContracts(List<Contract> newRecords, Map<Id, SObject> oldRecordsMap) {
        // Set<Id> contractsToQuery = new Set<Id>();
        // List<Contract> contractsToUpdate = new List<Contract>();
        Map<String, String> opportunityIdsByContractId = new Map<String, String>();
        Map<String, String> newContractByUpgraded = new Map<String, String>();
        for(Contract contract: (List<Contract>)newRecords) {
            System.debug('contract: ' + contract);
            System.debug('oldRecordsMap: ' + oldRecordsMap.get(contract.Id));
            if(SM_Utils.isChangedField(contract, oldRecordsMap.get(contract.Id), 'Status') && contract.Status == SM_ContractHelper.status.ACTIVATED){
                if (!opportunityIdsByContractId.containsKey(contract.Id) && contract.SM_UpgradedContract__c != null) {
                    opportunityIdsByContractId.put(contract.SM_UpgradedContract__c, contract.SM_Opportunity__c);
                    newContractByUpgraded.put(contract.SM_UpgradedContract__c, contract.Id);
                }
            }
        }
        // SM_CancelContractController cancelUpgradedContractsController = new SM_CancelContractController(opportunityIdsByContractId, newContractByUpgraded);
        // cancelUpgradedContractsController.execute();
        if (!opportunityIdsByContractId.isEmpty()) {
            System.enqueueJob(new SM_CancelContractController(opportunityIdsByContractId, newContractByUpgraded));
        }
    }

}