/**
 * @description       :
 * @author            : diego.jacanamijoy@gmail.com
 * @group             :
 * @last modified on  : 06-12-2021
 * @last modified by  : Jonathan S. Pachon Ariza -> jpachon.ariza@gmail.com
 * Modifications Log
 * Ver   Date         Author                        Modification
 * 1.0   01-07-2021   diego.jacanamijoy@gmail.com   Initial Version
**/
@IsTest
public with sharing class SM_AccountListItemControllerTest {

    @IsTest
    static void getFieldsToShowOk(){
        Test.startTest();
            SM_AccountListItemController.getFieldsToShow();
        Test.stopTest();
    }

}