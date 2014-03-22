module Smailer
  module Models
    class Property < ActiveRecord::Base
      if Smailer::Compatibility.rails_3_or_4?
        self.table_name = 'smailer_properties'
      else
        set_table_name 'smailer_properties'
      end

      validates_presence_of :name
      validates_uniqueness_of :name

      unless Smailer::Compatibility.rails_4?
        attr_accessible :name, :value, :notes
      end

      @@cache_created_at = Time.now

      def self.clear_cache_if_needed!
        if Time.now - @@cache_created_at > 1.minute
          remove_class_variable :@@properties rescue nil
          @@cache_created_at = Time.now
        end
      end

      def self.setup_cache!
        self.clear_cache_if_needed!
        @@properties ||= {} unless defined?(@@properties)
      end

      def self.get(name)
        self.setup_cache!
        name = name.to_s

        unless @@properties.has_key?(name)
          property = find_by_name name
          @@properties[name] = property ? property.value : nil
        end

        @@properties[name]
      end

      def self.get_all(name)
        self.setup_cache!
        name, cache_key = name.to_s, "#{name}[]"

        unless @@properties.has_key?(cache_key)
          properties = all(:conditions => ['name LIKE ?', "#{name}%"]).map { |p| [p.name, p.value] }
          @@properties[cache_key] = Hash[ properties ]
        end

        @@properties[cache_key]
      end

      def self.get_boolean(name)
        self.get(name).to_s.strip =~ /^(true|t|yes|y|on|1)$/i ? true : false
      end
    end
  end
end
