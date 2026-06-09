require "test_helper"
require_relative "../../../rails_helper"

describe "Mastodon::CLI::EmailDomainBlocks" do
  it "email_domain_blocks#remove" do
    load_typedefs :stdlib, :active_record

    # Define RDL types for required classes and methods used inside #remove
    RDL.type Array, :empty?, "() -> %bool", wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :fail_with_message, "(String) -> %any", wrap: false
    RDL.type Array, :each, "() { (String) -> %any } -> Array", wrap: false
    RDL.type 'EmailDomainBlock', 'self.find_by', "(Hash) -> EmailDomainBlock", wrap: false
    RDL.type EmailDomainBlock, :nil?, "() -> %bool", wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :say, "(String, Symbol) -> %any", wrap: false
    RDL.type 'EmailDomainBlock', 'self.where', "(Hash) -> ActiveRecord::Relation", wrap: false
    RDL.type EmailDomainBlock, :id, "() -> Integer", wrap: false
    RDL.type ActiveRecord::Relation, :count, "() -> Integer", wrap: false
    RDL.type EmailDomainBlock, :destroy, "() -> %bool", write: ["EmailDomainBlock"], wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :color, "(Integer, Integer) -> Symbol", wrap: false
    RDL.type Integer, :+, "(Integer) -> Integer", wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :remove, "(*String) -> %any", wrap: false

    define :remove, "(Mastodon::CLI::EmailDomainBlocks, *String) -> %any", prog_size: 50 do
      spec "removes an existing block" do
        setup {
          @cli = Mastodon::CLI::EmailDomainBlocks.new
          @domain = 'host.example'
          Fabricate(:email_domain_block, domain: @domain)
          remove(@cli, @domain)
        }
        post { |result|
          assert { !EmailDomainBlock.exists?(domain: @domain) }
        }
      end

      spec "does nothing when the block does not exist" do
        setup {
          @cli = Mastodon::CLI::EmailDomainBlocks.new
          @domain = 'host.example'
          @initial_count = EmailDomainBlock.count
          remove(@cli, @domain)
        }
        post { |result|
          assert { EmailDomainBlock.count == @initial_count }
        }
      end

      generate_program
    end
  end
end
