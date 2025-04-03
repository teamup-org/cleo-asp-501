class PrevStudentCourse < ApplicationRecord
    belongs_to :student, foreign_key: 'uin', primary_key: 'google_id'
    belongs_to :course
  
    validates :uin, presence: true
    validates :course_id, presence: true
    validates :semester, presence: true
    validates :grade, length: { maximum: 2 }, allow_blank: true

    # Validates uniqueness of course per student
    validates :course_id, uniqueness: { scope: :uin, message: "has already been taken for this student" }

    # Scope to get all courses for a student
    scope :for_student, ->(uin) { where(uin: uin) }
    
    # Scope to get courses by semester
    scope :by_semester, ->(semester) { where(semester: semester) }

    # Callbacks
    after_create :remove_from_recommendations

    private

    def remove_from_recommendations
        RecCourse.where(uin: self.uin, course_id: self.course_id).destroy_all
    end
end
  