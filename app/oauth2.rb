require 'faraday'

$the_app_token = nil
def app_token
  if $the_app_token.nil?
    $the_app_token = Faraday.new(:url => 'https://account.app.net/') do |a|
      a.request  :url_encoded 
      a.response :json, :content_type => /\bjson$/
      a.adapter  Faraday.default_adapter
    end.post('oauth/access_token', :client_id => ENV['ADN_ID'], :client_secret => ENV['ADN_SECRET'], :grant_type => 'client_credentials').body['access_token']
  end
  $the_app_token
end
