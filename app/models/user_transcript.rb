class UserTranscript < ApplicationRecord
    belongs_to :student, primary_key: :uin, foreign_key: "google_id"
  
    validates :transcript, presence: true
  end
  