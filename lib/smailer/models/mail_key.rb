require 'digest/md5'

module Smailer
  module Models
    class MailKey < ActiveRecord::Base
      validates_presence_of :email, :key
      validates_uniqueness_of :email
      validates_uniqueness_of :key
      validates_length_of :email, :key, :maximum => 255

      unless Smailer::Compatibility.rails_4?
        attr_accessible :email, :key
      end

      before_validation :set_key
      before_save :set_key

      def self.generate(email)
        Digest::MD5.hexdigest("The #{email} and our great secret, which lies in Mt. Asgard!")
      end

      def self.get(email)
        email  = extract_email(email)
        key    = generate(email)
        stored = find_by_key(key)

        create :email => email, :key => key unless stored

        key
      end

      def self.extract_email(email)
        email = $1.strip if email =~ /<(.+@.+)>\s*$/
        email
      end

      protected

      def set_key
        self.key = self.class.generate(email)
      end
    end
  end
end
