({
    setSlideWidth: function (component) {
        var logger = component.find('logger');
        
        var slideWidth = component.find("gallery").getElement().offsetWidth;
        logger.info('setSlideWidth: slideWidth=' + slideWidth);
        component.set("v.slideWidth", slideWidth);
    }
})