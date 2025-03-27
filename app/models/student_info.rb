class StudentInfo < ApplicationRecord
    self.primary_key = 'uin'
  
    belongs_to :student, foreign_key: 'uin', primary_key: 'google_id'

    PREFERRED_TIMES = ['No Preference', 'Morning', 'Afternoon', 'Evening']
    PREFERRED_LOCATIONS = ['No Preference', 'In-person', 'Online']
  
    validates :uin, presence: true, uniqueness: true
    validates :current_gpa, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 4.0 }, allow_nil: true
    validates :preferred_time, inclusion: { in: PREFERRED_TIMES, message: "%{value} is not a valid preferred time" }, presence: true, if: -> { student.present? && student.student_info&.persisted? }, allow_nil: true
    validates :preferred_loc, inclusion: { in: PREFERRED_LOCATIONS, message: "%{value} is not a valid preferred location" }, presence: true, if: -> { student.present? && student.student_info&.persisted? }, allow_nil: true
    validates :ferpa_consent, inclusion: { in: [true, false], message: "must be either true or false" }, allow_nil: true  
  end
  