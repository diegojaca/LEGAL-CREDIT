/*
    @Author : Santiago Rojas
    @BuiltDate : 30-01-2021
    @Description : Contract Trigger handler Class
    @Company : Trailhead
    @test: Covered by SM_ContractHandlerTest
*/
public class chargentOrTrController extends SM_TriggerHandler{

    public chargentOrTrController(String triggerName){
        super(triggerName);
    }
    
    override public void BeforeInsert() {}
 
    override public void BeforeUpdate() {}
 
    override public void BeforeDelete() {}
 
    override public void AfterInsert() {
        System.debug('Started Trigger ');
        /* Update the relatedContract */
        List<Contract> contractsToUpdateList = new List<Contract>();
        Try{
            Map<String,List<String>> idsMap = new Map<String,List<String>>();
            String trId = '';
            String orderId = '';
            for(sObject crObject: Trigger.newMap.values()){
                trId = String.valueOf(crObject.get('Id'));                
                orderId = String.valueOf(crObject.get('ChargentOrders__Order__c'));
                System.debug(crObject);
                System.debug(trId);
                System.debug(orderId);
                if(!idsMap.containsKey(trId)){
                    idsMap.put(trId,new List<String>{orderId});
                }
                else{
                    idsMap.get(trId).add(orderId);
                }
            }
            System.debug(idsMap);
            if(idsMap.size()>0){
                PupulateRelatedContract(idsMap,Trigger.newMap);
            }

        }Catch(System.Exception ex){
            /* Call the TransactionLogHandler class method to create a log 
               parameters need to pass in the method are System.Exception and the Handler ClassName
            */
            //TransactionLogHandler.doHandleException(ex , 'contractTGRController');
        }
    }
 
    override public void AfterUpdate() {
        System.debug('Started Trigger ');
        /* Update the relatedContract */
        Map<Id, SObject> validatedItems =  new Map<Id, SObject>();
        List<Contract> contractsToUpdateList = new List<Contract>();
        Try{
            Map<String,List<String>> idsMap = new Map<String,List<String>>();
            String trId = '';
            String orderId = '';
            for(sObject crObject: Trigger.newMap.values()){
                System.debug(crObject.get('ChargentOrders__Response_Status__c'));
                System.debug(trigger.oldMap.get(String.valueOf(crObject.get('Id'))).get('ChargentOrders__Response_Status__c'));
                if(crObject.get('ChargentOrders__Response_Status__c') != null && crObject.get('ChargentOrders__Account__c') == null){
                    trId = String.valueOf(crObject.get('Id'));                
                    orderId = String.valueOf(crObject.get('ChargentOrders__Order__c'));
                    System.debug(crObject);
                    System.debug(trId);
                    System.debug(orderId);
                    if(!idsMap.containsKey(trId)){
                        idsMap.put(trId,new List<String>{orderId});
                    }
                    else{
                        idsMap.get(trId).add(orderId);
                    }
                }
            }
            if(idsMap.size()>0){
                PupulateRelatedContract(idsMap,Trigger.newMap);
            }

        }Catch(System.Exception ex){
            /* Call the TransactionLogHandler class method to create a log 
               parameters need to pass in the method are System.Exception and the Handler ClassName
            */
            system.debug(ex);
            
            system.debug(ex.getStackTraceString());
            //TransactionLogHandler.doHandleException(ex , 'contractTGRController');
        }
    }
 
    override public void AfterDelete() {}

 
    override public void AfterUndelete() {}

    private void PupulateRelatedContract(Map<String,List<String>> ids, Map<Id, SObject> insertedData){
        SM_Utils.DynamicQueryStructure structure = new SM_Utils.DynamicQueryStructure();
        Contract tmpCtr = new Contract();
        List<Contract> toUpdate = new List<Contract>();
        SM_Payment_Method__c tmpPaymentMethod = new SM_Payment_Method__c(); 
        map<Id,SM_Payment_Method__c> toInsertPaymentMethods = new map<Id,SM_Payment_Method__c>();
        ChargentOrders__ChargentOrder__c tmpChargentOrder = new ChargentOrders__ChargentOrder__c();
        Set<String> AccountId = new Set<String>();
        structure.AdditionalFields = 'Contract__r.Status,Contract__r.SM_Process_automation_by_product_family__r.SM_Maximum_Number_Of_Failed_Transactions__c,'
                                     +'Contract__r.SM_Charged_AC_Amount__c,Contract__r.SM_Partially_Charged_AC_Fees__c,'
                                     +'Contract__r.SM_Total_Charged_AC_Suscription__c,Contract__r.SM_Charged_SB_Fees__c,'
                                     +'Contract__r.SM_Partially_Charged_SB_Fees__c,Contract__r.SM_Charged_SB_Amount__c,'
                                     +'Contract__r.SM_Failed_SB_Fees__c,Contract__r.SM_Total_AC__c,Contract__r.AccountId,'
                                    +'Contract__r.SM_Number_of_AC_Fees__c,Contract__r.SM_Charged_AC_Fees__c,Contract__r.SM_Failed_AC_Fees__c,';
        structure.sObjectName = 'ChargentOrders__ChargentOrder__c';
        structure.whereClause = new map<String,List<object>>{'Id'=>new List<object>()};
        structure.orderByParent ='';
        for(String idData: ids.keySet()){
            structure.whereClause.get('Id').addAll(ids.get(idData));
        }
        map<Id,SObject> orders  = new Map<Id,SObject>(SM_Utils.getDynamicQuery(structure));
        System.debug(orders);
        List<ChargentOrders__Transaction__c> data = [SELECT ChargentOrders__Type__c,ChargentOrders__Order__c,ChargentOrders__Order__r.ChargentOrders__Card_Last_4__c,
                                                            ChargentOrders__Order__r.ChargentOrders__Card_Type__c,ChargentOrders__Order__r.ChargentOrders__Card_Year_Indicator__c,
                                                            ChargentOrders__Order__r.ChargentOrders__Credit_Card_Name__c,
                                                            ChargentOrders__Order__r.ChargentOrders__Charge_Amount__c,ChargentOrders__Order__r.ChargentOrders__Subtotal__c,ChargentOrders__Order__r.ChargentOrders__Payment_Received__c,
                                                            ChargentOrders__Response_Status__c,ChargentOrders__Order__r.ChargentOrders__UseTokenization__c,
                                                            ChargentOrders__Order__r.ChargentOrders__Card_Number__c,ChargentOrders__Tokenization__c,
                                                            ChargentOrders__Order__r.ChargentOrders__Card_Month_Indicator__c,
                                                            ChargentOrders__Order__r.Contract__r.AccountId,ChargentOrders__Order__r.Contract__c
                                                        FROM ChargentOrders__Transaction__c 
                                                        WHERE ID=:insertedData.keySet()];        
        for(ChargentOrders__Transaction__c cOT: data){
            tmpCtr = new Contract(); 
            tmpChargentOrder = (ChargentOrders__ChargentOrder__c)orders.get(cOT.ChargentOrders__Order__c);
            tmpCtr= tmpChargentOrder.contract__r;
            if(cOT.ChargentOrders__Type__c=='Charge'){
                if(cOT.ChargentOrders__Response_Status__c =='Approved'){                    
                    if(tmpChargentOrder.SM_Payment_Type__c == 'AC'){
                        tmpCtr.SM_Failed_AC_Fees__c =0;
                        tmpCtr.SM_Charged_AC_Fees__c = tmpCtr.SM_Charged_AC_Fees__c==null?0:tmpCtr.SM_Charged_AC_Fees__c;
                        tmpCtr.SM_Partially_Charged_AC_Fees__c = tmpCtr.SM_Partially_Charged_AC_Fees__c==null?0:tmpCtr.SM_Partially_Charged_AC_Fees__c;
                        tmpCtr.SM_Charged_AC_Amount__c = tmpCtr.SM_Charged_AC_Amount__c==null?0:tmpCtr.SM_Charged_AC_Amount__c;
                        if(tmpCtr.SM_Charged_AC_Amount__c == 0){
                            tmpCtr.SM_Payment_Received__c = true;
                        }
                        tmpCtr.SM_Charged_AC_Fees__c += 1;
                        tmpCtr.SM_Charged_AC_Amount__c += cOT.ChargentOrders__Order__r.ChargentOrders__Subtotal__c;
                        if(cOT.ChargentOrders__Order__r.ChargentOrders__Payment_Received__c == 'Partial'){
                            tmpCtr.SM_Partially_Charged_AC_Fees__c += 1;
                        }
                        if(tmpCtr.SM_Charged_AC_Amount__c>= tmpCtr.SM_Total_AC__c){
                            tmpCtr.SM_AC_collected__c = true;
                            tmpCtr.status = 'Activated';
                        }
                    }
                    if(tmpChargentOrder.SM_Payment_Type__c == 'Suscription'){
                        System.debug('Arrived');
                        
                        tmpCtr.SM_Failed_SB_Fees__c = 0;
                        tmpCtr.SM_Charged_SB_Fees__c = tmpCtr.SM_Charged_SB_Fees__c==null?0:tmpCtr.SM_Charged_SB_Fees__c;
                        if(tmpCtr.status != 'Activated' && tmpCtr.SM_Charged_SB_Fees__c == 0){
                            tmpCtr.status = 'Activated';
                        }
                        tmpCtr.SM_Partially_Charged_SB_Fees__c = tmpCtr.SM_Partially_Charged_SB_Fees__c==null?0:tmpCtr.SM_Partially_Charged_SB_Fees__c;
                        tmpCtr.SM_Charged_SB_Amount__c = tmpCtr.SM_Charged_SB_Amount__c==null?0:tmpCtr.SM_Charged_SB_Amount__c;
                        tmpCtr.SM_Charged_SB_Fees__c +=+1;
                        if(cOT.ChargentOrders__Order__r.ChargentOrders__Payment_Received__c == 'Partial'){
                            tmpCtr.SM_Partially_Charged_SB_Fees__c += 1;
                        }
                        tmpCtr.SM_Charged_SB_Amount__c += cOT.ChargentOrders__Order__r.ChargentOrders__Charge_Amount__c;
                    }
                    tmpCtr.SM_Total_Charged_AC_Suscription__c = tmpCtr.SM_Total_Charged_AC_Suscription__c==null?0:tmpCtr.SM_Total_Charged_AC_Suscription__c;
                    
                    tmpCtr.SM_Total_Charged_AC_Suscription__c = tmpCtr.SM_Total_Charged_AC_Suscription__c+cOT.ChargentOrders__Order__r.ChargentOrders__Charge_Amount__c;
                }
                else if(cOT.ChargentOrders__Response_Status__c =='Declined' || cOT.ChargentOrders__Response_Status__c =='Error'){
                    System.debug('Arrived');
                    if(tmpChargentOrder.SM_Payment_Type__c == 'AC'){
                        System.debug('Arrived');
                        tmpCtr.SM_Failed_AC_Fees__c = tmpCtr.SM_Failed_AC_Fees__c==null?0:tmpCtr.SM_Failed_AC_Fees__c;
                        tmpCtr.SM_Failed_AC_Fees__c = tmpCtr.SM_Failed_AC_Fees__c+1;
                    }
                    else if(tmpChargentOrder.SM_Payment_Type__c == 'Suscription'){
                        System.debug('Arrived');
                        tmpCtr.SM_Failed_SB_Fees__c = tmpCtr.SM_Failed_SB_Fees__c==null?0:tmpCtr.SM_Failed_SB_Fees__c;
                        tmpCtr.SM_Failed_SB_Fees__c = tmpCtr.SM_Failed_SB_Fees__c+1;
                    }
                }
            }
            
            cOT.Contract__c=tmpCtr.Id;
            cOT.ChargentOrders__Account__c = tmpCtr.AccountId;
            if(tmpCtr.Id != null){
                toUpdate.add(tmpCtr);
            }
        }
        if(toInsertPaymentMethods.size()>0){
            insert toInsertPaymentMethods.values();
            //Pass info to Contract
            for(Contract ctr: toUpdate){
                
                Id pId = toInsertPaymentMethods.get(ctr.Id).Id;
                if(pId != null){
                    ctr.SM_Payment_Method__c = pId;
                }
            }
        }
        
        update data;
        if(toUpdate.size()>0){
            update toUpdate;
        }
    }

}