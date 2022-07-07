/**
 * @description       : Helper class of convert lead process from button on lead object
 * @author            : jpachon@legal-credit.com
 * @group             :
 * @last modified on  : 06-12-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                        Modification
 * 1.0   12-03-2020   jpachon@legal-credit.com   Initial Version
**/
public with sharing class SM_AccountListItemController {

    @AuraEnabled(cacheable=true)
    public static List<String> getFieldsToShow() {
        try {
            return SM_Utils.getFieldsFromFieldSet('Account', 'Lead_Convert_Process');
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}