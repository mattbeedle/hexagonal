module Hexagonal
  module Responses
    class FindAllResponse
      delegate :error!, :garner, :pagination, :present, to: :target

      def initialize(target, key, paginated: false, cache_method: nil)
        @target       = target
        @key          = key
        @paginated    = paginated
        @cache_method = cache_method
      end

      def found(objects)
        garner.bind(cache_key(objects)) do
          present(key, objects).as_json
          present(:meta, pagination(objects)).as_json if paginated
        end
      end

      def invalid(exception)
        error!({ errors: exception.record.errors }, 422)
      end

      private

      attr_reader :cache_method, :key, :paginated, :target

      def cache_key(objects)
        cache_method ? objects.send(cache_method) : objects
      end
    end
  end
end
