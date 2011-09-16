module Smailer
  module Compatibility
    def self.rails_3?
      Rails::VERSION::MAJOR == 3
    end

    def self.save_without_validation(object)
      rails_3? ? object.save(:validate => false) : object.save(false)
    end
  end
end