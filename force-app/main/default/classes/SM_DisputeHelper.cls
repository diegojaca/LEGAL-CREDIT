/**
 * @description       : 
 * @author            : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 03-16-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon@legal-credit.com
 * Modifications Log 
 * Ver   Date         Author                                                 Modification
 * 1.0   03-15-2021   Jonathan S. Pachon Ariza -> jpachon@legal-credit.com   Initial Version
**/
public without sharing class SM_DisputeHelper {

    //Instances of enums
    public static StatusEnum status = new StatusEnum();

    /** This class represents Enum to attribute Status (Developer name) */
    public class StatusEnum {
        public String NEW_CASE = 'New Case';
        public String DOCUMENTATION_COMPLETE = 'Documentation Complete';
        public String AC_COMPLETE = 'AC Complete';
        public String IN_DISPUTE = 'In Dispute';
        public String CASE_ON_HOLD = 'Case On Hold';
        public String CANCELLED = 'Cancelled';
        public String FINISH = 'Finish';
        public String CLOSED = 'Closed';
        public String PENDING = 'Pending';
        public String DRAFT = 'Draft';
    }
    
    public class TokenObtainPair{
        public String email{get; set;}
        public String password{get; set;}
    }
 
    
 
    public class Token{
        public String refresh{get; set;}
        public String access{get; set;}
       
    }
 
    public class Status{
        public String id{get; set;}
        public String name{get; set;}
       
    }
    public class StatusDispute{
        Status status {get; set;}
       
    }
    
}