# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "democi/version"

Gem::Specification.new do |spec|
  spec.name = "democi"
  spec.version = Democi::VERSION
  spec.authors = ["Tsehau Chao"]
  spec.email = ["jodeci@5xruby.tw"]

  spec.description = "just a gem for demo"
  spec.summary = "just a gem for demo"
  spec.homepage = "https://github.com/jodeci/democi"
  spec.files = Dir["lib/**/*", "LICENSE.txt", "README.md"]
end
