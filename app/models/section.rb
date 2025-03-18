class Section < ApplicationRecord
    self.primary_key = 'section_number'
  
    has_many :section_attributes, foreign_key: %i[section_number course_id], primary_key: %i[section_number course_id]

    belongs_to :course
  
    validates :section_number, presence: true, uniqueness: true
    validates :start_time, numericality: { only_integer: true }, allow_nil: true
    validates :end_time, numericality: { only_integer: true }, allow_nil: true
    validates :course_id, presence: true
  end
  