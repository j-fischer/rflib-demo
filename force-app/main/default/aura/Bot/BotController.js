({
	utteranceHandler : function(component, event, helper) {
        var logger = component.find('logger');
        
        var utterance = event.getParam("value");
        var messages = component.get("v.messages");
        logger.info('utteranceHandler: utterance={0}, messages={1}', [utterance, JSON.stringify(messages)]);
        
        messages.push({author: "Me", messageText: utterance});
        component.set("v.messages", messages);
        helper.submit(component, utterance, component.get('v.session'), null, null, function(answer) {
            if (answer) {
                logger.info("Answer: " + JSON.stringify(answer));
                component.set("v.session", answer.session);
                Array.prototype.push.apply(messages, answer.messages);
                component.set("v.messages", messages);
            } 
        });
        component.find("voiceInput").clear();
	},
    
    postbackButtonClickHandler : function(component, event, helper) {
        var logger = component.find('logger');
        
    	var utterance = event.getSource().get("v.label");
		var messages = component.get("v.messages");
        logger.info('postbackButtonClickHandler: utterance={0}, messages={1}', [utterance, JSON.stringify(messages)]);
        
        
        messages.push({author: "Me", messageText: utterance});
        component.set("v.messages", messages);
        helper.submit(component, utterance, component.get('v.session'), null, null, function(answer) {
            if (answer) {
                logger.info(answer);
                component.set("v.session", answer.session);
                Array.prototype.push.apply(messages, answer.messages);
                component.set("v.messages", messages);
            }
        });
    },
    
	uploadFile: function(component, event, helper) {
        var logger = component.find('logger');
        logger.info('uploadFile');

        var files = component.get("v.files");
        if (files && files.length > 0) {
	        var file = files[0][0];
            if (!file.type.match(/(image.*)/)) {
                return alert('Image file not supported');
            }
            var reader = new FileReader();
            reader.onloadend = function() {
                logger.info('Uploading file: ' + file.name);

                var dataURL = reader.result;
                var content = dataURL.match(/,(.*)$/)[1];
                var messages = component.get("v.messages");
                var utterance = component.find('utterance').getElement().value;
            	messages.push({author: "Me", messageText: "Uploading file " + file.name, imageURL: dataURL});
	        	component.set("v.messages", messages);
				helper.submit(component, utterance, component.get('v.session'), file.name, content, function(answer) {
                    if (answer) {
                        logger.info(answer);
                        component.set("v.session", answer.session);
                        Array.prototype.push.apply(messages, answer.messages);
                        component.set("v.messages", messages);
                    }
                });
            };
            reader.readAsDataURL(file);
        }
    },
    
    fieldClickHandler: function(component, event) {
        var logger = component.find('logger');
        logger.info('fieldClickHandler:' + event.target.href);

        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": event.target.href
        });
        urlEvent.fire();
        event.preventDefault();
    }
    
})