require 'net/http'
require 'json'

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

talks.select { |t| t[:track].casecmp('keynote').zero? } .each do |talk|
  speaker = talk[:speakers][0]
  person = speaker[:full_public_name]
  person_slug = slug(person)
  about = speaker[:abstract]
  link = speaker[:links].first
  url = link ? link[:url] : '#'

  html = <<-HTML
          <section topic="#{talk[:track].downcase}">
            <article>
              <header>
                <figure>
                  <img src="/assets/images/speaker/#{person_slug}.png" />
                </figure>
                <div>
                  <h4>Keynote</h4>
                  <p>"#{talk[:title]}"</p>
                  <a href="#{url}">#{person}</a>
                </div>
              </header><div>
                <p>#{about}</p>
              </div>
            </article>
          </section>
  HTML
  indentation = html.lines.first[/^ */].size
  puts html.lines.map { |l| l.gsub(/^ {#{indentation}}/, '') }.join
end
