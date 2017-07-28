require_dependency 'enum'

class WatchedWord < ActiveRecord::Base

  def self.actions
    @actions ||= Enum.new(
      block: 1,
      censor: 2,
      require_approval: 3,
      flag: 4
    )
  end

  MAX_WORDS_PER_ACTION = 1000

  before_validation do
    self.word = self.class.normalize_word(self.word)
  end

  validates :word,   presence: true, uniqueness: true, length: { maximum: 50 }
  validates :action, presence: true
  validates_each :word do |record, attr, val|
    if WatchedWord.where(action: record.action).count >= MAX_WORDS_PER_ACTION
      record.errors.add(:word, :too_many)
    end
  end

  after_save    :clear_cache
  after_destroy :clear_cache

  scope :by_action, -> { order("action ASC, word ASC") }

  def self.normalize_word(w)
    w.strip.downcase.squeeze('*')
  end

  def self.create_or_update_word(params)
    w = find_or_initialize_by(word: normalize_word(params[:word]))
    w.action_key = params[:action_key] if params[:action_key]
    w.action = params[:action] if params[:action]
    w.save
    w
  end

  def action_key=(arg)
    self.action = self.class.actions[arg.to_sym]
  end

  def clear_cache
    WordWatcher.clear_cache!
  end

end
