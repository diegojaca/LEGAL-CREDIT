/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 01-18-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   01-14-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
public without sharing class SM_SetupCallsDistributeHelper {

    public static RecordTypeEnum recordType = new RecordTypeEnum();

    // This class represents Enum to record type attribute (Developer name)
    public class RecordTypeEnum {
        public String five9List = 'Five9 List';
        public String reminder = 'Reminder';
    }

}