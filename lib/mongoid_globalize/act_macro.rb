module Mongoid::Globalize
  module ActMacro
    # TODO: other interface of +translates+. Like this:
    #     translates do
    #       field :title
    #       field :visible, type: Boolean
    #     end
    def translates(*attr_names_or_hashes)
      attr_hash = attr_names_or_hashes.inject({}) do |hash,attr|
        hash.merge(attr.is_a?(Hash) ? attr : {attr => String})
      end
      attr_hash.each do |name, type|
        self.translated_attribute_names.push name.to_sym
        translated_attr_accessor(name)
        translation_class.field name, type: type
      end
    end

    def fallbacks_for_empty_translations!
      self.fallbacks_for_empty_translations = true
    end
  end
end
