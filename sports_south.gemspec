# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sports_south/version'

Gem::Specification.new do |spec|
  spec.name          = "sports_south"
  spec.version       = SportsSouth::VERSION
  spec.authors       = ["Dale Campbell"]
  spec.email         = ["oshuma@gmail.com"]
  spec.summary       = %q{Sports South API Ruby library.}
  spec.description   = %q{Sports South API Ruby library.}
  spec.homepage      = "https://github.com/ammoready/sports_south"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "nokogiri", "~> 1.6"

  spec.add_development_dependency "activesupport", "~> 5"
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "net-http-spy", "~> 0.2"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.3"
  spec.add_development_dependency "webmock", "~> 1.20"
end
