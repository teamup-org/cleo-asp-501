# frozen_string_literal: true

class CreateStudentInfo < ActiveRecord::Migration[7.2]
  def change
    create_table :student_infos, id: false do |t|
      t.boolean :ferpa_consent
      t.string :preferred_time
      t.string :preferred_loc
      t.decimal :current_gpa, precision: 3, scale: 2
      t.string :uin, primary_key: true  # FK to STUDENT

      t.timestamps
    end

    add_foreign_key :student_infos, :students, column: :uin, primary_key: "google_id"
  end
end
