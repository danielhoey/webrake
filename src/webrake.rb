require 'rake'
require 'pathname'
Dir["#{File.expand_path(File.dirname(__FILE__))}/*.rb"].each {|f| require f}
Dir["#{File.expand_path(File.dirname(__FILE__))}/filters/*.rb"].each {|f| require f}
Dir["#{File.expand_path(File.dirname(__FILE__))}/layout/*.rb"].each {|f| require f}

class Webrake
  attr_accessor :intermediate_files, :output_files

  def initialize(rake_app, file_system, rules={})
    @rake_app = rake_app
    @file_system = file_system
    @intermediate_files = []
    @output_files = []
    @file_system.mkdir('output/')

    add_rules(rules) unless rules.empty?
  end

  def add_rules(rules)
    process_rule(rules.delete(:filters), @intermediate_files, 'source/', :remove_file_extension => '.*')
    process_rule(rules.delete(:output), @output_files, 'output/')

    define_clean_tasks
    define_build_task
    
    raise "Invalid rule type: #{rules.keys}" unless rules.keys.empty?
  end

  def process_rule(rules, file_list, output_dir, options={})
    return if rules.nil?

    rules.each do |glob, filter|
      r = Rule.new(filter, @file_system, output_dir, options)
      input_files("source/#{glob}").each do |f|
        add_task(r.create_task(f), file_list)
      end
    end
  end

  def add_task(t, file_list)
    file_list << t.output
    @rake_app.define_task(t.rake_task, {t.output => t.source}, &t.proc)
  end

  def define_clean_tasks
    @rake_app.define_task(Rake::Task, :clean_intermediate_files) do 
      @file_system.remove_all(@intermediate_files)
    end
    
    @rake_app.define_task(Rake::Task, :clean_output_files) do 
      @file_system.remove_all(@output_files)
    end
    
    @rake_app.define_task(Rake::Task, :clean => [:clean_intermediate_files, :clean_output_files])
  end

  def define_build_task
    @rake_app.define_task(Rake::Task, :build => @intermediate_files + @output_files)
  end

  def input_files(glob)
    files = @file_system.file_list(glob)
    @intermediate_files.each do |f| 
      files.add(f) if File.fnmatch(glob, f)
    end
    return files
  end
end



if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
class WebrakeTest < Minitest::Unit::TestCase
  def test_input_files
    file_system = Minitest::Mock.new
    rake_app = Minitest::Mock.new
    file_system.expect(:mkdir, nil, ['output/'])
    webrake = Webrake.new(rake_app, file_system)

    file_system.expect(:file_list, FileList['file1'], ['file*'])
    assert_equal(%w(file1), webrake.input_files('file*'))

    webrake.intermediate_files = ['file2']
    file_system.expect(:file_list, FileList['file1'], ['file*'])
    assert_equal(%w(file1 file2), webrake.input_files('file*'))

    webrake.intermediate_files = ['file2']
    file_system.expect(:file_list, FileList[], ['file*'])
    assert_equal(%w(file2), webrake.input_files('file*'))
  end

end
end
