({
    calculateMonthlyPayment : function(component, event, helper) {
        var logger = component.find('logger');
        logger.info('calculateMonthlyPayment invoked');
        helper.calculateMonthlyPayment(component);
	},

    recordUpdated : function(component) {
        var logger = component.find('logger');
        logger.info('recordUpdated');
        
        var property = component.get("v.property");
        if (property) {
            logger.info('property.Price__c=' + property.Price__c);
            component.set("v.principal", property.Price__c);
        }
	}
})