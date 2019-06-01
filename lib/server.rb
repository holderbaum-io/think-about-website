require 'sinatra/base'
require 'sinatra/reloader'
require 'renderer'

class Server < Sinatra::Application
  get '/favicon.ico' do
    status 404
  end

  get '/:ignore.png' do
    status 404
  end

  get '/:ignore.svg' do
    status 404
  end

  get '/assets/*' do
    renderer = Renderer.new
    file = params[:splat].first
    result = renderer.render_asset(file)
    content_type result.type
    result.content
  end

  get '/blog/**' do
    begin
      renderer = Renderer.new
      file = 'blog' + params[:splat].join('/')
      result = renderer.render(file)
      content_type result.type
      result.content
    rescue Renderer::RenderError => e
      [e.type, e.text]
    end
  end

  get '/**' do
    begin
      renderer = Renderer.new
      file = params[:splat].join('/')
      result = renderer.render(file)
      content_type result.type
      result.content
    rescue Renderer::RenderError => e
      [e.type, e.text]
    end
  end
end
