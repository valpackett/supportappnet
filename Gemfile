source 'https://rubygems.org'

# serving
gem "thin"
gem "rack_csrf"
gem "sinatra"
gem "sinatra-flash"
gem "slim"
gem "redcarpet"

# requesting
gem "faraday"
gem "faraday_middleware"
gem "faraday_middleware-multi_json"
gem "omniauth"
gem "omniauth-appdotnet"

# storing
gem "curator", :git => "git://github.com/braintree/curator.git"
gem "mongo", "1.6.0"
gem "bson_ext", "1.6.0"

# etc
gem "oj"
gem "nokogiri"

group :development, :test do
  gem "rspec"
  gem "shotgun"
end

group :production do
  gem "newrelic_rpm"
end
