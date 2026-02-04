class ComplexError < Exception
  attr_reader :outer_receiver, :outer_method, :inner_error

  def initialize(inner_error, outer_receiver:, outer_method:)
    @inner_error    = inner_error
    @outer_receiver = outer_receiver
    @outer_method   = outer_method

    super(build_message)
    set_backtrace(inner_error.backtrace)
  end

  private

  def build_message
    "Outer call: #{outer_receiver.inspect}.#{outer_method} | " \
    "Inner error: #{inner_error.class}: #{inner_error.message}"
  end
end