public with sharing class SharingUtilities {
    public static final String EDIT_LEVEL = 'Edit';
    
    public static void insertSharingRecords(List<SObject> l_records) {
        List<Database.saveresult> l_srt = Database.insert(l_records, false);
        for (Database.SaveResult sr : l_srt) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully created sharing. Sharing ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Sharing that affected this error: ' + err.getFields());
                }
            }
        }
    }

    public static void deleteSharingRecords(List<SObject> l_records){
        Database.DeleteResult[] l_srt = Database.delete(l_records, false);
        for(Database.DeleteResult dr : l_srt) {
            if (dr.isSuccess() == false ) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully deleted sharing with ID: ' + dr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : dr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Delete Sharing Failed: ' + err.getFields());
                }
            }
        }
    }

    public static Map<Id, litify_pm__Matter__c> getMatters(Set<Id> s_ids) {
        return new Map<Id, litify_pm__Matter__c>([SELECT ID, OwnerId, Private__c, 
                                                                            (SELECT ID ,
                                                                            litify_pm__Role__r.Name,
                                                                            litify_pm__User__c,
                                                                            litify_pm__User__r.isActive,
                                                                            litify_pm__User__r.Name
                                                                            FROM litify_pm__Matter_Teams__r) FROM litify_pm__Matter__c WHERE Id IN: s_ids]);
    }

    public static SObject fillSharingRecords(Schema.SObjectType objectType, Id parentId, Id userId, String accessLevel) {
        SObject newSharing = objectType.newSObject();
        newSharing.put('ParentId',parentId);
        newSharing.put('UserOrGroupId', userId);
        newSharing.put('AccessLevel', accessLevel);
        newSharing.put('RowCause', 'Manual');
        return newSharing;
    }
}