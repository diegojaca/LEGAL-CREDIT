/**
 * @description       : Dispute Object OpportunityLineItem
 * @author            : cjimenez@legal-credit.com
 * @group             :
 * @last modified on  : 06-12-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date          Author                        Modification
 * 1.0   11-02-2021   cjimenez@legal-credit.com  Initial Version
**/
public with sharing class SM_OpportunityLineItemHandler extends SM_TriggerHandler {
    public SM_OpportunityLineItemHandler(String triggerName){
        super(triggerName);

    }


    /************* Overwrite DML methods *************/
    override public void beforeInsert() {
        try {

            validateProductsByFamily(Trigger.new);
        } catch (Exception e) {
            System.debug('An error occurred in afterUpdate  OpportunityLineItem '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }

    /** override after insert method */
    override public void afterInsert() {
        try {
            handleBundleProduct(Trigger.new);//DAJC 01/06/2021
        } catch (Exception e) {
            System.debug('An error occurred in afterInsert  OpportunityLineItem '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }

    /**
    * @description This method process validate Products By Family
    * @author cjimenez@legal-credit.com | 11-02-2021
    * @param newOpportunityLineItems
    **/
    public void validateProductsByFamily(List<OpportunityLineItem> newOpportunityLineItems) {
        Map<String,OpportunityLineItem> productByOppLineItem=new Map<String,OpportunityLineItem>();
        Set<Id> productIds = new Set<Id>();
        List<Opportunity> lstOpportunity=new List<Opportunity>();

        for(OpportunityLineItem oppLineItem: newOpportunityLineItems){
           productByOppLineItem.put(oppLineItem.Product2id,oppLineItem);
           productIds.add(oppLineItem.Product2id);
        }

         validateScreenCapturedProducts(productByOppLineItem);


    }

    /**
    * @description This method validation Products By Family in Capture Screen
    * @author cjimenez@legal-credit.com | 22-02-2021
    * @param productByOppLineItem
    **/
    public void validateScreenCapturedProducts(Map<String,OpportunityLineItem> productByOppLineItem){
        Map<String,Product2> productByOppFam=new Map<String,Product2>();
        Map<String,OpportunityLineItem> oppLineItemByFam=new Map<String,OpportunityLineItem>();
        Boolean catchLimitPerfamily=false;
        String idOpportunity='';
        for (Product2 produc:[SELECT id,Family,SM_Product_type__c
                             FROM Product2
                             WHERE ID IN :productByOppLineItem.Keyset()
                             AND Process_automation_by_product_family__r.Quantity_Products_Pallowed_Custome__c != null]){
        String key = produc.Family;
        Product2 product=productByOppFam.containsKey(key) ? productByOppFam.get(key) : null;
        OpportunityLineItem oppLineItem=productByOppLineItem.containsKey(produc.id) ? productByOppLineItem.get(produc.id) : null;
        oppLineItemByFam.put(key,oppLineItem);
        idOpportunity=oppLineItem.OpportunityId;
        if(product != null || oppLineItem.Quantity > 1){
           showErrorMessage(oppLineItem);
           catchLimitPerfamily=true;
        }
        productByOppFam.put(key,produc);

       }
       if(!catchLimitPerfamily && !productByOppFam.isEmpty())
         validateProductsCapturedByOpportunities(idOpportunity,productByOppFam,oppLineItemByFam);
   }

      /**
    * @description This method validation Products By Family in Opportunitis
    * @author cjimenez@legal-credit.com | 22-02-2021
    * @param productByOppFam,productByOppLineItem
    **/
    public void validateProductsCapturedByOpportunities(String idOpportunity,Map<String,Product2> productByOppFam,Map<String,OpportunityLineItem> productByOppLineItem){
        String idAccount='';

        for(Opportunity opportunity:[SELECT id,StageName,AccountId
                                    ,(SELECT id,Product2Id,Product2.Family FROM OpportunityLineItems)
                                    FROM Opportunity
                                    WHERE id =: idOpportunity ]){

          for(OpportunityLineItem oppLineItem:opportunity.OpportunityLineItems){
                String key = oppLineItem.Product2.Family;
                Product2 product=productByOppFam.containsKey(key) ? productByOppFam.get(key) : null;
                OpportunityLineItem oppLineItemScreen=productByOppLineItem.containsKey(key) ? productByOppLineItem.get(key) : null;
                if(product != null){
                 showErrorMessage(oppLineItemScreen);
                }
           }
            idAccount=opportunity.AccountId;
        }
        for(Account account:[SELECT id
                           ,(SELECT id,Product2Id,Product2.Family FROM Assets WHERE SM_Contract__r.Status not in ('Finalized','Cancelled') )
                            FROM Account
                            WHERE id =: idAccount]){
            for(Asset asset:account.Assets){
                String key = asset.Product2.Family;
                Product2 product=productByOppFam.containsKey(key) ? productByOppFam.get(key) : null;
                OpportunityLineItem oppLineItemScreen=productByOppLineItem.containsKey(key) ? productByOppLineItem.get(key) : null;
                if(product != null){
                 showErrorMessage(oppLineItemScreen);
                }
             }
          }


    }

    /**
    * @description
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 01/06/2021
    * @param newOpportunityLineItems
    **/
    public void handleBundleProduct(List<OpportunityLineItem> newOpportunityLineItems){

        Id recordTypeBundle = SM_Utils.getRecordTypeIdByDeveloperName('Product2', 'Bundle');//RT Bundle
        Set<String> p2Bundles = new Set<String>();
        Set<String> pb2s = new Set<String>();
        List<OpportunityLineItem> oppLntItemsToInsert = new List<OpportunityLineItem>();
        List<OpportunityLineItem> oppLntItemsToUpdate = new List<OpportunityLineItem>();
        Map<String,PricebookEntry> pbEntryByOppAndP2 = new Map<String,PricebookEntry>();

        //validate if is bundle
        newOpportunityLineItems = [SELECT Product2Id, Product2.RecordTypeId, Opportunity.Pricebook2Id,
                                            OpportunityId, SM_AC_Price__c, UnitPrice, SM_Monthly_Offer__c
                                    FROM OpportunityLineItem
                                    WHERE Id IN :newOpportunityLineItems];

        for(OpportunityLineItem oppLnIt: newOpportunityLineItems){
            if(oppLnIt.Product2.RecordTypeId == recordTypeBundle){
                p2Bundles.add(oppLnIt.Product2Id);
                pb2s.add(oppLnIt.Opportunity.Pricebook2Id);
            }
        }

        //get buldles records
        Map<String,Product2> bundlesById = new Map<String,Product2>([SELECT Id,
                                    (SELECT SM_AC_value_in_the_bundle__c, SM_Monthly_Offer_in_the_bundle__c, SM_Product__c FROM Products_per_bundle__r)
                                    FROM Product2
                                    WHERE Id IN :p2Bundles]);

        //Get pricebookentries
        for(PricebookEntry pbe: [SELECT Product2Id, Pricebook2Id FROM PricebookEntry WHERE Pricebook2Id IN :pb2s]){
            pbEntryByOppAndP2.put(pbe.Product2Id + '-'+ pbe.Pricebook2Id, pbe);
        }

        //Iterate oppLnItems
        for(OpportunityLineItem oppLnIt: newOpportunityLineItems){
            if(bundlesById.containsKey(oppLnIt.Product2Id)){
                //create child bundles
                oppLntItemsToInsert.addAll(createChildBundles(oppLnIt, bundlesById.get(oppLnIt.Product2Id), pbEntryByOppAndP2));
                //Set value to parent bundle
                if(oppLnIt.SM_AC_Price__c <> 0 || oppLnIt.UnitPrice <> 0 || oppLnIt.SM_Monthly_Offer__c <> 0){
                    oppLnIt.SM_AC_Price__c = 0;
                    oppLnIt.UnitPrice = 0;
                    oppLnIt.SM_Monthly_Offer__c = 0;
                    oppLntItemsToUpdate.add(oppLnIt);
                }
            }
        }

        //create oppLnItems
        if(!oppLntItemsToInsert.isEmpty()){
            insert oppLntItemsToInsert;
        }

        //update oppLnItems
        if(!oppLntItemsToUpdate.isEmpty()){
            update oppLntItemsToUpdate;
        }
    }

    /**
    * @description
    * @author Diego Jacanamijoy -> diego.jacanamijoy@gmail.es | 01/06/2021
    * @param parent
    * @param parentBundle
    * @return List<OpportunityLineItem>
    **/
    public List<OpportunityLineItem> createChildBundles(OpportunityLineItem parent, Product2 parentBundle, Map<String,PricebookEntry> pbEntryByOppAndP2){
        List<OpportunityLineItem> childsBundles = new List<OpportunityLineItem>();

        //Iterate bundles
        for(SM_Product_per_bundle__c childBundle: parentBundle.Products_per_bundle__r){
            //Create oppLntItems by child bundle
            childsBundles.add(
                new OpportunityLineItem(
                        OpportunityId = parent.OpportunityId,
                        PricebookEntryId = pbEntryByOppAndP2.get(childBundle.SM_Product__c + '-' + parent.Opportunity.Pricebook2Id).Id,
                        SM_AC_Price__c = childBundle.SM_AC_value_in_the_bundle__c,
                        UnitPrice = childBundle.SM_AC_value_in_the_bundle__c,
                        SM_Monthly_Offer__c = childBundle.SM_Monthly_Offer_in_the_bundle__c
                        )
            );
        }
        return childsBundles;
    }


    /**
    * @description This method shows the errors on the screen
    * @author cjimenez@legal-credit.com | 22-02-2021
    * @param oppLineItem
    **/
    public void showErrorMessage(OpportunityLineItem oppLineItem){
         oppLineItem.addError(LABEL.SM_OPPORTUNITYLINEITEM_MASSAGE);
    }

}