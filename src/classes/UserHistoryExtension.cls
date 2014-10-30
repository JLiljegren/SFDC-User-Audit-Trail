/***************************************************************************
// Description    : Class for the User History Viewer page, which will
//                  display UserHistory__c records related to a specific
//                  user
//
// 2014-03-12     : JLILJEGREN - Initial version
//***************************************************************************/
public with sharing class UserHistoryExtension {
    public final User usr { get; set; }
    public final User usrFullInfo { get; set; }
    public List<UserHistory__c> userHistoryRecords { get; set; }
    private Integer historyCount;
    public Boolean urlParamAllLines { get; set; }
    public Boolean urlParamAllUsers { get; set; }
    public List<UserHistoryLineWrapper> historyWrapperList { get; set; }

    private Set<Id> userIdsInvolvedSet = new Set<Id>();
    private Set<Id> profileIdsInvolvedSet = new Set<Id>();
    private Set<Id> roleIdsInvolvedSet = new Set<Id>();

    private Map<Id, User> usersInvolvedMap = new Map<Id, User>();
    private Map<Id, Profile> profilesInvolvedMap = new Map<Id, Profile>();
    private Map<Id, UserRole> rolesInvolvedMap = new Map<Id, UserRole>();

    public UserHistoryExtension (ApexPages.StandardController controller) {
        usr = (User)controller.getRecord();

        List<User> tmpUserList = [SELECT Id, Name
                                  FROM User
                                  WHERE Id = :usr.Id];

        system.assertNotEquals(null, tmpUserList, 'Error - Unable to populate userlist from Id ' + usr.Id);
        system.assertNotEquals(0, tmpUserList.size(), 'Error - Userlist contains no records with Id ' + usr.Id);

        usrFullInfo = tmpUserList[0];

        historyWrapperList = new List<UserHistoryLineWrapper>();

        if ( ApexPages.currentPage().getParameters().get('AllLines') == '1') {
            urlParamAllLines = true;
        } else {
            urlParamAllLines = false;
        }

        if ( ApexPages.currentPage().getParameters().get('AllUsers') == '1') {
            urlParamAllUsers = true;
        } else {
            urlParamAllUsers = false;
        }

        String usrQuery = 'SELECT Id, ' +
                                 ' Name,' +
                                 ' CreatedDate,' +
                                 ' CreatedById,' +
                                 ' CreatedBy.Name,' +
                                 ' Modified_Field__c,' +
                                 ' Modified_User__c,' +
                                 ' Modified_User__r.Name,' +
                                 ' Modified_User__r.CreatedDate,' +
                                 ' Modified_User__r.CreatedById,' +
                                 ' Modified_User__r.CreatedBy.Name,' +
                                 ' New_Value__c,' +
                                 ' Old_Value__c,' +
                                 ' Type_Of_Operation__c' +
                          ' FROM UserHistory__c';
        if(!urlParamAllUsers) {
            usrQuery += ' WHERE Modified_User__c = \'' + usr.Id + '\'';
        }

        usrQuery += ' ORDER BY CreatedDate DESC';

        userHistoryRecords = Database.query(usrQuery);

        if (userHistoryRecords != null && userHistoryRecords.size() > 0) {
            userIdsInvolvedSet.add(usr.Id);

            // Get all the users, profiles, roles involved
            for (UserHistory__c rec : userHistoryRecords) {
                String newVal = rec.New_Value__c;
                String oldVal = rec.Old_Value__c;

                userIdsInvolvedSet.add(rec.CreatedById);
                userIdsInvolvedSet.add(rec.Modified_User__r.CreatedById);
                userIdsInvolvedSet.add(rec.Modified_User__c);

                if ( rec.Modified_Field__c == 'ManagerId') {
                    if (newVal != null && newVal.startsWith('005') && newVal.length() == 18) {
                        userIdsInvolvedSet.add(newVal);
                    }
                    if (oldVal != null && oldVal.startsWith('005') && oldVal.length() == 18) {
                        userIdsInvolvedSet.add(oldVal);
                    }
                }

                if ( rec.Modified_Field__c == 'ProfileId') {
                    if (newVal != null && newVal.startsWith('00e') && newVal.length() == 18) {
                        profileIdsInvolvedSet.add(newVal);
                    }
                    if (oldVal != null && oldVal.startsWith('00e') && oldVal.length() == 18) {
                        profileIdsInvolvedSet.add(oldVal);
                    }
                }

                if ( rec.Modified_Field__c == 'UserRoleId') {
                    if (newVal != null && newVal.startsWith('00E') && newVal.length() == 18) {
                        roleIdsInvolvedSet.add(newVal);
                    }
                    if (oldVal != null && oldVal.startsWith('00E') && oldVal.length() == 18) {
                        roleIdsInvolvedSet.add(oldVal);
                    }
                }
            }

            // Query for all the users involved
            if (userIdsInvolvedSet != null && userIdsInvolvedSet.size() > 0) {
                usersInvolvedMap = new Map<Id, User>([SELECT Id,
                                                             Name,
                                                             CreatedDate,
                                                             CreatedById
                                                      FROM User
                                                      WHERE Id in :userIdsInvolvedSet]);
            }

            // Query for all the profiles involved
            if (profileIdsInvolvedSet != null && profileIdsInvolvedSet.size() > 0) {
                profilesInvolvedMap = new Map<Id, Profile>([SELECT Id,
                                                                   Name
                                                            FROM Profile
                                                            WHERE Id in :profileIdsInvolvedSet]);
            }

            // Query for all the roles involved
            if (roleIdsInvolvedSet != null && roleIdsInvolvedSet.size() > 0) {
                rolesInvolvedMap = new Map<Id, UserRole>([SELECT Id,
                                                                 Name
                                                          FROM UserRole
                                                          WHERE Id in :roleIdsInvolvedSet]);
            }

            for (UserHistory__c rec : userHistoryRecords) {
                historyWrapperList.add(new UserHistoryLineWrapper(rec,
                                                                  usersInvolvedMap,
                                                                  profilesInvolvedMap,
                                                                  rolesInvolvedMap));
            }

            // Add the line where the User was created
            historyWrapperList.add(new UserHistoryLineWrapper(usersInvolvedMap.get(usr.Id).CreatedDate,
                                                              usersInvolvedMap.get(usr.Id).CreatedById,
                                                              usr.Id,
                                                              usersInvolvedMap));
        }
    }

    public Integer getHistoryCount() {
        if(userHistoryRecords != null) {
            historyCount = userHistoryRecords.size();
        }
        else {
            historyCount = 0;
        }

        return historyCount;
    }

    public PageReference gotoFullReport() {
        System.Pagereference p = ApexPages.currentPage();
        p.getParameters().put('allLines', '1');
        p.setRedirect(true);
        return p;
    }

    public class UserHistoryLineWrapper {
        public String timeStamp {get; set;}
        public DateTime timeStampFull {get; set;}
        private User runningUser {get; set;}
        public String runningUserFancy {get; set;}
        private User modifiedUser {get; set;}
        public String modifiedUserFancy {get; set;}
        public String fieldChanged {get; set;}
        public String fieldOldValue {get; set;}
        public String fieldNewValue {get; set;}


        // Default constructor
        // Input: rec - one single UserHistory__c record
        //        usrMap - map of users and their IDs
        //        profileMap - map of profiles and their IDs
        //        roleMap - map of roles and their IDs
        public UserHistoryLineWrapper (UserHistory__c rec, Map<Id, User> usrMap, Map<Id, Profile> profileMap, Map<Id, UserRole> roleMap) {
            fieldOldValue = '<i>Blank value</i>';
            fieldNewValue = '<i>Blank value</i>';

            timeStampFull = rec.CreatedDate;
            timeStamp = rec.CreatedDate.format();
            runningUser = usrMap.get(rec.CreatedById);

            runningUserFancy = '<a href="/' + runningUser.Id + '?noredirect=1">' + runningUser.Name + '</a>';
            modifiedUser = usrMap.get(rec.Modified_User__c);
            modifiedUserFancy = '<a href="/' + modifiedUser.Id + '?noredirect=1">' + modifiedUser.Name + '</a>';

            if (rec.Modified_Field__c == 'ProfileId') {
                fieldChanged = 'Profile';
                if(profileMap.get(rec.Old_Value__c) != null) {
                    fieldOldValue = '<a href="/' + rec.Old_Value__c + '">' + profileMap.get(rec.Old_Value__c).Name + '</a>';
                }
                if(profileMap.get(rec.New_Value__c) != null) {
                    fieldNewValue = '<a href="/' + rec.New_Value__c + '">' + profileMap.get(rec.New_Value__c).Name + '</a>';
                }
            }
            else if (rec.Modified_Field__c == 'UserRoleId') {
                fieldChanged = 'Role';
                if(roleMap.get(rec.Old_Value__c) != null) {
                    fieldOldValue = '<a href="/' + rec.Old_Value__c + '">' + roleMap.get(rec.Old_Value__c).Name + '</a>';
                }
                if(roleMap.get(rec.New_Value__c) != null) {
                    fieldNewValue = '<a href="/' + rec.New_Value__c + '">' + roleMap.get(rec.New_Value__c).Name + '</a>';
                }
            }
            else if (rec.Modified_Field__c == 'ManagerId') {
                fieldChanged = 'Manager';
                if(usrMap.get(rec.Old_Value__c) != null) {
                    fieldOldValue = '<a href="/' + rec.Old_Value__c + '?noredirect=1">' + usrMap.get(rec.Old_Value__c).Name + '</a>';
                }
                if(usrMap.get(rec.New_Value__c) != null) {
                    fieldNewValue = '<a href="/' + rec.New_Value__c + '?noredirect=1">' + usrMap.get(rec.New_Value__c).Name + '</a>';
                }
            }
            else if (rec.Modified_Field__c == 'IsActive') {
                fieldChanged = '<i>';
                if(rec.New_Value__c == 'True') {
                    fieldChanged += 'User activated';
                } else {
                    fieldChanged += 'User deactivated';
                }
                fieldChanged += '</i>';
            }
            else {
                fieldChanged = rec.Modified_Field__c;
                fieldOldValue = rec.Old_Value__c;
                fieldNewValue = rec.New_Value__c;
            }
        }

        // Constructor for the Create action
        // Input: createDate - the date this user was created
        //        createUser - the user that created this user
        //        modUser - the user in context, ie the user being created/modified
        public UserHistoryLineWrapper (Datetime createDate, ID createUser, ID modUser, Map<Id, User> usrMap) {
            timeStamp = createDate.format();
            timeStampFull = createDate;
            runningUser = usrMap.get(createUser);
            runningUserFancy = '<a href="/' + runningUser.Id + '?noredirect=1">' + runningUser.Name + '</a>';
            modifiedUser = usrMap.get(modUser);
            modifiedUserFancy = '<a href="/' + modifiedUser.Id + '?noredirect=1">' + modifiedUser.Name + '</a>';
            fieldChanged = '<i>User created.</i>';
        }
    }
}