class PrevStudentCourse < ApplicationRecord
    belongs_to :student, foreign_key: 'uin', primary_key: 'google_id'
    belongs_to :course
  
    validates :uin, presence: true
    validates :course_id, presence: true
    validates :semester, presence: true
    validates :grade, length: { maximum: 2 }, allow_blank: true
  end
  