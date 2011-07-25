module Mongoid::Globalize
  class Adapter
    attr_accessor :record, :stash, :translations
    private :record=, :stash=

    def initialize(record)
      self.record = record
      self.stash = Attributes.new
    end

    def fetch_stash(locale, name)
      value = stash.read(locale, name)
      return value if value
      return nil
    end

    def fetch(locale, name)
      Mongoid::Globalize.fallbacks(locale).each do |fallback|
        value = fetch_stash(fallback, name) || fetch_attribute(fallback, name)
        unless fallbacks_for?(value)
          set_metadata(value, :locale => fallback, :requested_locale => locale)
          return value
        end
      end
      return nil
    end

    def write(locale, name, value)
      stash.write(locale, name, value)
    end

    def save_translations!
      stash.each do |locale, attrs|
        translation = record.translations.find_or_initialize_by_locale(locale.to_s)
        attrs.each{ |name, value| translation[name] = value }
        translation.save!
      end
      # TODO: it's actual for mongoid?
      #record.translations.reset
      reset
    end

    def prepare_translations!
      stash.each do |locale, attrs|
        translation = record.translations.find_or_initialize_by_locale(locale.to_s)
        attrs.each{ |name, value| translation[name] = value }
      end
    end

    def reset
      stash.clear
    end

  protected
    def fetch_attribute(locale, name)
      translation = record.translation_for(locale)
      return translation && translation.send(name)
    end

    def set_metadata(object, metadata)
      object.translation_metadata.merge!(meta_data) if object.respond_to?(:translation_metadata)
      object
    end

    def fallbacks_for?(object)
      object.nil? || (fallbacks_for_empty_translations? && object.blank?)
    end

    def fallbacks_for_empty_translations?
      record.fallbacks_for_empty_translations
    end
  end
end
