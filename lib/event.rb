require 'psych'

class Event
  def self.lookup(slug)
    base_dir = 'data/events/' + slug
    raise "Could not find event '#{slug}'" unless File.directory? base_dir
    Event.new(slug, base_dir)
  end

  class Partner
    attr_accessor(
      :type,
      :event_slug,
      :name,
      :link,
      :slug,
      :height
    )
    def initialize(type, event_slug, data)
      @type = type
      @event_slug = event_slug
      @name = data[:name]
      @link = data[:link]
      @slug = data[:slug]
      @height = data.fetch(:height, '100%')
    end

    def image_path
      "/images/events/#{@event_slug}/partners/#{@slug}.svg"
    end
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

    def order
      %w[tech design society].index(@track_string) || -1
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

  class Host
    attr_accessor(
      :name,
      :slug,
      :link
    )

    def initialize(event_slug, data)
      @event_slug = event_slug
      @data = data
      @name = @data.fetch(:name)
      @slug = @data.fetch(:slug)
      @link = @data.fetch(:link)
    end

    def image_path
      "/images/events/#{@event_slug}/hosts/#{@slug}.svg"
    end
  end

  class Perfomance
    attr_accessor(
      :slug,
      :track,
      :language,
      :language_details,
      :speakers,
      :abstract,
      :type,
      :host
    )

    def initialize(event_slug, data, filename)
      @event_slug = event_slug
      @data = data
      @slug = filename
      @track = Track.new(@data[:track])
      @title = data.fetch(:title, nil)
      @language = data.fetch(:lang, 'en').upcase
      @language_details = data.fetch(:lang_details, nil)
      @speakers = @data[:speakers].map { |d| Speaker.new(event_slug, d) }
      @abstract = @data.fetch(:abstract, '')
      @draft = @data.fetch(:draft, false)
      @type = @data.fetch(:type, 'talk')
      host = @data.fetch(:host, nil)
      if host
        @host = Host.new(event_slug, host)
      end
    end

    def draft?
      @draft == true
    end

    def keynote?
      @track.keynote?
    end

    def workshop?
      @type == 'workshop'
    end

    def title?
      !@title.nil?
    end

    def title
      @title || 'Coming soon ...'
    end

    def host?
      !@host.nil?
    end

    def language_details?
      !!@language_details
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
    performances.reject(&:workshop?).select(&:keynote?)
  end

  def talks
    performances.reject(&:workshop?).reject(&:keynote?)
  end

  def workshops
    performances.select(&:workshop?)
  end

  def draft_performances
    all_performances.select(&:draft?)
  end

  def performances
    all_performances.reject(&:draft?)
  end

  def all_performances
    return @performances if @performances
    pattern = File.join @base_dir, 'talks', '*.yml'
    unordered_performances = Dir[pattern].map do |data_file|
      data = Psych.load File.read(data_file), symbolize_names: true

      Perfomance.new(@event_slug, data, File.basename(data_file, '.yml'))
    end
    @performances = unordered_performances.sort_by { |p| p.track.order }
  end

  def partners(type = nil)
    if type
      all_partners.select { |partner| partner.type == type }
    else
      all_partners
    end
  end

  def all_partners
    return @partners if @partners
    data_file = File.join @base_dir, 'partners.yml'
    data = Psych.load File.read(data_file), symbolize_names: true
    mapped_partners = data[:partners].map do |key, values|
      values.map do |value|
        Partner.new(key, @event_slug, value)
      end
    end
    @partners = mapped_partners.flatten
  end
end
