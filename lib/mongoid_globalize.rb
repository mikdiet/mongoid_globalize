require 'mongoid_globalize/adapter'
require 'mongoid_globalize/act_macro'
require 'mongoid_globalize/attributes'
require 'mongoid_globalize/class_methods'
require 'mongoid_globalize/document_translation'
require 'mongoid_globalize/fields_builder'
require 'mongoid_globalize/instance_methods'

module Mongoid::Globalize
  extend ActiveSupport::Concern
  included do
    class_attribute :translated_attribute_names, :fallbacks_for_empty_translations
    self.translated_attribute_names = []
    embeds_many :translations, :class_name  => translation_class.name
    before_save :prepare_translations!
    after_save :clear_translations!

    extend Mongoid::Globalize::ActMacro
  end

  class << self
    def locale
      read_locale || I18n.locale
    end

    def locale=(locale)
      set_locale(locale)
    end

    def with_locale(locale, &block)
      previous_locale = read_locale
      set_locale(locale)
      result = yield(locale)
      set_locale(previous_locale)
      result
    end

    def with_locales(*locales, &block)
      locales.flatten.map do |locale|
        with_locale(locale, &block)
      end
    end

    def fallbacks?
      I18n.respond_to?(:fallbacks)
    end

    def fallbacks(locale = self.locale)
      fallbacks? ? I18n.fallbacks[locale] : [locale.to_sym]
    end

  protected
    def read_locale
      Thread.current[:globalize_locale]
    end

    def set_locale(locale)
      Thread.current[:globalize_locale] = locale.to_sym rescue nil
    end
  end
end
