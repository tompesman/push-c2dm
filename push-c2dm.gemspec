$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "push-c2dm/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "push-c2dm"
  s.version     = PushC2dm::VERSION
  s.authors     = ["Tom Pesman"]
  s.email       = ["tom@tnux.net"]
  s.homepage    = "https://github.com/tompesman/push-c2dm"
  s.summary     = "C2DM (Android) part of the modular push daemon."
  s.description = "C2DM support for the modular push daemon."

  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.files         = `git ls-files lib`.split("\n") + ["README.md", "MIT-LICENSE"]
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "multi_json", "~> 1.0"
  s.add_dependency "push-core", "0.0.1.pre4"
  s.add_development_dependency "sqlite3"
end
