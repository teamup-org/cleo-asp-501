class StudentInfo < ApplicationRecord
    self.primary_key = 'uin'
  
    belongs_to :student, foreign_key: 'uin', primary_key: 'google_id'
  
    validates :uin, presence: true, uniqueness: true
    validates :current_gpa, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 4.0 }, allow_nil: true
    validates :preferred_time, :preferred_loc, presence: true, allow_blank: true
  end
  