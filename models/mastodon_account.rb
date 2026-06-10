# frozen_string_literal: true


class MastodonAccount< ApplicationRecord

  
  # Constants required for internal validations and state
  DEFAULT_FIELDS_SIZE = 4
  USERNAME_RE   = /[a-z0-9_]+([.-]+[a-z0-9_]+)*/i
  USERNAME_ONLY_RE = /\A#{USERNAME_RE}\z/i
  USERNAME_LENGTH_LIMIT = 30
  DISPLAY_NAME_LENGTH_LIMIT = 30
  NOTE_LENGTH_LIMIT = 500
  USERNAME_LENGTH_HARD_LIMIT = 2048
  AUTOMATED_ACTOR_TYPES = %w(Application Service).freeze

  # Explicitly defining the relationship to AccountStat
  has_one :mastodon_account_stat, class_name: 'MastodonAccountStat', inverse_of: :mastodon_account, dependent: :destroy

  has_many :active_relationships,  class_name: 'Follow', foreign_key: 'mastodon_account_id', dependent: :destroy
  has_many :passive_relationships, class_name: 'Follow', foreign_key: 'target_account_id', dependent: :destroy
  has_many :mastodon_statuses

  enum :protocol, { ostatus: 0, activitypub: 1 }
  enum :suspension_origin, { local: 0, remote: 1 }, prefix: true
  enum :id_scheme, { username_ap_id: 0, numeric_ap_id: 1 }

  # Core internal data validations
  validates :username, presence: true
  validates :username, format: { with: USERNAME_ONLY_RE }, length: { maximum: USERNAME_LENGTH_HARD_LIMIT }, if: -> { (remote? || actor_type_application?) && will_save_change_to_username? }
  validates :uri, presence: true, unless: :local?, on: :create
  validates :username, format: { with: /\A[a-z0-9_]+\z/i }, length: { maximum: USERNAME_LENGTH_LIMIT }, if: -> { local? && will_save_change_to_username? && !actor_type_application? }
  validates :display_name, length: { maximum: DISPLAY_NAME_LENGTH_LIMIT }, if: -> { local? && will_save_change_to_display_name? }
  validates :fields, length: { maximum: DEFAULT_FIELDS_SIZE }, if: -> { local? && will_save_change_to_fields? }
  validates :domain, exclusion: { in: [''] }

  normalizes :username, with: ->(username) { username.squish }

  # Scopes strictly involving AccountStat and basic internal queries
  scope :local, -> { where(domain: nil) }
  scope :discoverable, -> { where(discoverable: true).joins(:mastodon_account_stat) }
  scope :by_recent_status, -> { includes(:mastodon_account_stat).merge(AccountStat.by_recent_status).references(:mastodon_account_stat) }
  scope :by_recent_activity, -> { left_joins(:mastodon_account_stat).order(coalesced_activity_timestamps.desc).order(id: :desc) }
  scope :dormant, -> { joins(:mastodon_account_stat).merge(AccountStat.without_recent_activity) }

  # Internal state manipulation callbacks
  before_validation :prepare_contents, if: :local?
  before_create :generate_keys

  # Internal State Checkers & Mutators
  def local?
    domain.nil?
  end

  def remote?
    !domain.nil?
  end

  def bot?
    AUTOMATED_ACTOR_TYPES.include?(actor_type)
  end
  alias bot bot?

  def bot=(val)
    self.actor_type = ActiveModel::Type::Boolean.new.cast(val) ? 'Service' : 'Person'
  end

  def actor_type_application?
    actor_type == 'Application'
  end

  # Internal JSONb field mutators
  def fields
    (self[:fields] || []).filter_map do |f|
      MastodonAccount::Field.new(self, f)
    rescue
      nil
    end
  end

  def fields_attributes=(attributes)
    fields_arr = []
    old_fields = self[:fields] || []
    old_fields = [] if old_fields.is_a?(Hash)

    attributes = attributes.values if attributes.is_a?(Hash)

    attributes.each do |attr|
      next if attr[:name].blank? && attr[:value].blank?
      previous = old_fields.find { |item| item['value'] == attr[:value] }
      attr[:verified_at] = previous['verified_at'] if previous && previous['verified_at'].present?
      fields_arr << attr
    end

    self[:fields] = fields_arr
  end

  def build_fields
    return if fields.size >= DEFAULT_FIELDS_SIZE

    tmp = self[:fields] || []
    tmp = [] if tmp.is_a?(Hash)

    (DEFAULT_FIELDS_SIZE - tmp.size).times do
      tmp << { name: '', value: '' }
    end

    self.fields = tmp
  end

  class << self
    def coalesced_activity_timestamps
      # Trimmed to focus purely on the AccountStat data relation
      Arel.sql(
        <<~SQL.squish
          COALESCE(mastodon_account_stats.last_status_at, to_timestamp(0))
        SQL
      )
    end
  end

  private

  def prepare_contents
    display_name&.strip!
    note&.strip!
  end

  def generate_keys
    return unless local? && private_key.blank? && public_key.blank?

    keypair = OpenSSL::PKey::RSA.new(2048)
    self.private_key = keypair.to_pem
    self.public_key  = keypair.public_key.to_pem
  end
end