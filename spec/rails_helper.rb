here = File.dirname(__FILE__)
require "#{here}/../lib/superbolt"
Dir["#{here}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.color = true
  config.order = :rand
end
