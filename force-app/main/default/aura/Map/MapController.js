({

    jsLoaded: function(component) {
        component.set("v.jsLoaded", true);
    },
    
    setLocation: function(component, event, helper) {
        try {
            var params = event.getParam('arguments');
            if (params) {
                component.set("v.location", {
                    lat: params.lat,
                    long: params.long
                });
            }
        } catch (ex) {
            throw ex;
        }
    }

})