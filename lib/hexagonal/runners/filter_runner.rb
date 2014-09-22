module Hexagonal
  module Runners
    class FilterRunner
      attr_writer :form, :repository

      delegate :found, :invalid, to: :listener

      def initialize(listener, user, attributes = nil)
        @listener   = listener
        @user       = user
        @attributes = attributes
      end

      def run
        validate! if attributes
        found items
      rescue Hexagonal::Errors::RecordInvalidException => ex
        invalid ex
      end

      private

      attr_reader :listener, :user, :attributes

      def items
        @items ||= repository.filter_for_user(user, form.attributes)
      end

      def validate!
        unless form.valid?
          fail Hexagonal::Errors::RecordInvalidException, form, caller
        end
      end
    end
  end
end
