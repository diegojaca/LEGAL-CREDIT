/**
 * @description       : 
 * @author            : diego.jacanamijoy@gmail.com
 * @group             : 
 * @last modified on  : 11-27-2020
 * @last modified by  : diego.jacanamijoy@gmail.com
 * Modifications Log 
 * Ver   Date         Author                        Modification
 * 1.0   11-27-2020   diego.jacanamijoy@gmail.com   Initial Version
**/
@IsTest
public with sharing class SM_NotificationHelperTest {
    
    @TestSetup
    static void makeData(){
        insert SM_TestSmartDataFactory.getLead();
        insert SM_TestSmartDataFactory.getCompanySetting();
    }

    @IsTest
    static void sendNotificationOk(){
        Lead lead = [SELECT Id FROM Lead LIMIT 1];
        //Create instance of Notification of SM_NotificationHelper, with init data
        SM_NotificationHelper.Notification notification = new SM_NotificationHelper.Notification(
                                                            Label.DUPLICATE_LEAD_NOTIFICATION_TITLE,
                                                            'Test Body Notification',
                                                            UserInfo.getUserId(),
                                                            Label.NOTIFICATION_TYPE_NAME,
                                                            lead.Id,
                                                            new Set<String>{UserInfo.getUserId()}
                                                        );

        //Create instance of SM_NotificationHelper
        SM_NotificationHelper notificationhelper = new SM_NotificationHelper(new List<SM_NotificationHelper.Notification>{notification});
        notificationhelper.sendNotification();                                              
    }
}