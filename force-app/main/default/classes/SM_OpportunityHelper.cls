/**
 * @description       : Helper class of Account object
 * @author            : jpachon@legal-credit.com
 * @group             : 
 * @last modified on  : 02-04-2021
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-24-2020   jpachon@legal-credit.com   Initial Version
**/
public with sharing class SM_OpportunityHelper {

    public static StageEnum stageName = new StageEnum();
    public static ContractStageEnum contractStage = new ContractStageEnum();
    public static RecordTypeEnum recordType = new RecordTypeEnum();
    public static DispositionEnum dispositions = new DispositionEnum();

    public class StageEnum {
        public String qualitifation = 'Qualification';
        public String needsAnalysis = 'Needs Analysis';
        public String proposal = 'Proposal';
        public String negotiation = 'Negotiation';
        public String closedWon = 'Closed Won';
        public String paymentProcess = 'Payment Process';
        public String closedLost = 'Closed Lost';
        public String noContact = 'No Contact';
        public String notOriented = 'Not Oriented';
        public String oriented = 'Oriented';
        public String newSage = 'New';
    }

    public class ContractStageEnum {
        public String inCourse = 'In_course';
        public String none = 'None';
        public String cancel = 'Cancel';
    }

    public class RecordTypeEnum {
        public String harmone = 'Harmone';
        public String insuranceCompany = 'Insurance company';
        public String legalCreditSolutions = 'Legal credit solutions';
    }

    public class DispositionEnum {
        public String sale = 'Sale';
        public String salePtp = 'Sale PTP';
    }

    /**
    * @description return Opportunities by dinamic SOQL
    * @author diego.jacanamijoy@gmail.com | 02-04-2021
    * @param query 
    * @return Opportunity[] 
    **/
    public static Opportunity[] getOpportunitiesByDinamicQuery(String query){
        Opportunity[] opps;
        try{
            opps = Database.query(query);
        }catch(QueryException e){
            opps = new List<Opportunity>();
        }
        return opps;
    }

    /**
    * @description 
    * @author diego.jacanamijoy@gmail.com | 12-02-2020 
    * @param leadId 
    * @return Opportunity 
    **/
    public static Opportunity getOpportunityId(String opportunityId){
        Opportunity opp;
        try {
            opp = [SELECT OwnerId, SM_Company_Setting__r.SM_Opportunity_Stage_not_accessible__c, StageName
                    FROM Opportunity 
                    WHERE Id =: opportunityId 
                    LIMIT 1
                    ];
        } catch (QueryException e) {
            opp = null;
        }
        return opp;
    }
}