/**
 * @description       :
 * @author            : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * @group             :
 * @last modified on  : 07-09-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                                                Modification
 * 1.0   07-09-2021   Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com   Initial Version
**/
global without sharing class SM_SendPaymentNotificationSchedule implements Schedulable {

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new SM_SendPaymentNotificationBatch('sendEmail', null), 10);
    }
}