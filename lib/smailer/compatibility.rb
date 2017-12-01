module Smailer
  module Compatibility
    extend self

    def rails_2?
      Rails::VERSION::MAJOR == 2
    end

    def rails_3?
      Rails::VERSION::MAJOR == 3
    end

    def rails_4?
      Rails::VERSION::MAJOR == 4
    end

    def rails_3_or_4?
      rails_3? || rails_4?
    end

    def has_attr_accessible?
      rails_2? || rails_3?
    end

    def save_without_validation(object)
      rails_3_or_4? ? object.save(:validate => false) : object.save(false)
    end

    def update_all(scope, fields, conditions, options)
      if rails_3_or_4?
        scope = scope.limit(options[:limit]) if options[:limit]
        scope = scope.order(options[:order]) if options[:order]
        scope.where(conditions).update_all(fields)
      else
        scope.update_all(fields, conditions, options)
      end
    end
  end
end