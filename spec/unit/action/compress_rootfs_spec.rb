require 'unit_helper'

require 'vagrant-lxc'
require 'vagrant-lxc/action/compress_rootfs'
require 'vagrant-lxc/driver'
require 'vagrant-lxc/provider'

describe Vagrant::LXC::Action::CompressRootFS do
  let(:app)                    { double(:app, call: true) }
  let(:env)                    { {machine: machine, ui: double(info: true)} }
  let(:machine)                { double(Vagrant::Machine, provider: provider) }
  let(:provider)               { double(Vagrant::LXC::Provider, driver: driver) }
  let(:driver)                 { double(Vagrant::LXC::Driver, compress_rootfs: compressed_rootfs_path) }
  let(:compressed_rootfs_path) { '/path/to/rootfs.tar.gz' }

  subject { described_class.new(app, env) }

  before do
    provider.stub_chain(:state, :id).and_return(:stopped)
  end

  it "asks the driver to compress container's rootfs" do
    driver.should_receive(:compress_rootfs)
    subject.call(env)
  end

  it 'sets export.temp_dir on action env' do
    subject.call(env)
    env['package.rootfs'].should == compressed_rootfs_path
  end
end
