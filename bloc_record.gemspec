Gem::Specification.new do |s|
  s.name            = "bloc_record"
  s.version         = "0.0.0"
  s.date            = "2017-12-02"
  s.summary         = "blocRecord ORM"
  s.description     = "ORM adaptor"
  s.author          = ["Steven Houng"]
  s.email           = "syhoung1@gmail.com"
  s.files           = Dir["lib/**/*.rb"]
  s.require_paths   = ["lib"]
  s.homepage        =
     'http://rubygems.org/gems/bloc_record'
  s.license         = 'MIT'
  s.add_runtime_dependency 'sqlite3', '~> 1.3'
  s.add_runtime_dependency 'activesupport'
end