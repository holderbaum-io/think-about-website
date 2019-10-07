require 'minitest/autorun'
require 'minitest/spec'

require 'psych'
require 'tmpdir'
require 'fileutils'

require_relative '../lib/event'

REFERENCE_PERFORMANCE = {
  title: 'my title',
  track: 'keynote',
  lang: 'en',
  abstract: "my\nabstract",
  speakies: [
    {
      name: 'Speakie 1',
      slug: 'speakie_1',
      bio: "I am\nSpeakie 1",
      position: 'Senior Speakie',
      company: {
        name: 'Speaking Company',
        link: 'https://example.org/company'
      },
      links: [
        {
          name: 'My Website 1',
          link: 'https://example.org/mywebsite1'
        }
      ]
    },
    {
      name: 'Speakie 2',
      slug: 'speakie_2',
      bio: "I am\nSpeakie 2",
      position: 'Senior Speakie',
      company: {
        name: 'Speaking Company',
        link: 'https://example.org/company'
      },
      links: [
        {
          name: 'My Website 2',
          link: 'https://example.org/mywebsite2'
        }
      ]
    }
  ]
}.freeze

describe Event do
  before do
    @tmpdir = Dir.mktmpdir
    FileUtils.mkdir_p File.join(@tmpdir, 'talks')
  end

  after do
    FileUtils.remove_entry @tmpdir
  end

  it 'has no performances for an empty event' do
    event = Event.new 'myevent', '/tmp'
    assert_empty event.keynotes
    assert_empty event.talks
  end

  it 'parses all keys of a yml performance definition' do
    file = File.join(@tmpdir, 'talks', 'my_slug.yml')
    File.write(file, Psych.dump(REFERENCE_PERFORMANCE))

    event = Event.new 'myevent', @tmpdir
    assert_equal 1, event.keynotes.size
    assert_equal 0, event.talks.size

    keynote = event.keynotes.first

    assert_equal 'my_slug', keynote.slug
    assert_equal '/events/myevent/talks/my_slug.html', keynote.path

    assert_equal 'my title', keynote.title
    assert_equal 'EN', keynote.language

    assert_equal 2, keynote.speakers.size

    assert_equal 'Speakie 1 & Speakie 2', keynote.joined_speaker_names
    assert_equal 'Speaking Company', keynote.joined_company_names

    speaker1 = keynote.speakers.first
    assert_equal 'speakie_1', speaker1.slug
    assert_equal(
      '/images/events/myevent/speakies/speakie_1.jpg',
      speaker1.image_path
    )
  end
end
