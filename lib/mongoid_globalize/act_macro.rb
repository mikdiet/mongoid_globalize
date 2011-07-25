module Mongoid::Globalize
  module ActMacro
    #    translates do
    #      field :title
    #      field :visible, type: Boolean
    #    end
    def translates(&block)
      builder = FieldsBuilder.new(self)
      builder.instance_exec(&block)
    end
  end
end
