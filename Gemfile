# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }
gem 'fastlane'
gem 'railties'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)


group :debug do
  gem 'ruby-debug-ide', '0.7.3'
  # gem 'debase'
  gem 'bundler'

end

group :development do
end