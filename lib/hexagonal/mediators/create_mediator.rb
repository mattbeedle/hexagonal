module Hexagonal
  module Mediators
    class CreateMediator
      pattr_initialize :user, :attributes

      attr_writer :repository

      def initialize(user, attributes)
        @user       = user
        @attributes = attributes.merge(default_attributes)
      end

      def call
        repository.save! target
      end

      private

      attr_reader :attributes, :repository

      def default_attributes
        {}
      end
    end
  end
end
