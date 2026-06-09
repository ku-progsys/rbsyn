require "test_helper"
require_relative "../../../rails_helper"
require_relative "../../../cli/email_domain_blocks"
require_relative "../../../cli/email_domain_blocks_extension"

describe "Mastodon::CLI::EmailDomainBlocks" do
  it "email_domain_blocks#add" do
    load_typedefs :stdlib, :active_record

    # Define RDL types for required classes and methods used inside #add
    RDL.type Array, :empty?, "() -> %bool", wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :fail_with_message, "(String) -> %any", wrap: false
    RDL.type Array, :each, "() { (String) -> %any } -> Array", wrap: false
    RDL.type 'EmailDomainBlock', 'self.exists?', "(Hash) -> %bool", wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :say, "(String, Symbol) -> %any", wrap: false
    RDL.type Integer, :+, "(Integer) -> Integer", wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :options, "() -> Hash", wrap: false
    RDL.type Hash, :[], "(Symbol) -> %any", wrap: false
    RDL.type 'DomainResource', 'self.new', "(String) -> DomainResource", wrap: false
    RDL.type DomainResource, :mx, "() -> Array", wrap: false
    RDL.type 'EmailDomainBlock', 'self.new', "(Hash) -> EmailDomainBlock", wrap: false
    RDL.type EmailDomainBlock, :save!, "() -> %bool", write: ["EmailDomainBlock"], wrap: false
    RDL.type EmailDomainBlock, :other_domains, "() -> Array", wrap: false
    RDL.type Array, :uniq, "() -> Array", wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :color, "(Integer, Integer) -> Symbol", wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :add, "(*String) -> %any", wrap: false

    define :add, "(Mastodon::CLI::EmailDomainBlocks, *String) -> %any", prog_size: 50 do
      spec "adds a new block when none exist" do
        setup {
          @cli = Mastodon::CLI::EmailDomainBlocks.new
          @domain = 'host.example'
          add(@cli, @domain)
        }
        post { |result|
          assert { EmailDomainBlock.exists?(domain: @domain) }
        }
      end

      spec "does not add a new block when one already exists" do
        setup {
          @cli = Mastodon::CLI::EmailDomainBlocks.new
          @domain = 'host.example'
          Fabricate(:email_domain_block, domain: @domain)
          @initial_count = EmailDomainBlock.count
          add(@cli, @domain)
        }
        post { |result|
          assert { EmailDomainBlock.count == @initial_count }
        }
      end

      generate_program
    end
  end
end
