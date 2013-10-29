# -*- coding: utf-8 -*-
module HamlHelpers
  
  # Return the value of the title of the topic as part of search results.
  # @param result [Hash] the search result hash
  # @return [String] the title of the topic
  # @todo Add exception handling
  def search_result_title(result)
    title_field_name = "#{@locale}_title"
    return result["fields"][title_field_name]
  end
  
  # Return a snippet of the topic that has the search queries highlighted.
  # @param query [String] the full search query
  # @param result [Hash] the search result hash
  # @return [String] a snippet with HTML highlights for the search terms
  def search_result_highlighted(query, result)
    highlight_length = Settings[:SNIPPET_LENGTH]
    content_field_name = "#{@locale}_content"
    search_result = Rack::Utils.escape_html(result["fields"][content_field_name])

    # Shorten the returned string to the value of highlight_length or
    # smaller, depending on word boundaries. 
    # Find the location of a highlighted string.
    highlight_index = search_result.index(/#{get_query_as_regex(query)}/i)

    # Fallback in case nothing is highlighted
    highlight_index ||= 0
    
    # What character should we start on?  If it's too close to the
    # beginning, use the first character
    result_start = ((highlight_length / 2) > highlight_index ) ? 0 : highlight_index - (highlight_length / 2)
    
    #create the snippet
    if (result_start == 0)
      #if the term was found at the beginning, strip off the last word
      snippet = search_result[result_start, highlight_length].sub(/^(.*)[\s][^\s]*/m, '\1')
    elsif (result_start + highlight_length > search_result.length)
      #if the term was found at the end, strip off the first word
      snippet = search_result[result_start, highlight_length].sub(/^[^\s]*[\s](.*)/, '\1')
    else
      # Back off result_start a little so the user has a couple of words context.
      # Then use a regexp to make sure the result doesn't start, or
      # end, in the middle of a word.
      # The conditional is there to ensure that if the result starts
      # at 0, the first word isn't stripped.
      snippet_start = result_start > 25 ? result_start - 25 : 0
      snippet =  search_result[snippet_start, highlight_length].sub(/^[^\s]*[\s](.*)[\s][^\s]*/m, '\1')
      snippet = (snippet =~ /^[A-Z]/) ? snippet : "…#{snippet}"
    end
    
    # @todo Make this work for all lucene queries
    # Currently supports:
    # term
    # term term term ...
    # "term term"
    # term "term term" term
    # term -term
    # term NOT term
    if (query.include?('&quot;'))
      # The query includes a quoted string
      # Turn the query into an array. Each array entry represents either
      # a search term or a quoted group.
      query_fixed_for_quoted_groups = query.split('&quot;').reject(&:empty?)
      query_fixed_for_quoted_groups.each { |item|
        unless (item.nil? || item.empty?)
          query_term_regexp = get_query_as_regex(item.strip)
          snippet.gsub!(/#{query_term_regexp}/i, '<b>\0</b>')
        end
      }
    else
      query_term_regexp = get_query_as_regex(query)
      snippet.gsub!(/#{query_term_regexp}/i, '<b>\0</b>')
    end

    return snippet
  end
  
  # Clean the search term to do a basic snippet search
  def get_query_as_regex(query)
    #lucene syntax
    regex = query
        .gsub(/\?/, ".")
        .gsub(/\*/, '[^\s]*')
        .gsub(/&quot;(.*)&quot;/, '(\1)')
        .gsub(/\sAND\s/, "|")
        .gsub(/\sOR\s/, "|")
        .gsub(/[\s]?NOT [^\s]*/, "")
        .gsub(/\+/, '')
        .gsub(/\s\-[^\s]*/, '')
        
    #clean up the query
    regex = regex.gsub(/\s{2,}/, ' ')
    
    
    #if it's not a phrase, replace all space with an or
    unless(query.include?("&quot;"))
      regex = regex.gsub(/\s/, '|')
    end
    
    if (regex.nil? || regex.empty?)
      return "<EMTPY>" #this should never happen
    end
    return regex
  end
  
  ###
  # Return the application name to use
  # @param use_deliverable_title [boolean] Specifies whether or not to default to the deliverable title
  # @param app_name [String] The application name that may be used as the full app name
  # @return [String] The application's name
  def get_full_app_name(use_deliverable_title = false, app_name = nil)
    if (app_name.nil? || app_name.empty?)
      if (Settings[:APP_TYPE].nil? || t[Settings[:APP_TYPE].to_sym].nil?) #Use the generic application name
        return t.default.portal_title
      elsif (use_deliverable_title) #Return the deliverable title
        return t[Settings[:APP_TYPE].to_sym].deliverable_title
      else  #Return the portal title
        return t[Settings[:APP_TYPE].to_sym].portal_title
      end
    else
      return app_name
    end
  end
end
