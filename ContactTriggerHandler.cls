public with sharing class ContactTriggerHandler {
    public static void handleBefore(List<Contact> newRecords, Map<Id, Contact> oldRecords) {
        
        List<AggregateResult> primaryContactPerAccount = [SELECT AccountId From Contact WHERE Is_Primary_Contact__c = TRUE GROUP BY AccountId];
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
                        newRecord.Is_Primary_Contact__c.addError('There already exists a primary contact for this account');
                    } else {
                        multipleAccountPrimaryCheck(accountsPrimaryPhone, newRecord);
                    }
                }
            } else {
                Contact oldRecord = oldRecords.get(newRecord.Id);
                Boolean isPrimaryContactChanged = (newRecord.Is_Primary_Contact__c != oldRecord.Is_Primary_Contact__c);
                Boolean phoneChanged = (newRecord.Phone != oldRecord.Phone);
                Boolean accountIdChanged = (newRecord.AccountId != oldRecord.AccountId);
                
                if(newRecord.Is_Primary_Contact__c) {
                    if(isPrimaryContactChanged || phoneChanged || accountIdChanged) {
                        // Check if the Account already has a Primary Contact
                        if(accountsWithPrimaryContacts.contains(newRecord.AccountId)) {
                            Contact existingPrimaryContact = [SELECT Id FROM Contact WHERE AccountId = :newRecord.AccountId AND Is_Primary_Contact__c = TRUE];
                            System.debug('existingPrimaryContact.Id' + existingPrimaryContact.Id);
                            // Check if the updated Contact is the existing Primary Contact
                            if(existingPrimaryContact.Id != newRecord.Id) {
                                newRecord.Is_Primary_Contact__c.addError('There already exists a primary contact for this account');
                            } else {
                                multipleAccountPrimaryCheck(accountsPrimaryPhone, newRecord);
                            }
                        } else {
                            multipleAccountPrimaryCheck(accountsPrimaryPhone, newRecord);
                        }
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
            Boolean primaryPhoneNotChanged = (newRecord.Primary_Contact_Phone__c == oldRecord.Primary_Contact_Phone__c);
            
            if (primaryPhoneNotChanged) {
                changePrimaryPhones(newRecord, accountPrimaryPhoneMap);
            }
        }
    }
    
    public static void multipleAccountPrimaryCheck(Map<Id, String> accountsPrimaryPhone, Contact newRecord) {
        if(accountsPrimaryPhone.containsKey(newRecord.AccountId)) {
            newRecord.Is_Primary_Contact__c.addError('Cannot insert / update more than one Primary Contact per Account');
        } else {
            accountsPrimaryPhone.put(newRecord.AccountId, newRecord.Phone);
        }
    }
    
    public static void changePrimaryPhones(Contact newRecord, Map<Id, String> accountPrimaryPhoneMap) {
        if (newRecord.Is_Primary_Contact__c) {
            accountPrimaryPhoneMap.put(newRecord.AccountId, newRecord.Phone);
        }
        
        if (accountPrimaryPhoneMap.size() > 0) {
            AsyncUpdate.setPrimaryPhone(accountPrimaryPhoneMap);
        }
    }
}