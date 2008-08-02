require 'redcloth'

module Wikify
  def wikify(options = {})
    return "" if empty?

    marker = '%!%!%'
    num = 0
    replace = [ ]

    # @code@ is a shortcut for {{{code}}}
    out = self.gsub( /(!?)(@(\S.*?\S)@)/ ) do |match|
      $1 == "!" ? $2 : "{{{#{$3}}}}"
    end

    # Code Blocks
    #   replace {{{triple braced blocks}}}
    out.gsub!( /(!?)\{\{\{(\r?\n)?(.*?)(\r?\n)?\}\}\}/m ) do |match|
      unless $1 == "!"
        r = $3
        p1, p2 = "", ""
        p1, p2 = "<pre class=\"code\">", "</pre>" if $2 =~ /^[\n\r]/
        replace[num+=1] = p1 + "<code>" + "#{r}" + "</code>" + p2
        marker + num.to_s + marker
      else
        match[1,match.length]
      end
    end

    # Wiki Links
    #   replace "[bracketed words]" of the following types:
    #     [wiki page name]
    #     [wiki page name|display text]
    #     [http://externallink.com]
    #     [http://externallink.com|display text]
    #     [http://externallink.com display text]
    #   do not replace if preceded by an "!"
    out.gsub!( /(!?)\[(.*?)(\|(.*?))?\]/ ) do |match|
      if $1 == "!"
        match[1,match.length]
      else
        if $2.include? "://"
          parts = $2.split(' ')
          class_str = "external"
          href = parts.shift
          link_text = $4 || ( parts.empty? ? $2.gsub(/^https?:\/\/(www\.)?/, '') : parts.join(' ') )
        else
          class_str = (defined? Page && Page.exists?($2)) ? "" : "notfound"
          href = "/page/#{URI.encode($2.strip)}"
          link_text = $4 || $2
        end
        class_str &&= ' class="' + class_str + '"'
        replace[num+=1] = '<a href="' + href + '"' + class_str + '>' + link_text + '</a>'
        marker + num.to_s + marker
      end
    end

    # mask <a> links from URL autolinking
    out.gsub!( /<a[^>]*>/ ) do |match|
      replace[num+=1] = match
      marker + num.to_s + marker
    end

    # protect <pre> blocks from hard breaks and URL autolinking
    out.gsub!( /<pre>.*?<\/pre>/m ) do |match|
      replace[num+=1] = match
      marker + num.to_s + marker
    end

    # autolink URLs
    # look for http://url.com
    # don't link if preceded by "!"
    out.gsub!( /(!?)(https?:\/\/(www\.)(\S+))([.!?,)]?)/ ) do |match|
      if $1 == '!'
        $2 + $5
      else
        replace[num+=1] = '<a href="' + $2 + '" class="external">' + $4 + '</a>'
        marker + num.to_s + marker + $5
      end
    end

    # hard breaks (the RedCloth :hard_breaks option seems to be broken)
    out.gsub!( /([^\s|][ \t]*?)(\r?\n[^\r\n])/ ) do |match|
      "#{$1}<br />#{$2}"
    end

    # replace temporary tags
    out.gsub!( Regexp.new(marker + '([0-9]+)' + marker) ) do |match|
      replace[$1.to_i]
    end

    # RedCloth Textile parsing
    RedCloth.new(out, [:no_span_caps]).to_html(
                                 :block_textile_table,
                                 :block_textile_lists,
                                 :block_textile_prefix,
                                 :inline_textile_image,
                                 :inline_textile_span,
                                 :inline_textile_link,
                                 :glyphs_textile
                                )
  end
end

class String
  include Wikify
end
