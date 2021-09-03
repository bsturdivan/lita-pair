Gem::Specification.new do |spec|
  spec.name          = "lita-pair"
  spec.version       = "0.1.0"
  spec.authors       = ["Brian Sturdivan"]
  spec.email         = ["bsturdivan@gmail.com"]
  spec.description   = "Auto pairs users in a Slack channel that have been added to the pairing list"
  spec.summary       = "Lita handler for pairing two or more Slack users"
  spec.homepage      = "https://github.com/bsturdivan/lita-pair"
  spec.license       = "Apache-2.0"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.8"
  spec.add_runtime_dependency "rufus-scheduler"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
end
