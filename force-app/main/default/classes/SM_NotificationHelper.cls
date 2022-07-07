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
public with sharing class SM_NotificationHelper {
    
    private Notification[] customNotifications;

    public SM_NotificationHelper(Notification[] customNotifications){
        this.customNotifications = customNotifications;
    }

    public void sendNotification(){
        Map<String, CustomNotificationType> notificationsTypes = new Map<String, CustomNotificationType>();
        Set<String> notificationTypeNames = new Set<String>();
        try {
            //Iterate by buils set of notificationTypeNames
            for(Notification notification: this.customNotifications){
                notificationTypeNames.add(notification.notificationTypeName);
            }
            //create map notificationsTypes
            for(CustomNotificationType customNotificationType: [SELECT DeveloperName FROM CustomNotificationType WHERE DeveloperName IN: notificationTypeNames]){
                notificationsTypes.put(customNotificationType.DeveloperName, customNotificationType);
            }
            //Iterate by create and send notifications
            for(Notification customNotification: this.customNotifications){
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setBody(customNotification.body);
                notification.setTitle(customNotification.title);
                notification.setSenderId(customNotification.senderId);
                notification.setNotificationTypeId(notificationsTypes.get(customNotification.notificationTypeName).Id);
                notification.setTargetId(customNotification.targetId);
                notification.send(customNotification.sendIds);
            }   
        } catch (Exception e) {
            throw new NotificationException('An error occurred sending notification '+ e.getTypeName() + ' ' + e.getMessage() + ' ' +e.getStackTraceString());
        }
    }
    
    /** Inner class, to manage custom notifications **/
    public class Notification{
        //Params
        public String title;
        public String body;
        public String senderId;
        public String notificationTypeName;
        public String targetId;
        public Set<String> sendIds;
        //Constructor
        public Notification(String title, String body, String senderId, String notificationTypeName, String targetId, Set<String> sendIds){
            this.title = title;
            this.body = body;
            this.senderId = senderId;
            this.notificationTypeName = notificationTypeName;
            this.targetId = targetId;
            this.sendIds = sendIds;
        }
    }

    //Inner class, to manage custom exceptions
    public class NotificationException extends Exception {}
}