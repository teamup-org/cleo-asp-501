class RecCourse < ApplicationRecord
    belongs_to :course
    belongs_to :student, foreign_key: 'uin', primary_key: 'google_id'
  
    validates :course_id, presence: true
    validates :uin, presence: true
    validates :semester, presence: true

  end
  