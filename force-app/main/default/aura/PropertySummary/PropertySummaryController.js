({
    /*
    When a new Property is selected (in another component), load the corresponding
    property record.
    */
    recordChangeHandler: function (component, event) {
        var logger = component.find('logger');

        logger.info('recordChangeHandler: property=' + component.get("v.property"));
        component.set("v.recordId", event.getParam("recordId"));
        var service = component.find("service");
        service.reloadRecord();    
    },

    editRecord: function (component, event, helper) {
        var logger = component.find('logger');
        
        var recordId = component.get("v.recordId")
        logger.info('editRecord: recordId=' + recordId);
        
        var editRecordEvent = $A.get("e.force:editRecord");
        editRecordEvent.setParams({
            "recordId": recordId
        });
        editRecordEvent.fire();
    },

    navigateToBrokerRecord : function(component, event) {
        var logger = component.find('logger');

        var brokerId = component.get("v.property").Broker__r.Id;
        logger.info('navigateToBrokerRecord: brokerId=' + brokerId);

	    var navigateEvent = $A.get("e.force:navigateToSObject");
        navigateEvent.setParams({"recordId": brokerId, slideDevName: "detail"});
	    navigateEvent.fire();
    }

})