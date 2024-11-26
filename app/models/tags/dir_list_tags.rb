# See "dir_list_tags_extension.rb" for details.

module Tags::DirListTags
  include Radiant::Taggable

  desc %{
Executes a Perl script at the given path and includes its <code>stdout</code> result in the page. Output whatever type of text is used by that page, or if wanting to output HTML into a page with a non-HTML filter, wrap the tag in <code><notextile>...</notextile></code> or equivalent for the filter in use.

If the path you require includes spaces or other special characters, escape them with a backslash.

<pre><code><r:perl_script_output location="/home/foo/perl_script.pl" /></code></pre>
}
  tag "perl_script_output" do |tag|
    unless location = tag.attr['location']
      raise TagError.new("`perl_script_output' tag must contain `location' attribute")
    end

    command = "`perl #{location}`"
    result = eval(command)

    if ($?.success?)
      result
    else
      raise TagError.new("Perl command failed with exit status #{$?.exitstatus}")
    end
  end

  desc %{
Enumerates the contents of a directory within <code><li>...</li></code> containers. Environment variable SERVER_DOCUMENT_ROOT must be set and is used as the root path for directory enumeration. Even so, directory traversal is not prevented so only use this tag when content editors are trusted.

You must wrap output in <code><notextile>...</notextile></code> or an equivalent if you're using a filtered page type since the tag's value is raw HTML. An outer container such as <code><ul></code> or <code><ol></code> must be placed around the tag as only the inner list items are returned.

<pre><code><r:linked_directory_listing dir="search_directory" /></code></pre>

Certain magic directories are ignored (CVS, .svn).
}
  tag "linked_directory_listing" do |tag|
    unless dir = tag.attr['dir']
      raise TagError.new("`linked_directory_listing' tag must contain `dir' attribute")
    end

    docroot = ENV['SERVER_DOCUMENT_ROOT']
    # See description text in "dir_list_tags_extension.rb" for details.
    raise TagError.new("You must make environment variable SERVER_DOCUMENT_ROOT available to Radiant") if (docroot.nil?)

    "<notextile>" + recursive_directory_list_in_li_tags(docroot, dir) + "</notextile>"
  end

  desc %{
Renders a set of HTML tables that enumerate a directory in a parsed, augmented fashion. Environment variable SERVER_DOCUMENT_ROOT must be set and is used as the root path for directory enumeration. Even so, directory traversal is not prevented so only use this tag when content editors are trusted.

Output is wrapped in <code><notextile>...</notextile></code> on assumption of Textile filtering.

Certain magic directories are ignored (CVS, .svn). The directory can contain a file 'config.yml' in subdirectory 'config', which works as described below. The intention is that each table corresponds to a group of files in some kind of file drop box, with a header above naming the group.

<pre><code><r:linked_parsed_directory_listing dir="search_directory"
                     link_base="foo"
                     link_icon="bar" /></code></pre>

*Drop box display configuration*

Filenames of entries in the drop box are converted by looking for everything up to the first '.' and treating this as a leafname. The leafname is looked up in the configuration hash. After the '.', anything up to but not including a filename extension is treated as a version string. Filename extensions are assumed to be present and form a three-letter code after a final '.'. For 'tar.gz', use 'tgz'.

Each entry in the tables of items can have a 'Details' column. These contain links, formed by appending the leafname as described above to whatever value is provided in the Radiant tag's "link_base" attribute. If the attribute is omitted, the column is omitted too. If included, the links contain the text "Details". To use an icon instead, provide a path to the icon in the "link_icon" attribute.

Rails helper methods are used to create human-readable versions of default strings from the path components. For examples, please see <a href="http://rails.rubyonrails.org/classes/ActiveSupport/CoreExtensions/String/Inflections.html" target="_blank">this part of the Rails API</a>.

The configuration file is optional and allows the writer to both override strings generated with the above method, as well as specify things which cannot be determined purely from the drop box filenames. Syntax are as follows:

<pre><code>        appname_1:
  config_item_1: config_value
  config_item_2: config_value
  config_item_3: config_value

appname_2:
  config_item_1: config_value
  config_item_2: config_value
  config_item_3: config_value</code></pre>

...and so-on, i.e. it's a very simple usage of the YAML syntax.

*Items which override values determined from the filename*

<pre><code>        name:    'Component display name"
version: 'Version string'
icon:    'Icon filename name' (no path components allowed)
link:    'Details link' (Wiki by default; for links within the
                         ROOL site, use "/foo/bar/baz.html" -
                         i.e. do NOT include the host name)</code></pre>

*Items which are optional*

<pre><code>        info:  'One-liner description' (else "-" by default)
group: 'Group name' (groups are sorted alphabetically and
                     ungrouped items are listed afterwards;
                     use singular non-abbreviated forms)</code></pre>

*Icons and overall layout*

Icons must be placed in subdirectory @icons@, again within the drop box, so that it forms a tree as follows:

<pre><code>        dropbox_root
|
+--config
|  |
|  +--config.yml
|
+--icons
|  |
|  +--app1.png
|  +--app2.png
|  +--etc...
|
+--app1.vsnstring.zip
+--app2.vsnstring.zip
+--etc...</code></pre>

If an icon cannot be found, @icons/_default.png@ is tried. If that doesn't exist either, the relevant table cell will be left blank.
}
  tag "linked_parsed_directory_listing" do |tag|
    unless dir = tag.attr['dir']
      raise TagError.new("`linked_parsed_directory_listing' tag must contain `dir' attribute")
    end

    link_base = tag.attr['link_base']
    link_icon = tag.attr['link_icon']

    docroot = ENV['SERVER_DOCUMENT_ROOT']
    # See description text in "dir_list_tags_extension.rb" for details.
    raise "You must make environment variable SERVER_DOCUMENT_ROOT available to Radiant" if (docroot.nil?)

    "<notextile>" + parsed_directory_list_in_table(docroot, dir, link_base, link_icon) + "</notextile>"
  end

  # Support the various directory listing tags. Returns an array of items
  # describing a directory contents and the contents of any subdirectories
  # as a flat unsorted list. The last parameter is 'false' to avoid scanning
  # to a level beyond the current directory.
  #
  require 'find'
  #
  def recursive_directory_list(base, dir, recurse = true)
    # Partly based on:
    #
    #   http://www.oreillynet.com/onjava/blog/2006/03/recursive_directory_list_with.html

    excludes = [ 'CVS', '.svn' ]
    collect  = [];
    dir      = File.join( base, dir )
    first    = true

    Find.find(dir) do |path|
      if FileTest.directory?(path)
        if (recurse == false)
          if (first)
            first = false
            next
          else
            Find.prune
          end
        else
          if (excludes.include?(File.basename(path)))
            Find.prune # Don't look any further into this directory.
          else
            next
          end
        end
      else
        mod = File.mtime(path)
        collect.push({
                       :leaf => File.basename(path),
                       :mod  => File.mtime(path),
                       :link => "#{path[base.length..-1]}?#{mod.tv_sec}",
                       :size => number_to_human_size(File.size(path))
                    });
      end
    end

    return collect
  end

  # Support the linked_directory_listing tag.
  #
  def recursive_directory_list_in_li_tags(base, dir)
    html = ''

    recursive_directory_list(base, dir).sort do |x, y|
      #x[:leaf] <=> y[:leaf]
      y[:mod] <=> x[:mod]
    end.each do |entry|
      html << "<li><a href=\"#{entry[:link]}\"><b>#{entry[:leaf]}</b></a> (#{entry[:size]})<br /><small>Last modified #{entry[:mod]}</small></li>"
    end

    html = '<li>There are no files currently available.</li>' if html.empty?
    return html
  end

  # Ripped straight out of ActionView::Helpers::NumberHelper.
  #
  def number_to_human_size(size)
    case
      when size < 1.kilobyte
        '%d Bytes' % size
      when size < 1.megabyte
        '%.1f KB'  % (size / 1.0.kilobyte)
      when size < 1.gigabyte
        '%.1f MB'  % (size / 1.0.megabyte)
      when size < 1.terabyte
        '%.1f GB'  % (size / 1.0.gigabyte)
      else
        '%.1f TB'  % (size / 1.0.terabyte)
    end.sub('.0', '')
  rescue
    nil
  end

  # Support the linked_parsed_directory_listing tag.
  #
  def parsed_directory_list_in_table( base, dir, link_base, link_icon )

    list = recursive_directory_list(base, dir, false)

    # Load the configuration file, if provided

    begin
      configuration = YAML.load_file( File.join( base, dir, 'config', 'config.yml' ) )
    rescue
      configuration = {}
    end

    # Assemble the configured strings within groups

    groups = {}

    list.each do |entry|

      # Parser: Various charaters, a dot, then: one or more digits (0-9)
      # followed by an optional dot, repeated at least once, this whole
      # assembly optional, recording only the collection of digits and
      # dots, not individual digits-plus-dots sets ("(?:" => don't include
      # this group in the match data). Then zero or more other characters,
      # non-greedy.

      leaf      = entry[:leaf]
      regexp    = /^(.*?)\.((?:[0-9]+\.?)+)?(.*?)$/
      scanned   = leaf.scan( regexp )[ 0 ]
      base_name = scanned[0]
      version   = (scanned[1] || '').chomp('.') # May have trailing '.'
      filetype  = scanned[2] || ''

      config    = configuration[base_name] || configuration[leaf] || {}

      name      = config['name']    || base_name.humanize.titleize
      version   = config['version'] || ((version.empty?) ? '-' : version)
      icon      = config['icon']    || "#{base_name}.png"
      link      = config['link']    || "#{link_base}#{name}"
      info      = config['info']    || '-'
      group     = config['group']   || :Ungrouped
      md5       = config['md5']
      md5_time  = config['md5_time']

      unless ( md5.nil? || md5_time.nil? )
        md5, md5_time = nil if ( entry[:mod] > md5_time )
      end

      icon = "#{dir}/icons/#{icon}"

      unless (File.exist?("#{base}#{icon}"))
        icon = "#{dir}/icons/_default.png"
        unless (File.exist?("#{base}#{icon}"))
          icon = ''
        end
      end

      # Change "foo/bar/baz" to "foo / bar / baz" - i.e. a "/" without a
      # space either side is changed to a slash with a space on each side.
      # Helps enormously with line wrapping in browsers.

      info.gsub!( /([^< ])\/([^ ])/, '\1 / \2' )

      groups[ group ] = [] if (groups[ group ].nil?)
      groups[ group ].push( {
        :name    => name,
        :version => version,
        :icon    => icon,
        :link    => link,
        :info    => info,
        :md5     => md5,
        :raw     => entry
      } )
    end

    html = ''

    groups.keys.sort do | x, y |

      # Sort the groups, pushing keys of Symbol class (i.e. ':Ungrouped')
      # to the end.

      if ( x.class == Symbol )
        1
      elsif( y.class == Symbol )
        -1
      else
        x <=> y
      end

    end.each do | group_key |

      # For each sorted key, output a table.

      dscwd = link_base ? '40%' : '50%'

      count = 0
      html << "<h3>#{group_key}<a name=\"#{group_key.to_s.gsub(/\W/, '_').downcase}\" style=\"text-decoration: none; border-bottom: none; font-size: 1px\">&nbsp</a></h3>\n"
      html << "<table width=\"100%\" class=\"parsed_directory_listing\" border=\"0\">\n"
      html << "<tr><th width=\"10%\">Icon</th><th width=\"20%\" align=\"left\">Name,&nbsp;date&nbsp;&amp;&nbsp;MD5</th><th width=\"#{dscwd}\" align=\"left\">Description</th><th width=\"10%\">Version</th><th width=\"10%\">Size</th>"
      html << "<th width=\"10%\">Details</th>" if (link_base)
      html << "</tr>\n"

      # Sort the items inside each group by name and output each in a table
      # row.

      groups[group_key].sort do | x, y |

        x[:name] <=> y[:name]

      end.each do |entry|

        row_class = (count % 2 == 0) ? 'even' : 'odd'
        count += 1

        html << "<tr class=\"#{row_class}\">"

        if (entry[:icon].empty?)
          html << "<td>&nbsp;</td>"
        else
          html << "<td align=\"center\"><a href=\"#{entry[:raw][:link]}\" class=\"img\"><img src=\"#{entry[:icon]}\" alt=\"icon\" /></a></td>"
        end

        time = entry[:raw][:mod]

        if (time.nil?)
          tstr = ''
        else
          tstr = "<div class=\"parsed_directory_listing_datestamp\">" <<
                 "#{time.strftime('%Y-%m-%d')} " <<
                 "#{time.strftime('%H:%M:%S')}" <<
                 "</div>"
        end

        md5 = entry[:md5]

        if (md5.nil?)
          md5str = ''
        else
          md5str = "<div class=\"parsed_directory_listing_md5\">#{ md5 }</div>"
        end

        html << "<td><a name=\"#{entry[:name].gsub(/\W/, '_').downcase}\" href=\"#{entry[:raw][:link]}\">#{entry[:name]}</a>#{tstr}#{md5str}</td>"
        html << "<td class=\"can_wrap\">#{entry[:info]}</td>"
        html << "<td align=\"center\">#{entry[:version]}</td>"
        html << "<td align=\"center\">#{entry[:raw][:size]}</td>"

        if (link_base)
          if (link_icon)
            html << "<td align=\"center\"><a href=\"#{entry[:link]}\" class=\"img\"><img src=\"#{link_icon}\" alt=\"info\" /></a></td>"
          else
            html << "<td align=\"center\"><a href=\"#{entry[:link]}\">Details</a></td>"
          end
        end

        html << "</tr>\n"
      end

      html  << "</table>\n\n"
    end

    html = '<p>There are no files currently available.</p>' if (list.empty?)
    return html
  end

end
