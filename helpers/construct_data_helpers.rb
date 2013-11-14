#Copyright (c) 2013,salesforce.com 
#All rights reserved.

#Redistribution and use in source and binary forms, with or without
#modification, are permitted provided that the following conditions
#are met:

#Redistributions of source code must retain the above copyright
#notice, this list of conditions and the following disclaimer.

#Redistributions in binary form must reproduce the above copyright
#notice, this list of conditions and the following disclaimer in the
#documentation and/or other materials provided with the distribution.

#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
#"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
#LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
#A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
#HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
#BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
#OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
#AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
#WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#POSSIBILITY OF SUCH DAMAGE.


=begin
 Helper module to construct data and insert it into the database 
=end
module ConstructDataHelpers
   
  ##
  #Construct a design document
  #
  def construct_design_doc(fileName, locales)
    #specify the path directly to the lucene file
    fileName = Pathname.new(File.dirname(__FILE__) + "/../" + fileName).cleanpath
    file = File.open(fileName, "rb")
    content = file.read
      
    #if locales are specified, then replace the <placeholder> content with a delimited list of locales
    unless(locales.nil?)
      #replace the locales
      count = 0
      delimitedLocales = ""
      locales.each do |locale|
        #if it's the first item in the list, don't add a comma
        if(count > 0)
          delimitedLocales << ","
        end
        delimitedLocales << "'#{locale}'"
        count += 1
      end
      #replace the content
      if (content.include?("'<placeholder>'"))
        content["'<placeholder>'"] = delimitedLocales
      end
    end
    return content
  end
  
  # Map the lang-locale string to a analyzer for search in cloudant
  def locales2languages(locales = [Settings[:DEFAULT_LOCALE]])
    analyzers = ""
    unless(locales.nil?)
      locales.each_with_index do |locale,index|
        if (index+1 == locales.length)
          sep = ""
        else
          sep = ","
        end
        case locale.to_s
        when "da-dk"
          analyzers.concat(":'da-dk_content => 'danish',:'da-dk_title' => 'danish'''#{sep}")
        when "de-de"
          analyzers.concat(":'de-de_content' => 'german', ':de-de_title' => 'german'#{sep}")
        when "en-us"
          analyzers.concat(":'en-us_content' => 'english', :'en-us_title' => 'english'#{sep}")
        when "es-es"
          analyzers.concat(":'es-es_content' => 'spanish', :'es-es_title' => 'spanish'#{sep}")
        when "fi-fi"
          analyzers.concat(":'fi-fi_content' => 'finnish', :'fi-fi_title' => 'finnish'#{sep}")
        when "fr-fr"
          analyzers.concat(":'fr-fr_content' => 'french', :'fr-fr_title' => 'french'#{sep}")
        when "it-it"
          analyzers.concat(":'it-it_content' => 'italian', :'it-it_title' => 'italian'#{sep}")
        when "ja-jp"
          analyzers.concat(":'ja-jp_content' => 'japanese', :'ja-jp_title' => 'japanese'#{sep}")
        when "ko-kr"
          analyzers.concat(":'ko-kr_content' => 'cjk', :'ko-kr_title' => 'cjk'#{sep}")
        when "nl-nl"
          analyzers.concat(":'nl-nl_content' => 'dutch', :'nl-nl_title' => 'dutch'#{sep}")
        when "pt-br"
          analyzers.concat(":'pt-br_content' => 'brazilian', :'pt-br_title' => 'brazilian'#{sep}")
        when "ru-ru"
          analyzers.concat(":'ru-ru_content' => 'russion', :'ru-ru_title' => 'russion'#{sep}")
        when "sv-se"
          analyzers.concat(":'sv-se_content' => 'swedish', :'sv-se_title' => 'swedish'#{sep}")
        when "th-th"
          analyzers.concat(":'th-th_content' => 'thai', :'th-th_title' => 'thai'#{sep}")
        when "zh-cn"
          analyzers.concat(":'zh-cn_content' => 'cjk', :'zh-cn_title' => 'cjk'#{sep}")
        when "zh-tw"
          analyzers.concat(":'zh-tw_content' => 'cjk', :'zh-tw_title' => 'cjk'#{sep}")
        end
      end
    end
    return analyzers
  end
end
