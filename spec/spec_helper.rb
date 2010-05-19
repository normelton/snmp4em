$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

MODELS = File.join(File.dirname(__FILE__), "models")
$LOAD_PATH.unshift(MODELS)
Dir[ File.join(MODELS, "*.rb") ].sort.each { |file| require File.basename(file) }

require 'rubygems'
require "spec"
require "snmp4em"

def em
  EM.run {
    yield
    EM.stop
  }
end

