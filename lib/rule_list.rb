
module Webrake
class RuleList < Array
  def initialize(glob_rules)
    @rules = glob_rules.sort{|a,b| a[0] <=> b[0]}.map{|glob, rule| [glob, rule] }
  end

  def create_tasks(files)
    files.map {|f| create_task(f)}.compact
  end

  def create_task(file)
    glob,rule = @rules.find do |glob, rule|
      glob.match_including_subdirectories(file)
    end
    return nil if glob.nil?
    return rule.create_task(file)
  end
end

if ARGV[0] == 'test'
require 'byebug'
require "minitest/autorun"
require_relative 'rule'
require_relative 'glob'
class RuleListTest < Minitest::Unit::TestCase
  def test_apply_first_matching_rule
    default_rule = MiniTest::Mock.new
    default_rule.expect(:create_task, Task.new('index.html.erb', :unused, :unused, :unused), ['index.html.erb'])
    blog_rule = MiniTest::Mock.new
    blog_rule.expect(:create_task, Task.new('blog/index.html.erb', :unused, :unused, :unused), ['blog/index.html.erb'])

    rule_list = RuleList.new({Glob.new('*.erb') => default_rule, Glob.new('blog/*.erb') => blog_rule})
 
    assert_equal(nil, rule_list.create_task('index.html'))
    assert_equal('index.html.erb', rule_list.create_task('index.html.erb').source)
    assert_equal('blog/index.html.erb', rule_list.create_task('blog/index.html.erb').source)
  end
end
end
end
