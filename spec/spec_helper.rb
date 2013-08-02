require 'rspec'
require 'rspec/mocks'

require 'vagrant-rightscale/api15'

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter     = 'documentation'
end

