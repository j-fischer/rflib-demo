({
    onInit: function(component, event, helper) {
        component.set('v.datasetColumns', [
            {label: 'Label', fieldName: 'name', type: 'text'},
            {label: 'Examples', fieldName: 'numExamples', type: 'number'}
        ]);
        component.set('v.modelColumns', [
            {label: 'Model Id', fieldName: 'modelId', type: 'text'},
            {label: 'Progress', fieldName: 'progress', type: 'text'},
            {label: 'Status', fieldName: 'status', type: 'text'}
        ]);
    },

    onModelsTab: function(component, event, helper) {
        helper.getModelsByDataset(component);
        component.set('v.currentTab', 'models');
    },
    
    onLabelsTab: function(component, event, helper) {
        var logger = component.find('logger');

        logger.info(JSON.stringify(component.get("v.dataset")));
        component.set('v.currentTab', 'labels');
    },

    onRefresh: function(component, event, helper) {
		helper.getModelsByDataset(component);
    },

    onDeleteDataset: function(component, event, helper) {
        var logger = component.find('logger');

        var action = component.get("c.deleteDataset"); 
        action.setParams({
            datasetId: component.get("v.dataset").id
        });
        action.setCallback(this, function(response) {
            var changeEvent = component.getEvent("onchange");
            changeEvent.fire();
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
            var result = response.getReturnValue();
            logger.info(result);
        });
        $A.enqueueAction(action); 
    },
    
    onTrainModel: function(component, event, helper) {
        var logger = component.find('logger');

        var action = component.get("c.trainModel"); 
        var dataset = component.get("v.dataset");
        action.setParams({
            modelName: dataset.name + " model",
            datasetId: dataset.id
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
            
            var result = response.getReturnValue();
            logger.info(result);
            //alert("Started training model");
        });
        $A.enqueueAction(action); 
    },
})