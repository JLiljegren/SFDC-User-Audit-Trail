/***************************************************************************
// Description    : Class for the User History Viewer page, which will
//                  display UserHistory__c records related to a specific
//                  user
//
// 2014-03-12     : JLILJEGREN - Initial version
//***************************************************************************/
@isTest (seeAllData=false)
private class UserHistoryExtension_Test {

    static User testUserRunAs;
    static User testUserToChange1;

    static testMethod void testUrlParams() {
        setupData();

        //Page reference and controller defining.
        PageReference pageRef = Page.UserHistoryViewer;
        Test.setCurrentPageReference(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(testUserToChange1);
        UserHistoryExtension ext;

        // Without any URL params
        ext = new UserHistoryExtension(stdController);
        system.assertEquals(false, ext.urlParamAllLines, 'The allLines URL param should have been false!');
        system.assertEquals(false, ext.urlParamAllUsers, 'The allUsers URL param should have been false!');

        // Setting allLines to '1'
        ext.gotoFullReport(); // Set the allLines URL param to 1
        ext = new UserHistoryExtension(stdController);
        system.assertEquals(true, ext.urlParamAllLines, 'The allLines URL param should have been true!');

        // Setting allUsers to '1'
        ApexPages.currentpage().getparameters().put('allUsers' , '1');
        ext = new UserHistoryExtension(stdController);
        system.assertEquals(true, ext.urlParamAllUsers, 'The allUsers URL param should have been true!');
    }

    static testMethod void testWithoutHistoryRecords() {
        setupData();

        //Page reference and controller defining.
        PageReference pageRef = Page.UserHistoryViewer;
        Test.setCurrentPageReference(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(testUserToChange1);
        ApexPages.currentpage().getparameters().put('Id' , testUserToChange1.Id);

        UserHistoryExtension ext;
        ext = new UserHistoryExtension(stdController);
    }

    static testMethod void testWithHistoryRecords() {
        setupData();

        System.runAs(testUserRunAs) {
            Test.startTest();

            // Create roles to use for updating
            List<UserRole> userRoles = new List<UserRole>();
            UserRole role1 = TestUtils.createUserRole('role1');
            userRoles.add(role1);
            UserRole role2 = TestUtils.createUserRole('role2');
            role2.ParentRoleId = role1.Id;
            userRoles.add(role2);
            insert userRoles;

            // Create a new user that we'll use as a new manager
            List<User> tmpMgrs = new List<User>();
            User tempMgrUser1 = TestUtils.createRandomUser();
            tmpMgrs.add(tempMgrUser1);
            User tempMgrUser2 = TestUtils.createRandomUser();
            tmpMgrs.add(tempMgrUser2);
            insert tmpMgrs;

            testUserToChange1.LastName = TestUtils.createRandomString(10);
            testUserToChange1.FirstName = TestUtils.createRandomString(10);
            testUserToChange1.Email = TestUtils.createRandomString(8) + '.' + testUserToChange1.Email;
            testUserToChange1.Username = TestUtils.createRandomString(8) + '.' + testUserToChange1.Username;
            testUserToChange1.UserRoleId = role1.Id;
            testUserToChange1.ManagerId = tempMgrUser1.Id;
            testUserToChange1.ProfileId = TestUtils.usrProfile( Constants.PROFILE_SYSADMIN ).Id;
            testUserToChange1.IsActive = !testUserToChange1.IsActive;
            testUserToChange1.Title = TestUtils.createRandomString(8);

            update testUserToChange1;

            // Update the manager and role again, because the first time it may have changed from a blank value
            testUserToChange1.ManagerId = tempMgrUser2.Id;
            testUserToChange1.UserRoleId = role2.Id;

            update testUserToChange1;

            Test.stopTest();
        }

        //Page reference and controller defining.
        PageReference pageRef = Page.UserHistoryViewer;
        Test.setCurrentPageReference(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(testUserToChange1);
        ApexPages.currentpage().getparameters().put('Id' , testUserToChange1.Id);

        UserHistoryExtension ext;
        ext = new UserHistoryExtension(stdController);

        if(TriggerState.isActive('UserHistoryTrigger')) {
            system.assert(ext.getHistoryCount() > 0, 'Unable to find any history records for updated user...');
        }
    }

    private static void setupData() {
        testUserRunAs = TestUtils.createRandomUser();
        testUserToChange1 = TestUtils.createRandomUser();

        testUserRunAs.ProfileId = TestUtils.usrProfile( Constants.PROFILE_SYSADMIN ).Id;

        List<User> userList = new List<User>();
        userList.add(testUserRunAs);
        userList.add(testUserToChange1);
        insert userList;
    }
}