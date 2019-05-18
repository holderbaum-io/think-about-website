require 'json'
require 'date'
require 'kramdown'
require 'oga'

def link_text(title)
  if title == 'Independent Consultant'
    'Website'
  else
    title.split(' @ ').last
  end
end

def slug(string)
  string.downcase.gsub!(/[ äöüß]/) do |match|
    case match
    when 'ä' then 'ae'
    when 'ö' then 'oe'
    when 'ü' then 'ue'
    when 'ß' then 'ss'
    when ' ' then '_'
    end
  end
end

schedule = JSON.parse(File.read('data/events.json'), symbolize_names: true)

talks = schedule[:conference_events][:events].select do |talk|
  talk[:type] == 'lecture' && !talk[:speakers].empty?
end

talks.each do |talk|
  joined_names = talk[:speakers].map { |s| s[:full_public_name] }.join(' and ')
  filename = "pages/speakies/#{slug(joined_names)}.html.erb"
  people = talk[:speakers]

  bios = people[0][:abstract].split("\r\n\r\n\r\n")
  File.write("content/en/speakies/#{slug(joined_names)}.md", bios[0])
  if bios.size > 1
    File.write("content/de/speakies/#{slug(joined_names)}.md", bios[1])
  else
    File.write("content/de/speakies/#{slug(joined_names)}.md", bios[0])
  end

  track = talk[:track].capitalize
  title = talk[:title].gsub(/\(\w+\)/, '').strip
  lang = talk[:title].match(/(\(\w+\))/)
  lang = lang ? lang[1].tr('()', '') : 'EN'

  text = talk[:abstract]
  abstract = if text.size > 10
               Kramdown::Document.new(text).to_html
             else
               "<%= t('speaker-details.abstract-missing') %>"
             end

  text_abstract = if text.size > 10
                    html = Kramdown::Document.new(text).to_html
                    parsed = Oga.parse_html(html)
                    parsed.xpath('p[1]').text + ' ...'
                  else
                    "The talk abstract will be published soon."
                  end

  images = people.map{ |p| "<img src=\"/assets/images/speaker/#{slug(p[:full_public_name])}_big.png\" />" }.join('')
  links = people[0][:links].map { |l| "<a href=\"#{l[:url]}\">#{link_text l[:title]}</a>"}.join(' | ')

  data = {
    title: title,
    track: track,
    abstract: text_abstract
  }
  File.write(
    "data/speakies/#{slug(joined_names)}.json",
    JSON.pretty_generate(data)
  )

  track_html = if track.casecmp('introoutro') != 0
                 "<li><em>#{track}</em></li>"
               end

  length_html = if track.casecmp('introoutro') != 0
                  "<li><%= t('speaker-details.length') %>: 45 Min</li>"
                end

  html = <<-HTML
    <main>
      <section class="speaker-details">
        <div>
          <h1>#{title}</h1>
          <ul>
            #{track_html}
            #{length_html}
            <li><%= t('speaker-details.language') %>: #{lang}</li>
          </ul>
          <article>#{abstract}</article>
        </div>
      </section>
      <section class="speaker-details">
        <div>
          <article class="bio">
            <figure>
              #{images}
            </figure>
            <div>
              <h1>#{people.map {|p| p[:full_public_name] }.join(' &amp; ')}</h1>
              <p>#{people[0][:links].first[:title]}<p>
              <p><%= content('speakies/#{slug(joined_names)}') %></p>
              <p>#{links}</p>
            </div>
          </article>
        </div>
      </section>
      <section>
        <%= partial 'tickets_footer' %>
      </section>
      <section class="universe-sponsors">
        <%= partial 'universe_sponsors' %>
      </section>
      <section>
        <%= partial 'updates' %>
      </section>
    </main>
  HTML
  indentation = html.lines.first[/^ */].size
  result = html.lines.map { |l| l.gsub(/^ {#{indentation}}/, '') }.join
  File.write(filename, result)
end


