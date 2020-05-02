public with sharing class HandlerCostCenter implements BotHandler {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('HandlerCostCenter');
    
    public BotResponse handle(String utterance, String[] params, Map<String, String> session, String fileName, String fileContent) {
        LOGGER.info('handle({0}, {1}, {2}, {3})', new Object[] { utterance, params, session, fileContent });
        return new BotResponse(new BotMessage('Bot', 'Your cost center is 21852'));
    }
    
}