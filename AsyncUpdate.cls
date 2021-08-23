public class AsyncUpdate {
    
    @future
    public static void setPrimaryPhone(Map<Id, String> accountPrimaryPhoneMap) {
        
        List<Contact> updatedContacts = new List<Contact>();
        
        try {
            for (Id accountId : accountPrimaryPhoneMap.keySet()) {
                List<Contact> contacts = [SELECT Id, LastName, Primary_Contact_Phone__c FROM Contact WHERE AccountId = :accountId];
                
                for (Contact contact : contacts) {
                    contact.Primary_Contact_Phone__c = accountPrimaryPhoneMap.get(accountId);
                    System.debug(contact.LastName + ' PPN = ' + contact.Primary_Contact_Phone__c);
                    updatedContacts.add(contact);
                }
            }            
            update updatedContacts;
            
        } catch (QueryException e) {
            System.debug(e);
        } catch (DMLException e) {
            System.debug(e);
        }
    }
}