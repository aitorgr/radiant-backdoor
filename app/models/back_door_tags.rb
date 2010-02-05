module BackDoorTags
  include Radiant::Taggable

  class TagError < StandardError; end

  # don't remove the comment below, it's used by README.erb
  # ruby
  desc %{
    Executes the content of the tag body as Ruby code and renders the returned value.

    *Usage:*

      <pre><code> <r:ruby> [ruby code] </r:ruby> </code></pre>

    *Example:*

      <pre><code> With this fine extension you have access to all this information: <r:ruby> self.inspect </r:ruby> </code></pre>
      <pre><code> This machine identifies itself as <r:ruby> `uname -a` </r:ruby> </code></pre>
  }
  tag "ruby" do |tag|
    eval( tag.expand)
  end

  # don't remove the comment below, it's used by README.erb
  # erb
  desc %{
    Executes the content of the tag body as ERB code and renders the returned value.

    *Usage:*

      <pre><code> <r:erb> [ERB template] </r:erb> </code></pre>

    *Example:*

      <pre><code>
      <r:erb>
        <table>
          <tr>
            <th>name</th> <th>password</th> <th>uid</th> <th>gid</th> <th>class</th> <th>home_dir</th> <th>shell</th>
          </tr>
          <%  File.open( "/etc/passwd") do |io|
                while line = io.gets
                  next if line =~ /^\s*#/
                  fields = line.split( ":")
          %>
                  <tr>
                   <% fields.each do |field| %>
                    <td> <%= field %> </td>
                  <% end %>
                  </tr>
          <%    end
              end
          %>
        </table>
      </r:erb>
      </code></pre>

    *Caveats:*

    When using ruby looping constructs inside a ERB template, the Radius tags present in the template get expanded
    only once, and then "repeated" multiple times by the Ruby code.  For example, the following code:

      <r:erb>
        <% 5.times do %>
          <%= <r:cycle values="1, 2, 3, 4, 5"/> %>
        <% end %>
      </r:erb>

    returns "11111", though intuitively it should return "12345" (ignoring whitespace).  This is because the <r:cycle>
    tag gets expanded only once.

    Nearly always this is irrelevant, since Radiant tags are all side effect free, that is, they always return the same value
    when called multiple times in the same context.  Notable exceptions are the <r:cycle> and <r:random> tags.

    For the case of tags with side effects, use the <r:expand> tag as documented in the description for that tag.
  }
  tag "erb" do |tag|
    ERB.new( tag.expand).result( binding)
  end

  # don't remove the comment below, it's used by README.erb
  # expand
  desc %{
    When used inside an "r:erb" tag, it expands the tag named in the "tag" attribute with the given attributes.

    This tag avoids the "tag only expands once inside ruby loops" problem described in the "r:erb" tag.  It takes a required
    "tag" attribute that identifies an existing tag, and expands that tag passing it the rest of attributes.

    NOTE that this tag must be used inside an ERB <%= %> construct.

    *Usage:"

      <pre><code> <r:expand tag="tag-name" [ tag-name-attribute="value"]* /> </code></pre>

    *Example:"

      <r:erb>
        <% <r:cycle values="1, 2, 3, 4, 5" reset="true"/> %>
        <% 5.times do %>
          <%=
          <r:expand tag="cycle" values="1, 2, 3, 4, 5"/>
          %>
        <% end %>
      </r:erb>

    renders "23451" (ignoring whitespace)
  }
  tag "erb:expand" do |tag|
    raise TagError.new( "'expand' tag must contain a 'tag' attribute.") unless tag.attr.has_key?( "tag")
    tag_name = tag.attr.delete( "tag")
    "tag.render( \"#{tag_name}\", #{tag.attr.inspect})"
  end

  # don't remove the comment below, it's used by README.erb
  # if
  desc %{
    Renders the tag body if the given Ruby expression evaluates to true. If not it renders an inner "r:else" tag, if present. Note that there are some caveats regarding the "r:else" tag, look the description of if for more information.
    
    *Usage:*

      <pre><code> <r:if cond="[ruby expression]"> [HTML content] </r:if> </code></pre>
      <pre><code> <r:if cond="[ruby expression]"> [HTML content] <r:else> [HTML content] </r:else> </r:if> </code></pre>

    *Example:*

      <pre><code>
      <r:if cond="request.env[ 'HTTP_USER_AGENT'] =~ /MSIE/">
        <!-- Internet Explorer needs some ugly hacks to render PNG images with transparency -->
        <div id="logo" style="filter:progid:DXImageTransform.Microsoft.AlphaImageLoader(src=\'/images/logo.png\',sizingMethod=\'scale\');"></div>
        <r:else>
          <!-- the rest of browsers just make it rigth -->
          <img src="/images/logo.png" id="logo" alt="Logo"/>
        </r:else>
      </r:if>
      </code></pre>

    *Caveats:*

    There are two caveats with the "r:if/unless" and "r:else" tags (used "r:if" as example, but equally applicable to "r:unless"):

    * to allow the expansion of an "r:else" part inside a "r:if" tag, the containing "r:if" tag must be
      expanded even if the condition of the "r:if" tag evaluates to false.  In this case, the body of the
      "r:if" tag is ignored.  This is not a problem unless the body of the "r:if" tag has "side effects":

        <pre><code>
        <r:ruby>
          @counter = 0
          ""
        </r:ruby>
        <r:if cond="false">
          This text is evaluated and ignored, but the following "ruby" tag has a side effect that affects the "else" tag
          <r:ruby> @counter += 1 </r:ruby>
          <r:else> <r:ruby> @counter </r:ruby> </r:else>
        </r:if>
        </code></pre>

    * the rendered value of the "r:if" tag contains also any data after an "r:else" tag:

        <pre><code>
        <r:if cond="true">
          Hello
          <r:else> Hello Radiant! </r:else>
          world!
        </r:if>
        </code></pre>

      evaluates to "Hello world!" (ignoring whitespace)
  }
  tag "if" do |tag|
    raise TagError.new( "'if' tag must contain a 'cond' attribute.") unless tag.attr.has_key?( "cond")
    cond = eval( tag.attr[ "cond"])
    tag.globals.else_cond = !cond       # we pass to the <r:else> tag the flag that specifies if it should evaluate or not
    tag.globals.else_result = ""        # an <r:else> tag inside this <r:if> tag can modify this
    if_result = tag.expand              # we expand the tag in any case, this is because the <r:else> tag inside (if any) must be evaluated
    return cond ? if_result: tag.globals.else_result
  end

  # don't remove the comment below, it's used by README.erb
  # unless
  desc %{
    The inverse of the "r:if" tag.  Refer to the description of the "r:if" tag for complete documentation.
  }
  tag "unless" do |tag|
    raise TagError.new( "'unless' tag must contain a 'cond' attribute.") unless tag.attr.has_key?( "cond")
    cond = eval( tag.attr[ "cond"])
    tag.globals.else_cond = cond        # we pass to the <r:else> tag the flag that specifies if it should evaluate or not
    tag.globals.else_result = ""        # an <r:else> tag inside this <r:else> tag can modify this
    if_result = tag.expand              # we expand the tag in any case, this is because the <r:else> tag inside (if any) must be evaluated
    return cond ? tag.globals.else_result: if_result
  end

  # don't remove the comment below, it's used by README.erb
  # else
  desc %{
    Specifies the "else" part for "r:if" and "r:unless".  Refer to the description of the "r:if" tag for complete documentation.
  }
  [ "if:else", "unless:else"].each do |tag_id|
    tag tag_id do |tag|
      if tag.globals.else_cond
        tag.globals.else_result = tag.expand
      end
      ""
    end
  end

  # don't remove the comment below, it's used by README.erb
  # tag
  desc %{
    Defines a new tag, which can subsequently be used as a normal Radius tag.  It can be seen as a programmable and parametrized snippet.

    The new tag receives the tag context with the standard name "tag" (see the example below).  Note that this tag must be rendered by
    Radiant before the tag it defines is used.  This typically means that this tag must be used early in a page layout.
    
    *Usage:*

    <pre><code> 

      <!-- define a new tag -->
      <r:tag name="tag-name">
        [Ruby code]
      </r:tag>

      <!-- use the new defined tag -->
      <r:tag-name [params]>
        [content]
      </r:tag-name>

    </code></pre>

    *Example:*

    <pre><code>

      <!-- define a new tag -->
      <r:tag name="originating_ip">
        @request.remote_ip
      </r:tag>

      <!-- use it -->
      Article posted from IP <r:originating_ip />

    </code></pre>
  }
  tag "tag" do |external_tag|
    raise TagError.new( "'tag' tag must contain a 'name' attribute.") unless external_tag.attr.has_key?( "name")
    code = external_tag.expand
    external_tag.context.define_tag( external_tag.attr[ "name"]) do |tag|
      eval( code)
    end
  end

  # don't remove the comment below, it's used by README.erb
  # erb_tag
  desc %{
    Same functionality as the "tag" tag but the body of the tag is interpreted as ERB code.  Handy for heavy parametrized templating.

    *Usage:*

    <pre><code> 

      <!-- define a new tag -->
      <r:tag name="tag-name">
        [Ruby code]
      </r:tag>

      <!-- use the new defined tag -->
      <r:tag-name [params]>
        [content]
      </r:tag-name>

    </code></pre>

    *Example:*

    <pre><code>

      <!-- define a new tag -->
      <r:erb_tag name="article">
        <div class="<%= tag.attr[ "class"] || "article" %>">
          <div class="article-title"> <%= tag.attr[ "title"] %> </div>
          <div class="article-body"> <%= tag.expand %> </div>
          <div class="article-footer"> Posted in <page/> </div>
        </div>
      </r:erb>

      <!-- use it -->
      <article title="New BackDoor release">
        Blah, blah, blah
      </article>

    </code></pre>
  }
  tag "erb_tag" do |external_tag|
    raise TagError.new( "'tag' tag must contain a 'name' attribute.") unless external_tag.attr.has_key?( "name")
    code = external_tag.expand
    external_tag.context.define_tag( external_tag.attr[ "name"]) do |tag|
      ERB.new( code).result( binding)
    end
  end
end
