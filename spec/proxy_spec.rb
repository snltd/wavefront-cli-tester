#!/usr/bin/env ruby

require 'json'
require_relative '../spec_helper'

PROXY = 'Proxy on shark-wf-test'.freeze

# We can't create a proxy -- only proxies can do that. So these
# tests depend on there being something recognizable there already.
#
# I have a proxy whose name is 'Proxy on shark-wf-test'. You need
# that to run these tests.
#
class ProxyTests < CommandTest
  def command
    'proxy'
  end

  # Get the name of the proxy we'll use in other tests. This also
  # serves as a test of the exact search mechanism. No need to do
  # that later.
  #
  def test_02_search_exact
    out = search_objects("name=\"#{PROXY}\"")
    assert_match(/\A#{UUID_REGEX}\s+#{PROXY}$/, out)
    @@id = extract_id_search(out)
  end

  def test_10_list_json
    fields = %i[version name id status customerId inTrash]
    out = list_all_objects_json
    assert out.key?(:items)
    assert out[:items].is_a?(Array)
    out[:items].each { |proxy| assert_empty(fields - proxy.keys) }
  end

  def test_11_list_brief
    out = list_all_objects_brief_human
    assert_match(/^#{UUID_REGEX}\s+\w+/, out)
  end

  def test_15_describe
    out = describe_test_object(@@id)
    assert_equal(out[:name], PROXY)
  end

  def test_22_search_like
    out = search_objects('name~"shark-wf-test"')
    assert_match(/^#{UUID_REGEX}\s+#{PROXY}$/, out)
  end

  def test_21_search_nomatch
    assert_equal("No matches.\n", search_objects('name=cmpletenonsnse'))
  end

  def test_23_search_begin
    out = search_objects('name^Proxy')
    assert_match(/^#{UUID_REGEX}\s+Proxy/, out)
  end

  def test_30_rename
    out = rename_test_object("\"Renamed #{PROXY}\"", @@id)
    assert_match(/^name\s+Renamed #{PROXY}$/, out)
  end

  def test_31_renamed
    out = describe_test_object(@@id)
    assert_equal(out[:name], "Renamed #{PROXY}")
  end

  def test_32_rename
    out = rename_test_object("\"#{PROXY}\"", @@id)
    assert_match(/^name\s+#{PROXY}$/, out)
  end

  def test_90_delete
    out = delete_test_object(@@id)
    assert_match(/^Deleted .* '#{@@id}'.$/, out)
  end

  def test_94_undelete
    out = undelete_test_object(@@id)
    assert_match(/^Undeleted .* '#{@@id}'.$/, out)
  end

  def test_95_undelete_undeleted
    out, err = undelete_undeleted_test_object(@@id)
    assert_empty(out)
    assert_match(/is not soft deleted/, err)
  end
end
