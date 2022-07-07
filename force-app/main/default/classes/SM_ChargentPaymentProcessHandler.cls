/**
 * @description       :
 * @author            : Santiago Rojas Q -> srojas@legal-credit.com
 * @group             :
 * @last modified on  : 08-26-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                 Modification
 * 2.0   02-16-2021   Santiago Rojas Q -> srojas@legal-credit.com            Chargent Logic added
**/
public inherited sharing class SM_ChargentPaymentProcessHandler {
    public SM_ChargentPaymentProcessHandler() {

    }

    /**
    * @description This Method creates the AC records Specificly
    * @author srojas@legal-credit | 05-02-2021
    * @param sOIds
    * @param Pmethods
    **/
    public static void CreateACOrderRecordsChargent(List<String>  sOIds,List<Object> Pmethods,List<Object> chPtypes){

        List<ChargentOrders__ChargentOrder__c> ords = new List<ChargentOrders__ChargentOrder__c>();
        SM_Utils.DynamicQueryStructure structure = new SM_Utils.DynamicQueryStructure();
        Set<String> setPM = new set<String>();
        if(sOIds.size()>0){
            structure.AdditionalFields = 'SM_Opportunity__r.SM_Company_Setting__c'
                                        +',SM_Payment_Method__r.SM_Chargent_Order__c'
                                        +',SM_Opportunity__r.SM_Company_Setting__r.SM_Gateway__c'
                                        +',SM_Opportunity__r.SM_Company_Setting__r.SM_IVU_Municipal_Amount__c'
                                        +',SM_Opportunity__r.SM_Company_Setting__r.SM_IVU_State_Amount__c,'
                                        +'SM_Process_automation_by_product_family__r.SM_Maximum_Number_Of_Failed_Transactions__c,';
            structure.sObjectName = 'Contract';
            structure.subqueryObj = 'Chargent_Orders__r';
            structure.whereClause = new map<String,List<object>>{'Id'=>(List<object>)sOIds};
            structure.childsWhereClause = new map<String,List<object>>{'SM_Payment_Type__c'=>chPtypes};
            structure.orderByParent ='';
            List<sObject> objs  = SM_Utils.getDynamicQuery(structure);
            set<String> companySettingId = new set<String>();
            sObject crRelationShip = null;
            Map<String,set<String>> requiredFields = new Map<String,set<String>>();
            if(objs.size()>0){
                for(sObject obj :objs){
                    crRelationShip = obj.getSObject('SM_Opportunity__r');
                    if(crRelationShip != null){
                        companySettingId.add(String.ValueOf(crRelationShip.get('SM_Company_Setting__c')));
                    }
                }
            }
            for(Object obj: Pmethods){
                setPM.add((String)obj);
            }
            if(companySettingId.size()>0){
                requiredFields =  SM_Utils.getRequiredFieldsByProcess('Contract', companySettingId,setPM);
                System.debug(requiredFields);
            }
            Map<String,Boolean> response = new Map<String,Boolean>();
            if(requiredFields.size()>0){

                system.debug('No error');
                response = validateMandatoryFields(requiredFields,objs);

                system.debug('No error');
            }
            system.debug(response);
            if(response.size()>0){
                for(Contract ctr: (List<Contract>)objs){
                    if(!response.get(ctr.Id) || ctr.Chargent_Orders__r.size()>0){
                        continue;
                    }
                    ords.addAll(createTMPRows(ctr));
                }
            }
            if(ords.size()>0){
                System.debug('entered to insert');
                insert ords;
                System.debug('out from insert');
            }

        }
    }


    /**
    * @description This method creates the Subscription records which are going to be charged when activating the contract
    * @author srojas@legal-credit | 05-02-2021
    * @param sOIds
    **/
    public static void CreateSubscriptionOrderRecordsChargent(List<String>  sOIds){
        System.debug('Entered to Suscription methods');
        List<ChargentOrders__ChargentOrder__c> ords = new List<ChargentOrders__ChargentOrder__c>();
        Map<Id,List<ChargentOrders__ChargentOrder__c>> contractOrders = new Map<Id,List<ChargentOrders__ChargentOrder__c>>();
        SM_Utils.DynamicQueryStructure structure = new SM_Utils.DynamicQueryStructure();
        List<SM_Asset_Fee__c> allAssetFees = new List<SM_Asset_Fee__c>();
        if(sOIds.size()>0){
            structure.AdditionalFields = 'SM_Opportunity__r.SM_Company_Setting__c'
                                        +',SM_Payment_Method__r.SM_Chargent_Order__c'
                                        +',SM_Opportunity__r.SM_Company_Setting__r.SM_Gateway__c'
                                        +',SM_Opportunity__r.SM_Company_Setting__r.SM_IVU_Municipal_Amount__c'
                                        +',SM_Opportunity__r.SM_Company_Setting__r.SM_IVU_State_Amount__c,'
                                        +'SM_Process_automation_by_product_family__r.SM_Maximum_Number_Of_Failed_Transactions__c,';
            structure.sObjectName = 'Contract';
            structure.subqueryObj = 'Chargent_Orders__r';
            structure.whereClause = new map<String,List<object>>{'Id'=>(List<object>)sOIds};
            structure.childsWhereClause = new map<String,List<object>>{'SM_Payment_Type__c'=>new List<Object>{'Subscription','Fee'}};
            structure.orderByParent ='';
            List<sObject> objs  = SM_Utils.getDynamicQuery(structure);
            set<String> companySettingId = new set<String>();
            sObject crRelationShip = null;
            Map<String,Set<String>> requiredFields = new Map<String,Set<String>>();
            if(objs.size()>0){
                for(sObject obj :objs){
                    crRelationShip = obj.getSObject('SM_Opportunity__r');
                    if(crRelationShip != null){
                        companySettingId.add(String.ValueOf(crRelationShip.get('SM_Company_Setting__c')));
                    }
                }
            }
            if(companySettingId.size()>0){
                if(companySettingId.size()>0){
                    requiredFields =  SM_Utils.getRequiredFieldsByProcess('Contract', companySettingId,new Set<String>{'Subscription','Fee'});
                }
            }
            Map<String,Boolean> response = new Map<String,Boolean>();
            if(requiredFields.size()>0){
                response = validateMandatoryFields(requiredFields,objs);
            }
            if(response.size()>0){

                for(Contract ctr: (List<Contract>)objs){
                    if(!response.get(ctr.Id) || ctr.Chargent_Orders__r.size()>0){
                        continue;
                    }
                    System.debug('Before Creating subscription');
                    ords.addAll(createTMPRowsSubscription(ctr));
                    contractOrders.put(ctr.Id,ords);
                    System.debug('After Creating subscription');
                    System.debug(ords);
                }
                Map<Id,List<SM_Asset_Fee__c>> assetFees = SM_ChargentOrderHandler.createAssetFeesProcess(sOIds);
                for(List<SM_Asset_Fee__c> fees: assetFees.values()){
                    allAssetFees.addAll(fees);
                }
                insert allAssetFees;
                System.debug('Before Calculating');
                calculateAssetFee(ords,sOIds,1);
                System.debug('After Calculating');
            }
            if(ords.size()>0){
                System.debug(ords);
                insert ords;
                List<Asset> assetsToProcess = [SELECT Id,SM_Contract__c FROM Asset WHERE SM_Contract__c IN :sOIds AND Price > 0 AND SM_Chargent_Order__c = null];
                Map<Id,List<Asset>> assetsPerContract = new Map<Id,List<Asset>>();
                List<Asset> assetToUpdate = new List<Asset>();
                for(Asset asset : assetsToProcess){
                    if(assetsPerContract.containsKey(Asset.SM_Contract__c)){
                        assetsPerContract.get(Asset.SM_Contract__c).add(asset);
                    }
                    else{
                        assetsPerContract.put(Asset.SM_Contract__c,new List<Asset>{asset});
                    }
                }
                set<Id> contractAlrearyProcessed = new set<Id>();
                for(SM_Asset_Fee__c assetFee: allAssetFees){
                    Id chargentOrder = null;
                    if(contractOrders.containsKey(assetFee.SM_Contract__c)){
                        chargentOrder = contractOrders.get(assetFee.SM_Contract__c)[0].Id;
                        Date chargeDate = contractOrders.get(assetFee.SM_Contract__c)[0].ChargentOrders__Payment_Start_Date__c;
                        assetFee.SM_Chargent_Order__c = chargentOrder;
                        assetFee.SM_Date__C = chargeDate;
                    }
                    if(!contractAlrearyProcessed.add(assetFee.SM_Contract__c)){
                        continue;
                    }
                    if(assetsPerContract.containsKey(assetFee.SM_Contract__c)){
                        List<Asset> AssetsTmp = assetsPerContract.get(assetFee.SM_Contract__c);
                        for(Asset assetToFill: AssetsTmp){
                            assetToFill.SM_Chargent_Order__c = chargentOrder;
                        }
                        assetToUpdate.addAll(AssetsTmp);
                    }
                }
                List<SObject> objsToUpdate = new List<SObject>();
                objsToUpdate.addAll((List<SObject>)allAssetFees);
                objsToUpdate.addAll((List<SObject>)assetToUpdate);
                update objsToUpdate;
            }
        }
    }

    /**
    * @description This method Validates the Fields that are required
    * @author srojas@legal-credit | 05-02-2021
    * @param objs
    **/
    private static Map<String,Boolean> validateMandatoryFields(Map<String,set<String>> requiredFields,List<SObject> objs){
        Map<String,Boolean> resp = new Map<String,Boolean>();
        String crKey = '';
        String crCSetting = '';
        for(sObject obj : objs){
            crKey= String.ValueOf(obj.get('Id'));
            crCSetting = String.valueOf(obj.get('SM_Company_Setting__c'));
            if(requiredFields.containsKey(crCSetting)){
                for(String required: requiredFields.get(crCSetting)){
                    if(obj.get(required) == null){
                        resp.put(crKey,false);
                        break;
                    }
                }
                if(!resp.containsKey(crKey)){
                    resp.put(crKey,true);
                }
                else{
                    Trigger.new[0].adderror(new ObjectException('Please Meake Sure That you filled the AC/Subscription information and that you\'ve register a Card, or selected a Payment method'));
                }
            }
        }
        return resp;
    }

    public class ObjectException extends Exception {
    }

    /**
    * @description This method will create the TMP Rows to add to a list
    * @author srojas@legal-credit | 05-02-2021
    * @param ctr
    **/
    private static List<ChargentOrders__ChargentOrder__c> createTMPRows(Contract ctr){

        List<ChargentOrders__ChargentOrder__c> resp  = new List<ChargentOrders__ChargentOrder__c>();
        ChargentOrders__ChargentOrder__c tmpOrder = new ChargentOrders__ChargentOrder__c();
        Boolean isOneTime = false;
        SM_Utils.DynamicQueryStructure structure = new SM_Utils.DynamicQueryStructure();

        structure = new SM_Utils.DynamicQueryStructure();
        structure.sObjectName = 'ChargentOrders__ChargentOrder__c';
        structure.whereClause = new map<String,List<object>>{
            'Id'=> new list<Object>{ctr.SM_Payment_Method__r.SM_Chargent_Order__c}
        };
        structure.orderByParent ='';
        structure.AdditionalFields = '';
        List<ChargentOrders__ChargentOrder__c> baseRecord  = (List<ChargentOrders__ChargentOrder__c>)SM_Utils.getDynamicQuery(structure);
        System.debug(baseRecord);
        if(ctr.SM_Requires_AC_Payment__c){
            if(ctr.SM_Way_of_AC_Payment__c =='One payment'){
                isOneTime = true;
            }
            if(isOneTime){
                if(baseRecord.size()>0){
                    tmpOrder = baseRecord[0].clone(false);
                    tmpOrder.SM_IsRegisterToken__c = false;
                    tmpOrder.SM_Migrated__c = false; // JSPA - 08/26/2021 - Case 00001012
                    tmpOrder.SM_Migration_Date__c = null; // JSPA - 08/26/2021 - Case 00001012
                    tmpOrder.ChargentOrders__Payment_Frequency__c = 'Once';
                    tmpOrder.ChargentOrders__Account__c = ctr.AccountId;
                    tmpOrder.ChargentOrders__Payment_Count__c = 1;
                    tmpOrder.ChargentOrders__Payment_Stop__c = 'Count';
                    tmpOrder.ChargentOrders__Gateway__c = ctr.SM_Opportunity__r.SM_Company_Setting__r.SM_Gateway__c;
                    tmpOrder.ChargentOrders__Payment_Method__c = 'Credit Card';
                    tmpOrder.ChargentOrders__Payment_Status__c = 'Recurring';
                    tmpOrder.ChargentOrders__Payment_Start_Date__c = ctr.SM_AC_start_date__c;
                    tmpOrder.ChargentOrders__Subtotal__c = ctr.SM_Total_AC__c;
                    tmpOrder.Contract__c = ctr.Id;
                    tmpOrder.SM_P_IVU_Municipal_Amount__c = ctr.SM_Opportunity__r.SM_Company_Setting__r.SM_IVU_Municipal_Amount__c;
                    tmpOrder.SM_P_IVU_State_Amount__c = ctr.SM_Opportunity__r.SM_Company_Setting__r.SM_IVU_State_Amount__c;
                    if(tmpOrder.SM_P_IVU_Municipal_Amount__c != null && tmpOrder.SM_P_IVU_State_Amount__c != null){
                        System.debug(tmpOrder.SM_P_IVU_Municipal_Amount__c);
                        System.debug(tmpOrder.SM_P_IVU_State_Amount__c);
                        System.debug(tmpOrder.SM_P_IVU_Municipal_Amount__c);
                        System.debug((tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_Municipal_Amount__c)/100);
                        System.debug(((tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_State_Amount__c)/100));
                        Decimal subtotal = (tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_Municipal_Amount__c)/100;
                        subtotal += (tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_State_Amount__c)/100;
                        System.debug(subtotal);
                        subtotal = subtotal.setScale(3);
                        tmpOrder.ChargentOrders__Tax__c = subtotal;
                        tmpOrder.ChargentOrders__Charge_Amount__c = tmpOrder.ChargentOrders__Subtotal__c+subtotal;
                    }
                    tmpOrder.SM_Payment_Type__c = 'AC';
                    resp.add(tmpOrder);
                }
            }
            else{
                System.debug(ctr.SM_Total_AC__c);
                double amount = ctr.SM_Total_AC__c/2;
                System.debug(amount);
                List<Integer> counter = new List<Integer>{1,2};
                for(Integer count : counter){
                    System.debug(counter);
                    tmpOrder = baseRecord[0].clone(false);
                    tmpOrder.SM_IsRegisterToken__c = false;
                    tmpOrder.SM_Migrated__c = false; // JSPA - 08/26/2021 - Case 00001012
                    tmpOrder.SM_Migration_Date__c = null; // JSPA - 08/26/2021 - Case 00001012
                    tmpOrder.ChargentOrders__Account__c = ctr.AccountId;
                    tmpOrder.ChargentOrders__Payment_Frequency__c = 'Once';
                    tmpOrder.ChargentOrders__Payment_Count__c = 1;
                    tmpOrder.ChargentOrders__Payment_Stop__c = 'Count';
                    tmpOrder.ChargentOrders__Gateway__c = ctr.SM_Opportunity__r.SM_Company_Setting__r.SM_Gateway__c;
                    tmpOrder.ChargentOrders__Payment_Method__c = 'Credit Card';
                    tmpOrder.ChargentOrders__Payment_Status__c = 'Recurring';
                    tmpOrder.ChargentOrders__Payment_Start_Date__c = ctr.SM_AC_start_date__c;
                    tmpOrder.ChargentOrders__Subtotal__c = amount;
                    tmpOrder.Contract__c = ctr.Id;
                    tmpOrder.SM_Payment_Type__c = 'AC';
                    tmpOrder.SM_P_IVU_Municipal_Amount__c = ctr.SM_IVU_Municipal__c;
                    tmpOrder.SM_P_IVU_State_Amount__c = ctr.SM_IVU_State__c;
                    System.debug(tmpOrder.SM_P_IVU_Municipal_Amount__c);
                    System.debug(tmpOrder.SM_P_IVU_State_Amount__c);
                    System.debug(tmpOrder.SM_P_IVU_Municipal_Amount__c);
                    System.debug((tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_Municipal_Amount__c)/100);
                    System.debug(((tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_State_Amount__c)/100));
                    if(tmpOrder.SM_P_IVU_Municipal_Amount__c != null && tmpOrder.SM_P_IVU_State_Amount__c != null){
                        System.debug(tmpOrder.SM_P_IVU_Municipal_Amount__c);
                        System.debug(tmpOrder.SM_P_IVU_State_Amount__c);
                        System.debug(tmpOrder.SM_P_IVU_Municipal_Amount__c);
                        System.debug((tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_Municipal_Amount__c)/100);
                        System.debug(((tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_State_Amount__c)/100));
                        Decimal subtotal = (tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_Municipal_Amount__c)/100;
                        subtotal += (tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_State_Amount__c)/100;
                        System.debug(subtotal);
                        subtotal = subtotal.setScale(3);
                        tmpOrder.ChargentOrders__Tax__c = subtotal;
                        tmpOrder.ChargentOrders__Charge_Amount__c = tmpOrder.ChargentOrders__Subtotal__c+subtotal;
                    }
                    ctr.SM_AC_start_date__c = ctr.SM_AC_Split_Date__c;
                    resp.add(tmpOrder);
                }
            }
        }
        System.debug(resp);
        return resp;
    }

    /**
    * @description This method creates a list member for subscription
    * @author srojas@legal-credit | 05-02-2021
    * @param ctr
    **/
    private static List<ChargentOrders__ChargentOrder__c> createTMPRowsSubscription(Contract ctr){
        List<ChargentOrders__ChargentOrder__c> resp  = new List<ChargentOrders__ChargentOrder__c>();
        ChargentOrders__ChargentOrder__c tmpOrder = new ChargentOrders__ChargentOrder__c();
        Boolean isOneTime = false;
        SM_Utils.DynamicQueryStructure structure = new SM_Utils.DynamicQueryStructure();
        structure = new SM_Utils.DynamicQueryStructure();
        structure.sObjectName = 'ChargentOrders__ChargentOrder__c';
        structure.whereClause = new map<String,List<object>>{
            'Id'=> new list<Object>{ctr.SM_Payment_Method__r.SM_Chargent_Order__c}
        };
        structure.orderByParent ='';
        structure.AdditionalFields = '';
        List<ChargentOrders__ChargentOrder__c> baseRecord  = (List<ChargentOrders__ChargentOrder__c>)SM_Utils.getDynamicQuery(structure);
        if(ctr.SM_Requires_RC_Payment__c && ctr.SM_Way_of_Contract_Payment__c == 'Subscription'){
            if(baseRecord.size()>0){
                tmpOrder = baseRecord[0].clone(false);
                tmpOrder.SM_IsRegisterToken__c = false;
                tmpOrder.SM_Migrated__c = false; // JSPA - 08/26/2021 - Case 00001012
                tmpOrder.SM_Migration_Date__c = null; // JSPA - 08/26/2021 - Case 00001012
                tmpOrder.ChargentOrders__Payment_Frequency__c = ctr.SM_Frecuency__c;
                tmpOrder.ChargentOrders__Account__c = ctr.AccountId;
                tmpOrder.ChargentOrders__Payment_Stop__c = 'Unending';
                tmpOrder.ChargentOrders__Gateway__c = ctr.SM_Opportunity__r.SM_Company_Setting__r.SM_Gateway__c;
                tmpOrder.ChargentOrders__Payment_Method__c = 'Credit Card';
                tmpOrder.ChargentOrders__Payment_Status__c = 'Recurring';
                tmpOrder.ChargentOrders__Payment_Start_Date__c = ctr.SM_Start_date__c;
                tmpOrder.ChargentOrders__Subtotal__c = ctr.SM_Monthly_offer__c;
                tmpOrder.SM_Payment_Type__c = 'Subscription';
                tmpOrder.Contract__c = ctr.Id;
                tmpOrder.ChargentOrders__Charge_Date__c = String.valueOf(ctr.SM_Payment_day__c);
                tmpOrder.sm_Fee_to_collect__c = 1;
                tmpOrder.SM_P_IVU_Municipal_Amount__c = ctr.SM_Opportunity__r.SM_Company_Setting__r.SM_IVU_Municipal_Amount__c;
                tmpOrder.SM_P_IVU_State_Amount__c = ctr.SM_Opportunity__r.SM_Company_Setting__r.SM_IVU_State_Amount__c;
                if(tmpOrder.SM_P_IVU_Municipal_Amount__c != null && tmpOrder.SM_P_IVU_State_Amount__c != null){
                    System.debug(tmpOrder.SM_P_IVU_Municipal_Amount__c);
                    System.debug(tmpOrder.SM_P_IVU_State_Amount__c);
                    System.debug(tmpOrder.SM_P_IVU_Municipal_Amount__c);
                    System.debug((tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_Municipal_Amount__c)/100);
                    System.debug(((tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_State_Amount__c)/100));
                    Decimal subtotal = (tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_Municipal_Amount__c)/100;
                    subtotal += (tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_State_Amount__c)/100;
                    System.debug(subtotal);
                    subtotal = subtotal.setScale(3);
                    tmpOrder.ChargentOrders__Tax__c = subtotal;
                    tmpOrder.ChargentOrders__Charge_Amount__c = tmpOrder.ChargentOrders__Subtotal__c+subtotal;
                }
                resp.add(tmpOrder);
            }
        }
        if(ctr.SM_Requires_RC_Payment__c && ctr.SM_Way_of_Contract_Payment__c == 'Fix Term'){
            double amount = ctr.SM_Monthly_offer__c/ctr.SM_Plan_Months__c;
            if(baseRecord.size()>0){
                tmpOrder = baseRecord[0].clone(false);
                tmpOrder.SM_IsRegisterToken__c = false;
                tmpOrder.SM_Migrated__c = false; // JSPA - 08/26/2021 - Case 00001012
                tmpOrder.SM_Migration_Date__c = null; // JSPA - 08/26/2021 - Case 00001012
                tmpOrder.ChargentOrders__Account__c = ctr.AccountId;
                tmpOrder.ChargentOrders__Payment_Frequency__c = ctr.SM_Frecuency__c;
                tmpOrder.ChargentOrders__Payment_Stop__c = 'Count';
                tmpOrder.ChargentOrders__Payment_Count__c = ctr.SM_Plan_Months__c;
                tmpOrder.ChargentOrders__Gateway__c = ctr.SM_Opportunity__r.SM_Company_Setting__r.SM_Gateway__c;
                tmpOrder.ChargentOrders__Payment_Method__c = 'Credit Card';
                tmpOrder.ChargentOrders__Payment_Status__c = 'Recurring';
                tmpOrder.ChargentOrders__Payment_Start_Date__c = ctr.SM_Start_date__c;
                tmpOrder.ChargentOrders__Subtotal__c = amount;
                tmpOrder.SM_Payment_Type__c = 'Fee';
                tmpOrder.Contract__c = ctr.Id;
                tmpOrder.sm_Fee_to_collect__c = 1;
                tmpOrder.ChargentOrders__Charge_Date__c = String.valueOf(ctr.SM_Payment_day__c);
                tmpOrder.SM_P_IVU_Municipal_Amount__c = ctr.SM_Opportunity__r.SM_Company_Setting__r.SM_IVU_Municipal_Amount__c;
                tmpOrder.SM_P_IVU_State_Amount__c = ctr.SM_Opportunity__r.SM_Company_Setting__r.SM_IVU_State_Amount__c;

                if(tmpOrder.SM_P_IVU_Municipal_Amount__c != null && tmpOrder.SM_P_IVU_State_Amount__c != null){
                    System.debug(tmpOrder.SM_P_IVU_Municipal_Amount__c);
                    System.debug(tmpOrder.SM_P_IVU_State_Amount__c);
                    System.debug(tmpOrder.SM_P_IVU_Municipal_Amount__c);
                    System.debug((tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_Municipal_Amount__c)/100);
                    System.debug(((tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_State_Amount__c)/100));
                    Decimal subtotal = (tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_Municipal_Amount__c)/100;
                    subtotal += (tmpOrder.ChargentOrders__Subtotal__c*tmpOrder.SM_P_IVU_State_Amount__c)/100;
                    System.debug(subtotal);
                    subtotal = subtotal.setScale(3);
                    tmpOrder.ChargentOrders__Tax__c = subtotal;
                    tmpOrder.ChargentOrders__Charge_Amount__c = tmpOrder.ChargentOrders__Subtotal__c+subtotal;
                }
                resp.add(tmpOrder);
            }
        }
        return resp;
    }

    private static void  calculateAssetFee(List<ChargentOrders__ChargentOrder__c> orders,List<String> contractIds,Integer assetFeeToCollect){
        Map<Id,List<ChargentOrders__ChargentOrder__c>> mapContractOrders = new map<Id,List<ChargentOrders__ChargentOrder__c>>();
        String tempContractId = '';
        List<ChargentOrders__ChargentOrder__c> tmpOrders = new List<ChargentOrders__ChargentOrder__c>();
        List<ChargentOrders__ChargentOrder__c> finalOrders = new List<ChargentOrders__ChargentOrder__c>();
        AggregateResult[] amountsPerContract = [
            SELECT SUM(SM_Amount__c) Amount,SM_Position_Text__c Position,sm_Contract__c Contract
            FROM SM_Asset_Fee__c
            WHERE sm_Contract__c in:contractIds AND (sm_Fee_To_Collect__c = true
                OR SM_Type__c = 'Subscription')
            GROUP BY sm_Contract__c,SM_Position_Text__c
        ];
        //Store the summary of all the asset Fees required in a map Contract,Amount
        map<Id,Map<Integer,Decimal>> mapAmountsPerContract = new map<Id,Map<Integer,Decimal>>();
        Id contractId = null;
        Double sumFees = null;
        Integer position =null;
        Double value =null;
        Map<Integer,Double> tmpMap = new Map<Integer,Double>();
        for(AggregateResult contractAmount: amountsPerContract){
            contractId = String.valueOf(contractAmount.get('Contract'));
            sumFees = Decimal.valueOf(String.valueOf(contractAmount.get('Amount')));
            position = Integer.valueOf(String.valueOf(contractAmount.get('Position')));
            if(mapAmountsPerContract.containsKey(contractId)){
                tmpMap = mapAmountsPerContract.get(contractId);
                if(tmpMap.containsKey(position)){
                    value = tmpMap.get(position);
                    value += tmpMap.get(position);
                    mapAmountsPerContract.get(contractId).put(position,value);
                }
                else{
                    mapAmountsPerContract.get(contractId).put(
                        position, sumFees
                    );
                }
            }
            else{
                mapAmountsPerContract.put(contractId,
                    new Map<Integer,Double>{position=>sumFees}
                );
            }
        }
        //Store the orders related to the Contract--- Currently only subscription and it will be only one. but the method takes a list as per the standards
        for(ChargentOrders__ChargentOrder__c order :orders){
            System.debug('Gotten this far');
            tempContractId = order.Contract__c;
            if(mapContractOrders.containsKey(tempContractId)){
                mapContractOrders.get(tempContractId).add(order);
            }
            else{
                mapContractOrders.put(tempContractId,new List<ChargentOrders__ChargentOrder__c>{order});
            }
        }
        //Gets the amount to be populated in the order and fills it
        for(Id contractIdent : mapContractOrders.keySet()){
            for(ChargentOrders__ChargentOrder__c order : mapContractOrders.get(contractIdent)){
                if(!mapAmountsPerContract.containsKey(contractIdent)){
                    orders.clear();
                }
                if(mapAmountsPerContract.containsKey(contractIdent) && mapAmountsPerContract.get(contractIdent).containsKey(assetFeeToCollect)){
                    order.ChargentOrders__Subtotal__c = mapAmountsPerContract.get(contractIdent).get(assetFeeToCollect);
                    Decimal subtotal = (order.ChargentOrders__Subtotal__c*order.SM_P_IVU_Municipal_Amount__c)/100;
                    subtotal += (order.ChargentOrders__Subtotal__c*order.SM_P_IVU_State_Amount__c)/100;
                    System.debug(subtotal);
                    subtotal = subtotal.setScale(3);
                    order.ChargentOrders__Tax__c = subtotal;
                    order.ChargentOrders__Charge_Amount__c = order.ChargentOrders__Subtotal__c+subtotal;
                }
                finalOrders.add(order);
            }
        }
        orders = finalOrders;
    }

}