/**
 * @description       : Helper class of Account object
 * @author            : jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 01-26-2021
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-24-2020   jpachon@legal-credit.com   Initial Version
**/
public with sharing class SM_AccountHelper {

    public static RecordTypeEnum recordType = new RecordTypeEnum();

    public class RecordTypeEnum {
        public String personAccount = 'PersonAccount';
    }

    /**
    * @description return Accounts by dinamic SOQL
    * @author diego.jacanamijoy@gmail.com | 01-26-2021 
    * @param query 
    * @return Account[] 
    **/
    public static Account[] getAccountsByDinamicQuery(String query){
        Account[] accounts;
        try{
            accounts = Database.query(query);
        }catch(QueryException e){
            accounts = new List<Account>();
        }
        return accounts;
    }
}