function(doc){
  function indexContent(locale) {
        if (doc.locale === locale) {
          index(locale + '_content', doc['search_content'], {'store':'yes'});
          index(locale + '_title', doc['title'], {'store':'yes'});
        }
    }

  if(doc.search_content) {
    var locales = ['<placeholder>'];
    
    for (var i = 0; i < locales.length; i++) {
      indexContent(locales[i]);
    }
  
    if (doc.locale === '#{Settings[:DEFAULT_LOCALE]}') {
      index('default', doc['search_content'], {'store':'yes'});  
    }

    index('uri', doc['name'], {'store':'yes'});
    index('updated', doc['updated'], {'store':'yes'});
    index('version', doc['version'], {'store':'yes'});

    index('app_area', doc['app_area'], {'store':'yes'});
    index('role', doc['role'], {'store':'yes'});
    index('edition', doc['edition'], {'store':'yes'});
    index('topic_type', doc['topic_type'], {'store':'yes'});
    index('technology', doc['technology'], {'store':'yes'});
    index('deliverable_title', doc['deliverable_title'], {'store':'yes'});
    index('deliverable_type', doc['deliverable_type'], {'store':'yes'});
    index('deliverable_home', doc['deliverable_home'], {'store':'yes'});
  }
}
