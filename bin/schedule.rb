require 'json'
require 'date'
require 'time'

schedule = JSON.parse(File.read('data/events.json'), symbolize_names: true)

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

def printable_person_name(talk)
  talk[:speakers].map { |s| s[:full_public_name] }.join(' & ')
end

def printable_person_slug(talk)
  talk[:speakers].map { |s| slug(s[:full_public_name]) }.join('_and_')
end

def speaker_image_pathes(talk)
  talk[:speakers].map do |s|
    '/assets/images/speaker/' + slug(s[:full_public_name]) + '.png'
  end
end

def speakers_company(talk)
  link = talk[:speakers].first[:links].first
  link ? link[:title].split(' @ ').last : 'TODO'
end

def process_speaker(talk)
  if !talk[:speakers].empty?
    { has_person: true,
      person: printable_person_name(talk),
      person_slug: printable_person_slug(talk),
      company: speakers_company(talk),
      images: speaker_image_pathes(talk) }
  else
    { has_person: false, images: [] }
  end
end

def process_title(talk)
  lang = talk[:title].match(/(\(\w+\))/)
  lang = lang[1].tr('()', '') if lang

  { lang: lang ? " (#{lang})" : '',
    title: talk[:title].gsub(/\(\w+\)/, '').strip }
end

def process_talk(talk)
  event = {}

  event = event.merge process_speaker(talk)
  event = event.merge process_title(talk)
  event[:track] = talk[:track]
  event[:stage] = talk[:room][:name]
  event[:start_time] = Time.parse(talk[:start_time]).strftime('%H:%M')
  event[:end_time] = Time.parse(talk[:end_time]).strftime('%H:%M')

  event
end

def process_orga(orga)
  event = {}
  event[:title] = orga[:title].strip
  event[:track] = orga[:track]
  event[:start_time] = Time.parse(orga[:start_time]).strftime('%H:%M')
  event[:end_time] = Time.parse(orga[:end_time]).strftime('%H:%M')
  event
end

events = Hash.new { |h, k| h[k] = [] }

schedule[:conference_events][:events]
  .sort_by { |event| Time.parse(event[:start_time]) }
  .each do |event|
  track = event[:track]
  day = Date.parse(event[:start_time]).strftime('%Y-%m-%d')
  event = if %w[Keynote Tech Design Society].include? track
            process_talk(event)
          else
            process_orga(event)
          end
  events[day] << event
end

json = JSON.pretty_generate(events)
File.write('data/schedule.json', json)
