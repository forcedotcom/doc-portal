/**
 * When the page loads, trigger these functions
 */
$(window).load(function() {
    enableDisableSidebarControls();
    
    //Resize frames when everything is done loading
    eqHeights();
});

/*
 * When the window resizes, resize the ToC and topic divs
 */ 
$(window).bind('resize', function() {
	eqHeights();
});

/*
 * Adding a click event for the container ToC topics and stopping
 * propogation so we don't get a flicker.
 *
 * Also, set the ToC and topic divs to the same height
 */
$(document).ready(function(){
	$('div[data-topic-url]').click(function(event) {
	    location.assign(this.getAttribute('data-topic-url'));
	    event.stopImmediatePropagation();
	  });
  
  	//When any item in the toc is expanded/collapsed, resize
	$('div.accordion-body').on('shown', function () {
		eqHeights();
		return false;	//Stop calling for parents
	})
	$('div.accordion-body').on('hidden', function () {
		eqHeights();
	  	return false;	//Stop calling for parents
	})
});

/*
 * Enable/disable css on the sidebar menu 
 */
function enableDisableSidebarControls() {
    $('.side-menu-link').click(function() {
    	$('.toccontent').toggleClass('hidden-phone');
    	return false;
    });
}

/*
 * Method to:
 * - highlight the currently active leaf-node in the TOC based on the filename in the URL
 * - auto-expand the parent node that the child leaf node is apart of
 */
function renderToc() {
    //Find the id based on the url name
    var lastSlashIndex = location.pathname.lastIndexOf("/");
    if (lastSlashIndex >= 0) {
	var lastSlash = lastSlashIndex + 1;
	var pageURL = location.pathname.substr(lastSlash);
	var pageName = pageURL.substr(0, pageURL.lastIndexOf("."));	
	
	//highlight the leaf node of the current page
	var foundLi = $("div#" + pageName);
        // Can't check against null, since the object is never null
	if (foundLi.get(0)) {
            // Make it active
	    foundLi.toggleClass('active');
            // Make the parent collapsable element the default
            $("div#" + pageName).parent('div.collapse').attr('class', function(i, value) {
                return 'in ' + value;
            });
            // Turn the plus to a minus
             $("a[href~='" + pageURL + "']").parents("div.collapse").parent("div.accordion-group").children("div.accordion-heading").children("a").children("i.icon-plus").toggleClass("icon-plus icon-minus");
            // Show all the parent items
            $("div#" + pageName).parents('div.collapse').collapse('show');
        } else {
            // Check to see if it's a container with an href
            foundLi = $("a[href~='" + pageURL + "']");
            // Can't check against null, since the object is never null
	    if (foundLi.get(0)) {
                // Make it active
                $("a[href~='" + pageURL + "']").parent("div").toggleClass('active');
                // Make the parent collapsable element the default
                $("a[href~='" + pageURL + "']").parent('div.collapse').attr('class', function(i, value) {
                    return 'in ' + value;
                });
                // Show all the parent items
                $("a[href~='" + pageURL + "']").parents('div.collapse').collapse('show');
            } else { // Maybe there's a path in the href
                foundLi = $("a[href$='" + pageURL + "']");
	        if (foundLi.get(0)) {
                    // Make it active
                    $("a[href$='" + pageURL + "']").parent("div").toggleClass('active');
                    // Make the parent collapsable element the default
                    $("a[href$='" + pageURL + "']").parent('div.collapse').attr('class', function(i, value) {
                        return 'in ' + value;
                    });
                    // Show all the parent items
                    $("a[href$='" + pageURL + "']").parents('div.collapse').collapse('show');
            }
                }
            
        }
    }
}

/*
 * Change the state of the +/- icon on the side nav
 */
function changeTocIconState() {
    $('.accordion').on('show hide', function (n) {
        $(n.target).siblings('.accordion-heading').each(function() {
            $(this).find('a.toc-plus-block i').toggleClass('icon-plus icon-minus');
        });
    });
}

/*
 * Clear the search box
 */
function clearSearch(id) {
	$('.search-box').val('');
}

/*
 *  Make the elements the same height, but not on the phone
 */
function eqHeights() {
	//Reset the heights to natural state
	$('.toccontent').css("height", "");
	$('.content').css("height", "");
	if ($('.toccontent').is(':visible') && ($(window).width() > 768)) {
		//Set the maximum height
		var max_height = Math.max($('.toccontent').height(),
								$('.content').height());
		$('.toccontent').height(max_height);
		$('.content').height(max_height);
	}
};

