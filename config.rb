require 'uri'
require 'fastimage'
require 'yaml'

load './lib/event.rb'

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page '/path/to/file.html', layout: 'other_layout'

# Proxy pages
# https://middlemanapp.com/advanced/dynamic-pages/

schedule = File.read 'data/events/2019/schedule.json'
JSON.parse(schedule, symbolize_names: true).each do |_day, talks|
  talks.each do |talk|
    slug = talk[:person_slug]
    next if slug.nil?
    proxy("/events/2019/speakers/#{slug}.html",
          '/events/2019/speakers/template.html',
          locals: { talk: talk },
          ignore: true)
  end
end

event = Event.lookup('2020')
event.performances.each do |performance|
  proxy("/events/2020/talks/#{performance.slug}.html",
        '/events/2020/talks/template.html',
        locals: { talk: performance },
        ignore: true)
end


# proxy(
#   '/this-page-has-no-template.html',
#   '/template-file.html',
#   locals: {
#     which_fake_page: 'Rendering a fake page with a local variable'
#   },
# )

# Helpers
# Methods defined in the helpers block are available in templates
# https://middlemanapp.com/basics/helper-methods/

helpers do
  def events(slug)
    Event.lookup(slug)
  end

  def selling_tickets?
    true
  end

  def nav_link(name, path)
    current_url = current_page.url
    if path.end_with?('/') && current_url.start_with?(path)
      link_to name, path, class: 'current'
    elsif path == current_url
      link_to name, path, class: 'current'
    else
      link_to name, path
    end
  end

  def is_landing_page?
    current_page.url == '/'
  end

  def is_event?
    current_page.url =~ %r{^/events/.+\.html}
  end

  def encode(string)
    URI::encode string
  end

  def blogdate(article)
    article.date.strftime('%b %d')
  end

  def blogimg(article)
    "/images/blog/#{article.slug}/header.png"
  end

  def social_url(article)
    'https://' + social_domain + article.url
  end

  def social_img(article)
    'https://' + social_domain + blogimg(article)
  end

  def social_domain
    'think-about.io'
  end

  def images(glob)
    captions = YAML.safe_load(File.read('data/captions.yaml'))
    Dir[glob].sort.each.map do |filepath|
      caption = captions.fetch filepath, ''
      path = filepath.gsub(/^source/, '')
      thumb = File.dirname(path) + '/thumb/' + File.basename(filepath)
      size = FastImage.size(filepath)
      {
        basename: File.basename(path),
        path:  path,
        thumb: thumb,
        caption: caption,
        width: size[0],
        height: size[1]
      }
    end
  end

  def markdown(text)
    Kramdown::Document.new(text).to_html
  end

  def talk_recorded?(event, slug)
    return false if slug.nil?
    recordings = File.read "data/events/#{event}/recordings.json"
    JSON.parse(recordings, symbolize_names: true).key? slug.to_sym
  end

  def talk_recordings(event, slug)
    return [] if slug.nil?
    recordings = File.read "data/events/#{event}/recordings.json"
    JSON.parse(recordings, symbolize_names: true).fetch(slug.to_sym)
  end

  def keynotes(event)
    schedule = File.read "data/events/#{event}/schedule.json"
    JSON
      .parse(schedule, symbolize_names: true)
      .map { |_day, talks| talks }
      .flatten
      .select { |talk| talk[:track].casecmp('keynote').zero? }
  end

  def track_order(track)
    %w[
      tech
      design
      society
    ].index((track || '').downcase) || 4
  end

  def talks(event)
    schedule = File.read "data/events/#{event}/schedule.json"
    JSON
      .parse(schedule, symbolize_names: true)
      .map { |_day, talks| talks }
      .flatten
      .sort_by { |t| t[:start_time] || '' }
      .sort_by { |t| t[:stage] || '' }
      .sort_by { |t| track_order t[:track] }
      .select do |talk|
        talk[:track].casecmp('tech').zero? ||
          talk[:track].casecmp('design').zero? ||
          talk[:track].casecmp('society').zero?
      end
  end
end

activate :blog do |blog|
  blog.prefix = 'blog'
  # blog.sources = 'articles/{year}-{month}-{day}-{title}.html.markdown'
  blog.permalink = '{title}.html'
  blog.layout = 'article'
end

postcss = './bin/build-css.sh'

activate :external_pipeline,
         name: :postcss,
         command: build? ? postcss : postcss + ' --watch',
         source: '.tmp/dist',
         latency: 1
