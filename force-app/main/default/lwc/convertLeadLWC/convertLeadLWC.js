/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 09/02/2021
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   01-06-2021   diego.jacanamijoy@gmail.com   Initial Version
**/
import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import executeConvertLead from '@salesforce/apex/SM_ConvertLeadLWCController.executeConvertLead';
import convertLeadToAccount from '@salesforce/apex/SM_ConvertLeadLWCController.convertLeadToAccount';
import createOpportunity from '@salesforce/apex/SM_ConvertLeadLWCController.createOpportunity';
import updateTrackingInboundRecordsAndConvertLead from '@salesforce/apex/SM_ConvertLeadLWCController.updateTrackingInboundRecordsAndConvertLead';
import updateOldAccount from '@salesforce/apex/SM_ConvertLeadLWCController.updateOldAccount';
import ALREADY_EXISTS_AN_OPP_LBL from '@salesforce/label/c.ALREADY_EXISTS_AN_OPP';
import THERE_IS_NO_ANY_ACCOUNT_LBL from '@salesforce/label/c.THERE_IS_NO_ANY_ACCOUNT';
import FOUND_ACCOUNTS_LBL from '@salesforce/label/c.FOUND_ACCOUNTS';

/* eslint-disable no-debugger, no-console */
export default class ConvertLeadLWC extends LightningElement {

    @api recordId;
    @track accounts = [];
    @track opportunity;
    @track showSpinner = false;
    @track showAccounts;
    @track showOpportunity = false;
    @track createAccount = false;
    @track accountCreated = false;
    @track isLockToContinue = true;
    alreadyExistsAnOppLbl = ALREADY_EXISTS_AN_OPP_LBL;
    thereIsNoAnyAccLbl = THERE_IS_NO_ANY_ACCOUNT_LBL;
    foundAccountsLbl = FOUND_ACCOUNTS_LBL;
    leadObj;
    selectedItem;

    connectedCallback() {
        this.showHideSpinner();
        executeConvertLead({
            leadId: this.recordId
        }).then(result => {
            this.showHideSpinner();
            this.leadObj = result.leadObj;
            if (result.isSuccess) {
                if (result.accounts.length > 0) {
                    this.accounts = result.accounts;
                    this.showAccounts = true;
                } else {
                    this.createAccount = true;
                }
            } else {
                this.showToast('error', result.errorMessage);
            }
        }).catch(error => {
            console.log('error: ', JSON.stringify(error));
            this.showToast('error', error.body.message);
        });
    }

    handleBack() {
        console.log('handleBack');
    }

    handleProcess(event) {
        this.selectedItemId = event.detail.selectedItemId;
        this.isLockToContinue = false;
    }

    handleClick() {
        this.showHideSpinner();
        this.searchOpportunity();
    }

    searchOpportunity() {
        const leadDestination = this.leadObj.SM_Destination_business_unit__c;
        const selectedAcc = this.accounts.filter(acc => acc.Id === this.selectedItemId)[0];
        let opps;
        if (selectedAcc.Opportunities) {
            opps = selectedAcc.Opportunities.filter(opp => this.validateOpportunityData(opp, leadDestination));
        }
        if (opps && opps.length > 0) {
            this.opportunity = opps[0];
            this.showOpportunityRecord();
        } else {
            this.handleCreateOpportunity();
        }
    }

    /**
    * @description This method update old data of account
    * @author diego.jacanamijoy@gmail.com | 01-06-2021 
    * @param selectedAcc
    * @param leadDestination
    **/
    updateOldAccount(selectedAcc, leadDestination, opportunityId) {
        updateOldAccount({
            leadId: this.recordId, 
            account: selectedAcc,
            companyName: leadDestination,
            opportunityId: opportunityId
        })
    }

    /**
    * @description This method validate opportunity data
    * @author diego.jacanamijoy@gmail.com | 01-06-2021 
    * @param opp
    * @param leadDestination
    * @return Boolean 
    **/
    validateOpportunityData(opp, leadDestination) {
        const statusDonTCreateOpp = ['Closed Won','Closed Lost'];
        if(opp.RecordType.Name === leadDestination){
            if(!statusDonTCreateOpp.includes(opp.StageName)){
                return true;
            }else if(opp.StageName === 'Closed Won' && opp.SM_Contract_Stage__c !== 'Cancel'){
                return true;
            }
        }
        return false;
    }

    showOpportunityRecord() {
        this.showHideSpinner();
        this.showAccounts = false;
        this.showOpportunity = true;
    }

    handleCreateOpportunity() {
        const leadDestination = this.leadObj.SM_Destination_business_unit__c;
        const selectedAcc = this.accounts.filter(acc => acc.Id === this.selectedItemId)[0];
        createOpportunity({
            leadId: this.recordId,
            accountId: this.selectedItemId,
            companySettingId: this.leadObj.SM_Company_Setting__c
        }).then(result => {
            if (result.isSuccess) {
                this.goToRecord(result.opp.Id, 'Opportunity');
                //Call method to update old account
                this.updateOldAccount(selectedAcc, leadDestination, result.opp.Id);
            } else {
                this.showToast('error', result.errorMessage);
            }
        }).catch(error => {
            console.log('createOpportunity - error: ', JSON.stringify(error));
            this.showToast('error', error.body.message);
        });
    }

    handleClickGoToOpp(event) {
        const leadDestination = this.leadObj.SM_Destination_business_unit__c;
        const selectedAcc = this.accounts.filter(acc => acc.Id === this.selectedItemId)[0];
        this.showHideSpinner();
        console.log(event.currentTarget.dataset.key);
        updateTrackingInboundRecordsAndConvertLead({
            leadId: this.recordId,
            accountId: this.selectedItemId,
            opportunityId: this.opportunity.Id
        }).then(result => {
            console.log('updateTrackingInboundRecordsAndConvertLead - result: ' + JSON.stringify(result));
            if (result.isSuccess) {
                this.goToRecord(this.opportunity.Id, 'Oppotunity');
                //Call method to update old account
                this.updateOldAccount(selectedAcc, leadDestination, this.opportunity.Id);
            } else {
                this.showToast('error', result.errorMessage);
            }
            this.showHideSpinner();
        }).catch(error => {
            this.showHideSpinner();
            this.showToast('error', error.body.message);
        });
    }

    handleClickGoToAcc(event) {
        console.log(event.currentTarget.dataset.key);
        this.goToRecord(this.newAccount.Id, 'Account');
    }

    handleClickCreateAccount() {
        this.showHideSpinner();
        convertLeadToAccount({
            leadId: this.recordId,
            companySettingId: this.leadObj.SM_Company_Setting__c
        }).then(result => {
            console.log('convertLeadToAccount - result: ' + JSON.stringify(result));
            if (result.isSuccess) {
                this.goToRecord(result.opp.Id, 'Opportunity');
            } else {
                this.showToast('error', result.errorMessage);
            }
        }).catch(error => {
            this.showHideSpinner();
            console.log('error: ', JSON.stringify(error));
            this.showToast('error', error.body.message);
        });

    }

    goToRecord(recordId, sObjectName) {
        this.template.querySelector('c-navigate-to').navigateToRecordViewPage(recordId, sObjectName, 'view');
    }

    /****************************************
     * Method to show success or error message
     *****************************************/
    showToast(variant, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error during convertion process.',
                message: message,
                variant: variant,
            }),
        );
    }

    /****************************************
     * Method to switch value of showSpinner.
     *****************************************/
    showHideSpinner() {
        this.showSpinner = !this.showSpinner;
    }
}