module Smailer
  module Compatibility
    extend self

    def rails_3?
      Rails::VERSION::MAJOR == 3
    end

    def rails_4?
      Rails::VERSION::MAJOR == 4
    end

    def rails_3_or_4?
      rails_3? || rails_4?
    end

    def save_without_validation(object)
      rails_3_or_4? ? object.save(:validate => false) : object.save(false)
    end
  end
end