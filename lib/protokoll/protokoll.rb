module Protokoll
  extend ActiveSupport::Concern

  module ClassMethods

    # Class method available in models
    #
    # == Example
    #   class Order < ActiveRecord::Base
    #      protokoll :number
    #   end
    #
    def protokoll(column, _options = {})
      options = { :pattern       => "%Y%m#####",
                  :number_symbol => "#",
                  :column        => column,
                  :start         => 0,
                  :scope_by      => nil,
                  :model_name    => nil }

      options.merge!(_options)
      raise ArgumentError.new("pattern can't be nil!") if options[:pattern].nil?
      raise ArgumentError.new("pattern requires at least one counter symbol #{options[:number_symbol]}") unless pattern_includes_symbols?(options)

      # Defining custom method
      send :define_method, "reserve_#{options[:column]}!".to_sym do
        self[column] = Counter.next(self, options)
      end
      send :define_method, "preview_next_#{options[:column]}".to_sym do
        Counter.preview_next(self, options)
      end

      # preview before_validation if column is blank
      before_validation do |record|
        if record[column].blank?
          record[column] = Counter.preview_next(self, options)
        end
      end

      # Signing before_create
      before_create do |record|
        if record[column].blank? || ( record[column] == Counter.preview_next(self, options) )
          record[column] = Counter.next(self, options)
        end
      end
    end

    private

    def pattern_includes_symbols?(options)
      options[:pattern].count(options[:number_symbol]) > 0
    end
  end

end
