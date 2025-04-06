class TemporaryTranscriptCourse < ApplicationRecord
  validates :session_id, presence: true
  validates :ccode, presence: true
  validates :cnumber, presence: true
  validates :credit_hours, presence: true, numericality: { greater_than: 0 }

  def self.for_session(session_id)
    where(session_id: session_id)
  end

  def self.clear_session(session_id)
    where(session_id: session_id).destroy_all
  end
end 