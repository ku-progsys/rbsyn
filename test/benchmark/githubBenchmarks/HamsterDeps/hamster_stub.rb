# require "thread"
# require "set"
require "concurrent/atomics"

# require "hamster/undefined"
# require "hamster/enumerable"
# require "hamster/hash"
# require "hamster/set"

module Hamster
  class << self

    # Create a lazy, infinite List_1.
    #
    # The given block is called as necessary to return successive elements of the List_1.
    #
    # @example
    #   Hamster.stream { :hello }.take(3)
    #   # => Hamster::List_1[:hello, :hello, :hello]
    #
    # @return [List_1]
    def stream(&block)
      return EmptyList_1 unless block_given?
      LazyList_1.new { Cons_1.new(yield, stream(&block)) }
    end
  end



  module List_1
    include Enumerable

    # @private
    CADR = /^c([ad]+)r$/

    # Create a new `List_1` populated with the given items.
    #
    # @example
    #   list = Hamster::List_1[:a, :b, :c]
    #   # => Hamster::List_1[:a, :b, :c]
    #
    # @return [List_1]
    def self.[](*items)
      from_enum(items)
    end


    # def split_at(number)
    #   [take(number), drop(number)].freeze
    # end


    # Return an empty `List_1`.
    #
    # @return [List_1]
    def self.empty
      EmptyList_1
    end


    # Return the number of items in this `List_1`.
    # @return [Integer]
    def size
      result, list = 0, self
      until list.empty?
        if list.cached_size?
          return result + list.size
        else
          result += 1
        end
        list = list.tail
      end
      result
    end
    alias :length :size


    def add(item)
      Cons_1.new(item, self)
    end
    alias :cons :add

    def <<(item)
      append(List_1[item])
    end

    def each
      return to_enum unless block_given?
      list = self
      until list.empty?
        yield(list.head)
        list = list.tail
      end
    end

    def take(number)
      LazyList_1.new do
        next self if empty?
        next Cons_1.new(head, tail.take(number - 1)) if number > 0
        EmptyList_1
      end
    end


    def drop(number)
      LazyList_1.new do
        list = self
        while !list.empty? && number > 0
          number -= 1
          list = list.tail
        end
        list
      end
    end





    # Retrieve the item at `index`. Negative indices count back from the end of
    # the list (-1 is the last item). If `index` is invalid (either too high or
    # too low), return `nil`.
    def at(index)
      index += size if index < 0
      return nil if index < 0
      node = self
      while index > 0
        node = node.tail
        index -= 1
      end
      node.head
    end

    def self.from_enum(items)
      # use destructive operations to build up a new list, like Common Lisp's NCONC
      # this is a very fast way to build up a linked list
      list = tail = Hamster::Cons_1.allocate
      items.each do |item|
        new_node = Hamster::Cons_1.allocate
        new_node.instance_variable_set(:@head, item)
        tail.instance_variable_set(:@tail, new_node)
        tail = new_node
      end
      tail.instance_variable_set(:@tail, Hamster::EmptyList_1)
      list.tail
    end

    # Return specific objects from the `List_1`. All overloads return `nil` if
    # the starting index is out of range.
    def slice(arg, length = (missing_length = true))
      if missing_length
        if arg.is_a?(Range)
          from, to = arg.begin, arg.end
          from += size if from < 0
          return nil if from < 0
          to   += size if to < 0
          to   += 1    if !arg.exclude_end?
          length = to - from
          length = 0 if length < 0
          list = self
          while from > 0
            return nil if list.empty?
            list = list.tail
            from -= 1
          end
          list.take(length)
        else
          at(arg)
        end
      else
        return nil if length < 0
        arg += size if arg < 0
        return nil if arg < 0
        list = self
        while arg > 0
          return nil if list.empty?
          list = list.tail
          arg -= 1
        end
        list.take(length)
      end
    end
    alias :[] :slice


    # Return true if `other` has the same type and contents as this `Hash`.
    def eql?(other)
      list = self
      loop do
        return true if other.equal?(list)
        return false unless other.is_a?(List_1)
        return other.empty? if list.empty?
        return false if other.empty?
        return false unless other.head.eql?(list.head)
        list = list.tail
        other = other.tail
      end
    end

    # See `Object#hash`
    # @return [Integer]
    def hash
      reduce(0) { |hash, item| (hash << 5) - hash + item.hash }
    end

    # Return `self`. Since this is an immutable object duplicates are
    def dup
      self
    end
    alias :clone :dup

    # Return `self`.
    # @return [List_1]
    def to_list
      self
    end

    # Return the contents of this `List_1` as a programmer-readable `String`. If all the
    # items in the list are serializable as Ruby literal strings, the returned string can
    # be passed to `eval` to reconstitute an equivalent `List_1`.
    def inspect
      result = "Hamster::List_1["
      each_with_index { |obj, i| result << ', ' if i > 0; result << obj.inspect }
      result << "]"
    end

    # Allows this `List_1` to be printed at the `pry` console, or using `pp` (from the
    # Ruby standard library), in a way which takes the amount of horizontal space on
    # the screen into account, and which indents nested structures to make them easier
    # to read.
    def pretty_print(pp)
      pp.group(1, "Hamster::List_1[", "]") do
        pp.breakable ''
        pp.seplist(self) { |obj| obj.pretty_print(pp) }
      end
    end

    # @private
    def respond_to?(name, include_private = false)
      super || !!name.to_s.match(CADR)
    end

    # Return `true` if the size of this list can be obtained in constant time (without
    # traversing the list).
    # @return [Integer]
    def cached_size?
      false
    end

    private

    # Perform compositions of `car` and `cdr` operations (traditional shorthand
    # for `head` and `tail` respectively). Their names consist of a `c`,
    # followed by at least one `a` or `d`, and finally an `r`. The series of
    # `a`s and `d`s in the method name identify the series of `car` and `cdr`
    # operations performed, in inverse order.
    def method_missing(name, *args, &block)
      if name.to_s.match(CADR)
        code = "def #{name}; self."
        code << Regexp.last_match[1].reverse.chars.map do |char|
          {'a' => 'head', 'd' => 'tail'}[char]
        end.join('.')
        code << '; end'
        List_1.class_eval(code)
        send(name, *args, &block)
      else
        super
      end
    end
  end

  # The basic building block for constructing lists
  class Cons_1
    include List_1

    attr_reader :head, :tail

    def initialize(head, tail = EmptyList_1)
      @head = head
      @tail = tail
      @size = tail.cached_size? ? tail.size + 1 : nil
    end

    def empty?
      false
    end

    def size
      @size ||= super
    end
    alias :length :size

    def cached_size?
      @size != nil
    end
  end

  # A `LazyList_1` takes a block that returns a `List_1`, i.e. an object that responds
  # to `#head`, `#tail` and `#empty?`. The list is only realized (i.e. the block is
  # only called) when one of these operations is performed.
  #
  # By returning a `Cons_1` that in turn has a {LazyList_1} as its tail, one can
  # construct infinite `List_1`s.
  #
  # @private
  class LazyList_1
    include List_1

    def initialize(&block)
      @head   = block # doubles as storage for block while yet unrealized
      @tail   = nil
      @atomic = Concurrent::AtomicReference.new(0) # haven't yet run block
      @size   = nil
    end

    def head
      realize if @atomic.get != 2
      @head
    end
    alias :first :head

    def tail
      realize if @atomic.get != 2
      @tail
    end

    def empty?
      realize if @atomic.get != 2
      @size == 0
    end

    def size
      @size ||= super
    end
    alias :length :size

    def cached_size?
      @size != nil
    end

    private

    QUEUE = ConditionVariable.new
    MUTEX = Mutex.new

    def realize
      while true
        # try to "claim" the right to run the block which realizes target
        if @atomic.compare_and_swap(0,1) # full memory barrier here
          begin
            list = @head.call
            if list.empty?
              @head, @tail, @size = nil, self, 0
            else
              @head, @tail = list.head, list.tail
            end
          rescue
            @atomic.set(0)
            MUTEX.synchronize { QUEUE.broadcast }
            raise
          end
          @atomic.set(2)
          MUTEX.synchronize { QUEUE.broadcast }
          return
        end
        # we failed to "claim" it, another thread must be running it
        if @atomic.get == 1 # another thread is running the block
          MUTEX.synchronize do
            # check value of @atomic again, in case another thread already changed it
            #   *and* went past the call to QUEUE.broadcast before we got here
            QUEUE.wait(MUTEX) if @atomic.get == 1
          end
        elsif @atomic.get == 2 # another thread finished the block
          return
        end
      end
    end
  end

  # Common behavior for other classes which implement various kinds of `List_1_1`s
  # @private
  class Realizable_1
    include List_1

    def initialize
      @head, @tail, @size = Undefined, Undefined, nil
    end

    def head
      realize if @head == Undefined
      @head
    end
    alias :first :head

    def tail
      realize if @tail == Undefined
      @tail
    end

    def empty?
      realize if @head == Undefined
      @size == 0
    end

    def size
      @size ||= super
    end
    alias :length :size

    def cached_size?
      @size != nil
    end

    def realized?
      @head != Undefined
    end
  end

  # A List_1 without any elements. This is a singleton, since all empty List_1s are equivalent.
  # @private
  module EmptyList_1
    class << self
      include List_1

      # There is no first item in an empty List_1, so return `nil`.
      # @return [nil]
      def head
        nil
      end
      alias :first :head

      # There are no subsequent elements, so return an empty List_1.
      # @return [self]
      def tail
        self
      end

      def empty?
        true
      end

      # Return the number of items in this `List_1`.
      # @return [Integer]
      def size
        0
      end
      alias :length :size

      def cached_size?
        true
      end
    end
  end.freeze
end