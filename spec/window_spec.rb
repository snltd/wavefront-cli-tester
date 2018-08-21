#!/usr/bin/env ruby

require 'date'
require 'json'
require_relative '../spec_helper'

LINK_PREFIX = test_object_prefix.freeze

class WindowTests < CommandTest
  def setup
    @props = { name:        "#{LINK_PREFIX} link name",
               description: "#{LINK_PREFIX} link description",
               template:    "https://#{LINK_PREFIX}.wftest.tld/{{source}}" }
  end

  def command
    'window'
  end

  def test_01_import
    out = import_test_object
    @@imported_id = extract_id(out)
    assert_match(/^title\s+sample test window$/, out)
    assert_match(/^reason\s+window for CLI testing/, out)
  end

  def test_02_export
    out = describe_test_object(@@imported_id)
    raw_import = JSON.parse(IO.read(import_file), symbolize_names: true)
    keys = %i[id creatorId updaterId createdEpochMillis updatedEpochMillis]
    assert_equal(drop_keys(out, keys), drop_keys(raw_import, keys))
  end

  def test_05_create
    out = create_test_object('-d "window create test"',
                             '--start 1534870800',
                             '--end "2018-08-21 19:00:00 +0100"',
                             '-H testhost1',
                             '--host=testhost2',
                             '-A atag1',
                             '--atag=atag2',
                             '-T ttag1',
                             '--htag ttag2',
                             'test window')
    @@id = extract_id(out)
    assert_match(/^title\s+test window$/, out)
    assert_match(/^endTimeInSeconds\s+1534874400$/, out)
    assert_match(/^relevantHostNames      testhost1\n\s+testhost2$/, out)
  end

  def test_10_list_json
    out = list_all_objects_json
    assert out.key?(:items)
    ids = out[:items].map { |i| i[:id] }
    assert_includes(ids, @@id)
    assert_includes(ids, @@imported_id)
  end

  def test_11_list_brief
    out = list_all_objects_brief_human
    assert_match(/^#{@@id}\s+test window$/, out)
  end

  def test_15_describe
    out = describe_test_object(@@id)
    assert_equal(1_534_870_800, out[:startTimeInSeconds])
    assert_equal(%w[testhost1 testhost2], out[:relevantHostNames])
    assert_equal('window create test', out[:reason])
  end

  def test_20_search_like
    out = search_objects('relevantHostNames~testhost1')
    assert_match(/^#{@@id}\s+testhost1, testhost2$/, out)
  end

  def test_21_search_nomatch
    assert_equal("No matches.\n", search_objects('title=cmpletenonsnse'))
  end

  def test_22_search_exact
    out = search_objects('reason="window create test"')
    assert_match(/\A#{@@id}\s+window create test\Z/, out)
  end

  def test_23_search_begin
    out = search_objects('title^test')
    assert_match(/^#{@@id}\s+test window$/, out)
  end

  def test_30_update
    out = update_test_object('reason="some other reason"', @@id)
    assert_match(/^reason\s+some other reason$/, out)
  end

  def test_40_extend_by
    run_cmd format('extend by 1h %s', @@id)
    out = describe_test_object(@@id)
    assert_equal(1_534_878_000, out[:endTimeInSeconds])
  end

  def test_41_extend_to
    tomorrow = (Date.today + 2).to_time.to_i
    run_cmd format('extend to "%s" %s', Time.at(tomorrow), @@id)
    out = describe_test_object(@@id)
    assert_equal(tomorrow, out[:endTimeInSeconds])
    assert_equal('ONGOING', out[:runningState])
  end

  def test_43_close
    out = run_cmd format('close %s', @@id)
    assert_match(/^runningState\s+ENDED$/, out)
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
