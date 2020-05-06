({
    previousPage: function (component) {
        component.find('logger').info('previousPage');
        var pageChangeEvent = component.getEvent('pagePrevious');
        pageChangeEvent.fire();
    },

    nextPage: function (component) {
        component.find('logger').info('nextPage');
        var pageChangeEvent = component.getEvent('pageNext');
        pageChangeEvent.fire();
    },
});
