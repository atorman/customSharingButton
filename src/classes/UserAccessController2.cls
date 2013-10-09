/**
 * Custom Sharing Button per tweet: https://twitter.com/judis217/status/384040196297076736
 *
 * @authors: @atorman, @capeterson, @_johnbrock
 * @September 2013
 *
 * This code requires a button on each page layout that redirects user to this page and passes the record Id: 
 * for example: /apex/userAccess2?Id={!Account.Id}
 * from there it's up to the admin user to find the target user in order to determine their level of access.
 * 
 * This is an update with some optimizations for unit testing and simplification
 */   
public class UserAccessController2 { 

   	public String queryString { get; set; }
    public List<UserRow> userResults {get; private set;} 
   	
    public UserAccessController2(ApexPages.StandardController controller) {
    	userResults = new List<UserRow>();
    }
    
    // query user from the User's Name input Text
   	public void queryUsersAndRecordAccess() {   
    	// prevent SOQL Injection - oh no Mr. Bill!
    	String safeQuery = '%' + queryString + '%'; 
		List<User> returnedUsers = queryForUsers(safeQuery);
                
        // create list of UserRows
        userResults = new List<UserRow>();
        for (User user : returnedUsers) {
            // set isSelected==true -- selection not implemented at this point
        	userResults.add(new UserRow(user, true));
        }
        
        // query and fill UserRecordAccess
        userResults = fillUserResultsRecordAccess(userResults, getEntityIdParam());
    }

   /** 
	*  Determine User Access based on the queryUser obtained earlier with the Id from PageReference
	*
	*  We're querying the user's access rights across OWD, Sharing Rules, Manual Shares, CRUD, and User Permissions
    *  like View All Data and Transfer Records. The resulting 'MaxAccessLevel' will be across all of these different
    *  categories of access.
    *  
    *  More information about UserRecordAccess sObject can be found here: 
    *  http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_objects_userrecordaccess.htm
   	*/
   	public List<UserRow> fillUserResultsRecordAccess(List<UserRow> userResults, String recordId) {        
        if (!userResults.isEmpty()) {
        	// Query the UserRecordAccess using the userId and recordId from the page
            for (UserRow row : userResults) {
                if (row.isSelected) {
            		List<UserRecordAccessWrapper> recordAccess = queryRecordAccess(recordId, String.valueOf(row.user.Id)); 
                    if (!recordAccess.isEmpty()) {
                    	row.recordAccess = recordAccess[0];
                    } else {
                    	row.recordAccess = new UserRecordAccessWrapper();
                    }
                }
            }
        }
        return userResults;
   	}
    
    // get parameter of entity from URL, or return fake Id if doing test
    private String getEntityIdParam() {
        if(Test.isRunningTest()) {
        	return 'FAKE_ENTITY_ID';
        } else {
        	return ApexPages.currentPage().getParameters().get('Id');
        }
    }
    
    // query for users based on input query text, or return test users if running test
    public List<User> queryForUsers(String query) {
        if(Test.isRunningTest()) {
        	List<User> users = new List<User>();
            users.add(createUser('test1@test.com', 'test1', '005i0000000ZZzy'));
            users.add(createUser('test2@test.com', 'test2', '005i0000000ZZzz'));
            return users;      
        } else {
            // Query on EITHER name *or* title *or* profile -- can include more params if needed
            return [SELECT Id, Username, Name, Title, Profile.Name, UserRole.Name
                         FROM User
                         WHERE Name 		like :query
                         OR Title 			like :query
                         OR Profile.Name 	like :query 
                         ORDER by Name
                         LIMIT 100];    
        }
    }
    
    // query to get real UserRecordAccess then put in wrapper class, or return mocked results if test
    private List<UserRecordAccessWrapper> queryRecordAccess(String recordId, String userId) {
		List<UserRecordAccessWrapper> results = new List<UserRecordAccessWrapper>();        
        
        if(Test.isRunningTest()) {
            UserRecordAccessWrapper ura = new UserRecordAccessWrapper(recordId, userId, 'Full');
        	results.add(ura);
        } else {
            List<UserRecordAccess> uraList = [SELECT MaxAccessLevel, RecordId 
                								FROM UserRecordAccess 
                								WHERE RecordId = :recordId
                									AND UserId = :userId ];
            for (UserRecordAccess ura : uraList) {
            	results.add(new UserRecordAccessWrapper(recordId, userId, ura.MaxAccessLevel));
            }
        }
        return results;
    }
    
    // inner class since cannot mock nor create a new UserRecordAccess sObject
    public class UserRecordAccessWrapper {
        public String RecordId{get;set;}
        public String UserId{get;set;}
        public String MaxAccessLevel{get;set;}
        
        public UserRecordAccessWrapper() {}
        
        public UserRecordAccessWrapper(String recordId, String userId, String MaxAccessLevel) {
        	this.RecordId = recordId;
            this.UserId = userId;
            this.MaxAccessLevel = maxAccessLevel;
        }
    }
    
    // inner-class used as a wrapper to hold selected state and User sObject
    public class UserRow {
        public User user{get; private set;}        
        public boolean isSelected{get;set;}
        public UserRecordAccessWrapper recordAccess{get;set;}
        
        public UserRow(User user, boolean isSelected) {
        	this(user, isSelected, new UserRecordAccessWrapper());
        }
        
        public UserRow(User user, boolean isSelected, UserRecordAccessWrapper recordAccess) {
        	this.user = user;
            this.isSelected = isSelected;
            this.recordAccess = recordAccess;
        }
    }
    
    // create simple test user -- doesn't insert
    static public User createUser(String username, String alias, String userId) {
        Profile profile = [SELECT Id from Profile Where Name='Standard User'];
        User user = new User(Alias = alias, Email='test@test.com', 
      		EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
      		LocaleSidKey='en_US', ProfileId = profile.Id, 
      		TimeZoneSidKey='America/Los_Angeles', UserName = username, Id = userId);
        return user;
    }
}