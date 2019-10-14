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
  speakers: [
    {
      name: 'Speaker 1',
      slug: 'speaker_1',
      bio: "I am\nSpeaker 1",
      position: 'Senior Speaker',
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
      name: 'Speaker 2',
      slug: 'speaker_2',
      bio: "I am\nSpeaker 2",
      position: 'Senior Speaker',
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
    assert_equal "my\nabstract", keynote.abstract
    assert_equal 'EN', keynote.language

    assert_equal 2, keynote.speakers.size

    assert_equal 'Speaker 1 & Speaker 2', keynote.joined_speaker_names
    assert_equal 'Speaking Company', keynote.joined_company_names
    assert_equal ['https://example.org/company'], keynote.company_links

    speaker1 = keynote.speakers.first
    assert_equal 'speaker_1', speaker1.slug
    assert_equal(
      '/images/events/myevent/speakers/speaker_1.jpg',
      speaker1.image_path
    )
    assert_equal(
      '/images/events/myevent/speakers/speaker_1_big.jpg',
      speaker1.big_image_path
    )
    assert_equal 'Senior Speaker', speaker1.job_title
    assert_equal "I am\nSpeaker 1", speaker1.bio

    assert_equal 1, speaker1.links.size
    assert_equal 'My Website 1', speaker1.links.first.name
    assert_equal 'https://example.org/mywebsite1', speaker1.links.first.link
  end
end
