public with sharing class InitPropertyDateListedHandler implements rflib_TriggerHandler {
    
    private static rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('InitPropertyDateListedHandler');

    /* 
       For demo purpose: when properties are added, generate a random value for Date_Listed__c 
       (between 5 and 50 days ago)
    */
    public void run(rflib_TriggerManager.Args args) {
        
        try {
            Integer min = 5;
            Integer max = 50;
        
            LOGGER.info('Trigger started, min={0}, max={1}', new Object[] {min, max});
        
            for (Property__c property : (List<Property__c>) args.newRecords) {
                
                Integer daysListed = (Integer) - (Math.random() * (max - min) + min);
        
                if (property.Date_Listed__c == null) {
                    LOGGER.debug('Setting Date_Listed__c on Property {0} field to {1}', new Object[] { property.Title__c, daysListed});
                    property.Date_Listed__c = system.today().addDays(daysListed);
                } 
            }

            LOGGER.info('Trigger completed');
        } catch (Exception ex) {
            LOGGER.fatal('Failed to insert Date_Listed__c', ex);
        }
    }

    public void onConsecutiveRun(rflib_TriggerManager.Args args, Integer numInvocation) { }

}
