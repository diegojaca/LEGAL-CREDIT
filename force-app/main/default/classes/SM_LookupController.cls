/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 07-24-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   02-27-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
public without sharing class SM_LookupController {

    /**
    * @description Method to search contac point address records by filters
    * @author jpachon@legal-credit.com | 03-03-2021
    * @param searchTerm 
    * @param addressType 
    * @return records List<ContactPointAddress>
    **/
    @AuraEnabled(cacheable=true)
    public static List<ContactPointAddress> searchAddresses(String searchTerm, String addressType, String accountId) {
        searchTerm = '%' + searchTerm + '%';
        List<ContactPointAddress> records;
        if(searchTerm == null || searchTerm == ''){
            records = [SELECT Id, Name, Street, State, PostalCode, Country, City FROM ContactPointAddress WHERE SM_Type__c = :addressType AND ParentId =: accountId ORDER BY LastViewedDate DESC LIMIT  5];
        }
        else {
            records = [SELECT Id, Name, Street, State, PostalCode, Country, City FROM ContactPointAddress WHERE (Name like :searchTerm OR Street like :searchTerm OR State like :searchTerm OR PostalCode like :searchTerm OR Country like :searchTerm OR City like :searchTerm) AND SM_Type__c =: addressType AND ParentId =: accountId LIMIT 5];
        }
        System.debug('records: ' + JSON.serialize(records));
        return records;
    }

}