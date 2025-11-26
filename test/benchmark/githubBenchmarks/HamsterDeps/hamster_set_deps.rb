require_relative "enumerable"
require_relative "immutable"
require_relative "trie"
#require "hamster"


module Hamster

  class Set_1
    include Immutable
    include Enumerable
    attr_accessor :trie

    class << self

      def [](*items)
        items.empty? ? empty : new(items)
      end


      def empty
        @empty ||= self.new
      end


      def alloc(trie = EmptyTrie)
        allocate.tap { |s| s.instance_variable_set(:@trie, trie) }
      end
    end

    def initialize(items=[])
      @trie = Trie.new(0)
      items.each { |item| @trie.put!(item, nil) }
    end


    def empty?
      @trie.empty?
    end

    def size
      @trie.size
    end
    alias :length :size


    def add(item)
      include?(item) ? self : self.class.alloc(@trie.put(item, nil))
    end
    alias :<< :add

  
    def add?(item)
      !include?(item) && add(item)
    end

    def include?(object)
      @trie.key?(object)
    end
    alias :member? :include?

    # def delete(item)
    #   trie = @trie.delete(item)
    #   new_trie(trie)
    # end

    # def delete?(item)
    #   include?(item) && delete(item)
    # end

    def new_trie(trie)
      if trie.empty?
        self.class.empty
      elsif trie.equal?(@trie)
        self
      else
        self.class.alloc(trie)
      end
    end
    
    def eql?(other)
      return true if other.equal?(self)
      return false if not instance_of?(other.class)
      other_trie = other.instance_variable_get(:@trie)
      return false if @trie.size != other_trie.size
      @trie.each do |key, _|
        return false if !other_trie.key?(key)
      end
      true
    end
    alias :== :eql?

    def empty
      @empty ||= self.new
    end


    
  end
  EmptySet_1 = Hamster::Set_1.empty
end