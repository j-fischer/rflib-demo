({
    onInit : function(component, event, helper) {
        var logger = component.find('logger');
        logger.info('onInit invoked');
        helper.loadPictures(component);
    },
    
	onUploadFinished: function (component, event, helper) {
        var logger = component.find('logger');
        logger.info('onUploadFinished invoked');

        helper.loadPictures(component);
    },
    
    recordChangeHandler: function (component, event, helper) {
        component.set("v.recordId", event.getParam("recordId"));
        var logger = component.find('logger');
        logger.info('recordChangeHandler invoked');
        
        helper.loadPictures(component);
    },

})