@isTest
public class UserTriggerHandler_Test {
    static final Integer MAX_NBR_USERS = 50;

    static testmethod void insertUsers() {
        List<User> inUsers = new List<User>();
        
        for ( Integer i = 0; i < MAX_NBR_USERS; i++ ) {
			inUsers.add(newUser('casfqf',
                        		'v43tfe',
                         		'foobargazonk.net',
                         		'hfd'+i+'rt',
                         		'caijcuo'+i,
                         		'ciajcoi'+i,
                         		getProfile().Id));
        }
		Test.StartTest();
        insert inUsers;
        
        List<User> outUsers = new List<User>([select id from user where id in :inUsers]);

        System.assertNotEquals(null, outUsers);
        System.assertEquals(MAX_NBR_USERS, outUsers.size());

        // Get the new user's ID and make sure
        // there was an audit trail record created for each
        List<User_Audit_Trail__c> trails = new List<User_Audit_Trail__c>();
        trails = [select Id,
                  		 Modified_User__c,
                 		 Type_Of_Operation__c
                  from User_Audit_Trail__c
                  where Modified_User__c in :outUsers and
                	    Type_Of_Operation__c = 'Insert'];
        
        // There should be one and only one Audit Trail record
        System.assertEquals(MAX_NBR_USERS, trails.size());
		Test.StopTest();
    }

    static testmethod void updateLastname() {
        List<User> updUsers = new List<User>([select id, Lastname from user where Id<>:UserInfo.getUserId() limit :MAX_NBR_USERS]);

        System.assertNotEquals(null, updUsers);

        final Integer NBR_USERS = updUsers.size();
        for ( User u : updUsers ) {
			String tmp = u.Lastname;
            u.Lastname = tmp + 'x';
        }

        Test.StartTest();
        update updUsers;
        Test.StopTest();

        // Get the new user's ID and make sure
        // there was an audit trail record created for each
        checkTrails(updUsers, 'Update', 'Last Name', NBR_USERS);
    }

    static testmethod void updateFirstname() {
        List<User> updUsers = new List<User>([select id, Firstname from user where Id<>:UserInfo.getUserId() limit :MAX_NBR_USERS]);

        System.assertNotEquals(null, updUsers);

        final Integer NBR_USERS = updUsers.size();
        for ( User u : updUsers ) {
			String tmp = u.Firstname;
            u.Firstname = tmp + 'x';
        }

        Test.StartTest();
        update updUsers;
        Test.StopTest();

        // Get the new user's ID and make sure
        // there was an audit trail record created for each
        checkTrails(updUsers, 'Update', 'First Name', NBR_USERS);
    }

    static testmethod void updateUsername() {
        List<User> updUsers = new List<User>([select id, Username from user where Id<>:UserInfo.getUserId() limit :MAX_NBR_USERS]);

        System.assertNotEquals(null, updUsers);

        final Integer NBR_USERS = updUsers.size();

        // Change each user's Username by adding an 'x'
        for ( User u : updUsers ) {
			String tmp = u.Username;
            u.Username = tmp + 'x';
        }

        // We need to run the DML operation as another user
        // Otherwise, we're going to hit a MIXED_DML_OPERATION exception
        User runningUser = [select id from user where Id<>:UserInfo.getUserId() and IsActive=true limit 1];
        
        system.runas(runninguser) {
        Test.StartTest();
        update updUsers;
        Test.StopTest();
        }		

        // Get the new user's ID and make sure
        // there was an audit trail record created for each
        checkTrails(updUsers, 'Update', 'Username', NBR_USERS);
    }

    public Static void checkTrails(List<User> users,
                                      String op,
                                      String field,
                                      Integer nbrRecsExpected) {
        List<User_Audit_Trail__c> trails = new List<User_Audit_Trail__c>();
        trails = [select Id,
                  		 Modified_User__c,
                 		 Type_Of_Operation__c,
                  		 Modified_Field__c
                  from User_Audit_Trail__c
                  where Modified_User__c in :users and
                	    Type_Of_Operation__c = :op and
                 		Modified_Field__c = :field];

        // There should be one Audit Trail record per user
        System.assertEquals(nbrRecsExpected, trails.size());
    }

	//==========================================================//
  	//Create a new User (It will not make any DML operation)
  	//==========================================================//  
  	public static User newUser (String firstName,
                                String lastName,
                                String domain,
                                String seed,
								String alias,
                                String nickName,
                                Id profileId) {

		String email = firstName + lastName + seed + '@' + domain + '.' + seed;

		User pUsr = new User(FirstName = firstName,
                             LastName = lastName,
                             Email = email,
							 UserName = email,
                             Alias = alias.left(8),
							 CommunityNickName = nickName,
                             ProfileId = profileId,
                             TimeZoneSidKey = 'America/New_York',
                             LocaleSidKey = 'en_US',
                             EmailEncodingKey = 'UTF-8',
                             LanguageLocaleKey = 'en_US');

     	return pUsr;
  	}

  	public static Profile getProfile() { return UserTriggerHandler_Test.getProfile('System Administrator'); }
  	public static Profile getProfile(String profileName) { return [SELECT Id, Name FROM Profile WHERE Name =: profileName LIMIT 1]; }

}