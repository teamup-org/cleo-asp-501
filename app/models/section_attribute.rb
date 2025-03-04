class SectionAttribute < ApplicationRecord
    belongs_to :section, foreign_key: %i[section_number course_id], primary_key: %i[section_number course_id]
  
    validates :section_number, presence: true
    validates :course_id, presence: true
    validates :attribute_id, presence: true, uniqueness: { scope: %i[section_number course_id] }
    validates :attribute_name, presence: true
  end
  