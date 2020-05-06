({
	navigateToDetailsView : function(component) {
        var logger = component.find('logger');
        
		var property = component.get("v.property");
        logger.info('navigateToDetailsView: id=' + property.Id);
        
        var myEvent = $A.get("e.force:navigateToSObject");
        myEvent.setParams({
            "recordId": property.Id
        });
        myEvent.fire();
	},

	propertySelected : function(component) {
        var logger = component.find('logger');
        
        var property = component.get("v.property");
        logger.info('propertySelected: id=' + property.Id);
        
        var myEvent = $A.get("e.ltng:selectSObject");
        myEvent.setParams({"recordId": property.Id, channel: "Properties"});
        myEvent.fire();
    }

})