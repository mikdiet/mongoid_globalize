module Mongoid::Globalize
  # The +Adapter+ class used for stashing translates and changes in its before
  # they will be persisted or rejected.
  class Adapter
    attr_accessor :record, :stash, :translations
    private :record=, :stash=

    # Initialises new instance of +Adapter+. Creates empty stash for storing
    # translates.
    # Param: translatable Class
    def initialize(record)
      self.record = record
      self.stash = Attributes.new
    end

    # Returns value of attribute from stash for given locale.
    # Param: String or Symbol - name of locale
    # Param: String or Symbol - name of attribute
    # Returns nil if no value finded
    def fetch_stash(locale, name)
      value = stash.read(locale, name)
      return value if value
      return nil
    end

    # Returns value of attribute for given locale or it's fallbacks.
    # Param: String or Symbol - name of locale
    # Param: String or Symbol - name of attribute
    # Returns nil if no value finded
    def fetch(locale, name)
      Mongoid::Globalize.fallbacks(locale).each do |fallback|
        value = fetch_stash(fallback, name) || fetch_attribute(fallback, name)
        return value unless fallbacks_for?(value)
      end
      return nil
    end

    # Writes value of attribute for given locale into stash.
    # Param: String or Symbol - name of locale
    # Param: String or Symbol - name of attribute
    # Param: Object - value of attribute
    def write(locale, name, value)
      stash.write(locale, name, value)
    end

    # Prepares data from stash for persisting in embeded Translation documents.
    # Also clears stash for further operations.
    def prepare_translations!
      stash.each do |locale, attrs|
        if attrs.any?
          translation = record.translations.find_by_locale(locale)
          translation ||= record.translations.build(:locale => locale)
          attrs.each{ |name, value| translation[name] = value }
        end
      end
      reset
    end

    # Clears stash.
    def reset
      stash.clear
    end

  protected
    # Returns persisted value of attribute for given locale or nil.
    def fetch_attribute(locale, name)
      translation = record.translation_for(locale)
      return translation && translation.send(name)
    end

    # Checks if +object+ needs fallbacks
    # Param: Object
    # Result: true or false
    def fallbacks_for?(object)
      object.nil? || (fallbacks_for_empty_translations? && object.blank?)
    end

    # Checks option +fallbacks_for_empty_translations+
    def fallbacks_for_empty_translations?
      record.fallbacks_for_empty_translations
    end
  end
end
