class PaginationListLinkRenderer < WillPaginate::Sinatra::LinkRenderer
  # Override the renderer for will_paginate to work with Bootstrap 3

  protected
  def page_number(page)
    unless page == current_page
       tag(:li,link(page, page, :rel => rel_value(page)))
    else
       tag(:li, link(page, "#"), :class => "disabled")
    end
  end
    
  def previous_or_next_page(page, text, classname)
      if page
        tag(:li, link(text, page), :class => classname)
      else
        tag(:li, link(text, "#"), :class => classname + ' disabled')
      end
  end

  def html_container(html)
      tag(:div, tag(:ul, html, container_attributes), :class => 'pagination pagination-centered')
  end
  
end



