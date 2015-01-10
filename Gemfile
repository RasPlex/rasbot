source 'https://rubygems.org'

gem 'sinatra'
gem 'thin'
gem "httparty", "~> 0.13.0"
gem "sinatra-contrib", "~> 1.4.2"
gem "datamapper", "~> 1.2.0"
gem "dm-sqlite-adapter", "~> 1.2.0"
gem "eventmachine", "~> 1.0.3"
gem 'capistrano', '~> 3.1.0'
gem "geoip", "~> 1.3.5"

group :production do
  gem 'mysql2'
  gem "dm-mysql-adapter", "~> 1.2.0"
end

group :development, :test do
  gem 'sqlite3'
  gem "sqlite3-ruby", "~> 1.3.3"
  gem 'mysql2'
  gem "dm-mysql-adapter", "~> 1.2.0"
end


group :deploy do
  gem 'capistrano-bundler', '~> 1.1.2'
end


