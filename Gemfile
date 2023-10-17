# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'fastlane'
gem 'railties'
gem 'fileutils'
gem 'git'
gem 'public_suffix', "< 5.0.0"
gem 'httparty'
gem "activesupport", "= 7.0.8"
# gem 'fastlane', :path => '../fastlane'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)


group :debug do
  gem 'ruby-debug-ide', '0.7.3'
  gem 'debase', '0.2.5.beta2'
  # gem 'debase'
  gem 'bundler'

end

group :development do
end