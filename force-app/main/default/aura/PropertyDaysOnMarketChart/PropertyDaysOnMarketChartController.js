({
    recordUpdated: function (component, event, helper) {
        var logger = component.find('logger');

        var changeType = event.getParams().changeType;
        logger.info('recordUpdated: changeType=' + changeType);
        if (changeType === 'LOADED' || changeType === 'CHANGED') {
            helper.showDaysOnMarket(component);
        }
    },

    recordChangeHandler: function (component, event) {
        var logger = component.find('logger');
        var id = event.getParam('recordId');

        logger.info('recordChangeHandler: id=' + id);
        component.set('v.recordId', id);
        var service = component.find('service');
        
        service.reloadRecord();
    },
});
