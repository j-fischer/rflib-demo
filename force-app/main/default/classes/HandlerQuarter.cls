public with sharing class HandlerQuarter implements BotHandler {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('HandlerQuarter');
    
    public BotResponse handle(String utterance, String[] params, Map<String, String> session, String fileName, String fileContent) {
        LOGGER.info('handle({0}, {1}, {2}, {3})', new Object[] { utterance, params, session, fileContent });

        return new BotResponse(new BotMessage('Bot', 'Your quarter so far:', 'https://s3-us-west-1.amazonaws.com/sfdc-demo/charts/quarter2.png'));
        
    }
    
}