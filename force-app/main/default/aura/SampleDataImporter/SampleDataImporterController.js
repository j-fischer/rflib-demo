({
    importData : function(component, event, helper) {
        var logger = component.find('logger');

        var action = component.get("c.importSampleData");
        component.set("v.showSpinner", true);
        action.setCallback(this, function (response) {
            component.set("v.showSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") { 
                component.find('notifLib').showToast({
                    "variant": "success",
                    "header": "Success",
                    "message": "Sample data successfully imported.",
                });
            } else {
                logger.info(response.getError());
                component.find('notifLib').showToast({
                    "variant": "error",
                    "header": "Error",
                    "message": "Sample data import failed.",
                });
            }
        });
        $A.enqueueAction(action);
    },
    importDataAsync : function(component, event, helper) {
        var logger = component.find('logger');

        var action = component.get("c.importSampleDataAsync");
        component.set("v.showSpinner", true);
        action.setCallback(this, function (response) {
            component.set("v.showSpinner", false);
            var state = response.getState();
            if (state === "SUCCESS") { 
                component.find('notifLib').showToast({
                    "variant": "success",
                    "header": "Success",
                    "message": "Scheduled Action to import sample data.",
                });
            } else {
                logger.info(response.getError());
                component.find('notifLib').showToast({
                    "variant": "error",
                    "header": "Error",
                    "message": "Scheduling action to import Sample data failed.",
                });
            }
        });
        $A.enqueueAction(action);
    }
})