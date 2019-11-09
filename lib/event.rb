require 'psych'

class Event
  def self.lookup(slug)
    base_dir = 'data/events/' + slug
    raise "Could not find event '#{slug}'" unless File.directory? base_dir
    Event.new(slug, base_dir)
  end

  class Track
    def initialize(track_string)
      @track_string = track_string.downcase
    end

    def keynote?
      @track_string == 'keynote'
    end

    def readable
      @track_string.capitalize
    end

    def slug
      @track_string
    end
  end

  class Link
    attr_accessor(
      :name,
      :link
    )

    def initialize(data)
      @name = data.fetch(:name)
      @link = data.fetch(:link)
    end
  end

  class Speaker
    attr_accessor(
      :slug,
      :name,
      :job_title,
      :bio,
      :links
    )

    def initialize(event_slug, data)
      @data = data
      @event_slug = event_slug
      @slug = data[:slug]
      @name = data.fetch :name
      @independent = !data.key?(:company)
      @job_title = data.fetch(:position, nil)
      @bio = data.fetch(:bio)
      @links = data.fetch(:links).map { |d| Link.new(d) }
    end

    def big_image_path
      "/images/events/#{@event_slug}/speakers/#{@slug}_big.jpg"
    end

    def image_path
      "/images/events/#{@event_slug}/speakers/#{@slug}.jpg"
    end

    def independent?
      @independent
    end

    def company_name
      @data.fetch(:company).fetch(:name)
    end

    def company_link
      @data.fetch(:company).fetch(:link)
    end
  end

  class Perfomance
    attr_accessor(
      :slug,
      :track,
      :title,
      :language,
      :speakers,
      :abstract
    )

    def initialize(event_slug, data, filename)
      @event_slug = event_slug
      @data = data
      @slug = filename
      @track = Track.new(@data[:track])
      @title = data[:title]
      @language = data.fetch(:lang, 'en').upcase
      @speakers = @data[:speakers].map { |d| Speaker.new(event_slug, d) }
      @abstract = @data[:abstract]
    end

    def keynote?
      @track.keynote?
    end

    def path
      "/events/#{@event_slug}/talks/#{@slug}.html"
    end

    def joined_speaker_names
      @speakers.map(&:name).join(' & ')
    end

    def joined_company_names
      @speakers.map do |speaker|
        speaker.independent? ? speaker.job_title : speaker.company_name
      end.uniq.join(', ')
    end

    def company_links
      @speakers.map(&:company_link).uniq
    end


    def [](key)
      @data.fetch key
    end
  end

  def initialize(slug, base_dir)
    @event_slug = slug
    @base_dir = base_dir
  end

  def keynotes
    performances.select(&:keynote?)
  end

  def talks
    performances.reject(&:keynote?)
  end

  def performances
    return @performances if @performances
    pattern = File.join @base_dir, 'talks', '*.yml'
    @performances = Dir[pattern].map do |data_file|
      data = Psych.load File.read(data_file), symbolize_names: true

      Perfomance.new(@event_slug, data, File.basename(data_file, '.yml'))
    end
  end
end
