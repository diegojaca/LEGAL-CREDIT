/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * @group             :
 * @last modified on  : 07-13-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                Modification
 * 1.0   07-13-2021   Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com   Initial Version
**/
({
    refreshview : function(component, event, helper) {
        console.log('Executing refresh view');
        $A.get('e.force:refreshView').fire();
    }
})