public with sharing class HandlerFileUpload implements BotHandler {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('HandlerFileUpload');
    
	public BotResponse handle(String utterance, String[] params, Map<String, String> session, String fileName, String fileContent) {
        LOGGER.info('handle({0}, {1}, {2}, {3})', new Object[] { utterance, params, session, fileContent });
        try {
            ContentVersion v = new ContentVersion();
            v.versionData = EncodingUtil.base64Decode(fileContent);
            v.title = fileName;
            v.pathOnClient = fileName;
            insert v;
			ContentDocument doc = [SELECT Id FROM ContentDocument where LatestPublishedVersionId = :v.Id];
			List<BotRecord> records = new List<BotRecord>();
            List<BotField> fields = new List<BotField>();
            fields.add(new BotField('Name', v.Id, '/lightning/r/ContentDocument/' + doc.Id + '/view'));
            fields.add(new BotField('Name', v.title));
            records.add(new BotRecord(fields));
	        return new BotResponse(new BotMessage('Bot', 'Your file was uploaded successfully', records));
        } catch (Exception e) {
            LOGGER.error('Failed to upload file', e);
			return new BotResponse(new BotMessage('Bot', 'An error occured while uploading the file'));            
        }
    }
    
}