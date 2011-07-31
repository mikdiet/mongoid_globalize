module Mongoid::Globalize
  module InstanceMethods
    delegate :translated_locales, :to => :translations

    def globalize
      @globalize ||= Adapter.new(self)
    end

    def attributes
      if @stop_merging_translated_attributes# || translated_attributes_not_changed?
        super
      else
        @attributes.merge! translated_attributes
        @attributes
      end
    end

    def process(attributes, *args)
      with_given_locale(attributes) { super }
    end

    def write_attribute(name, value, options = {})
      if translated?(name)
        options = {:locale => nil}.merge(options)
        access = name.to_s
        unless attributes[access] == value || attribute_changed?(access)
          attribute_will_change! access
        end
        @translated_attributes[access] = value
        globalize.write(options[:locale] || Mongoid::Globalize.locale, name, value)
      else
        super(name, value)
      end
    end

    def read_attribute(name, options = {})
      options = {:translated => true, :locale => nil}.merge(options)
      if translated?(name) and options[:translated]
        globalize.fetch(options[:locale] || Mongoid::Globalize.locale, name)
      else
        super(name)
      end
    end

    # TODO
    def remove_attribute(name)
      super name
    end

    # Mongoid documents haven't attribute_names method, so I replace +super+
    # with +@attributes.keys.sort+. So this method returns only translated and
    # existing attribute names (but not all available names as in AR or G3) 
    def attribute_names
      translated_attribute_names.map(&:to_s) + @attributes.keys.sort
    end

    def translated?(name)
      self.class.translated?(name)
    end

    def translated_attributes_not_changed?
      if @last_translated_attributes == translated_attributes
        true
      else
        @last_translated_attributes = translated_attributes
        false
      end
    end

    def translated_attributes
      @translated_attributes ||= translated_attribute_names.inject({}) do |attributes, name|
        attributes.merge(name.to_s => translation.send(name))
      end
    end

    def untranslated_attributes
      attrs = {}
      attribute_names.each do |name|
        attrs[name] = read_attribute(name, {:translated => false})
      end
      attrs
    end

    def set_translations(options)
      options.keys.each do |locale|
        translation = translation_for(locale) || translations.build(:locale => locale.to_s)
        translation.update_attributes!(options[locale])
      end
    end

    def reload
      translated_attribute_names.each { |name| @attributes.delete(name.to_s) }
      globalize.reset
      super
    end

    def clone
      obj = super
      return obj unless respond_to?(:translated_attribute_names)

      # obj.instance_variable_set(:@translations, nil) if new_record?
      obj.instance_variable_set(:@globalize, nil )
      each_locale_and_translated_attribute do |locale, name|
        obj.globalize.write(locale, name, globalize.fetch(locale, name) )
      end
      return obj
    end

    def translation
      translation_for(Mongoid::Globalize.locale)
    end

    def translation_for(locale)
      @translation_caches ||= {}
      unless @translation_caches[locale]
        _translation = translations.detect{|t| t.locale.to_s == locale.to_s}
        _translation ||= translations.build(:locale => locale)
        @translation_caches[locale] = _translation
      end
      @translation_caches[locale]
    end

  protected
    def each_locale_and_translated_attribute
      used_locales.each do |locale|
        translated_attribute_names.each do |name|
          yield locale, name
        end
      end
    end

    def used_locales
      locales = globalize.stash.keys.concat(globalize.stash.keys).concat(translations.translated_locales)
      locales.uniq!
      locales
    end

    def prepare_translations!
      @stop_merging_translated_attributes = true
      translated_attribute_names.each do |name|
        @attributes.delete name.to_s
        @changed_attributes.delete name.to_s
      end
      globalize.prepare_translations!
    end

    def clear_translations!
      @translation_caches = {}
      @stop_merging_translated_attributes = nil
    end

    def with_given_locale(attributes, &block)
      attributes.symbolize_keys! if attributes.respond_to?(:symbolize_keys!)
      if locale = attributes.try(:delete, :locale)
        Mongoid::Globalize.with_locale(locale, &block)
      else
        yield
      end
    end
  end
end
