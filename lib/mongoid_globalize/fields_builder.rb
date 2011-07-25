module Mongoid::Globalize
  class FieldsBuilder
    def initialize(model)
      @model = model
    end

    def field(name, *params)
      @model.translated_attribute_names.push name.to_sym
      @model.translated_attr_accessor(name)
      @model.translation_class.field name, *params
    end

    def fallbacks_for_empty_translations!
      @model.fallbacks_for_empty_translations = true
    end
  end
end
