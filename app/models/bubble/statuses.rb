module Bubble::Statuses
  extend ActiveSupport::Concern

  included do
    enum :status, %w[ creating drafted published ].index_by(&:itself)

    scope :published_or_drafted_by, ->(user) { where(status: :published).or(where(status: :drafted, creator: user)) }
  end

  def can_recover_abandoned_creation?
    abandoned_creations.where(updated_at: 1.day.ago..).any?
  end

  def recover_abandoned_creation
    abandoned_creations.last.tap do |bubble|
      Bubble.creating.where(creator: creator).excluding(bubble).destroy_all
    end
  end

  def publish
    transaction do
      published!
      track_event :published

      if assignments.any?
        track_event :assigned, assignee_ids: assignee_ids
      end
    end
  end

  private
    def abandoned_creations
      Bubble.creating.where(creator: creator).where("created_at != updated_at").excluding(self)
    end
end
