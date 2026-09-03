# frozen_string_literal: true

module RecordingStudioPublications
  class PublicationType
    TOKENS = %w[magazine newspaper journal site broadcast].freeze

    def self.parse(raw)
      token = raw.to_s
      raise ArgumentError, "unknown publication type" unless TOKENS.include?(token)

      new(token)
    end

    def self.try_parse(raw)
      parse(raw)
    rescue ArgumentError
      nil
    end

    def self.select_options
      TOKENS.map { |token| [new(token).label, token] }
    end

    def initialize(token)
      @token = token
    end
    private_class_method :new

    attr_reader :token

    def label
      token.titleize
    end

    def to_s
      token
    end

    def ==(other)
      other.is_a?(self.class) && other.token == token
    end
  end
end
