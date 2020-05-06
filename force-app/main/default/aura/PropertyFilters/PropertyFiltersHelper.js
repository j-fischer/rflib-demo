({
    fireFilterChangeEvent : function(component) {
        var logger = component.find('logger');
        
        var filterChangeEvent = $A.get("e.c:PropertyFilterChange");
        filterChangeEvent.setParams({
            "searchKey": component.get("v.searchKey"),
            "minPrice": component.get("v.minPrice"),
            "maxPrice": component.get("v.maxPrice"),
            "numberBedrooms": component.get("v.numberBedrooms"),
            "numberBathrooms": component.get("v.numberBathrooms"),
            "visualSearchKey": component.get("v.visualSearchKey"),
        });
        
        logger.info('fireFilterChangeEvent: params=' + JSON.stringify(filterChangeEvent.getParams()));

        filterChangeEvent.fire();
    }
})
