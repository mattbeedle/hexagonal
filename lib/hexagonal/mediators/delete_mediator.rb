module Hexagonal
  module Mediators
    class DeleteMediator
      pattr_initialize :user, :target

      attr_writer :repository

      def call
        repository.destroy target
      end

      private

      attr_reader :repository
    end
  end
end
