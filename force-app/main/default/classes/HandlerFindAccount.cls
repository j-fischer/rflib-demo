public with sharing class HandlerFindAccount implements BotHandler {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('HandlerFindAccount');
    
    public BotResponse handle(String utterance, String[] params, Map<String, String> session, String fileName, String fileContent) {
        LOGGER.info('handle({0}, {1}, {2}, {3})', new Object[] { utterance, params, session, fileContent });
        String key = '%' + params[0] + '%';
        List<Account> accounts = 
            [SELECT Id, Name, Phone FROM Account
             WHERE Name LIKE :key
             ORDER BY Name
             LIMIT 5];
        
        List<BotRecord> records = new List<BotRecord>();
        
        for (Account a : accounts) {
            List<BotField> fields = new List<BotField>();
            fields.add(new BotField('Name', a.Name, '/lightning/r/Account/' + a.Id + '/view'));
            fields.add(new BotField('Phone', a.Phone, 'tel:' + a.Phone));
            records.add(new BotRecord(fields));
        }
        return new BotResponse(new BotMessage('Bot', 'Here is a list of accounts matching "' + params[0] + '":', records));
        
    }
    
}