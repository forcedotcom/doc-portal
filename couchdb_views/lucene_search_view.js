function(doc) { 
  var res=new Document(); 
  function indexContent(locale) {
    if (doc.locale === locale) {
      res.add(doc.search_content, {field: locale + '_content', store: 'yes'});
      res.add(doc.title, {field: locale + '_title', store: 'yes'});
    }
  }
  if(doc.search_content) {
    var locales = ['<placeholder>'];
    for (var i = 0; i < locales.length; i++) {
      if (doc.locale === locales[i]) {
        indexContent(locales[i]);
      }
    }
    res.add(doc.title, {field: 'title', store: 'yes'});
    res.add(doc.name, {field:'uri', store: 'yes'}); 
    res.add(doc.updated, {field:'updated', store: 'yes'});
    res.add(doc.version, {field: 'version', store: 'yes'})

    res.add(doc.app_area, {field: 'app_area', store: 'yes'})
    res.add(doc.role, {field: 'role', store: 'yes'})
    res.add(doc.edition, {field: 'edition', store: 'yes'})
    res.add(doc.topic_type, {field: 'topic_type', store: 'yes'})
    res.add(doc.technology, {field: 'technology', store: 'yes'})
    res.add(doc.deliverable_title, {field: 'deliverable_title', store: 'yes'})
    res.add(doc.deliverable_type, {field: 'deliverable_type', store: 'yes'})
    res.add(doc.deliverable_home, {field: 'deliverable_home', store: 'yes'})

    return res; 
  } 
}
