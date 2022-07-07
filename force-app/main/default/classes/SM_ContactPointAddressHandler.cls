/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 03-08-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   03-02-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
public without sharing class SM_ContactPointAddressHandler extends SM_TriggerHandler{

    public SM_ContactPointAddressHandler(String triggerName){
        super(triggerName);
    }

    /************* Overwrite DML methods *************/
    override public void beforeInsert(){
        try {
            fillName(Trigger.new);
        }catch(Exception e){
            System.debug('An error occurred in beforeInsert ContactPointAddress  '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }        
    }

    /************* Overwrite DML methods *************/
    override public void beforeUpdate(){
        try {
            fillName(Trigger.new);
        }catch(Exception e){
            System.debug('An error occurred in beforeUpdate ContactPointAddress  '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }        
    }

    /************* Auxiliar methods *************/

    /**
    * @description this method validate required fields
    * @author diego.jacanamijoy@gmail.com | 11-24-2020 
    * @param newCPA 
    **/
    private static void fillName(List<ContactPointAddress> newCPA){
        for (ContactPointAddress cpa : newCPA) {
            // cpa.Name = cpa.Street + ' ' + cpa.City + ', ' + cpa.State + ' ' + cpa.PostalCode + ' ' + cpa.Country; 
            cpa.Name = (String.isNotBlank(cpa.Street) ? cpa.Street : '') + ' ' + (String.isNotBlank(cpa.City) ? cpa.City : '') + ', ' + (String.isNotBlank(cpa.State) ? cpa.State : '') + ' ' + (String.isNotBlank(cpa.PostalCode) ? cpa.PostalCode : '') + ' ' + (String.isNotBlank(cpa.Country) ? cpa.Country : ''); 
        }
    }

}