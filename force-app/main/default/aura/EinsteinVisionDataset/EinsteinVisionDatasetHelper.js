({
	getModelsByDataset : function(component) {
        var logger = component.find('logger');

        var action = component.get("c.getModelsByDataset"); 
        action.setParams({
            datasetId: component.get("v.dataset").id
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            logger.info(state);
            if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        alert("Error message: " + errors[0].message);
                    }
                } else {
                    logger.info("Unknown error");
                }
            }
            var models = JSON.parse(response.getReturnValue()).data;
            for (var i=0; i<models.length; i++) {
                logger.info(models[i].progress);
                if (models[i].progress) {
	                models[i].progress = parseFloat(models[i].progress) * 100 + "%";
                    logger.info(models[i].progress);
                } else {
                    logger.info('n/a');
                }
            }
            component.set("v.models", models);
        });
        $A.enqueueAction(action); 
	}
})