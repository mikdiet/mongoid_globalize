module Mongoid::Globalize
  module ClassMethods
    def translated_locales
      all.distinct("translations.locale").sort.map &:to_sym
    end

    def with_locales(*locales)
      where(translated_field_name(:locale).in => locales.flatten)
    end
    
    def with_translations(*locales)
      locales = translated_locales if locales.empty?
      with_locales(locales).with_required_attributes
    end
    
    def with_required_attributes
      required_translated_attributes.inject(self) do |scope, name|
        scope.where(translated_field_name(name).exists => true)
      end
    end

    def translated_field_name(name)
      "translations.#{name}".to_sym
    end

    # TODO:
    #def with_translated_attribute(name, value, locales = nil)
    #  locales ||= Globalize.fallbacks
    #  with_translations.where(
    #    translated_field_name(name)    => value,
    #    translated_field_name(:locale) => Array(locales).map(&:to_s)
    #  )
    #end

    def translated?(name)
      translated_attribute_names.include?(name.to_sym)
    end

    def required_attributes
      validators.map{ |v| v.attributes if v.is_a?(ActiveModel::Validations::PresenceValidator) }.flatten.compact
    end

    def required_translated_attributes
      translated_attribute_names & required_attributes
    end

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
