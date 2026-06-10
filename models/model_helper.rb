ActiveRecord::Schema.define do
  create_table :users, force: true do |t|
    t.string :name
    t.string :username
    t.string :password
    t.boolean :staged
    t.boolean :active
    t.boolean :admin
    t.boolean :moderator
  end
  create_table :user_emails, force: true do |t|
    t.string :email
    t.boolean :primary
    t.references :user
  end
  create_table :email_tokens, force: true do |t|
    t.string :email
    t.string :token
    t.boolean :confirmed
    t.boolean :expired
    t.references :user
  end
  create_table :another_users, force: true do |t|
    t.string :name
    t.string :username
    t.string :password
    t.boolean :staged
    t.string :email
    t.boolean :active
  end
  create_table :posts, force: true do |t|
    t.string :created_by
    t.string :slug
    t.string :title
  end
  create_table :demo_users, force: true do |t|
    t.string :name
    t.string :username
    t.boolean :admin
  end
  create_table :gitlab_issues, force: true do |t|
    t.integer :state_id
    t.datetime :closed_at
    t.references :closed_by
  end
  create_table :gitlab_users, force: true do |t|
    t.boolean :otp_required_for_login
    t.string :encrypted_otp_secret
    t.string :encrypted_otp_secret_iv
    t.string :encrypted_otp_secret_salt
    t.string :otp_backup_codes
    t.datetime :otp_grace_period_started_at
  end
  create_table :gitlab_notes, force: true do |t|
    t.bigint :gitlab_note_id
    t.bigint :gitlab_discussion_id
  end
  create_table :gitlab_merge_requests, force: true do |t|
    t.bigint :gitlab_note_id
  end
  create_table :gitlab_discussions, force: true do |t|
    t.bigint :note_id
    t.bigint :noteable_id
  end
  create_table :invitation_codes, force: true do |t|
    t.string :token
    t.integer :diaspora_user_id
    t.integer :count
  end
  create_table :diaspora_users, force: true do |t|
    t.string :username
    t.integer :invited_by_id
    t.string :confirm_email_token
    t.string :email
    t.string :unconfirmed_email
  end
  create_table :diaspora_pods, force: true do |t|
    t.datetime :updated_at
    t.boolean :scheduled_check
    t.integer :status
  end
  create_table :mastodon_accounts, force: true do |t|
    t.string :actor_type
    t.boolean :discoverable
    t.string :display_name
    t.string :domain
    t.text :fields
    t.text :private_key
    t.integer :protocol, default: 0
    t.text :public_key
    t.integer :suspension_origin, default: 0
    t.integer :id_scheme, default: 0
    t.string :uri
    t.string :username
    t.text :note
  end
  create_table :mastodon_account_stats, force: true do |t|
    t.references :mastodon_account, null: false # Fixed typo
    t.integer :statuses_count, default: 0       # Added missing column
    t.integer :following_count, default: 0      # Added missing column
    t.integer :followers_count, default: 0      # Added missing column
  end

  # Add this to handle the "statuses" recount logic
  create_table :mastodon_statuses, force: true do |t|
    t.references :mastodon_account, null: false
    t.integer :visibility, default: 0
    t.bigint :in_reply_to_id
    t.bigint :reblog_of_id
    t.bigint :quoted_status_id
    t.text :text
  end

  # Add this to store the counts that Cache#recount updates
  create_table :mastodon_status_stats, force: true do |t|
    t.references :mastodon_status, null: false
    t.integer :replies_count, default: 0
    t.integer :reblogs_count, default: 0
    t.integer :favourites_count, default: 0
    t.integer :quotes_count, default: 0
  end

  create_table :follows, force: true do |t|
    t.references :mastodon_account, null: false
    t.references :target_account, null: false
  end

  create_table :favourites, force: true do |t|
    t.references :mastodon_account, null: false, foreign_key: { to_table: :mastodon_accounts }
    t.references :mastodon_status,  null: false, foreign_key: { to_table: :mastodon_statuses }
    
  end
end

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def self.update_index(*args, &block)
    # no-op for testing purposes
  end
end

require_relative "user"
require_relative "user_email"
require_relative "email_token"
require_relative "another_user"
require_relative "post"
require_relative "demo_user"
require_relative "gitlab_issue"
require_relative "gitlab_user"
require_relative "gitlab_discussion"
require_relative "diaspora"
require_relative "mastodon_account"
require_relative "mastodon_account_stat"
require_relative "mastodon_status"
require_relative "mastodon_status_stat"
require_relative "follow"
require_relative "favourite"