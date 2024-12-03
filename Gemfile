source "https://rubygems.org"

ruby "3.3.0"

gem "rails", "~> 7.2.0"

# Use PostgresSQL
#
gem 'pg', '~> 1.5.8'

# Use the Puma web server [https://github.com/puma/puma]
#
gem "puma", ">= 5.0"

# Reduces boot times through caching; required in config/boot.rb
#
gem "bootsnap", require: false

# For Windows or esoteric Unix/Linux-like distributions.
#
gem 'tzinfo-data'

# Use SCSS for stylesheets via a robust preprocessing step:
# https://rubygems.org/gems/cssbundling-rails/
#
gem 'cssbundling-rails' # ...using whatever version Rails wants

# Use a robust preprocessing step for JavaScript, too; this lets us manage any
# components available in NPM that have both JS and CSS components using the
# same mechanism (Yarn):
# https://rubygems.org/gems/jsbundling-rails/
#
gem 'jsbundling-rails' # ...using whatever version Rails wants

# Rails 7+ 'modern' asset pipeline:
# https://rubygems.org/gems/propshaft
#
gem 'propshaft', '~> 1.1'

# https://rubygems.org/gems/haml-rails
#
gem "haml-rails", "~> 2.0"

# Use Hub for authentication [https://github.com/pond/hubssolib]
#
gem 'hubssolib', '~> 2.0', require: 'hub_sso_lib'

# Easy pagination [https://rubygems.org/gems/will_paginate]
#
gem 'will_paginate', '~> 4.0'

# Tag-based templates (abandoneware, but runs on Ruby 2.6+, so Ruby 3.x should
# also be fine) (https://github.com/jlong/radius)
#
gem 'radius', '~> 0.7'

# Textile support [https://rubygems.org/gems/RedCloth]
#
gem 'RedCloth', '~> 4.3'

# Markdown with GFM extensions etc. [https://rubygems.org/gems/commonmarker]
#
gem 'commonmarker', '~> 1.1'

# Wider support for markup formats [https://rubygems.org/gems/github-markup]
#
gem 'github-markup', '~> 5.0'

# HTML processing [https://rubygems.org/gems/html-pipeline]
#
# TODO: v3.2.1 breaks things...
#
gem 'html-pipeline', '= 3.2.0'

# RSS parsing for the news feed extension.
#
gem 'rss', '~> 0.3'

# "Native" vs English language names:
# https://rubygems.org/gems/i18n-language-mapping
#
gem 'i18n-language-mapping', '~> 0.1'

# Replace Rails <= 3.0 'auto_link' [https://rubygems.org/gems/rails_autolink]
#
gem 'rails_autolink', '~> 1.1'

# Page heirarchy [https://rubygems.org/gems/acts_as_tree]
#
gem 'acts_as_tree', '~> 2.9'

# First-time setup.
#
gem 'highline', '~> 3.1'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Be able to run 'bin/dev'
  gem "foreman"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
end
