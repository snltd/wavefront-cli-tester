require 'json'
require 'pathname'
require 'minitest/autorun'
require 'securerandom'

ROOT    = Pathname.new(__FILE__).dirname
WF      = Pathname.new(ENV['HOME']) + 'work' + 'wavefront-cli' + 'bin' + 'wf'
C_OPTS  = ''.freeze # use default credentials
IMPORTS = ROOT + 'spec' + 'resources' + 'imports'

UUID_REGEX = '[\da-f]{8}(-[\da-f]{4}){3}-[\da-f]{12}'.freeze

def test_object_prefix
  SecureRandom.hex[0..9]
end

# Methods to facilitate testing
#
class CommandTest < MiniTest::Test
  attr_reader :props

  # We have to run the tests in order. Because we're going to create,
  # manipulate, and clean up objects, testing each step as we go.
  #
  def self.test_order
    :alpha
  end

  def run_cmd(cmd, return_both = false)
    cmd = format('%s %s %s %s', WF, command, C_OPTS, cmd).squeeze(' ')
    puts "running #{cmd.gsub(/#{WF}/, 'wf')}"
    out, err = capture_subprocess_io { system(cmd) }

    if return_both
      [out, err]
    else
      assert_empty(err)
      out
    end
  end

  # Wrapper to #run_cmd which returns out as a parsed object
  #
  def prun_cmd(cmd)
    JSON.parse(run_cmd(cmd), symbolize_names: true)
  end

  def create_test_object(*args)
    args.map! do |a|
      if !a.start_with?('-') && a =~ /[\s\[\{\]\}]/
        format('"%s"', a)
      else
        a
      end
    end

    run_cmd format('create %s', args.join(' '))
  end

  def import_test_object
    run_cmd format('import %s', import_file)
  end

  def import_file
    IMPORTS + format('%s.json', command)
  end

  def delete_test_object(id)
    run_cmd format('delete %s', id)
  end

  def undelete_test_object(id)
    run_cmd format('undelete %s', id)
  end

  def undelete_undeleted_test_object(id)
    run_cmd(format('undelete %s', id), true)
  end

  def list_all_objects_json
    prun_cmd 'list -f json'
  end

  def list_all_objects_brief_human
    run_cmd 'list -f human'
  end

  def describe_test_object(id)
    prun_cmd format('describe -f json %s', id)
  end

  def tag_test_object
    puts 'tagging test object'
  end

  def search_objects(pattern)
    puts 'searching for test object'
    run_cmd format('search %s', pattern)
  end

  def update_test_object(param, id)
    run_cmd format('update %s %s', param, id)
  end

  def rename_test_object(newname, id)
    run_cmd format('rename %s %s', id, newname)
  end

  # Extract the ID from the output you get when creating an object
  #
  def extract_id(out)
    out.split("\n").each do |line|
      k, v = line.split
      return v if k == 'id'
    end

    abort 'could not find ID'
  end

  # Extract the ID from a search. Takes the first match if there are
  # many.
  #
  def extract_id_search(out)
    out.split("\n")[0].split[0]
  end

  # Return the orignal hash, minus the ID key
  #
  def drop_keys(hash, keys = [:id])
    hash.reject { |k, _v| keys.include?(k) }
  end
end
