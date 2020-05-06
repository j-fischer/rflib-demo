({
    onFilterChange: function (component, event, helper) {
        var logger = component.find('logger');
        logger.info('onFilterChange params=' + JSON.stringify(event.getParams()));

        component.set("v.searchKey", event.getParam("searchKey"));
        component.set("v.minPrice", event.getParam("minPrice"));
        component.set("v.maxPrice", event.getParam("maxPrice"));
        component.set("v.numberBedrooms", event.getParam("numberBedrooms"));
        component.set("v.numberBathrooms", event.getParam("numberBathrooms"));
        component.set("v.visualSearchKey", event.getParam("visualSearchKey"));
        helper.getProperties(component);
    },
    
    onInit: function (component, event, helper) {
        component.find('logger').info('onInit')
        helper.getProperties(component);
    },

    onJSLoaded: function (component) {
        component.find('logger').info('onJSLoaded')
        component.set("v.jsLoaded", true);
    },

})