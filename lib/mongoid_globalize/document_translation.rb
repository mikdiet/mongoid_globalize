module Mongoid::Globalize
  class DocumentTranslation
    include Mongoid::Document
    field :locale
    class << self
      attr_accessor :translated_klass

      def with_locales(*locales)
        locales = locales.flatten.map(&:to_s)
        where(:locale.in => locales)
      end
      alias with_locale with_locales

      def translated_locales
        all.distinct("locale").sort.map &:to_sym
      end

      def find_by_locale(locale)
        with_locale(locale.to_s).first
      end
    end

    def locale
      read_attribute(:locale).to_sym
    end

    def locale=(locale)
      write_attribute(:locale, locale.to_s)
    end
  end
end
