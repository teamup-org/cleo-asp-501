# frozen_string_literal: true

class CreateRecCourses < ActiveRecord::Migration[7.2]
  def change
    create_table :rec_courses do |t|
      t.integer :course_id, null: false  # FK to COURSE
      t.string :semester, null: false
      t.string :uin, null: false  # FK to STUDENT

      t.timestamps
    end

    add_foreign_key :rec_courses, :courses, column: :course_id
    add_foreign_key :rec_courses, :students, column: :uin, primary_key: "google_id"
  end
end
