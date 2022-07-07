/**
 * @File Name          : navigateTo.js
 * @Description        :
 * @Author             : jpachon@legal-credit.com
 * @Group              :
 * @Last Modified By   : jpachon@legal-credit.com
 * @Last Modified On   : 12-04-2020
 * @Modification Log   :
 * Ver       Date            Author      		    Modification
 * 1.0    12-04-2020   jpachon@legal-credit.com     Initial Version
**/
import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

const NAVIGATE_STANDARD_RECORD_PAGE = 'standard__recordPage';

/* eslint-disable no-console */
export default class NavigateTo extends NavigationMixin(LightningElement) {

    @api objName;
    @api filterName;
    @api actionName;
    @api recordId;
    @api relationName;
    @api tabApiName;
    @api url;
    @api pageName;

    @api navigateToRecordViewPage(recordId, objName, actionName) {
        // View a custom object record.
        this[NavigationMixin.Navigate]({
            type: NAVIGATE_STANDARD_RECORD_PAGE,
            attributes: {
                recordId: recordId,
                objectApiName: objName, // objectApiName is optional
                actionName: actionName
            }
        });
    }
}