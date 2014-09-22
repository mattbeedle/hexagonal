module Hexagonal
  module Responses
    class CreateResponse
      def created_successfully(object)
        present object.class.to_s.underscore.to_sym, object
      end

      def creation_failed(exception)
        error!({ errors: exception.record.errors }, 422)
      end
    end
  end
end