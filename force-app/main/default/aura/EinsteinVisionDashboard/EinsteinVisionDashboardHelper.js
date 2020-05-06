({
	getDatasets : function(component) {
        var logger = component.find('logger');

        var action = component.get("c.getDatasets"); 
        action.setCallback(this, function(response) {
            component.set("v.waiting", false);
            var state = response.getState();
            logger.info('getDatasets completed: state= ' + state);
            if (state === 'ERROR') {
                var errors = response.getError();
                if (errors) {
                    logger.error("Error: " + JSON.stringify(errors))
                    if (errors[0] && errors[0].message) {
                        return alert(errors[0].message);
                    }
                } else {
                    return logger.error("Unknown error");
                }
            }
            var result = response.getReturnValue();
            component.set("v.datasets", JSON.parse(result).data);
        });
        component.set("v.waiting", true);
        $A.enqueueAction(action); 
	}
})