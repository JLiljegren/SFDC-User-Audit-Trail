#SFDC-User-Audit-Trail

Platform: Salesforce.com/Force.com, Apex Trigger + Custom object
Using native SFDC technology, produces an audit trail for changes to User records.

##Features
Changes to the following fields are currently tracked:
* ManagerId
* ProfileId
* UserRoleId
* FirstName
* LastName
* IsActive
* Username
* Email

##Known limitations
For known limitations, see Issues area

#Background (What are we trying to solve here?)

When changes are made to a User, it's not tracked in a way that's easy to get to. Sure, you can see who last modified a user (LastModifiedById field) but that won't tell you *what* they changed. Even worse, if you're not a super admin, the system won't even let you near the audit logs in the first place.

#Solution
##Short version
When a User record is created or modified, have an Apex trigger create an audit record with info on who made the change + before and after values.

##Long version
_Coming Soon<TM>_

