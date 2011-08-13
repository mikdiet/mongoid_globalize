module Mongoid::Globalize
  class FieldsBuilder
    # Initializes new istance of FieldsBuilder.
    # Param Class
    def initialize(model)
      @model = model
    end

    # Creates new field in translation document.
    # Param String or Symbol
    # Other params are the same as for Mongoid's +field+
    def field(name, *params)
      @model.translated_attribute_names.push name.to_sym
      @model.translated_attr_accessor(name)
      @model.translation_class.field name, *params
    end

    # Sets +fallbacks_for_empty_translations+ option.
    def fallbacks_for_empty_translations!
      @model.fallbacks_for_empty_translations = true
    end
  end
end
