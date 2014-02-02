source 'https://rubygems.org'

gemspec

group :development do
  gem 'vagrant',          github: 'mitchellh/vagrant', tag: 'v1.4.3'
  # TODO: Switch back to master
  gem 'vagrant-cachier',  github: 'fgrehm/vagrant-cachier', branch: 'next'
  gem 'vagrant-pristine', github: 'fgrehm/vagrant-pristine'
  gem 'vagrant-omnibus'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-inotify'
end


group :development, :test do
  gem 'rake'
  gem 'vagrant-spec', github: 'mitchellh/vagrant-spec'
  # TODO: Update to 3.0 when it's out
  gem 'rspec', '2.99.0.beta1'
  gem 'coveralls', require: false
end
