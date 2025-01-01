({
    doInit: function(component, event, helper) {
        helper.getDatasets(component);
    },
    
    onRefresh: function(component, event, helper) {
        helper.getDatasets(component);
    },

    onCreateDataset: function(component, event, helper) {
        try {
            var logger = component.find('logger');

            var action = component.get("c.createDataset"); 
            action.setParams({
                pathToZip: component.get("v.pathToZip")
            });
            action.setCallback(this, function(response) {
                component.set("v.waiting", false);
                var state = response.getState();
                logger.info(state);
                if (state === 'ERROR') {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            return alert(errors[0].message);
                        }
                    } else {
                        return logger.info("Unknown error");
                    }
                }
                var result = response.getReturnValue();
                helper.getDatasets(component);
            });
            component.set("v.waiting", true);
            $A.enqueueAction(action); 
        } catch(e) {
            // swallow the exception for instrumentation purposes
        }
    },
    
    datasetChange: function(component, event, helper) {
		helper.getDatasets(component);        
    }
    
})