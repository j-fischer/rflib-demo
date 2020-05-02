public with sharing class HandlerNext implements BotHandler {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('HandlerNext');
    
    public BotResponse handle(String utterance, String[] params, Map<String, String> session, String fileName, String fileContent) {
        LOGGER.info('handle({0}, {1}, {2}, {3})', new Object[] { utterance, params, session, fileContent });
        
        List<Opportunity> opportunities = 
            [SELECT Id, Name, Amount, Probability, StageName, CloseDate FROM Opportunity WHERE isClosed=false ORDER BY amount DESC LIMIT 1];
        
        List<BotRecord> opportunityRecords = new List<BotRecord>();
        
        for (Opportunity o : opportunities) {
            List<BotField> fields = new List<BotField>();
            fields.add(new BotField('Name', o.Name, '/lightning/r/Opportunity/' + o.Id + '/view'));
            fields.add(new BotField('Amount', '$' + o.Amount));
            fields.add(new BotField('Probability', '' + o.Probability + '%'));
            fields.add(new BotField('Stage', o.StageName));
            opportunityRecords.add(new BotRecord(fields));
        }
        BotMessage opportunityMessage = new BotMessage('Bot', 'You have an overdue item for the following opportunity:', opportunityRecords);
        
        List<Case> cases = 
            [SELECT Id, CaseNumber, Subject, Status, Priority, Contact.Id, Contact.Name FROM Case WHERE OwnerId =:UserInfo.getUserId() AND Priority='High' AND Status != 'Closed'];
        
        List<BotRecord> caseRecords = new List<BotRecord>();
        
        for (Case c : cases) {
            List<BotField> fields = new List<BotField>();
            fields.add(new BotField('Name', c.CaseNumber, '/lightning/r/Case/' + c.Id + '/view'));
            fields.add(new BotField('Subject', c.Subject));
            fields.add(new BotField('Status', c.Status));
            fields.add(new BotField('Name', c.Contact.Name, '/lightning/r/Contact/' + c.Contact.Id + '/view'));
            caseRecords.add(new BotRecord(fields));
        }
        BotMessage caseMessage = new BotMessage('Bot', 'You should work on these high priority cases assigned to you:', caseRecords);

        BotResponse r = new BotResponse();
        
        r.messages = new BotMessage[] {opportunityMessage, caseMessage};
        
        return r;
        
    }
    
}