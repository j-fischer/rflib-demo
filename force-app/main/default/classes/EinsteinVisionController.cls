global with sharing class EinsteinVisionController {
    
    private static final rflib_Logger LOGGER = rflib_LoggerUtil.getFactory().createBatchedLogger('EinsteinVisionController');

    public static String VISION_API = 'https://api.metamind.io/v1/vision';
	private static final Dreamhouse_Settings__c settings = Dreamhouse_Settings__c.getOrgDefaults();

    public class Prediction {
        @AuraEnabled
        public String label {get;set;}
        @AuraEnabled
        public Double probability {get;set;}
    }

    // You can upload the 'einstein_platform.pem' into your Salesforce org as 'File' sObject and read it as below
    private static String getAccessToken() {
        LOGGER.info('getAccessToken()');

        if (settings == null || String.isEmpty(settings.Einstein_Vision_Email__c)) {
            LOGGER.fatal('Cannot create Einstein Vision token: "Einstein Vision Email" not defined in Custom Settings');
            throw new AuraHandledException('Cannot create Einstein Vision token: "Einstein Vision Email" not defined in Custom Settings');
        }
        ContentVersion base64Content;
        try {
        	base64Content = [SELECT Title, VersionData FROM ContentVersion where Title='einstein_platform' LIMIT 1];
        } catch (Exception e) {
            LOGGER.fatal('Cannot create Einstein Vision token: einstein_platform.pem file not found');
	        throw new AuraHandledException('Cannot create Einstein Vision token: einstein_platform.pem file not found');    
        }
        String keyContents = base64Content.VersionData.tostring();
        keyContents = keyContents.replace('-----BEGIN RSA PRIVATE KEY-----', '');
        keyContents = keyContents.replace('-----END RSA PRIVATE KEY-----', '');
        keyContents = keyContents.replace('\n', '');

        // Get a new token
        JWT jwt = new JWT('RS256');
        jwt.pkcs8 = keyContents; // Comment this if you are using jwt.cert
        jwt.iss = 'developer.force.com';
        jwt.sub = settings.Einstein_Vision_Email__c;
        jwt.aud = 'https://api.metamind.io/v1/oauth2/token';
        jwt.exp = '3600';
        String access_token;

        if (!Test.isRunningTest()) {
            access_token = JWTBearerFlow.getAccessToken('https://api.metamind.io/v1/oauth2/token', jwt);
        } else {
            LOGGER.debug('Unit tests: skipping token generation');
        }
        return access_token;    
    }

    @AuraEnabled
    public static List<Prediction> predict(String fileName, String content, String modelId) {
        try {
            LOGGER.info('predict({0}, {1}, {2})', new Object[] { fileName, content, modelId});
            if (String.isBlank(modelId)) {
                return EinsteinVisionController.predictDemo(fileName, content);    
            } else {
                return EinsteinVisionController.predictReal(fileName, content, modelId);            
            }
        } finally {
            LOGGER.publishBatchedLogEvents();
        }
    }
    
    @AuraEnabled
    public static List<Prediction> predictReal(String fileName, String content, String modelId) {
        try {
            LOGGER.info('predictReal({0}, {1}, {2})', new Object[] { fileName, content, modelId});
            String access_token;
            try {
                access_token = EinsteinVisionController.getAccessToken();
            } catch (Exception e) {
                throw new AuraHandledException('Cannot create Einstein Vision token. Did you upload the einstein_platform.pem file and specify the Einstein Vision email address to use in Custom Settings?');			
            }
            List<Prediction> predictions = EinsteinVisionController.predictInternal(content, access_token, modelId, true);
            
            LOGGER.info('Predictions: ' + JSON.serialize(predictions));
            return predictions;
        } finally {
            LOGGER.publishBatchedLogEvents();
        }
    }

    @AuraEnabled
    public static List<Prediction> predictDemo(String fileName, String content) {
        try {
            LOGGER.info('predictDemo({0}, {1})', new Object[] { fileName, content});
            Integer pos = fileName.indexOf('_');
            String label;
            if (pos > 0) {
                // if the filename is like "victorian_01.jpg", we return "victorian"
                label = fileName.substring(0, pos);    
            } else {
                // else we return a category selected randomly
                List<String> categories = new List<String>{'Victorian', 'Colonial', 'Contemporary'};
                Integer index = Math.mod(Math.round(Math.random()*1000), 3);
                label = categories[index];    
            }
            List<Prediction> predictions = new List<Prediction>();
            Prediction prediction = new Prediction();
            prediction.label = label;    
            prediction.probability = 1;
            predictions.add(prediction);
            
            LOGGER.info('Predictions: ' + JSON.serialize(predictions));
            return predictions;
        } finally {
            LOGGER.publishBatchedLogEvents();
        }
    }
    
	@AuraEnabled
    public static String getDatasets() {
        LOGGER.info('getDatasets()');
        String access_token = EinsteinVisionController.getAccessToken();
        rflib_HttpRequest req = new rflib_HttpRequest();
        req.setMethod('GET');    
        req.setHeader('Authorization', 'Bearer ' + access_token);
        req.setHeader('Cache-Control', 'no-cache');
        req.setEndpoint(VISION_API + '/datasets');
		try {
            if (!Test.isRunningTest()) {
                HTTPResponse res = req.send();
                return res.getBody();
            } else {
                return '';
            }
        } catch(Exception ex){
            LOGGER.error('Failed to retrieve datasets.', ex);
            return '{"error": "' + ex.getMessage() + '"}';
        } finally {
            LOGGER.publishBatchedLogEvents();
        }
    }
    
	@AuraEnabled
    public static String getModelsByDataset(Integer datasetId) {
        LOGGER.info('getModelsByDataset({0})', new Object[]{ datasetId});
        
        String accessToken = EinsteinVisionController.getAccessToken();
        rflib_HttpRequest req = new rflib_HttpRequest();
        req.setMethod('GET');    
        String endpoint = VISION_API + '/datasets/' + datasetId + '/models';
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Cache-Control', 'no-cache');
		try {
            if (!Test.isRunningTest()) {
                HTTPResponse res = req.send();
				return res.getBody();
            } else {
                return null;
            }
        } catch(Exception ex){
            LOGGER.error('Failed to retrieve models.', ex);
            return '{"error": "' + ex.getMessage() + '"}';
        } finally {
            LOGGER.publishBatchedLogEvents();
        }
    }
    
    @AuraEnabled
    public static String deleteDataset(Integer datasetId) {
        LOGGER.info('deleteDataset({0})', new Object[]{ datasetId});

        String accessToken = EinsteinVisionController.getAccessToken();
        String endpoint = VISION_API + '/datasets/' + datasetId;
        rflib_HttpRequest req = new rflib_HttpRequest();
        req.setMethod('DELETE');    
        req.setEndpoint(endpoint);
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setHeader('Cache-Control', 'no-cache');
		try {
            if (!Test.isRunningTest()) {
	            HTTPResponse res = req.send();
				return res.getBody();
            } else {
                return null;
            }
        } catch(Exception ex){
            LOGGER.error('Failed to delete dataset.', ex);
            return '{"error": "' + ex.getMessage() + '"}';
        } finally {
            LOGGER.publishBatchedLogEvents();
        }
    }
    
    @AuraEnabled
    public static String createDataset(String pathToZip) {
        LOGGER.info('createDataset({0})', new Object[] {pathToZip});
        String accessToken = EinsteinVisionController.getAccessToken();
        String contentType = HttpFormBuilder.GetContentType();
        String form64 = '';
        form64 += HttpFormBuilder.WriteBoundary();
        form64 += HttpFormBuilder.WriteBodyParameter('path', pathToZip);
        form64 += HttpFormBuilder.WriteBoundary(HttpFormBuilder.EndingType.CrLf);
        Blob formBlob = EncodingUtil.base64Decode(form64);
        String contentLength = string.valueOf(formBlob.size());
        rflib_HttpRequest req = new rflib_HttpRequest();
        req.setBodyAsBlob(formBlob);
        req.setMethod('POST');    
        req.setEndpoint(VISION_API + '/datasets/upload');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
		req.setHeader('Connection', 'keep-alive');
		req.setHeader('Content-Length', contentLength);
        req.setHeader('Content-Type', contentType);
        
		try {
            if (!Test.isRunningTest()) {
                HTTPResponse res = req.send();
				return res.getBody();
            } else {
                return null;
            }
        } catch(Exception ex){
            LOGGER.error('Failed  to create dataset.', ex);
            return '{"error": "' + ex.getMessage() + '"}';
        } finally {
            LOGGER.publishBatchedLogEvents();
        }
    }
    
    @AuraEnabled
    public static String trainModel(String modelName, Integer datasetId) {
        LOGGER.info('trainModel({0}, {1})', new Object[] {modelName, datasetId});
        String accessToken = EinsteinVisionController.getAccessToken();
        string contentType = HttpFormBuilder.GetContentType();
        string form64 = '';
        form64 += HttpFormBuilder.WriteBoundary();
        form64 += HttpFormBuilder.WriteBodyParameter('name', modelName);
        form64 += HttpFormBuilder.WriteBoundary();
        form64 += HttpFormBuilder.WriteBodyParameter('datasetId', '' + datasetId);
        form64 += HttpFormBuilder.WriteBoundary(HttpFormBuilder.EndingType.CrLf);
        blob formBlob = EncodingUtil.base64Decode(form64);
        string contentLength = string.valueOf(formBlob.size());
        rflib_HttpRequest req = new rflib_HttpRequest();
		req.setBodyAsBlob(formBlob);
        req.setMethod('POST');    
        req.setEndpoint(VISION_API + '/train');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
		req.setHeader('Connection', 'keep-alive');
		req.setHeader('Content-Length', contentLength);
        req.setHeader('Content-Type', contentType);
		req.setHeader('Cache-Control', 'no-cache');
		req.setTimeout(120000);

		try {
            if (!Test.isRunningTest()) {
                HTTPResponse res = req.send();
				return res.getBody();
            } else {
                return null;
            }
        } catch(Exception ex){
            LOGGER.error('Failed  to create dataset.', ex);
            return '{"error": "' + ex.getMessage() + '"}';
        } finally {
            LOGGER.publishBatchedLogEvents();
        }
    }
    
    private static List<Prediction> predictInternal(String sample, String access_token, String model, boolean isBase64) {
        LOGGER.info('predictInternal({0}, {1}, {2}, {3})', new Object[] {sample, access_token, model, isBase64});
        string contentType = HttpFormBuilder.GetContentType();
        //  Compose the form
        string form64 = '';
        
        form64 += HttpFormBuilder.WriteBoundary();
        form64 += HttpFormBuilder.WriteBodyParameter('modelId', EncodingUtil.urlEncode(model, 'UTF-8'));
        form64 += HttpFormBuilder.WriteBoundary();
        if(isBase64) {
            form64 += HttpFormBuilder.WriteBodyParameter('sampleBase64Content', sample);
        } else {
            form64 += HttpFormBuilder.WriteBodyParameter('sampleLocation', sample);
        }
        form64 += HttpFormBuilder.WriteBoundary(HttpFormBuilder.EndingType.CrLf);
        
        blob formBlob = EncodingUtil.base64Decode(form64);
        string contentLength = string.valueOf(formBlob.size());
        //  Compose the http request
        rflib_HttpRequest httpRequest = new rflib_HttpRequest();
        
        httpRequest.setBodyAsBlob(formBlob);
        httpRequest.setHeader('Connection', 'keep-alive');
        httpRequest.setHeader('Content-Length', contentLength);
        httpRequest.setHeader('Content-Type', contentType);
        httpRequest.setMethod('POST');
        httpRequest.setTimeout(120000);
        httpRequest.setHeader('Authorization','Bearer ' + access_token);
        httpRequest.setEndpoint(VISION_API + '/predict');
        
        List<Prediction> predictions = new List<Prediction>();
        if (!Test.isRunningTest()) {
            try {
                HTTPResponse res = httpRequest.send();
                if (res.getStatusCode() == 200) {
                    System.JSONParser parser = System.JSON.createParser(res.getBody());
                    while (parser.nextToken() != null) {
                        if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'probabilities')) {
                            parser.nextToken();
                            if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                                while (parser.nextToken() != null) {
                                    // Advance to the start object marker to
                                    //  find next probability object.
                                    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                                        // Read entire probability object
                                        Prediction probability = (Prediction)parser.readValueAs(Prediction.class);
                                        predictions.add(probability);
                                    }
                                }
                            }
                            break;
                        }
                    }
                }
            } catch(System.CalloutException e) {
                LOGGER.error('ERROR:', e);
            } finally {
                LOGGER.publishBatchedLogEvents();
            }
        }
        return(predictions);
    }

}