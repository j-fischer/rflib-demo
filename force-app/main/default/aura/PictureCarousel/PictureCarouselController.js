({
    next: function(component) {
        var logger = component.find('logger');
        logger.info('next');
        
    	var slideIndex = component.get("v.slideIndex");
    	var slides = component.get("v.slides");
        if (slideIndex + 1 < slides.length) {
            slideIndex = slideIndex + 1;
            
            logger.info('slideIndex=' + slideIndex);
	        component.set("v.slideIndex", slideIndex);
        }
	},
    
    prev: function(component) {
        var logger = component.find('logger');
        logger.info('prev');

        var slideIndex = component.get("v.slideIndex");
        if (slideIndex > 0) {
            slideIndex = slideIndex - 1;

            logger.info('slideIndex=' + slideIndex);
	        component.set("v.slideIndex", slideIndex);
        }
    }

})