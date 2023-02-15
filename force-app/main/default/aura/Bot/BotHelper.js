({

    submit: function(component, utterance, session, fileName, base64Data, callback) {
        var logger = component.find('logger');
        logger.info('submit({0}, {1}, {2})', [utterance, session, fileName]);
        
        var applicationEventLogger = component.find('applicationEventLogger');

        applicationEventLogger.logApplicationEvent('bot-request', null, utterance);
        var action = component.get("c.submit"); 
        action.setParams({
      		utterance: utterance,
            session: session,
            fileName: fileName,
            fileContent: base64Data
        });
        action.setCallback(this, function(a) {
            var state = a.getState();
            if (state === "SUCCESS") {
                applicationEventLogger.logApplicationEvent('bot-request-success', null, utterance);
	            callback(a.getReturnValue());
            } else if (state === 'ERROR') {
                applicationEventLogger.logApplicationEvent('bot-request-failure', null, utterance);
	            var errors = a.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        logger.fatal(errors[0].message);
                    } else {
                        logger.fatal(JSON.stringify(errors));
                    }
                } else {
                    logger.fatal("Unknown error");
                }
            } else if (state === "INCOMPLETE") {
				console.fatal("Incomplete");
            }

        });
        $A.enqueueAction(action);
    }

})