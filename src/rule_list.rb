
module Webrake
class RuleList < Array
  def initialize(glob_rules)
    @rules = glob_rules.sort{|a,b| b[0] <=> a[0]}.map{|glob, rule| [glob, rule] }
  end

  def create_tasks(files, remove_extension=false)
    files.map {|f| create_task(f, remove_extension)}.compact
  end

  def create_task(file, remove_extension=false)
    glob,rule = @rules.find do |glob, rule|
      File.fnmatch("**/#{glob}", file, File::FNM_PATHNAME | File::FNM_DOTMATCH)
    end
    return nil if glob.nil?
    return rule.create_task(file, remove_extension)
  end
end

if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
require_relative 'rule'
class RuleListTest < Minitest::Test
  def test_apply_first_matching_rule
    default_rule = MiniTest::Mock.new
    default_rule.expect(:create_task, Rule::Task.new(:unused, 'index.html.erb', :unused, :unused), ['index.html.erb', false])
    blog_rule = MiniTest::Mock.new
    blog_rule.expect(:create_task, Rule::Task.new(:unused, 'blog/index.html.erb', :unused, :unused), ['blog/index.html.erb', false])

    rule_list = RuleList.new({'*.erb' => default_rule, 'blog/*.erb' => blog_rule})
 
    assert_equal(nil, rule_list.create_task('index.html'))
    assert_equal('index.html.erb', rule_list.create_task('index.html.erb').source)
    assert_equal('blog/index.html.erb', rule_list.create_task('blog/index.html.erb').source)
  end
end
end
end
