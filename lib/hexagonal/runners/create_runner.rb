module Hexagonal
  module Runners
    class Hexagonal::Runners::CreateRunner
      pattr_initialize :listener, :user, :attributes

      delegate :created_successfully, :creation_failed, to: :listener
      delegate :target,                                 to: :mediator

      attr_writer :form

      def run
        validate!
        create!
      rescue Hexagonal::Errors::RecordInvalidException => ex
        creation_failed(ex)
      end

      private

      def create!
        mediator.call
        created_successfully(target)
      end

      def validate!
        unless form.valid?
          fail Hexagonal::Errors::RecordInvalidException, form, caller
        end
      end
    end
  end
end