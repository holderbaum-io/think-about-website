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
  joined_names = talk[:speakers].map { |s| s[:full_public_name] }.join(' and ')
  filename = "pages/speakies/#{slug(joined_names)}.html.erb"

  track = talk[:track].capitalize
  title = talk[:title].gsub(/\(\w+\)/, '').strip
  lang = talk[:title].match(/(\(\w+\))/)
  lang = lang ? lang[1].tr('()', '') : 'EN'

  html = <<-HTML
    <main>
      <section class="speaker-details">
        <div>
          <h1>#{title}</h1>
          <ul>
            <li><em>#{track}</em></li>
            <li>Length: 45 Minutes</li>
            <li>Language: #{lang}</li>
          </ul>
          <article>
            <p>
              Research has identified what I like to call "an agile mindset," an attitude that equates failure and problems with opportunities for learning, a belief that we can all improve over time, that our abilities are not fixed but evolve with effort.
            <p>
              What's surprising about this research is the impact of our mindset on creativity and innovation, estimation, and collaboration in and out of the workplace.
            </p>
            <p>
              I'll share what we know so far about this mindset and offer some practical suggestions to help all of us become even more agile.
            </p>
          </article>
        </div>
      </section>
      <section class="speaker-details">
        <div>
          <article class="bio">
            <figure>
              <img src="/assets/images/speaker/linda_rising.png" />
            </figure>
            <div>
              <h1>Linda Rising</h1>
              <p>Independent Consultant<p>
              <p>
                With a Ph.D. from Arizona State University in object-based design metrics, Linda’s background includes university teaching and industry work. An internationally known presenter on topics related to patterns, agile development, the change process, and how your brain works, Linda is the author of numerous articles and five books. The latest: More Fearless Change, written with Mary Lynn Manns.
              </p>
              <p>
              <a href="#">Website</a> |
              <a href="#">Twitter</a>
              </p>
            </div>
          </article>
        </div>
      </section>
    </main>
  HTML
  indentation = html.lines.first[/^ */].size
  result = html.lines.map { |l| l.gsub(/^ {#{indentation}}/, '') }.join
  File.write(filename, result)
end


