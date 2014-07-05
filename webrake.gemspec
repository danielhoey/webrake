Gem::Specification.new do |s|
  s.name        = 'webrake'
  s.version     = '0.3.0'
  s.date        = Time.now.strftime('%Y-%m-%d')
  s.summary     = "Webrake is a static website generator leveraging Rake FileTasks with simple extension and customisation"
  s.description = "Webrake is static website generator that allows explicit control of how files are processed."
  s.authors     = ["Daniel Hoey"]
  s.email       = "dan@danhoey.com"
  s.files       = Dir["#{File.dirname(__FILE__)}/lib/**/*.rb"]
  s.homepage    = 'https://github.com/danielhoey/webrake'
  s.license     = 'MIT'
end
