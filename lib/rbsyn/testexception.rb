class TestException < StandardError
  attr_reader :extra_args

  # Initialize with a message (string) and optional extra arguments
  def initialize(message, *args)
    super(message)          # Pass the message to StandardError
    @extra_args = args      # Store the extra arguments
  end
end

