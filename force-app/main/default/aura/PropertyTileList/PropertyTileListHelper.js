({
    getProperties: function (component, pageNumber) {
        var logger = component.find('logger');
        
        var action = component.get('c.getPropertyListPage');
        var pageSize = component.get('v.pageSize');
        var startTime = performance.now();
        
        action.setParams({
            searchKey: component.get('v.searchKey'),
            minPrice: component.get('v.minPrice'),
            maxPrice: component.get('v.maxPrice'),
            numberBedrooms: component.get('v.numberBathrooms'),
            numberBathrooms: component.get('v.numberBedrooms'),
            visualSearchKey: component.get('v.visualSearchKey'),
            pageSize: pageSize,
            pageNumber: pageNumber || 1,
        });
        logger.info('getProperties: startTime={0}, params={1}', [startTime, action.getParams()] );
        action.setCallback(this, function (response) {
            var page = response.getReturnValue();
            logger.info('Page {0} loaded in {1}ms, properties={2}', [page.pageNumber, performance.now() - startTime, page.properties]);
            component.set('v.properties', page.properties);
            component.set('v.pageNumber', page.pageNumber);
            component.set('v.total', page.total);
            component.set('v.pages', Math.ceil(page.total / pageSize));
        });
        $A.enqueueAction(action);
    },
});
