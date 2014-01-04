require_relative "spec/acceptance/base"

box_file = 'vagrant-lxc-precise-amd64-2013-10-23.box'
box = ENV.fetch('BOX_PATH', File.expand_path("./boxes/output/#{box_file}", File.dirname(__FILE__)))

Vagrant::Spec::Acceptance.configure do |c|
  c.provider "lxc",
    box:      box,
    contexts: ["provider-context/lxc"]
end

