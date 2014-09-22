module Hexagonal
  module Adapters
    class ActiveRecordAdapter
      include ActiveSupport::Rescuable

      pattr_initialize :persistence

      rescue_from ActiveRecord::RecordNotFound,   with: :record_not_found
      rescue_from ActiveRecord::StatementInvalid, with: :statement_invalid

      def find(id)
        persistence.find id
      rescue ActiveRecord::RecordNotFound, ActiveRecord::StatementInvalid => e
        rescue_with_handler(e)
      end

      def save(object)
        object.save
      rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
        rescue_with_handler(e)
      end

      def save!(object)
        object.save!
        object
      rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
        rescue_with_handler(e)
      end

      def destroy(object)
        object.destroy
      rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
        rescue_with_handler(e)
      end

      def query(&block)
        yield(persistence)
      rescue ActiveRecord::RecordNotFound, ActiveRecord::StatementInvalid => e
        rescue_with_handler(e)
      end

      def unit_of_work
        @unit_of_work ||=
          Hexagonal::Adapters::ActiveRecordAdapter::UnitOfWork.new
      end

      def method_missing(method_sym, *arguments, &block)
        persistence.send(method_sym, *arguments, &block)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::StatementInvalid => e
        rescue_with_handler(e)
      end

      private

      def record_not_found(exception)
        fail Hexagonal::Errors::RecordNotFoundException, exception, caller
      end

      def statement_invalid(exception)
        fail Hexagonal::Errors::StatementInvalidException, exception, caller
      end

    end
  end
end
