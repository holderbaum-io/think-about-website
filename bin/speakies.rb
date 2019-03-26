require 'json'
require 'date'

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

def track_order(track)
  %w[
    tech
    design
    society
  ].index((track || '').downcase) || 4
end

schedule = JSON.parse(File.read('data/events.json'), symbolize_names: true)

talks = schedule[:conference_events][:events].select do |talk|
  talk[:type] == 'lecture'
end

talks.each do |talk|
  talk[:track] ||= 'none'
end

talks.reject { |t| t[:track].casecmp('keynote').zero? }
     .sort_by { |t| track_order(t[:track]) }
     .each do |talk|
  speaker = talk[:speakers][0]
  person = speaker[:full_public_name]
  person_slug = slug(person)
  link = speaker[:links].first
  url = link ? link[:url] : '#'
  company = link ? link[:title].split(' @ ').last : 'TODO'
  lang = talk[:title].match(/(\(\w+\))/)
  title = talk[:title].gsub(/\(\w+\)/, '').strip
  lang = lang[1].tr('()', '') if lang
  lang_string = lang ? " (#{lang})" : ''

  link_open = "<a href=\"/<%= lang %>/speakies/#{person_slug}.html\">"
  link_close = '</a>'
  html = <<-HTML
          <section topic="#{talk[:track].downcase}">
            #{link_open}<article>
              <h4>#{talk[:track].capitalize} Talk</h4>
              <p>"#{title}"<em>#{lang_string}</em></p>
              <hr/>
              <header>
                <div>
                  <h1>#{person}</h1>
                  <p>#{company}</p>
                </div><figure>
                  <img src="/assets/images/speaker/#{person_slug}.jpg" />
                </figure></header>
            </article>#{link_close}
          </section>
  HTML
  indentation = html.lines.first[/^ */].size
  puts html.lines.map { |l| l.gsub(/^ {#{indentation}}/, '') }.join
end
