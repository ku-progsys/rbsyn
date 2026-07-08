class TypedNode < Parser::AST::Node
  # ttype: term type
  attr_reader :ttype

  def initialize(ttype, type, *children)
    @ttype = ttype
    super(type, children)
  end

  # This is monkey patched. See original source in ast gem
  # Use object identity (equal?) for children comparison instead of ==
  # to avoid ignoring ttype differences in structurally equal child nodes.
  def updated(type=nil, children=nil, properties=nil)
    new_type       = type       || @type
    new_children   = children   || @children

    if type.nil? && children.nil? && properties.nil?
      return self
    end

    if @type == new_type &&
        @children.length == new_children.length &&
        @children.each_with_index.all? { |item, i| item.equal?(new_children[i]) } &&
        properties.nil?
      self
    else
      original_dup.send :initialize, @ttype, new_type, *new_children
    end
  end

  def update_ttype(ttype)
    original_dup.send :initialize, ttype, @type, *@children
  end
end
