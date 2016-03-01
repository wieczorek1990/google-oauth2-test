require 'addressable/uri'
require 'oauth2'
require 'requests/sugar'
require 'sinatra'

# Visit https://console.developers.google.com/home/dashboard to create a web application with OAuth2
# Visit https://security.google.com/settings/security/permissions to revoke access and generate new refresh token
# Visit https://console.developers.google.com/permissions/projectpermissions to change permissions

enable :sessions
set :port, 80

redirect_uri = 'http://f957cf30.ngrok.io/oauth2/callback'
client_id = '897690190317-kjubs1pmrqlm9uhl45eb4ks8bt216f01.apps.googleusercontent.com'
client_secret = 'iK7i3JivIR7BeLnrpPfNF6FK'

authorize_url = 'https://accounts.google.com/o/oauth2/v2/auth'
token_url = 'https://www.googleapis.com/oauth2/v4/token'
tokeninfo_url = 'https://www.googleapis.com/oauth2/v3/tokeninfo'

client = OAuth2::Client.new(client_id, client_secret, :authorize_url => authorize_url, :token_url => token_url)

get '/oauth2/start' do
  uri = Addressable::URI.parse(client.auth_code.authorize_url(:redirect_uri => redirect_uri))
  arguments = {
    :access_type => :offline,
    :scope => [
      'https://www.google.com/calendar/feeds/',
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/plus.profile.emails.read',
      'https://www.googleapis.com/auth/gmail.compose',
      'https://www.googleapis.com/auth/gmail.modify',
      'https://www.googleapis.com/auth/contacts.readonly',
      'https://mail.google.com/'
    ].join(' ')
  }
  uri.query_values = (uri.query_values || {}).merge(arguments)
  redirect(uri.normalize.to_s)
end

get '/oauth2/callback' do
  response = client.auth_code.get_token(params[:code], :redirect_uri => redirect_uri)
  token = response.token
  refresh_token = response.refresh_token
  unless refresh_token.nil?
    session[:refresh_token] = refresh_token
    print refresh_token
  end
  "<a href=\"/oauth2/tokeninfo?access_token=#{token}\">tokeninfo</a><br>"\
  "<a href=\"/oauth2/refresh\">refresh</a><br>"\
  "<a href=\"https://accounts.google.com/o/oauth2/revoke?token=#{token}\">revoke</a>"
end

get '/oauth2/tokeninfo' do
  uri = Addressable::URI.parse(tokeninfo_url)
  uri.query_values = {
    :access_token => params[:access_token]
  }
  Requests.get(uri.normalize.to_s).body
end

get '/oauth2/refresh' do
  arguments = {
    :client_id => client_id,
    :client_secret => client_secret,
    :grant_type => :refresh_token,
    :refresh_token => session[:refresh_token]
  }
  Requests.post(token_url, data: arguments).body
end

