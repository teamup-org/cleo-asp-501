import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "courseCheckbox", "courseCode", "courseNumber", "courseName", "courseHours", "courseGrade"]

  connect() {
    this.updateSelectedCount()
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Handle course checkbox changes
    this.courseCheckboxTargets.forEach(checkbox => {
      checkbox.addEventListener('change', () => this.updateSelectedCount())
    })

    // Handle form submission
    this.formTarget.addEventListener('submit', (e) => {
      e.preventDefault()
      this.submitForm()
    })
  }

  updateSelectedCount() {
    const selectedCount = this.courseCheckboxTargets.filter(checkbox => checkbox.checked).length
    const totalCount = this.courseCheckboxTargets.length
    const countElement = document.querySelector('.selected-count')
    if (countElement) {
      countElement.textContent = `${selectedCount} of ${totalCount} courses selected`
    }
  }

  submitForm() {
    try {
      const selectedCourses = []
      
      this.courseCheckboxTargets.forEach((checkbox, index) => {
        if (checkbox.checked) {
          const course = {
            semester: checkbox.dataset.semester,
            ccode: this.courseCodeTargets[index].value,
            cnumber: this.courseNumberTargets[index].value,
            cname: this.courseNameTargets[index].value,
            credit_hours: parseFloat(this.courseHoursTargets[index].value),
            grade: this.courseGradeTargets[index].value
          }
          selectedCourses.push(course)
        }
      })

      if (selectedCourses.length === 0) {
        throw new Error('Please select at least one course to save.')
      }

      // Submit the form normally to allow for proper redirect handling
      this.formTarget.submit()
      
    } catch (error) {
      console.error('Validation error:', error)
      alert(error.message)
      return false
    }
  }
} 