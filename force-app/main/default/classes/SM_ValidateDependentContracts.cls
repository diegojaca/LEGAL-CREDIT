/**
 * @description       : 
 * @author            : Diego Jacanamijoy -> djacanamijoy@legal-credit.com
 * @group             : 
 * @last modified on  : 26/07/2022
 * @last modified by  : Diego Jacanamijoy -> djacanamijoy@legal-credit.com
**/
public with sharing class SM_ValidateDependentContracts {

    public static Map<Id, Contract> dependentByMasterIds = new Map<Id, Contract>();
    //Map Key => Id of contract master, value => Aux contract object with value of fields to validate
    public static Map<String,Contract> dependFieldByMasterId = new Map<String,Contract>();
    public static Datetime lastModifiedDependent;

    /**
    * @description 
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 21/07/2022 
    * @param newRecords 
    * @param oldRecordsMap 
    **/
    public static void checkReadyForCollectionContracts(List<Contract> newRecords, Map<Id, SObject> oldRecordsMap){

        Set<Id> masterContractIds = new Set<Id>();
        Set<Id> dependentContractIds = new Set<Id>();

        for (Contract newCt : newRecords) {

            Contract oldCt = (Contract) oldRecordsMap.get(newCt.Id);
            //Validate if change Collection_Main_Contract__c to Ready for collection and is dependent
            if (SM_Utils.isChangedField(newCt, oldCt, 'Collection_Main_Contract__c') && newCt.Collection_Main_Contract__c == SM_ContractHelper.collectionMain.READY_FOR_COLLECTION
                && newCt.Contract_Type__c == SM_ContractHelper.contractType.DEPENDENT && newCt.Principal_Contract__c <> null)
            {
                masterContractIds.add(newCt.Principal_Contract__c);
                dependentContractIds.add(newCt.Id);
                dependentByMasterIds.put(newCt.Principal_Contract__c, newCt);
            }
        }
        
        /** Check records to proccess */
        if(!masterContractIds.isEmpty()){
            searchDependentContractsByMaster(masterContractIds, dependentContractIds);
        }
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 21/07/2022 
    * @param masterContractIds 
    * @param dependentContractIds 
    **/
    private static void searchDependentContractsByMaster(Set<Id> masterContractIds, Set<Id> dependentContractIds){
        
        List<Contract> mastersToUpdate = new List<Contract>();
        Map<Id, Set<Id>> dependentIdsByMasterId = new  Map<Id, Set<Id>>();
        Boolean dependentValidates = true;

        //Get dependent contracts order by Collection_Main_Contract__c, to check first the records invalids
        for(Contract master: [SELECT 
                                    SM_Plan_Months__c, SM_Start_date__c, SM_Way_of_Contract_Payment__c,
                                    (
                                        SELECT 
                                            Collection_Main_Contract__c, SM_Requires_AC_Payment__c, SM_AC_start_date__c, SM_AC_Split_Date__c, Principal_Contract__c 
                                            , SM_Physical_address__c, SM_Postal_address__c, SM_Billing_Address__c, SM_Payment_methods__c, SM_Payment_Method__c
                                            , SM_Requires_RC_Payment__c, SM_Way_of_Contract_Payment__c, SM_Plan_Months__c, SM_Start_date__c
                                            , SM_Payment_day__c, SM_Frecuency__c, lastModifiedDate
                                        FROM Contracts1__r 
                                        //WHERE Id NOT IN: dependentContractIds 
                                        WHERE Contract_activation_form__c =: SM_ContractHelper.collectionActivationForm.INMEDIATE_ACTIVATION 
                                        ORDER BY Collection_Main_Contract__c
                                    ),
                                    (
                                        SELECT
                                            AC_Price__c, SM_Contract__c, Price
                                        FROM Assets1__r
                                        WHERE Contract_activation_form__c <>: SM_ContractHelper.collectionActivationForm.FUTURE_ACTIVATION
                                    ) 
                                FROM Contract 
                                WHERE Id IN: masterContractIds])
        {
            /** Reset date variable */
            lastModifiedDependent = null;

            /** Set values to master, this fields don´t dependt of dependent contratcs */
            master.StartDate = System.today();
            master.Collection_Main_Contract__c = SM_ContractHelper.collectionMain.READY_FOR_COLLECTION;
            
            /** Iterate and validate dependent contracts */
            for(Contract dependent: master.Contracts1__r){

                /** Build map to sum assets values to update master contract */
                if(!dependentIdsByMasterId.containsKey(master.Id)){
                    dependentIdsByMasterId.put(master.Id, new Set<Id>());
                }
                dependentIdsByMasterId.get(master.Id).add(dependent.Id);

                /** Check  Collection_Main_Contract__c to continue with other validations or connituos with next master*/
                if(dependent.Collection_Main_Contract__c <> SM_ContractHelper.collectionMain.READY_FOR_COLLECTION){
                    dependentValidates = false;
                    break;
                }

                /** Call method to other validations of dependent contracts */
                try {
                    validateDepentContract(dependent, master);    
                } catch (ValidateContractsException e ) {
                    dependentByMasterIds.get(master.Id).addError(e.getMessage());
                    dependentValidates = false;
                    break;
                }
                
            }

            /** If there is dependent with error, go to next master */
            if(!dependentValidates)continue;

            //If pass validations, update summation data from related assets to master contract
            setSummationAssetDataToMaster(master, dependentIdsByMasterId);

            /** Add master to list to update */
            mastersToUpdate.add(master);
        }

        /** Update master contracts */
        if(!mastersToUpdate.isEmpty()){
            update mastersToUpdate;
        }
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 21/07/2022 
    * @param dependent 
    * @param master 
    * @param lastModifiedDependent 
    **/
    private static Boolean validateDepentContract(Contract dependent, Contract master){

        Map<Id,Date> startDateBymaster = new Map<Id,Date>();//map to check same SM_AC_start_date__c
        Map<Id,Date> spliteDateBymaster = new Map<Id,Date>();//map to check same SM_AC_start_date__c
        //Billing contract fields to validate same value from dependent contracts
        Set<String> billingFieldsTovalidate = new Set<String>{'SM_Physical_address__c', 'SM_Postal_address__c', 'SM_Billing_Address__c', 'SM_Payment_methods__c', 'SM_Payment_Method__c'};

        /** Check Ac start data, if one depent contract has a diferent date or date is less than today, set user error */
        if(dependent.SM_Requires_AC_Payment__c){

            /** This date must be not null and greater than today */
            if(dependent.SM_AC_start_date__c == null || dependent.SM_AC_start_date__c < System.today()){
                throw new ValidateContractsException(Label.AC_START_DATE_ERROR);
            }

            /** Call method to validate same value by contract field SM_AC_start_date__c */
            checkSameValueByContractField(master, dependent, 'SM_AC_start_date__c', Label.AC_START_DATE_ERROR);

            /** This date must be null or greater than today */
            if(dependent.SM_AC_Split_Date__c <> null && dependent.SM_AC_Split_Date__c < System.today()){
                throw new ValidateContractsException(Label.AC_SPLIT_DATE_ERROR);
            }

            /**Call method to validate same value by contract field SM_AC_Split_Date__c*/
            checkSameValueByContractField(master, dependent, 'SM_AC_Split_Date__c', Label.AC_SPLIT_DATE_ERROR);
        }

        /** Validate billing data */
        for(String billingField: billingFieldsTovalidate){
            /**Call method to validate same value by contract billing fields*/
            checkSameValueByContractField(master, dependent, billingField, Label.BILLING_FIELDS_ERROR);
        }

        /** If past all validations, call method to set master contract data */
        setMasterContractData(master, dependent);

        return true;
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 21/07/2022 
    * @param master 
    * @param dependent 
    * @param fieldName 
    * @param errorMessage 
    **/
    private static Boolean checkSameValueByContractField(Contract master, Contract dependent, String fieldName, String errorMessage){

        if(dependFieldByMasterId.containsKey(master.Id)){

            //If field value is different set error
            if(dependFieldByMasterId.get(master.Id).isSet(fieldName) 
                && dependFieldByMasterId.get(master.Id).get(fieldName) <> dependent.get(fieldName))
            {
                throw new ValidateContractsException(errorMessage);
            }

            //If field value is null or is equal, set the same value
            dependFieldByMasterId.get(master.Id).put(fieldName, dependent.get(fieldName));
        }else {

            //Create init instance of aux contract with field values
            Contract auxContract = new Contract();
            auxContract.put(fieldName, dependent.get(fieldName));
            dependFieldByMasterId.put(master.Id, auxContract);
        }

        return true;
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 21/07/2022 
    * @param master 
    * @param dependent 
    * @param lastModifiedDependent 
    **/
    private static void setMasterContractData(Contract master, Contract dependent){

        //Contract fields to validate, if one dependent contract has value in one of this fields, set value to master contract
        Set<String> checkedFieldsTovalidate = new Set<String>{'SM_Requires_AC_Payment__c', 'SM_AC_start_date__c', 'SM_AC_Split_Date__c', 'SM_Requires_RC_Payment__c'};
        Set<String> fieldsBylastmodified = new Set<String>{'SM_Payment_day__c', 'SM_Frecuency__c', 'SM_Physical_address__c', 'SM_Postal_address__c', 'SM_Billing_Address__c', 'SM_Payment_Method__c', 'SM_Payment_methods__c'};

        /** Set individual fields */
        if(dependent.SM_Way_of_Contract_Payment__c == SM_ContractHelper.wayOfContract.SUSCRIPTION && master.SM_Way_of_Contract_Payment__c <> SM_ContractHelper.wayOfContract.SUSCRIPTION){
            master.SM_Way_of_Contract_Payment__c = dependent.SM_Way_of_Contract_Payment__c;
        }

        /** Validate not empty fields from dependent */
        for(String notEmptyField: checkedFieldsTovalidate){

            /** If field isn´t empty, set value in master contract */
            if(dependent.get(notEmptyField) <> null && dependent.get(notEmptyField) <> '' && dependent.get(notEmptyField) <> false){
                master.put(notEmptyField, dependent.get(notEmptyField));
            }
        }

        /** Set major values of dependet to master */
        if(master.SM_Plan_Months__c == null || master.SM_Plan_Months__c < dependent.SM_Plan_Months__c){
            master.SM_Plan_Months__c = dependent.SM_Plan_Months__c;
        }

        /** Set minor values of dependet to master */
        if(master.SM_Start_date__c == null || (master.SM_Start_date__c > dependent.SM_Start_date__c && dependent.SM_Start_date__c > System.today())){
            master.SM_Start_date__c = dependent.SM_Start_date__c;
        }

        /** Set values dependent of lastmodifieddate of dependent contracts */
        if(lastModifiedDependent == null || dependent.lastModifiedDate > lastModifiedDependent){

            lastModifiedDependent = dependent.lastModifiedDate;

            /** Iterate  fieldsBylastmodified and validate lastmodifieddate to update */
            for(String fieldName: fieldsBylastmodified){
                setValueByFieldname(master, dependent, fieldName);
            }
        }
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 21/07/2022 
    * @param master 
    * @param dependent 
    * @param fieldName 
    **/
    private static void setValueByFieldname(Contract master, Contract dependent, String fieldName){
        
        if(dependent.get(fieldName) <> null && dependent.get(fieldName) <> ''){
            master.put(fieldName, dependent.get(fieldName));
        }
    }

    /**
    * @description 
    * @author Diego Jacanamijoy -> djacanamijoy@legal-credit.com | 21/07/2022 
    * @param master 
    * @param dependentIdsByMasterId 
    **/
    private static void setSummationAssetDataToMaster(Contract master, Map<Id, Set<Id>> dependentIdsByMasterId){

        Decimal totalAc = 0;
        Decimal netMonthly = 0;

        //Check if related asset is from dependent contract, to sum data
        for(Asset asset: master.Assets1__r){

            /** Check if related contract it´s in map */
            if(dependentIdsByMasterId.get(master.Id).contains(asset.SM_Contract__c)){
                totalAc += asset.AC_Price__c;
                netMonthly += asset.Price;
            }
        }

        /** Set summarized data */
        master.SM_Total_ac__c = totalAc;
        master.SM_Monthly_offer__c = netMonthly;
    }

    public class ValidateContractsException extends Exception {}

}
