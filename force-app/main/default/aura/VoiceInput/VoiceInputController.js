({
    onInit: function (component, event, helper) {
        var logger = component.find('logger');
        logger.info('onInit');

        component.SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        component.SpeechGrammarList = window.SpeechGrammarList || window.webkitSpeechGrammarList;
        component.SpeechRecognitionEvent = window.SpeechRecognitionEvent || window.webkitSpeechRecognitionEvent;
    },

    onTalk: function (component, event, helper) {
        var logger = component.find('logger');
        logger.info('onTalk');

        component.set("v.talking", true);

        //var grammar = '#JSGF V1.0; grammar numbers; public number = 1 | 2 | 3 | 4 | 5 ';
        var recognition = new component.SpeechRecognition();
        var speechRecognitionList = new component.SpeechGrammarList();
        //speechRecognitionList.addFromString(grammar, 1);
        recognition.grammars = speechRecognitionList;
        recognition.lang = 'en-US';
        recognition.interimResults = false;
        recognition.maxAlternatives = 1;

        recognition.start();

        recognition.onresult = function (event) {
            var logger = component.find('logger');
            logger.info('recognition.onresult');

            component.set("v.talking", false);
            var utterance = event.results[0][0].transcript;

            var logger = component.find('logger');
            logger.info('recognition.onresult utterance=' + utterance);

            component.set("v.utterance", utterance);
            component.find('utterance').getElement().value = utterance;
            helper.fireChangeEvent(component);
            logger.info('Confidence: ' + event.results[0][0].confidence);
        }

        recognition.onspeechend = function () {
            component.find('logger').info('recognition.onspeechend');
            recognition.stop();
        }

        recognition.onerror = function (event) {
            component.find('logger').error('recognition.onerror: error=' + event.error);
            component.set("v.talking", false);
            component.set("v.result", event.error);
        }

        recognition.onaudiostart = function (event) {
            //Fired when the user agent has started to capture audio.
            component.find('logger').info('SpeechRecognition.onaudiostart');
        }

        recognition.onaudioend = function (event) {
            //Fired when the user agent has finished capturing audio.
            component.find('logger').info('SpeechRecognition.onaudioend');
        }

        recognition.onend = function (event) {
            //Fired when the speech recognition service has disconnected.
            logcomponent.find('logger').info('SpeechRecognition.onend');
        }

        recognition.onnomatch = function (event) {
            //Fired when the speech recognition service returns a final result with no significant recognition. This may involve some degree of recognition, which doesn't meet or exceed the confidence threshold.
            component.find('logger').info('SpeechRecognition.onnomatch');
        }

        recognition.onsoundstart = function (event) {
            //Fired when any sound � recognisable speech or not � has been detected.
            component.find('logger').info('SpeechRecognition.onsoundstart');
        }

        recognition.onsoundend = function (event) {
            //Fired when any sound � recognisable speech or not � has stopped being detected.
            component.find('logger').info('SpeechRecognition.onsoundend');
        }

        recognition.onspeechstart = function (event) {
            //Fired when sound that is recognised by the speech recognition service as speech has been detected.
            component.find('logger').info('SpeechRecognition.onspeechstart');
        }
        recognition.onstart = function (event) {
            //Fired when the speech recognition service has begun listening to incoming audio with intent to recognize grammars associated with the current SpeechRecognition.
            component.find('logger').info('SpeechRecognition.onstart');
        }

    },

    onKeyPress : function(component, event, helper) {
        var logger = component.find('logger');
        logger.info('onKeyPress: keyCode={0}, key={1}', [event.keyCode, event.key]);

        if (event.keyCode !== 13) {
            return;
        }
        component.set("v.utterance", event.target.value);
        logger.info('onKeyPress: utterance=' + event.target.value);

        helper.fireChangeEvent(component);
    },
    
    clear : function(component) {
        var logger = component.find('logger');
        logger.info('clear');
        component.find('utterance').getElement().value = '';
    }

})