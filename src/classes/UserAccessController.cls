/**
 * Custom Sharing Button per tweet: https://twitter.com/judis217/status/384040196297076736
 *
 * @author atorman@salesforce.com
 * @September 2013
 *
 * This code requires a button on each page layout that redirects user to this page and passes the record Id: 
 * for example: /apex/userAccess?Id={!Account.Id}
 * from there it's up to the admin user to find the target user in order to determine what their level of access is
 */   
   // **************** CONSTRUCTORS ****************
   public class UserAccessController{ 

   // create a getter/setter for user's name passed in when the Find User button is pressed
   public String uName 
   {
        get { return uName;}
        set { uName = value;}
    }

   // get the result from the queryUserName and present it into the page
   public List <User> getUserResults() 
   {
      return queryUser; 
   }
      
   // create an sObject to hold the queryUser results
   List <User> queryUser;  

   // query user from the User's Name input Text
   public void queryUserName() {
       
    // prevent SOQL Injection - oh no Mr. Bill!
    String queryU = '%' + uName + '%'; 
     
    // create query passing in queryLabel from input text in page
    // three where clauses allow you to query on EITHER name *or* title *or* profile
    // this can easily be changed to incorporate other search parameters 
    // only return one user - may require narrowing search results
    queryUser = [SELECT Id, Username, Name, Title, Profile.Name, UserRole.Name
                 FROM User
                 WHERE Name like :queryU
                 OR Title like :queryU
                 OR Profile.Name like :queryU 
                 ORDER by Name
                 LIMIT 1];
    
    //System.debug('queryUser = ' + queryUser);
   }

   // get the result from the user query to determine if the user has access
   
   /* We're querying the user's access rights across OWD, Sharing Rules, Manual Shares, CRUD, and User Permissions
    *  like View All Data and Transfer Records. The resulting 'MaxAccessLevel' will be across all of these different
    *  categories of access.
    *  
    *  More information about UserRecordAccess sObject can be found here: 
    *  http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_objects_userrecordaccess.htm
   */
   
   // get the result from the UserRecordAccess  query and present it into the page
   public List <UserRecordAccess> getAccessResults() 
   {
      return ura; 
   }
   
   // Create sObject ura to store the results of the UserRecordAccess query
   List <UserRecordAccess> ura;
   
   // Determine User Access based on the queryUser obtained earlier 
   // and the Id passed in through page reference in the URL using the button on the record
   public void queryAccess()
   {
       // Store queryUser results in a new object
       User u = [SELECT Id FROM User WHERE Id = :queryUser];
       
       // Extract the Id from the user results
       String uId = u.Id;     
       
       // Query the UserRecordAccess using the userId and recordId from the page
       ura = [SELECT MaxAccessLevel,RecordId
                               FROM UserRecordAccess 
                               WHERE RecordId = :ApexPages.currentPage().getParameters().get('Id') 
                                     AND UserId = :uId];
      
      // uncomment debug statement to view the results of the query
      //System.Debug('UserRecordAccess = '+ ura);
   } 
   
  }