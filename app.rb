require 'sinatra'
require 'sinatra/flash'
require 'omniauth'
require 'omniauth-appdotnet'
require 'faraday'
require 'faraday_middleware'
require 'slim'
require 'nokogiri'
require_relative 'oauth2.rb'
require_relative 'models.rb'
require_relative 'validator.rb'

enable :sessions
set :session_secret, ENV['SECRET_KEY'] || 'aaaaa'
set :server, :thin
set :port, 8080
set :markdown, :layout_engine => :slim
use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :appdotnet, ENV['ADN_ID'], ENV['ADN_SECRET'], :scope => 'write_post'
end

before do
  token = session[:token] || app_token
  @adn = Faraday.new(:url => 'https://alpha-api.app.net/stream/0/') do |adn|
    adn.request  :oauth2bearer, token
    adn.request  :json
    adn.response :json, :content_type => /\bjson$/
    adn.adapter  Faraday.default_adapter
  end
  unless session[:token].nil?
    @me = @adn.get('users/me').body['data']
  end
end

not_found do
  slim :not_found
end

helpers do
  def unmention(post)
    df = Nokogiri::HTML.fragment(post)
    first_mention = df.css('[itemprop=mention]').first
    first_mention.unlink unless first_mention.nil?
    first_hashtag = df.css('[itemprop=hashtag]').first
    first_hashtag.unlink unless first_hashtag.nil?
    df.to_html
  end

  def dateformat(datestr)
    Time.parse(datestr).strftime '%B %d, %Y %R'
  end

  def active_filter?(type)
    params[:filter] == type.downcase
  end

  def types
    [
      {:slug => 'ideas',  :singular => 'Idea',   :plural => 'Ideas',  :icon => 'icon-bullhorn'},
      {:slug => 'bugs',   :singular => 'Bug',    :plural => 'Bugs',   :icon => 'icon-fire'},
      {:slug => 'praise', :singular => 'Praise', :plural => 'Praise', :icon => 'icon-heart'},
    ]
  end

  def type_of_entry(entry)
    anns = entry['annotations'].select { |a| a['type'] == 'com.floatboth.supportadn.entry' }
    types.select { |t| t[:slug] == anns.first['value']['type'] }.first unless anns.empty?
  end

  def get_last_form
    form = session[:form] || {}
    session[:form] = nil
    form
  end

  def id_to_name(id)
    @adn.get("users/#{id}").body['data']['username']
  end
end

get '/auth/appdotnet/callback' do
  session[:token] = request.env['omniauth.auth']['credentials']['token']
  redirect request.env['omniauth.origin'] || '/'
end

get '/auth/logout' do
  session[:token] = nil
  redirect '/'
end

post '/new' do
  begin
    Validator.valid_page?(params[:name], params[:fullname])
    adn_page = @adn.post 'posts', :machine_only => true, :annotations => [{:type => 'com.floatboth.supportadn.page', :value => {:name => params[:name]}}]
    adn_page = adn_page.body['data']
    page = Page.new :name => params[:name], :fullname => params[:fullname], :adn_id => adn_page['id'], :author_adn_id => adn_page['user']['id']
    PageRepository.save page
    redirect '/' + page.name
  rescue ValidationException => e
    flash[:error] = e.message
    redirect '/'
  end
end

get '/docs' do
  markdown :docs
end

get '/' do
  unless @me.nil?
    @pages = PageRepository.find_by_author_adn_id @me['id']
    slim :index
  else
    slim :landing
  end
end

# /:name/action {{{
get '/:name' do
  @page = PageRepository.find_first_by_name params[:name]
  halt 404 if @page.nil?
  @entries = @adn.get("posts/#{@page.adn_id}/replies?include_annotations=1").body['data'].select { |p|
    p['reply_to'] == @page.adn_id && p['is_deleted'] != true
  }.sort_by { |p|
    p['num_reposts'].to_i
  }.reverse
  unless params[:filter].nil?
    @entries.select! { |p|
      anns = p['annotations'].select { |a| a['type'] == 'com.floatboth.supportadn.entry' }
      anns.first['value']['type'] == params[:filter] unless anns.empty?
    }
  end
  @page.archive ||= []
  unless params[:archive].nil?
    @entries.select! { |p| @page.archive.include? p['id'] }
  else
    @entries.reject! { |p| @page.archive.include? p['id'] }
  end
  @form = get_last_form
  slim :page
end

before '/:name/*' do
  @page = PageRepository.find_first_by_name params[:name]
end

post '/:name/reply' do
  begin
    text = "@#{id_to_name @page.author_adn_id} ##{@page.name} #{params[:text]}"
    Validator.valid_post? text, params[:text]
    @adn.post 'posts', :text => text, :reply_to => @page.adn_id, :annotations => [
      {:type => 'com.floatboth.supportadn.entry', :value => {:type => params[:type]}}
    ]
    flash[:success] = 'Thanks for your suggestion!'
  rescue ValidationException => e
    flash[:error] = e.message
    session[:form] = {:text => params[:text], :type => params[:type]}
  end
  redirect '/' + params[:name]
end

get '/:name/edit' do
  if @page.author_adn_id == @me['id']
    slim :page_edit
  else
    flash[:error] = "Can't edit page #{@page.name}."
    redirect '/'
  end
end

post '/:name/edit' do
  if @page.author_adn_id == @me['id']
    @page.name = params[:_name]
    @page.fullname = params[:_fullname]
    PageRepository.save @page
    redirect '/' + @page.name
  else
    flash[:error] = "Can't edit page #{@page.name}."
    redirect '/'
  end
end

get '/:name/delete' do
  if @page.author_adn_id == @me['id']
    @adn.delete "posts/#{@page.adn_id}"
    PageRepository.delete @page
    flash[:success] = "Deleted page #{@page.name}."
  else
    flash[:error] = "Can't delete page #{@page.name}."
  end
  redirect '/'
end
# }}}

# /:name/:entry_id/action {{{
get '/:name/:entry_id' do
  @entry = @adn.get("posts/#{params[:entry_id]}").body['data']
  @comments = @adn.get("posts/#{params[:entry_id]}/replies").body['data'].select { |p|
    p['reply_to'] == params[:entry_id] && p['is_deleted'] != true
  }.reverse
  @form = get_last_form
  slim :entry
end

post '/:name/:entry_id/reply' do
  begin
    sugg_author_username = @adn.get("posts/#{params[:entry_id]}").body['data']['user']['username']
    text = "@#{sugg_author_username} #{params[:text]}"
    Validator.valid_post? text, params[:text]
    @adn.post 'posts', :text => text, :reply_to => params[:entry_id]
    flash[:success] = 'Thanks for your comment!'
  rescue ValidationException => e
    flash[:error] = e.message
    session[:form] = {:text => params[:text]}
  end
  redirect "/#{params[:name]}/#{params[:entry_id]}"
end

get '/:name/:entry_id/vote' do
  @entry = @adn.get("posts/#{params[:entry_id]}").body['data']
  unless @entry['you_reposted']
    @adn.post "posts/#{params[:entry_id]}/repost"
    flash[:success] = 'Thanks for your vote!'
  else
    @adn.delete "posts/#{params[:entry_id]}/repost"
    flash[:success] = 'Successfully unvoted.'
  end
  redirect "/#{params[:name]}/#{params[:entry_id]}"
end

get '/:name/:entry_id/delete' do
  @entry = @adn.get("posts/#{params[:entry_id]}").body['data']
  if @entry['user']['id'] == @me['id']
    @adn.delete "posts/#{params[:entry_id]}"
    flash[:success] = 'Deleted your suggestion.'
  else
    flash[:error] = "Can't delete this suggestion."
  end
  redirect "/#{params[:name]}"
end

get '/:name/:entry_id/archive' do
  @entry = @adn.get("posts/#{params[:entry_id]}").body['data']
  if @page.author_adn_id == @me['id']
    @page.archive ||= []
    unless @page.archive.include? params[:entry_id]
      @page.archive << params[:entry_id]
      flash[:success] = 'Archived the suggestion.'
    else
      @page.archive.delete params[:entry_id]
      flash[:success] = 'Unarchived the suggestion.'
    end
    PageRepository.save @page
    redirect "/#{params[:name]}/#{params[:entry_id]}"
  else
    flash[:error] = "Can't archive this suggestion."
  end
end
# }}}
