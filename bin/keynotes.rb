require 'net/http'
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

uri = URI('https://orga.hrx.events/en/thinkabout2019/public/events.json')
response = Net::HTTP.get(uri)
schedule = JSON.parse(response, symbolize_names: true)

talks = schedule[:conference_events][:events].select do |talk|
  talk[:type] == 'lecture'
end

talks.each do |talk|
  talk[:track] ||= 'none'
end

selection = talks.select { |t| t[:track].casecmp('keynote').zero? }.sort_by { |t| Date.parse(t[:start_time]) }.reverse

selection.each do |talk|
  lang = talk[:title].match(/(\(\w+\))/)
  title = talk[:title].gsub(/\(\w+\)/, '').strip
  lang = lang[1].tr('()', '') if lang
  lang_string = lang ? " (#{lang})" : ''

  people = talk[:speakers].map do |speaker|
    person = speaker[:full_public_name]
    link = speaker[:links].first
    {
      person: person,
      person_slug: slug(person),
      url: link ? link[:url] : '#',
      link_title: link ? link[:title] : 'TODO'
    }
  end

  html = <<-HTML.strip
          <section topic="#{talk[:track].downcase}">
            <h4>Keynote</h4>
            <article>
              <p>"#{title}"<em>#{lang_string}</em></p>
              <hr/>
              <header>
                <div>
                  <h1>#{people.map { |p| p[:person] }.join(' &shy;&amp; ')}</h1>
                  <p><a href="#{people.first[:url]}">#{people.first[:link_title]}</a></p>
                </div>
  HTML

  people.each do |person|
    html += "<figure><img src=\"/assets/images/speaker/#{person[:person_slug]}.png\" /></figure>"
  end

  html += <<-HTML.strip
                </header>
              </article>
          </section>
  HTML
  indentation = html.lines.first[/^ */].size
  puts html.lines.map { |l| l.gsub(/^ {#{indentation}}/, '') }.join('')
end

if selection.size < 4
  puts "<p><%= t('keynotes.more') %></p>"
end
