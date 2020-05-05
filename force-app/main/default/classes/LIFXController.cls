public with sharing class LIFXController {

    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('LIFXController');

    private static final Dreamhouse_Settings__c settings = Dreamhouse_Settings__c.getOrgDefaults();

    @AuraEnabled
    public static String getLights() {
        LOGGER.info('getLights()');
        rflib_HttpRequest req = new rflib_HttpRequest();
        
        req.setMethod('GET');    
        req.setHeader('Authorization', 'Bearer ' + settings.LIFX_TOKEN__C);
        req.setEndpoint(settings.LIFX_URL__C + '/all');
		try {
            HTTPResponse res = req.send();
			return res.getBody();        	
        } catch(Exception ex){
            return '{"error": "' + ex.getMessage() + '"}';
        } finally {
            LOGGER.publishBatchedLogEvents();
        }
    }
    
    @AuraEnabled
    public static String setPower(String lightId, Boolean isOn) {
        try {
            LOGGER.info('setPower({0}, {1})', new Object[] { lightId, isOn});
            return LIFXController.setState(lightId, '{"power": "' + (isOn == true ? 'on' : 'off') + '"}');
        } finally {
            LOGGER.publishBatchedLogEvents();
        }
    }
    
    @AuraEnabled
    public static String setBrightness(String lightId, Decimal brightness) {
        try {
            LOGGER.info('setBrightness({0}, {1})', new Object[] { lightId, brightness});
            return LIFXController.setState(lightId, '{"brightness": ' + (brightness / 100) + '}');
        } finally {
            LOGGER.publishBatchedLogEvents();
        }
    }

    public static String setState(String lightId, String state) {
        LOGGER.info('setState({0}, {1})', new Object[] { lightId, state});
        rflib_HttpRequest req = new rflib_HttpRequest();
        
        req.setMethod('PUT');    
        req.setEndpoint(settings.LIFX_URL__C + '/' + lightId + '/state');
        req.setHeader('Authorization', 'Bearer ' + settings.LIFX_TOKEN__C);
        req.setHeader('Content-Type', 'application/json');
        req.setBody(state);
		try {
            HTTPResponse res = req.send();
			return res.getBody();        	
        } catch(Exception ex){
            return '{"error": "' + ex.getMessage() + '"}';
        }
    }
        
}