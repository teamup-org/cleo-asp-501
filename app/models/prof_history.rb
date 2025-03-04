class ProfHistory < ApplicationRecord
    belongs_to :course
  
    validates :course_id, presence: true
    validates :teacher_name, presence: true
    validates :average_gpa, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 4 }, allow_nil: true
    validates :semester, presence: true
  
    # Ensure uniqueness: Each (course_id, teacher_name, semester) combination must be unique
    validates :teacher_name, uniqueness: { scope: %i[course_id semester] }
  end
  