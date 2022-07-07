/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 01-18-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   01-15-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
public without sharing class SM_TaskHelper {

    public static RecordTypeEnum recordType = new RecordTypeEnum();
    public static StatusEnum status = new StatusEnum();

    // This class represents Enum to record type attribute (Developer name)
    public class RecordTypeEnum {
        public String five9 = 'Five9';
        public String reminder = 'Reminder';
    }

    // This class represents Enum to status attribute (Developer name)
    public class StatusEnum {
        public String open = 'Open';
        public String completed = 'Completed';
    }
}