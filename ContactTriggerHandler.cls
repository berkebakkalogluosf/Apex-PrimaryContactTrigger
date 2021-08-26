public with sharing class ContactTriggerHandler {
    static final String PRIMARY_EXISTS_ERROR = 'There already exists a primary contact for this account';
    static final String MULTIPLE_PRIMARY_ERROR = 'Cannot insert / update more than one Primary Contact per Account';
    
    public static void handleBefore(List<Contact> newRecords, Map<Id, Contact> oldRecords) {
        List<AggregateResult> primaryContactPerAccount = new List<AggregateResult>();
        
        try {
            primaryContactPerAccount = [SELECT AccountId From Contact WHERE Is_Primary_Contact__c = TRUE GROUP BY AccountId];
        } catch (QueryException e) {
            System.debug(e);
        }
        
        Set<Id> accountsWithPrimaryContacts = new Set<Id>();
        Map<Id, String> accountsPrimaryPhone = new Map<Id, String>();
        
        for(AggregateResult accountWithPrimaryContact : primaryContactPerAccount) {
            accountsWithPrimaryContacts.add((Id) accountWithPrimaryContact.get('AccountId'));
        }
        
        for(Contact newRecord : newRecords) {
            if(oldRecords == NULL) {
                if(newRecord.Is_Primary_Contact__c && newRecord.AccountId != NULL) {
                    // Check if Account already has a Primary Contact
                    if(accountsWithPrimaryContacts.contains(newRecord.AccountId)) {
                        newRecord.Is_Primary_Contact__c.addError(PRIMARY_EXISTS_ERROR);
                    } else {
                        multiplePrimaryPerAccountCheck(accountsPrimaryPhone, newRecord);
                    }
                }
            } else {
                Contact oldRecord = oldRecords.get(newRecord.Id);
                Boolean isPrimaryContactChanged = (newRecord.Is_Primary_Contact__c != oldRecord.Is_Primary_Contact__c);
                Boolean phoneChanged = (newRecord.Phone != oldRecord.Phone);
                Boolean accountIdChanged = (newRecord.AccountId != oldRecord.AccountId);
                
                if(newRecord.Is_Primary_Contact__c) {
                    if(isPrimaryContactChanged || phoneChanged || accountIdChanged) {
                        if(accountsWithPrimaryContacts.contains(newRecord.AccountId)) {
                            updatedExistingPrimaryCheck(accountsPrimaryPhone, newRecord);
                        }
                    } else {
                        multiplePrimaryPerAccountCheck(accountsPrimaryPhone, newRecord);
                    }
                }
            }
        }
    }
    
    public static void handleAfterInsert(List<Contact> newRecords) {
        Map<Id, String> accountPrimaryPhoneMap = new Map<Id, String>();
        
        for (Contact newRecord : newRecords) {
            changePrimaryPhones(newRecord, accountPrimaryPhoneMap);
        }
    }
    
    public static void handleAfterUpdate(List<Contact> newRecords, Map<Id, Contact> oldRecords) {
        Map<Id, String> accountPrimaryPhoneMap = new Map<Id, String>();
        
        for (Contact newRecord : newRecords) {
            Contact oldRecord = oldRecords.get(newRecord.Id);
            Boolean primaryPhoneChanged = (newRecord.Primary_Contact_Phone__c != oldRecord.Primary_Contact_Phone__c);
            
            if (!primaryPhoneChanged && newRecord.Phone != NULL) {
                changePrimaryPhones(newRecord, accountPrimaryPhoneMap);
            }
        }
    }
    
    private static void multiplePrimaryPerAccountCheck(Map<Id, String> accountsPrimaryPhone, Contact newRecord) {
        if(accountsPrimaryPhone.containsKey(newRecord.AccountId)) {
            newRecord.Is_Primary_Contact__c.addError(MULTIPLE_PRIMARY_ERROR);
        } else {
            accountsPrimaryPhone.put(newRecord.AccountId, newRecord.Phone);
        }
    }
    
    private static void updatedExistingPrimaryCheck(Map<Id, String> accountsPrimaryPhone, Contact newRecord) {
        Contact existingPrimaryContact = new Contact();
        try {
            existingPrimaryContact = [SELECT Id FROM Contact WHERE AccountId = :newRecord.AccountId AND Is_Primary_Contact__c = TRUE];
        } catch (QueryException e) {
            System.debug(e);
        }
        
        if(existingPrimaryContact.Id == newRecord.Id) {
            multiplePrimaryPerAccountCheck(accountsPrimaryPhone, newRecord);
        } else {
            newRecord.Is_Primary_Contact__c.addError(PRIMARY_EXISTS_ERROR);
        }
    }
    
    private static void changePrimaryPhones(Contact newRecord, Map<Id, String> accountPrimaryPhoneMap) {
        if (newRecord.Is_Primary_Contact__c) {
            accountPrimaryPhoneMap.put(newRecord.AccountId, newRecord.Phone);
        }
        
        if (accountPrimaryPhoneMap.size() > 0) {
            AsyncUpdate.setPrimaryPhone(accountPrimaryPhoneMap);
        }
    }
}