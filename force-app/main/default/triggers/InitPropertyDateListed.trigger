trigger InitPropertyDateListed on Property__c (before insert) {

    /* 
       For demo purpose: when properties are added, generate a random value for Date_Listed__c 
       (between 5 and 50 days ago)
    */

    rflib_Logger logger = rflib_LoggerUtil.getFactory().createBatchedLogger('InitPropertyDateListed');
    try {
        Integer min = 5;
        Integer max = 50;
    
        logger.info('Trigger started, min={0}, max={1}', new Object[] {min, max});
    
        for (Property__c property : Trigger.New) {
            
            Integer daysListed = (Integer) - (Math.random() * (max - min) + min);
    
            if (property.Date_Listed__c == null) {
                logger.debug('Setting Date_Listed__c on Property {0} field to {1}', new Object[] { property.Title__c, daysListed});
                property.Date_Listed__c = system.today().addDays(daysListed);
            } 
        }
    } catch (Exception ex) {
        logger.fatal('Failed to insert Date_Listed__c', ex);
    } finally {
        logger.publishBatchedLogEvents();
    }

}