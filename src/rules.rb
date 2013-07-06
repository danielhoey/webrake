require 'rake'

class Rules
  def initialize(rake_app, file_system, rules)
    @rake_app = rake_app
    @file_system = file_system
    rules.each do |file, filter|
      add_rule(file, filter)
    end
  end

  def add_rule(file, filter)
    output = "source/#{File.basename(file, '.*')}"
    source = "source/#{file}"
    @rake_app.define_task(Rake::FileTask, {output => source}) do
      content = filter.process(@file_system.read(source))
      @file_system.write(output, content, @file_system.mtime(source))
    end
  end
end
