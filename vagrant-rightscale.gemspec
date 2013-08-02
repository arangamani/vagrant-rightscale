# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-rightscale/version'

Gem::Specification.new do |gem|
  gem.name          = "vagrant-rightscale"
  gem.version       = VagrantPlugins::Rightscale::VERSION
  gem.authors       = ["caryp"]
  gem.email         = ["cary@rightscale.com"]
  gem.description   = %q{Provision your vagrant boxes using RightScale ServerTemplates.}
  gem.summary       = %q{RightScale provisioner plugin for Vagrant}
  gem.homepage      = "http://github.com/caryp/vagrant-rightscale"

  all_files = `git ls-files`.split($/)
  all_files.reject! { |file| file =~ /config\/.*/ }
  gem.files         = all_files
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('right_api_client', '>= 1.5.9')

  gem.add_development_dependency('rspec', '~> 2.5')
  gem.add_development_dependency('rake', '~> 10.0.3')
end
