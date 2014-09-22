module Hexagonal
  module Runners
    class DeleteRunner
      pattr_initialize :listener, :user, :id

      delegate :unauthorized, :deleted_successfully, to: :listener

      attr_writer :policy, :repository

      def run
        authorize!
        delete!
        deleted_successfully target
      rescue Hexagonal::Errors::UnauthorizedException => ex
        unauthorized(ex)
      end

      private

      def authorize!
        fail! unless policy.delete?
      end

      def fail!
        fail Hexagonal::Errors::UnauthorizedException, 'Unauthorized', caller
      end

      def delete!
        mediator.call
      end

      def target
        @target ||= repository.find id
      end
    end
  end
end
