public class UserTriggerHandler {
    //---------------------------------------------------------------------------    
    // On before insert trigger method
    //---------------------------------------------------------------------------
    public void OnBeforeInsert(List<User> newRecords) {
	} 

    //---------------------------------------------------------------------------
    // On after insert trigger method
    //---------------------------------------------------------------------------
    public void OnAfterInsert(List<User> newRecords) {
        logUserInserts(json.serialize(newRecords));
    }
    
    //---------------------------------------------------------------------------
    // On before update trigger method
    //---------------------------------------------------------------------------
    public void OnBeforeUpdate(Map<Id, User> oldMap, Map<Id, User> newMap) {
    }

    //---------------------------------------------------------------------------
    // On after update trigger method
    //---------------------------------------------------------------------------
    public void OnAfterUpdate (Map<Id, User> oldMap, Map<Id, User> newMap) {
        logUserUpdates(json.serialize(oldMap.values()));
    }

    //---------------------------------------------------------------------------
    // Inserts one User_Audit_Trail__c record for each user created
    //---------------------------------------------------------------------------
    @future
	private static void logUserInserts(String jsonStr) {
        List<User> newUsers = (List<User>)json.deserialize(jsonStr, List<User>.class);
        List<User_Audit_Trail__c> userTrails = new List<User_Audit_Trail__c>();
		for ( User newRec : newUsers ) {
        	userTrails.add( newAuditTrail(newRec.Id, 'N/A', 'Insert', 'N/A', 'N/A') );
        }
        
        if ( userTrails != null && userTrails.size() > 0 ) {
            insert userTrails;
        }
    }

    //---------------------------------------------------------------------------
    // Inserts one User_Audit_Trail__c record for each key user field
    // modified (e.g. Manager, Role, Profile)
    //
    // NOTE: Needs to be asynchronous (@future annotation) because you can't
    // modify a System object (User) and a non-system object (User_Audit_Trail__c)
    // in the same transaction. This way the non-system object insert is
    // broken up into its own context.
    // Because you can't send SObjects (User) as parameters to an asynchronous method
    // the input is a JSON serialized string
    //
    // @input: List of User records, serialized via json.serialize()
    // @output: N/A
    //---------------------------------------------------------------------------
	@future
	private static void logUserUpdates(String jsonStr) {

        List<User> oldUsers = (List<User>)json.deserialize(jsonStr, List<User>.class);
		List<User_Audit_Trail__c> userTrails = new List<User_Audit_Trail__c>();

		Map<Id, User> newUsers = new Map<Id, User>([select id,
                                                        ManagerId,
														ProfileId,
                                           		  		UserRoleId,
                                           		  		FirstName,
                                           		  		LastName,
                                           		  		Username,
                                           		  		Email,
                                                    	IsActive
                                                    from user
                                                    where id in :oldUsers]);
		for ( User oldRec : oldUsers ) {
            User newRec = newUsers.get(oldRec.Id);
            
            if ( newRec.ManagerId != oldRec.ManagerId ) {
                userTrails.add( newAuditTrail(newRec.Id, 'Manager', 'Update', oldRec.ManagerId, newRec.ManagerId) );
            }
			if ( newRec.ProfileId != oldRec.ProfileId ) {
                userTrails.add( newAuditTrail(newRec.Id, 'Profile ID', 'Update', oldRec.ProfileId, newRec.ProfileId) );
            }
            if ( newRec.UserRoleId != oldRec.UserRoleId ) {
                userTrails.add( newAuditTrail(newRec.Id, 'Role ID', 'Update', oldRec.UserRoleId, newRec.UserRoleId) );
            }
            if ( newRec.FirstName != oldRec.FirstName ) {
                userTrails.add( newAuditTrail(newRec.Id, 'First Name', 'Update', oldRec.FirstName, newRec.FirstName) );
            }
            if ( newRec.LastName != oldRec.LastName ) {
                userTrails.add( newAuditTrail(newRec.Id, 'Last Name', 'Update', oldRec.LastName, newRec.LastName) );
            }
            if ( newRec.Username != oldRec.Username ) {
                userTrails.add( newAuditTrail(newRec.Id, 'Username', 'Update', oldRec.Username, newRec.Username) );
            }
            if ( newRec.Email != oldRec.Email ) {
                userTrails.add( newAuditTrail(newRec.Id, 'Email address', 'Update', oldRec.Email, newRec.Email) );
            }
            if ( newRec.IsActive != oldRec.IsActive ) {
                userTrails.add( newAuditTrail(newRec.Id, 'Is Active', 'Update', oldRec.IsActive ? 'True' : 'False', newRec.IsActive ? 'True' : 'False') );
            }
        }
        if ( userTrails != null && userTrails.size() > 0 ) {
            insert userTrails;
        }
    }

    //---------------------------------------------------------------------------
    // Creates a new instance of User_Audit_Trail__c
    // Does NOT issue any DML
    //---------------------------------------------------------------------------
	private static User_Audit_Trail__c newAuditTrail(ID modUser,
                                                     String field,
                          					  		 String operation,
                          					  		 String oldVal,
                          					  		 String newVal) {

		User_Audit_Trail__c userTrail = new User_Audit_Trail__c();
        userTrail.Modified_User__c = modUser;
        userTrail.Modified_Field__c = field;
        userTrail.Type_Of_Operation__c = operation;
		userTrail.Old_Value__c = oldVal;
		userTrail.New_Value__c = newVal;

		return userTrail;
    }
}