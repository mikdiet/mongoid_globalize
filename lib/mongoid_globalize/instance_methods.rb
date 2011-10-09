module Mongoid::Globalize
  module InstanceMethods
    delegate :translated_locales, :to => :translations

    # Reader for adapter, where translations stashing during lifecicle. At first
    # use creates new one.
    # Return: Mongoid::Globalize::Adapter
    def globalize
      @globalize ||= Adapter.new(self)
    end

    # The most trouble method of Mongoid::Globalize :-(
    # Extends reader for @attributes. Mixes translated attributes to Mongoid
    # @attributes.
    # Return: Hash
    def attributes
      unless @stop_merging_translated_attributes
        @attributes.merge! translated_attributes
      end
      super
    end

    # Extends Mongoid::Document's method +process+. Pocesses given attributes in
    # consideration of possible :locale key. Used by Mongoid for all attribute-
    # related operations, such as +create+, +update+ etc.
    # Param: Hash of attributes
    # Other params will be transmitted into Mongoid::Document's method +process+
    # as is.
    def process(attributes, *args)
      with_given_locale(attributes) { super }
    end

    # Extends Mongoid::Document's method +write_attribute+. If writed attribute
    # is translateble, it is placed into adapter's stash.
    # Param: String or Symbol - name of attribute
    # Param: Object - value of attribute
    # Param: Hash of options
    def write_attribute(name, value, options = {})
      if translated?(name)
        options = {:locale => nil}.merge(options)
        access = name.to_s
        unless attributes[access] == value || attribute_changed?(access)
          attribute_will_change! access
        end
        @translated_attributes[access] = value
        the_locale = options[:locale] || Mongoid::Globalize.locale
        self.translations.reject!{ |t| t.new_record? && t.locale != the_locale }
        globalize.write(the_locale, name, value)
      else
        super(name, value)
      end
    end

    # Extends Mongoid::Document's method +read_attribute+. If writed attribute
    # is translateble, it is readed from adapter's stash.
    # Param: String or Symbol - name of attribute
    # Param: Hash of options
    # Return: Object - value of attribute
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

    # Checks whether field with given name is translated field.
    # Param String or Symbol
    # Returns true or false
    def translated?(name)
      self.class.translated?(name)
    end

    # Returns translations for current locale. Is used for initial mixing into
    # @attributes hash. Actual translations are in @translated_attributes hash.
    # Return Hash
    def translated_attributes
      @translated_attributes ||= translated_attribute_names.inject({}) do |attrs, name|
        attrs.merge(name.to_s => translation.send(name))
      end
    end

    # TODO:
    def untranslated_attributes
      attrs = {}
      attribute_names.each do |name|
        attrs[name] = read_attribute(name, {:translated => false})
      end
      attrs
    end

    # Updates fields separately for each given locale
    #     post.set_translations(
    #       :en => { :title => "updated title" },
    #       :de => { :content => "geänderter Inhalt" }
    #     )
    # Param: Hash, where keys are locales and values are Hashes of name-value
    # pairs for fields.
    def set_translations(options)
      options.keys.each do |locale|
        translation = translation_for(locale) || translations.build(:locale => locale.to_s)
        translation.update_attributes!(options[locale])
      end
    end

    # Extends Mongoid::Document's method +reload+. Resets all translation
    # changes.
    def reload
      translated_attribute_names.each { |name| @attributes.delete(name.to_s) }
      globalize.reset
      super
    end

    # Extends Mongoid::Document's method +clone+. Adds to cloned object all
    # translations from original object.
    def clone
      obj = super
      return obj unless respond_to?(:translated_attribute_names)
      obj.instance_variable_set(:@globalize, nil )
      each_locale_and_translated_attribute do |locale, name|
        obj.globalize.write(locale, name, globalize.fetch(locale, name) )
      end
      return obj
    end

    # Returns instance of Translation for current locale.
    def translation
      translation_for(Mongoid::Globalize.locale)
    end

    # Returns instance of Translation for given locale.
    # Param String or Symbol
    def translation_for(locale)
      @translation_caches ||= {}
      # Need to temporary switch of merging, because #translations uses
      # #attributes method too, to avoid stack level too deep error.
      @stop_merging_translated_attributes = true
      unless @translation_caches[locale]
        _translation = translations.find_by_locale(locale)
        _translation ||= translations.build(:locale => locale)
        @translation_caches[locale] = _translation
      end
      @stop_merging_translated_attributes = false
      @translation_caches[locale]
    end

  protected
    # Executes given block for each locale and translated attribute name for
    # this document.
    def each_locale_and_translated_attribute
      used_locales.each do |locale|
        translated_attribute_names.each do |name|
          yield locale, name
        end
      end
    end

    # Return Array with locales, used for translation of this document
    def used_locales
      locales = globalize.stash.keys.concat(globalize.stash.keys).concat(translations.translated_locales)
      locales.uniq!
      locales
    end

    # Before save callback. Cleans @attributes hash from translated attributes
    # and prepares them for persisting.
    def prepare_translations!
      @stop_merging_translated_attributes = true
      translated_attribute_names.each do |name|
        @attributes.delete name.to_s
        @changed_attributes.delete name.to_s
      end
      globalize.prepare_translations!
    end

    # After save callback. Reset some values.
    def clear_translations!
      @translation_caches = {}
      @stop_merging_translated_attributes = nil
    end

    # Detects locale in given attributes and executes given block for it.
    # Param: Hash of attributes
    # Param: Proc
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
