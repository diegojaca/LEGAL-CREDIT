/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 03-18-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   03-11-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
public without sharing class SM_ContactPointAddressHelper {

    //Instances of enums
    public static TypeEnum type = new TypeEnum();

    /** This class represents Enum to attribute Type (Developer name) */
    public class TypeEnum {
        public String BILLING_ADDRESS = 'Billing Address';
        public String PHYSICAL_ADDRESS = 'Physical Address';
        public String POSTAL_ADDRESS = 'Postal Address';
    }

    public static List<ContactPointAddress> getAddressesByParentIds(Set<String> parentIds){
        return [SELECT Id, Name, Street, City, State, PostalCode, Country, SM_Type__c, ParentId FROM ContactPointAddress WHERE ParentId IN :parentIds ORDER BY LastModifiedDate DESC];
    }
}