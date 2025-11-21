module Card::Statuses
  extend ActiveSupport::Concern

  included do
    enum :status, %w[ drafted published ].index_by(&:itself)

    before_save :update_created_at_on_publication
    after_create -> { track_event :published }, if: :published?

    scope :published_or_drafted_by, ->(user) { where(status: :published).or(where(status: :drafted, creator: user)) }
  end

  def publish
    transaction do
      published!
      track_event :published
    end
  end

  private
    def update_created_at_on_publication
      if will_save_change_to_status? && status_in_database.inquiry.drafted?
        self.created_at = Time.current
      end
    end
end
