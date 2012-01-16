module Mongoid::Globalize
  module ClassMethods
    # Returns all locales used for translation all of documents of this class.
    # Return Array of Symbols
    def translated_locales
      all.distinct("translations.locale").sort.map &:to_sym
    end

    # Finds documents where translations for given locales are present and where
    # attributes with presence validations aren't nil
    # Params String or Symbol or Array of Strings or Symbols
    # Returns Mongoid::Criteria
    def with_translations(*locales)
      locales = translated_locales if locales.empty?
      where :translations.matches => {:locale => {"$in" => locales.flatten}}.merge(required_fields_criteria)
    end

    # Returns structures hash of attributes with presence validations for using
    # in +with_translations+
    def required_fields_criteria
      required_translated_attributes.inject({}) do |criteria, name|
        criteria.merge name => {"$ne" => nil}
      end
    end

    # TODO:
    #def with_translated_attribute(name, value, locales = nil)
    #  locales ||= Globalize.fallbacks
    #  with_translations.where(
    #    translated_field_name(name)    => value,
    #    translated_field_name(:locale) => Array(locales).map(&:to_s)
    #  )
    #end
    #
    #def translated_field_name(name)
    #  "translations.#{name}".to_sym
    #end

    # Checks whether field with given name is translated field.
    # Param String or Symbol
    # Returns true or false
    def translated?(name)
      translated_attribute_names.include?(name.to_sym)
    end

    # Return Array of attribute names with presence validations
    def required_attributes
      validators.map{ |v| v.attributes if v.is_a?(Mongoid::Validations::PresenceValidator) }.flatten.compact
    end

    # Return Array of translated attribute names with presence validations
    def required_translated_attributes
      translated_attribute_names & required_attributes
    end

    # Returns translation class
    # First use creates this class as subclass of document's class based on
    # Mongoid::Globalize::DocumentTranslation, creates other side for embeded
    # relationship.
    def translation_class
      @translation_class ||= begin
        klass = self.const_get(:Translation) rescue nil
        if klass.nil?
          klass = self.const_set(:Translation, Class.new(Mongoid::Globalize::DocumentTranslation))
        end
        klass.embedded_in name.underscore.gsub('/', '_')
        klass.translated_klass = self
        klass
      end
    end

    # Generates accessor methods for translated attributes
    def translated_attr_accessor(name)
      define_method(:"#{name}=") do |value|
        write_attribute(name, value)
      end
      define_method(name) do |*args|
        read_attribute(name, {:locale => args.first})
      end
      alias_method :"#{name}_before_type_cast", name
    end
  end
end
