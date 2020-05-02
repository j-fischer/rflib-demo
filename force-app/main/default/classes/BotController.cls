public with sharing class BotController {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('BotController');

    class HandlerMapping {
        
        public String handlerClassName;
        public Pattern utterancePattern;

        public HandlerMapping(String handlerClassName, String patternStr) {
            this.handlerClassName = handlerClassName;
            this.utterancePattern = Pattern.compile(patternStr);
        }

    }

    static List<HandlerMapping> handlerMappings;
    
    static {
        List<Bot_Command__c> commands = [SELECT apex_class__c, pattern__c FROM Bot_Command__c WHERE Active__c = True ORDER BY Name];
        LOGGER.info('Bot commands: ' + commands);
        List<HandlerMapping> mappings = new List<HandlerMapping>();
        for (Bot_Command__c command : commands) {
			mappings.add(new HandlerMapping(command.apex_class__c, command.pattern__c));
        }
        handlerMappings = mappings;
    }
    
    @AuraEnabled
    public static BotResponse submit(String utterance, Map<String, String> session, String fileName, String fileContent) {
        LOGGER.info('submit({0}, {1})', new Object[] { utterance, fileName});
        try {
            
            if (session != null) {
                String nextCommand = session.get('nextCommand');
                if (nextCommand != null) {
                    LOGGER.info('Handling next command in session: ' + nextCommand);
                    Type t = Type.forName('', nextCommand);
                    BotHandler h = (BotHandler)t.newInstance();
                    return h.handle(utterance, null, session, fileName, fileContent);
                }
            }
        
            for (HandlerMapping mapping : BotController.handlerMappings) {
                Matcher utteranceMatcher = mapping.utterancePattern.matcher(utterance);
                if (utteranceMatcher.matches()) {
                    LOGGER.info('Utterance found');
                    Type t = Type.forName('', mapping.handlerClassName);
                    BotHandler h = (BotHandler)t.newInstance();
                    List<String> params = new List<String>();
                    for (Integer i=1; i<=utteranceMatcher.groupCount(); i=i+1) {
                        params.add(utteranceMatcher.group(i).trim());
                    }
                    return h.handle(utterance, params, session, fileName, fileContent);
                }
            }
            
            LOGGER.warn('No handler found');
            return new BotResponse(new BotMessage('Bot', 'I don\'t know how to answer that'));
            
        } catch (Exception e) {
            LOGGER.error('Failed to handle bot submission', e);                
            return new BotResponse(new BotMessage('Bot', 'Oops, something went wrong invoking that command'));
        }
        
    }
    
}