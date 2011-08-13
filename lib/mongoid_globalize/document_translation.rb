module Mongoid::Globalize
  # Base class for storing translations. All Translation classes are inherited
  # from it.
  class DocumentTranslation
    include Mongoid::Document

    field :locale

    class << self
      # Accessor to document class which translated
      attr_accessor :translated_klass

      # Scope for searching only in given locales
      # Params: String or Symbol - locales
      # Returns Mongoid::Criteria
      def with_locales(*locales)
        locales = locales.flatten.map(&:to_s)
        where(:locale.in => locales)
      end
      alias with_locale with_locales

      # Returns all locales used for translation.
      # Return Array of Symbols
      def translated_locales
        all.distinct("locale").sort.map &:to_sym
      end

      # Returns translation document for given locale
      # Param: String or Symbol - locale
      # Return: Translation
      def find_by_locale(locale)
        with_locale(locale.to_s).first
      end
    end

    # Reader for +locale+ attribute
    # Return Symbol
    def locale
      read_attribute(:locale).to_sym
    end

    # Writer for +locale+ attribute
    # Param: String or Symbol - locale
    def locale=(locale)
      write_attribute(:locale, locale.to_s)
    end
  end
end
