module Smailer
  module Compatibility
    def self.rails_3?
      Rails::VERSION::MAJOR == 3
    end

    def self.rails_4?
      Rails::VERSION::MAJOR == 4
    end

    def self.rails_3_or_4?
      self.rails_3? || self.rails_4?
    end

    def self.save_without_validation(object)
      rails_3_or_4? ? object.save(:validate => false) : object.save(false)
    end
  end
end