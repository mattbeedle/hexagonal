module Hexagonal
  module Adapters
    module ActiveRecordAdapter
      class UnitOfWork
        def run(&block)
          ActiveRecord::Base.transaction { yield }
        end
      end
    end
  end
end
