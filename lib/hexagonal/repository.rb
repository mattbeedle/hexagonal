module Hexagonal
  class Repository
    attr_writer :database_klass, :adapter

    def all
      adapter.all
    end

    def find(id)
      adapter.find id
    end

    def save(object)
      adapter.save(object)
    end

    def save!(object)
      adapter.save!(object)
    end

    def destroy(object)
      adapter.destroy(object)
    end

    def unit_of_work
      adapter.unit_of_work
    end

    private

    def adapter
      @adapter ||= Hexagonal::Adapters::ActiveRecordAdapter.new(database_klass)
    end
  end
end
