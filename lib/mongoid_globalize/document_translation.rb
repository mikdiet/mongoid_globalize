module Mongoid::Globalize
  class DocumentTranslation
    include Mongoid::Document
    field :locale
    class << self
      def with_locales(*locales)
        locales = locales.flatten.map(&:to_s)
        where(:locale.in => locales)
      end
      alias with_locale with_locales

      def translated_locales
        # TODO
        []
      end

      def find_or_initialize_by_locale(locale)
        with_locale(locale.to_s).first || build(:locale => locale.to_s)
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
