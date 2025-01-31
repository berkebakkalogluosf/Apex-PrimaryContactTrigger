@isTest
private class ContactTriggerTest {
    
    private static Account initAccount() {
        Account account = new Account(Name = 'Test Account');
        insert account;
        
        return account;
    }
    
    private static void initContacts(Account account) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 500; i++) {
            Contact contact = new Contact();
            contact.LastName = 'test' + i;
            contact.AccountId = account.Id;
            
            contacts.add(contact);
        }
        insert contacts;
    }
    
    private static List<Contact> initPrimaryContacts(Integer amount, Account account) {
        List<Contact> primaryContacts = new List<Contact>();
        
        for (Integer i = 0; i < amount; i++) {
            Contact primaryContact = new Contact();
            primaryContact.LastName = 'primary' + i;
            primaryContact.Phone = '' + i + i + i + i + i + i;
            primaryContact.Is_Primary_Contact__c = true;
            primaryContact.AccountId = account.Id;
            
            primaryContacts.add(primaryContact);
        }
        
        return primaryContacts;
    }
    
    @isTest
    private static void testAddingOnePrimaryContactSuccess() {
        Account account = initAccount();
        initContacts(account);
        List<Contact> primaryContacts = initPrimaryContacts(1, account);
        
        Test.startTest();
        
        insert primaryContacts;
        
        Test.stopTest();
        
        List<Contact> contacts = [SELECT Id, Primary_Contact_Phone__c FROM Contact WHERE AccountId =: account.Id];
        
        Boolean primaryPhoneUpdated = true;
        
        for (Contact contact : contacts) {
            if (contact.Primary_Contact_Phone__c != '000000') {
                primaryPhoneUpdated = primaryPhoneUpdated || false;
            }
        }
        
        System.assertEquals(true, primaryPhoneUpdated);
    }
    
    @isTest
    private static void testAddingOnePrimaryContactFailure() {
        Account account = initAccount();
        initContacts(account);
        List<Contact> primaryContacts = initPrimaryContacts(1, account);
        insert primaryContacts;
        
        try {
            Test.startTest();
            
            Contact extraPrimaryContact = new Contact();
            extraPrimaryContact.LastName = 'ExtraPrimaryContact';
            extraPrimaryContact.Is_Primary_Contact__c = true;
            extraPrimaryContact.AccountId = account.Id;
            
            Database.SaveResult result = Database.insert(extraPrimaryContact);
            
            Test.stopTest();
        } catch (DMLException e) {
            Boolean expectedExceptionThrown = e.getMessage().contains('There already exists a primary contact for this account');
            System.assertEquals(true, expectedExceptionThrown);
        }
    }
    
    @isTest
    private static void testAddingMultiplePrimaryContactsFailure() {
        Account account = initAccount();
        initContacts(account);
        List<Contact> primaryContacts = initPrimaryContacts(10, account);
        
        try {
            Test.startTest();
            
            Database.SaveResult[] results = Database.insert(primaryContacts);
            
            Boolean success = false;
            Integer errorCount = 0;
            for (Database.SaveResult result : results) {
                success = success || !result.isSuccess();
                errorCount += result.getErrors().size();
            }
            
            Test.stopTest();
            
        } catch (DMLException e) {
            Boolean expectedExceptionThrown = e.getMessage().contains('Cannot insert / update more than one Primary Contact per Account');
            System.assertEquals(true, expectedExceptionThrown);
        }
    }
}