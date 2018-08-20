#!/usr/bin/env ruby

require 'json'
require_relative '../spec_helper'

PREFIX  = test_object_prefix.freeze
COMMAND = 'link'.freeze

class LinkTests < CommandTest
  def setup
    @props = { name:        "#{PREFIX} link name",
               description: "#{PREFIX} link description",
               template:    "https://#{PREFIX}.wftest.tld/{{source}}" }
  end

  def test_01_import
    out = import_test_object
    @@imported_id = extract_id(out)
    assert_match(/^name\s+sample test link$/, out)
    assert_match(/^sourceFilterRegex\s+\.\*source.metric\.\*/, out)
  end

  def test_02_export
    out = describe_test_object(@@imported_id)
    raw_import = JSON.parse(IO.read(import_file), symbolize_names: true)
    keys = %i[id updatedEpochMillis createdEpochMillis]
    assert_equal(drop_keys(out, keys), drop_keys(raw_import, keys))
  end

  def test_05_create
    out = create_test_object(*props.values)
    assert_match(/^name\s+#{props[:name]}$/, out)
    @@id = extract_id(out)
  end

  def test_10_list_json
    out = list_all_objects_json
    assert out.key?(:items)
    test_obj = out[:items].select { |i| i[:id] == @@id }[0]
    props.each_pair { |k, v| assert_equal(test_obj[k.to_sym], v) }
  end

  def test_11_list_brief
    out = list_all_objects_brief_human
    assert_match(/^#{@@id}\s+#{props[:name]}$/, out)
  end

  def test_15_describe
    out = describe_test_object(@@id)
    props.each_pair { |k, v| assert_equal(out[k.to_sym], v) }
  end

  def test_20_search_like
    out = search_objects('name~link')
    assert_match(/^#{@@id}\s+#{props[:name]}$/, out)
    results = out.split("\n")
    assert results.size >= 2
  end

  def test_21_search_nomatch
    assert_equal("No matches.\n", search_objects('name=cmpletenonsnse'))
  end

  def test_21_search_exact
    out = search_objects("template=#{props[:template]}")
    assert_match(/\A#{@@id}\s+#{props[:template]}\Z/, out)
  end

  def test_21_search_begin
    out = search_objects("description^#{props[:description][0..10]}")
    assert_match(/\A#{@@id}\s+#{props[:description]}\Z/, out)
  end

  def test_30_update
    out = update_test_object('metricFilterRegex=newregex', @@id)
    assert_match(/^metricFilterRegex\s+newregex$/, out)
  end

  def _test_35_tag
    tag_test_object
  end

  def test_90_delete_created
    out = delete_test_object(@@id)
    assert_match(/^Deleted .* '#{@@id}'.$/, out)
  end

  def test_91_delete_imported
    out = delete_test_object(@@imported_id)
    assert_match(/^Deleted .* '#{@@imported_id}'.$/, out)
  end
end
