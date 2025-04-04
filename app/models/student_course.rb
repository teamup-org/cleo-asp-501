# frozen_string_literal: true

class StudentCourse < ApplicationRecord
  self.primary_key = %i[student_id course_id]

  belongs_to :student
  belongs_to :course

  validates :student_id, presence: true
  validates :course_id, presence: true
  validates :sem, presence: true
  validates :sem, numericality: { only_integer: true, greater_than: 0 }
  validates :course_id, uniqueness: { scope: :student_id, message: 'has already been added for this student.' }

  # Automatically add to recommended courses
  before_create :add_to_rec_courses

  after_destroy :remove_related_rec_course

  private

  def add_to_rec_courses
    semester_str = convert_semester(student, sem) # Convert integer to "SPRING2025"
    
    unless RecCourse.exists?(course_id: course_id, uin: student.google_id)
      RecCourse.create!(
        course_id: course_id,
        uin: student.google_id, # Assuming google_id is the correct unique identifier for RecCourse
        semester: semester_str
      )
    end
  end

  def convert_semester(student, sem_int)
    year = student.enrol_year
    semester = student.enrol_semester == "fall" ? "FALL" : "SPRING"

    # Adjust based on sem_int
    (sem_int - 1).times do
      if semester == "SPRING"
        semester = "FALL"
      else
        semester = "SPRING"
        year += 1
      end
    end

    "#{semester}#{year}"
  end

  def remove_related_rec_course
    RecCourse.find_by(uin: student.google_id, course_id: course.id)&.destroy
  end

end
