require 'mongoid_globalize/adapter'
require 'mongoid_globalize/act_macro'
require 'mongoid_globalize/attributes'
require 'mongoid_globalize/class_methods'
require 'mongoid_globalize/document_translation'
require 'mongoid_globalize/fields_builder'
require 'mongoid_globalize/methods'

module Mongoid::Globalize

  include Mongoid::Globalize::Methods

  # When Mongoid::Globalize included into Mongoid document class, for this class
  # code inside +included+ block will be executed, methods from
  # Mongoid::Globalize::ClassMethods module become class methods due to
  # ActiveSupport::Concern mechanism.
  extend ActiveSupport::Concern

  # Define some class attributes: +translated_attribute_names+ will be contain
  # attributes' names, when its will be registered as translated.
  # +fallbacks_for_empty_translations+ contains condition to show fallbacks for
  # blank value of attribute or not.
  #
  # Then one side for embeded relationship with translation documents is
  # created, and some callbacks for processing changed translations are defined.
  #
  # And then Mongoid document class extended by Mongoid::Globalize::ActMacro
  # module which contains macro method +translates+ for defining translated
  # fields, translations options etc.
  included do
    class_attribute :translated_attribute_names, :fallbacks_for_empty_translations
    self.translated_attribute_names = []
    embeds_many :translations, :class_name  => translation_class.name
    before_save :prepare_translations!
    after_save :clear_translations!

    extend Mongoid::Globalize::ActMacro
  end

  class << self
    # Get current locale. If curent locale doesn't set obviously for
    # Mongoid::Globalize, returns I18n locale
    #     Mongoid::Globalize.locale   #=> :en
    # Returns Symbol
    def locale
      read_locale || I18n.locale
    end

    # Set current locale by saving it in current thread.
    #     Mongoid::Globalize.locale = 'ru'    #=> :ru
    # Param String or Symbol
    # Returns Symbol or nil
    def locale=(locale)
      set_locale(locale)
    end

    # Runs block as if given locale is setted. Don't touch current locale. Yelds
    # locale into block.
    #     Mongoid::Globalize.with_locale(:de) { post.title = 'Titel' }
    # Param String or Symbol
    # Param Proc
    # Returns result from block
    def with_locale(locale, &block)
      previous_locale = read_locale
      set_locale(locale)
      result = yield(locale)
      set_locale(previous_locale)
      result
    end

    # Runs block for each given locale.
    #     Mongoid::Globalize.with_locale(:ru, [:de, :fr]) { post.title = 'Title' }
    # Params String or Symbol or Array of Strings or Symbols
    # Param Proc
    # Returns Array with results from block for each locale
    def with_locales(*locales, &block)
      locales.flatten.map do |locale|
        with_locale(locale, &block)
      end
    end

    # Checks whether I18n respond to +fallbacks+ method.
    # Returns true or false
    def fallbacks?
      I18n.respond_to?(:fallbacks)
    end

    # Returns fallback locales for given locale if any.
    # Returns Array of Symbols
    def fallbacks(locale = self.locale)
      fallbacks? ? I18n.fallbacks[locale] : [locale.to_sym]
    end

  protected
    # Reads locale from current thread
    def read_locale
      Thread.current[:globalize_locale]
    end

    # Writes locale to current thread
    def set_locale(locale)
      Thread.current[:globalize_locale] = locale.to_sym rescue nil
    end
  end
end
