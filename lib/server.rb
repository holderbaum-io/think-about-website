require 'sinatra/base'
require 'sinatra/reloader'
require 'renderer'

class Server < Sinatra::Application
  get '/assets/*' do
    renderer = Renderer.new
    file = params[:splat].first
    result = renderer.render_asset(file)
    content_type result.type
    result.content
  end

  get '/:lang/*' do
    begin
      renderer = Renderer.new
      lang = params[:lang]
      file = params[:splat].first
      result = renderer.render(lang, file)
      content_type result.type
      result.content
    rescue RenderError => e
      [e.type, e.text]
    end
  end
end
