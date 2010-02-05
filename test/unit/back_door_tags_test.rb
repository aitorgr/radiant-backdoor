require File.dirname(__FILE__) + '/../test_helper'

# *noTE* be careful with spaces into the template strings

class BackDoorTagsTest < Test::Unit::TestCase

  fixtures    :pages
  test_helper :render

  def setup
    @page = pages( :radius)
  end

  def test_ruby_tag
    assert_renders "hello", %q{<r:ruby> "hello" </r:ruby>} 
    assert_renders "0", %q{<r:ruby> 0 </r:ruby>}
    assert_renders "0123456789", %q{<r:ruby> (0..9).inject( "") { |acc,n| acc + n.to_s } </r:ruby>}

    # test that backdoor tags are executed in the same object context
    assert_render_match /\s+(\S+)\s+(\1)/, %q{
      <r:ruby> self.to_s </r:ruby>
      <r:ruby> self.to_s </r:ruby>
    }
  end

  def test_erb_tag
    assert_renders "hello", %q{<r:erb><%= "hello" %></r:erb>}
    assert_renders "0", %q{<r:erb><% n = 0 %><%= n %></r:erb>}
    assert_renders "0123456789", %q{<r:erb>0<%= (1..8).inject( "") { |acc,n| acc + n.to_s }%>9</r:erb>}

    # this test should use a RE of /\s*2\s*3\s*4\s*5\s*1/, see the doc for the <r:erb> tag
    assert_render_match /\s*2\s*2\s*2\s*2\s*2/, %q{
      <r:erb>
        <% <r:cycle values="1, 2, 3, 4, 5" reset="true"/> %>
        <% 5.times do %>
          <%= <r:cycle values="1, 2, 3, 4, 5"/> %>
        <% end %>
      </r:erb>
    }

    assert_render_match /\s*2\s*3\s*4\s*5\s*1/, %q{
      <r:erb>
        <% <r:cycle values="1, 2, 3, 4, 5" reset="true"/> %>
        <% 5.times do %>
          <%=
          <r:expand tag="cycle" values="1, 2, 3, 4, 5"/>
          %>
        <% end %>
      </r:erb>
    }
  end

  def test_if_tag

    # if
    assert_renders "true", %q{<r:if cond="true">true</r:if>}
    assert_renders "", %q{<r:if cond="false">true</r:if>}
    assert_raise BackDoorTags::TagError do
      assert_renders "", %q{<r:if con="false">true</r:if>}
    end

    # else
    assert_renders "true", %q{<r:if cond="true">true<r:else>false</r:else></r:if>}
    assert_renders "truetrue", %q{<r:if cond="true">true<r:else>false</r:else>true</r:if>}
    assert_renders "false", %q{<r:if cond="false">true<r:else>false</r:else></r:if>}
    assert_renders "false", %q{<r:if cond="false">true<r:else>false</r:else>true</r:if>}

    # side effects
    assert_render_match /\s*1\s*/, %q{
      <r:ruby>
        @counter = 0
        ""
      </r:ruby>
      <r:if cond="false">
        This text is evaluated and igored, but the following "ruby" tag has a side effect that affects the "else" tag
        <r:ruby> @counter += 1 </r:ruby>
        <r:else> <r:ruby> @counter </r:ruby> </r:else>
      </r:if>
    }
  end

  def test_unless_tag

    # unless
    assert_renders "false", %q{<r:unless cond="false">false</r:unless>}
    assert_renders "", %q{<r:unless cond="true">true</r:unless>}
    assert_raise BackDoorTags::TagError do
      assert_renders "", %q{<r:unless con="true">false</r:unless>}
    end

    # else
    assert_renders "false", %q{<r:unless cond="true">true<r:else>false</r:else></r:unless>}
    assert_renders "false", %q{<r:unless cond="true">true<r:else>false</r:else>true</r:unless>}
    assert_renders "true", %q{<r:unless cond="false">true<r:else>false</r:else></r:unless>}
    assert_renders "truetrue", %q{<r:unless cond="false">true<r:else>false</r:else>true</r:unless>}
  end

  def test_tag_definition

    assert_render_match /01234567/, %q{
      <r:tag name="test_tag">
        raise TagError.new( "'test_tag' tag must contain a 'up_to' attribute.") unless tag.attr.has_key?( "up_to")
        up_to = tag.attr[ "up_to"]
        (0..up_to.to_i).inject( "") { |acc,n| acc + n.to_s }
      </r:tag>
      <r:test_tag up_to="7" />
    }

    assert_render_match /(\s*Hello World!\s*){3}/, %q{
      <r:erb_tag name="test_tag">
        <% tag.attr[ "times"].to_i.times do %>
          Hello <%= [ "W", "o", "r", "l", "d", "!"].join %>
        <% end %>
      </r:erb_tag>
      <r:test_tag times="3" />
    }
  end

  def test_attribute_expansion
    assert_render_match /.*?(#2).*?(id-4)/, %q{
      <r:link anchor="=(1+1)" id='="id-#{(2+2)}"' />
    }
    assert_render_match /\s+(\S+)\s+(\1)/, %q{
      <r:ruby> self.to_s </r:ruby>
      <r:ruby attr="=self.to_s">
        tag.attr[ "attr"]
      </r:ruby>
    }
    # check that old expansion prefix does not work now
    assert_render_match /#\(1\+1\)/, %q{
      <r:link anchor="#(1+1)" />
    }
  end

  def test_attribute_expansion_in_a_loop
    assert_render_match /testtest/, %q{
      <r:ruby> @counter = 0; "" </r:ruby>
      <r:children:each>
        <r:link id="=@counter" />
        <r:ruby> @counter +=1; "" </r:ruby>
      </r:children:each>
    }
  end

end

=begin
      <r:erb>
        <% @counter = 1 %>
        -- <r:link id='=@counter' /> -- 
        <% 5.times do %>
          <%= @counter %>
          <%= %q{<r:link id='=0' />} %>
          <%# @counter %>
          <% @counter += 1 %>
        <% end %>
      </r:erb>
=end
