public with sharing class HandlerDashboard implements BotHandler {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('HandlerDashboard');
    
    public BotResponse handle(String utterance, String[] params, Map<String, String> session, String fileName, String fileContent) {
        LOGGER.info('handle({0}, {1}, {2}, {3})', new Object[] { utterance, params, session, fileContent });

        String key = '%' + params[0] + '%';
        List<Dashboard> dashboards = 
            [SELECT Id, Title, FolderName FROM Dashboard
             WHERE Title LIKE :key
             ORDER BY Title
             LIMIT 5];
        
        System.debug(dashboards);

        List<BotRecord> records = new List<BotRecord>();
        
        for (Dashboard d : dashboards) {
            List<BotField> fields = new List<BotField>();
            fields.add(new BotField('Name', d.Title, '/lightning/r/Dashboard/' + d.Id + '/view'));
            fields.add(new BotField('Folder', d.FolderName));
            records.add(new BotRecord(fields));
        }

        System.debug(records);

        return new BotResponse(new BotMessage('Astro', 'Here is a list of dashboards matching "' + params[0] + '":', records));
    }
    
}