({

    submit: function(component, utterance, session, fileName, base64Data, callback) {
        var logger = component.find('logger');
        logger.info('submit({0}, {1}, {2})', [utterance, session, fileName]);

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
	            callback(a.getReturnValue());
            } else if (state === 'ERROR') {
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