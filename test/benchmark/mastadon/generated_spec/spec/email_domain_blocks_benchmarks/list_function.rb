require "test_helper"
require_relative "../../../rails_helper"
require_relative "../../../cli/email_domain_blocks"
require_relative "../../../cli/email_domain_blocks_extension"

describe "Mastodon::CLI::EmailDomainBlocks" do
  it "email_domain_blocks#list" do
    load_typedefs :stdlib, :active_record

    # Define RDL types for required classes and methods used inside #list
    RDL.type Mastodon::CLI::EmailDomainBlocks, :options, "() -> Hash", wrap: false
    RDL.type Hash, :[], "(Symbol) -> %any", wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :fail_with_message, "(String) -> %any", wrap: false
    RDL.type 'EmailDomainBlock', 'self.parents', "() -> ActiveRecord::Relation", wrap: false
    RDL.type ActiveRecord::Relation, :where, "(Hash) -> ActiveRecord::Relation", wrap: false
    RDL.type ActiveRecord::Relation, :find_each, "() { (EmailDomainBlock) -> %any } -> %any", wrap: false
    RDL.type EmailDomainBlock, :domain, "() -> String", wrap: false
    RDL.type String, :to_s, "() -> String", wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :say, "(String, Symbol) -> %any", wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :shell, "() -> Thor::Shell::Basic", wrap: false
    # RDL.type Thor::Shell::Basic, :indent, "() { () -> %any } -> %any", wrap: false
    RDL.type 'EmailDomainBlock', 'self.where', "(Hash) -> ActiveRecord::Relation", wrap: false
    RDL.type EmailDomainBlock, :id, "() -> Integer", wrap: false
    RDL.type Mastodon::CLI::EmailDomainBlocks, :list, "() -> %any", wrap: false

    define :list, "(Mastodon::CLI::EmailDomainBlocks) -> %any", prog_size: 50 do
      spec "lists email domain blocks" do
        setup {
          @cli = Mastodon::CLI::EmailDomainBlocks.new
          @parent_block = Fabricate(:email_domain_block)
          list(@cli)
        }
        post { |result|
        }
      end

      generate_program
    end
  end
end
