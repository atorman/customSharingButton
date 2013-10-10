/**
 * Test Class for UserAccessController2
 */
@isTest
private class UserAccessController2Test {
    
    static testMethod void testFillUserResultsRecordAccess() {
        TestDataSetup testSetup = new TestDataSetup(false);

        // create instance of controller and call method with UserRows and Entity Id (testAccount)
        UserAccessController2 controller = new UserAccessController2();
        List<UserAccessController2.UserRow> returnedUserRows = controller.fillUserResultsRecordAccess(testSetup.userRows, testSetup.accountId);
        
        // compare expected access with returned access
        checkUserRows(testSetup.expectedRowsWithAccess, returnedUserRows);
    }
    
    static testMethod void testGetUserAccess() {
        // create instance of controller and call getUserAccess
        UserAccessController2 controller = new UserAccessController2();
        controller.getUserAccess();
        
        // compare expected access with returned access
        TestDataSetup testSetup = new TestDataSetup(true);
        checkUserRows(testSetup.expectedRowsWithAccess, controller.userResults);
    }
    
    /**
     * Compare the size of the result sets, and then compare the attributes (UserId, RecordId, MaxAccessLevel)
     */
    static private void checkUserRows(Map<Id, UserAccessController2.UserRow> expectedRows, List<UserAccessController2.UserRow> actualRows) {
        System.assertEquals(expectedRows.keySet().size(), actualRows.size(), 'List sizes did not match');
        for (UserAccessController2.UserRow row : actualRows) {
            Id userId = row.user.Id;
            System.assert(expectedRows.containsKey(userId), 'Expected rows did not contain one of returned keys.');
            
            UserAccessController2.UserRow expectedRow = expectedRows.get(userId);
            System.assertEquals(expectedRow.user.Id, row.user.Id, 'UserIds did not match.');
            System.assertEquals(expectedRow.recordAccess.RecordId, row.recordAccess.RecordId, 'RecordIds did not match.');
            System.assertEquals(expectedRow.recordAccess.MaxAccessLevel, row.recordAccess.MaxAccessLevel, 'MaxAccessLevel did not match.');
        }
    }
    
    // inner-class to initialize and hold common/shared test data
    private class TestDataSetup {
        Map<Id, UserAccessController2.UserRow> expectedRowsWithAccess{get;set;}
        List<UserAccessController2.UserRow> userRows{get;set;}
        String accountId{get;set;}
    
        public TestDataSetup(boolean shouldUseFakeEntityId) {
            expectedRowsWithAccess = new Map<Id, UserAccessController2.UserRow>();
            userRows = new List<UserAccessController2.UserRow>();          
            
            // create test users and add newly created UserRows to list that will be used to get UserRecordAccess
            User testUser1 = UserAccessController2.createUser('test1@test.com', 'alias1', '005i0000000ZZzy');
            User testUser2 = UserAccessController2.createUser('test2@test.com', 'alias2', '005i0000000ZZzz');
            userRows.add(new UserAccessController2.UserRow(testUser1, true));
            userRows.add(new UserAccessController2.UserRow(testUser2, true));
    
            // create test account and expected UserRecordAccessWrapper objects for each user
            Account testAccount = createAccount('TEST');
            accountId = shouldUseFakeEntityId ? 'FAKE_ENTITY_ID' : testAccount.Id;
            UserAccessController2.UserRecordAccessWrapper testAccess1 = new UserAccessController2.UserRecordAccessWrapper(accountId, testUser1.Id, 'Full');
            UserAccessController2.UserRecordAccessWrapper testAccess2 = new UserAccessController2.UserRecordAccessWrapper(accountId, testUser2.Id, 'Full');
               
            // create UserRows that will represent the expected access and add to ExpectedRows list
            expectedRowsWithAccess.put(testUser1.Id, new UserAccessController2.UserRow(testUser1, true, testAccess1));
            expectedRowsWithAccess.put(testUser2.Id, new UserAccessController2.UserRow(testUser2, true, testAccess2));             
        }      
    }

    // create simple test account
    static private Account createAccount(String name) {
        Account testAccount = new Account();
        testAccount.Name = name;
        insert(testAccount);
        
        return testAccount;
    }
}
