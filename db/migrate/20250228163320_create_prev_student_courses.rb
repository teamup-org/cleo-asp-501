# frozen_string_literal: true

class CreatePrevStudentCourses < ActiveRecord::Migration[7.2]
  def change
    create_table :prev_student_courses do |t|
      t.string :uin, null: false  # FK to STUDENT
      t.integer :course_id, null: false  # FK to COURSE
      t.string :semester, null: false
      t.string :grade

      t.timestamps
    end

    add_foreign_key :prev_student_courses, :students, column: :uin, primary_key: "google_id"
    add_foreign_key :prev_student_courses, :courses, column: :course_id
  end
end
