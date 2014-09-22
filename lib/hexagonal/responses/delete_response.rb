module Hexagonal
  module Responses
    class DeleteResponse < SimpleDelegator
      def deleted_successfully(object)
        status 204
      end

      def unauthorized(exception)
        error!({ message: exception.message }, 401)
      end
    end
  end
end
