    # def partition(&block)
    #   return enum_for(:partition) if not block_given?
    #   partitioner = Partitioner.new(self, block)
    #   mutex = Mutex.new
    #   [Partitioned.new(partitioner, partitioner.left, mutex),
    #    Partitioned.new(partitioner, partitioner.right, mutex)].freeze
    # end