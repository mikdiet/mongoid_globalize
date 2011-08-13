module Mongoid::Globalize
  module ActMacro
    # Determines translation parameters: fields and options. Available inside
    # block methods are defined in Mongoid::Globalize::FieldsBuilder.
    #     translates do
    #       field :title
    #       field :visible, type: Boolean
    #       fallbacks_for_empty_translations!
    #     end
    #
    # Param Proc
    def translates(&block)
      builder = FieldsBuilder.new(self)
      builder.instance_exec(&block)
    end
  end
end
