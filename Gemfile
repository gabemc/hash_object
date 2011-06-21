source "http://rubygems.org"

# Specify your gem's dependencies in hash_object.gemspec
gemspec

group :development do
  gem "choosy" # for tasks
  gem "yard" # for docs
end

group :test do
  gem "rspec"
  gem "autotest"
  gem "ZenTest"
  gem "autotest-notification"
  if `uname -a` =~ /^Darwin/
    gem "autotest-fsevent"
    gem "autotest-growl"
  end
end
