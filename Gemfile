source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.4'

# Use mysql as the database for Active Record (use specific version for Windows since have to match up with C-connector version)
if RUBY_PLATFORM =~ /mingw/
   gem 'wdm', '>= 0.1.0'
   gem 'mysql2', '0.3.21'
else
   gem 'mysql2', '>= 0.3.18', '< 0.5'
end

# Automatic updating of updated_by or created_by model fields
gem 'blamer', '~> 4.1.0'

# Use Puma as the app server
gem 'puma', '~> 3.7'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes

# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# Cocoon provides js functions for adding/removing lines in nested forms
gem 'cocoon', '~>1.2'

# Observers is now a separate gem
gem 'rails-observers'

# handle MS Excel using Open XML Format
gem 'rubyXL', '~> 3.3.3'

# ruby encyrption
gem 'ezcrypto'

# date validation
gem 'validates_timeliness'

# file uploading
gem 'carrierwave'

# authorization library
gem 'cancancan', '~> 2.0'

# rails jquery support
gem 'jquery-rails'

# rails jquery-ui support
gem 'jquery-ui-rails'

# jquery-ui autocomplete for rails
gem 'rails-jquery-autocomplete'

# boostrap CSS framework
gem 'bootstrap', '~> 4.0.0.beta2'

# boostrap form builder
gem 'bootstrap_form'

# spreadsheet and CSV processing
gem "roo", "~> 2.7.0"

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Gems for javascript interpreter (Windows)
gem 'therubyracer', '0.11.0beta1', :path => 'C:\Users\sgrimes\Software\rubygems', platforms: [:x64_mingw, :mingw]

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

#gem 'therubyracer', '0.11.0beta1', platforms: [:jruby, :x64_mingw]
#gem 'mini_racer', platforms: :ruby

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
