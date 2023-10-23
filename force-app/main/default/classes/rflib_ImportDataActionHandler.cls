public class rflib_ImportDataActionHandler implements rflib_RetryableActionHandler {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createLogger('rflib_ImportDataActionHandler');

    private static final rflib_ApplicationEventLogger APP_LOGGER = rflib_LoggerUtil.getApplicationEventLogger();

    public void execute(List<rflib_Retryable_Action__e> actions) {
        LOGGER.info('Executing import action.');
        try {
            APP_LOGGER.logApplicationEvent('import-sample-data-async', null, null);
            
            LOGGER.info('importSampleData()');
        
            LOGGER.info('Deleting Bot_Command__c records');
            delete [SELECT Id from Bot_Command__c];

            LOGGER.info('Deleting Property_Favorite__c records');
            delete [SELECT Id from Property_Favorite__c];
            
            LOGGER.info('Deleting Property__c records');
            delete [SELECT Id from Property__c];
            
            LOGGER.info('Deleting Broker__c records');
            delete [SELECT Id from Broker__c];
            
            LOGGER.info('Importing Bot commands');
            StaticResource botCommandsResource = [SELECT Id, Body from StaticResource WHERE Name = 'botCommands'];
            String botCommandsJSON = botCommandsResource.body.toString();
            List<Bot_Command__c> botCommands = (List<Bot_Command__c>) JSON.deserialize(botCommandsJSON, List<Bot_Command__c>.class);
            insert botCommands;
            
            LOGGER.info('Importing brokers');
            StaticResource brokersResource = [SELECT Id, Body from StaticResource WHERE Name = 'brokers'];
            String brokersJSON = brokersResource.body.toString();
            List<Broker__c> brokers = (List<Broker__c>) JSON.deserialize(brokersJSON, List<Broker__c>.class);
            insert brokers;
            
            LOGGER.info('Importing properties');
            StaticResource propertiesResource = [SELECT Id, Body from StaticResource WHERE Name = 'properties'];
            String propertiesJSON = propertiesResource.body.toString();
            List<Property__c> properties = (List<Property__c>) JSON.deserialize(propertiesJSON, List<Property__c>.class);
            insert properties;

            List<rflib_ApplicationEventDetails> details = new List<rflib_ApplicationEventDetails>();
            for (Property__c p : properties) {
                details.add(new rflib_ApplicationEventDetails('property-inserted', p.Id, null));
            }
            APP_LOGGER.logApplicationEvents(details);
        } catch (Exception ex) {
            LOGGER.fatal('Failed to import sample data: ', ex);
            APP_LOGGER.logApplicationEvent('import-sample-data-failed', null, null);
            throw ex;
        }        
    }
}