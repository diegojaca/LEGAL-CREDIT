/**
 * @description       : Helper class of Transaction object
 * @author            : Manuel Mendez
 * @group             : 
 * @last modified on  : 09/10/2021
 * @last modified by  : mmendez@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   09-10-2021   Manuel Mendez                 Initial Version
**/
public with sharing class SM_ErrorDescription_Helper {

     /**
    * @description 
    * @author Manuel Mendez 
    * @param  List<ChargentOrders__Transaction__c> lstNew, List<ChargentOrders__Transaction__c> lstOld
    * @Description This method update field SM_ResponseDetail__c on ChargentOrders__Transaction__c for create traduction for reason code
    **/
    public static void ErrorDescription (List<ChargentOrders__Transaction__c> lstNew, List<ChargentOrders__Transaction__c> lstOld){
        Map<String,String> mapErrorDescription = new Map<String,String>();
        list<SM_GatewayErrors__c> lstGatewayError = [SELECT Name,
                                                        SM_ErrorDescription__c,
                                                        SM_CodeError__c,
                                                        SM_Gateway__c 
                                                        FROM SM_GatewayErrors__c];
        if(!lstGatewayError.isEmpty()){
            for(SM_GatewayErrors__c objGateError : lstGatewayError){
                mapErrorDescription.put(objGateError.SM_CodeError__c,objGateError.SM_ErrorDescription__c);
            }
            String strZero = '.0';
            // When is insert event
            if(lstOld == null){
                for(ChargentOrders__Transaction__c objTransaction :lstNew){
                    if (objTransaction.ChargentOrders__Reason_Code__c != null) {
                        objTransaction.SM_ResponseDetail__c = mapErrorDescription.get(String.valueOf(objTransaction.ChargentOrders__Reason_Code__c).removeEnd(strZero)) != null ? mapErrorDescription.get(String.valueOf(objTransaction.ChargentOrders__Reason_Code__c).removeEnd(strZero)):'';    
                    }
                    
                }
            // When is update event
            }else{
                for(integer i=0; i<lstNew.size(); i++){
                    if (lstNew[i].ChargentOrders__Reason_Code__c != null) {
                        if(lstNew[i].ChargentOrders__Reason_Code__c != lstOld[i].ChargentOrders__Reason_Code__c && lstNew[i].ChargentOrders__Reason_Code__c != null){
                            lstNew[i].SM_ResponseDetail__c = mapErrorDescription.get(String.valueOf(lstNew[i].ChargentOrders__Reason_Code__c).removeEnd(strZero)) != null ? mapErrorDescription.get(String.valueOf(lstNew[i].ChargentOrders__Reason_Code__c).removeEnd(strZero)):'';
                        }
                    }
                }
            }
        }    
    }
}