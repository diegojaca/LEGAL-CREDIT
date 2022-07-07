/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * @group             :
 * @last modified on  : 06-12-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                Modification
 * 1.0   06-12-2021   Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com   Initial Version
**/
trigger SM_ChargentTransactionTGR on ChargentOrders__Transaction__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    //Call handler class to execute
    SM_chargentOrTr_Handler tgrController = new SM_chargentOrTr_Handler('SM_ChargentTransactionTGR');
    tgrController.run();

}