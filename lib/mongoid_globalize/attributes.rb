# Helper class for storing values per locale. Used by Mongoid::Globalize::Adapter
# to stash and cache attribute values.

module Mongoid::Globalize
  class Attributes < Hash # TODO: Think about using HashWithIndifferentAccess ?
    # Returns translations for given locale. Creates empty hash for locale, if
    # given locale doesn't present.
    # Param: String or Symbol - locale
    # Result: Hash of translations
    def [](locale)
      locale = locale.to_sym
      self[locale] = {} unless has_key?(locale)
      self.fetch(locale)
    end

    # Checks that given locale has translation for given name.
    # Param: String or Symbol - locale
    # Param: String or Symbol - name of field
    # Result: true or false
    def contains?(locale, name)
      self[locale].has_key?(name.to_s)
    end

    # Returns translation for given name and given locale.
    # Param: String or Symbol - locale
    # Param: String or Symbol - name of field
    # Result: Object
    def read(locale, name)
      self[locale][name.to_s]
    end

    # Writes translation for given name and given locale.
    # Param: String or Symbol - locale
    # Param: String or Symbol - name of field
    # Param: Object
    def write(locale, name, value)
      #raise 'z' if value.nil? # TODO
      self[locale][name.to_s] = value
    end
  end
end