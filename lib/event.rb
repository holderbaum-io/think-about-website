require 'psych'

class Event
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


  class Speaker
    attr_accessor(
      :slug,
      :name,
      :company_name
    )

    def initialize(event_slug, data)
      @event_slug = event_slug
      @slug = data[:slug]
      @name = data.fetch :name
      @company_name = data.fetch(:company).fetch(:name)
    end

    def image_path
      "/images/events/#{@event_slug}/speakies/#{@slug}.jpg"
    end
  end

  class Perfomance
    attr_accessor(
      :slug,
      :track,
      :title,
      :language,
      :speakers
    )

    def initialize(event_slug, data, filename)
      @event_slug = event_slug
      @data = data
      @slug = filename
      @track = Track.new(@data[:track])
      @title = data[:title]
      @language = data.fetch(:lang, 'en').upcase
      @speakers = @data[:speakies].map { |d| Speaker.new(event_slug, d) }
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
      @speakers.map(&:company_name).uniq.join(', ')
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

  private

  def performances
    return @performances if @performances
    pattern = File.join @base_dir, 'talks', '*.yml'
    @performances = Dir[pattern].map do |data_file|
      data = Psych.load File.read(data_file), symbolize_names: true

      Perfomance.new(@event_slug, data, File.basename(data_file, '.yml'))
    end
  end
end
