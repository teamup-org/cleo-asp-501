class RecCourse < ApplicationRecord
    belongs_to :course
    belongs_to :student, foreign_key: 'uin', primary_key: 'google_id'
  
    validates :course_id, presence: true
    validates :uin, presence: true
    validates :semester, presence: true

    after_destroy :remove_related_stu_course

    private

    def remove_related_stu_course
      if StudentCourse.exists?(student_id: student.google_id, course_id: course.id)
        StudentCourse.find_by(student_id: student.google_id, course_id: course.id)&.destroy
      end
    end

  end
  