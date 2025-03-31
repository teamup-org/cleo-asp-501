# frozen_string_literal: true

class StudentsController < ApplicationController
  before_action :set_student, only: %i[edit update show destroy]
  before_action :authenticate_admin!, only: [:index] # Ensure only admin can access index
  skip_before_action :authenticate_student_login! if Rails.env.test?

  def index
    @students = Student.all
  end

  def show
    @student = Student.find(params[:id])
    @tracks = Track.all.pluck(:tname) # Fetch track names
    @emphases = Emphasis.all.pluck(:ename) # Fetch emphasis names
  end

  def new
    @student = Student.new(
      first_name: params[:first_name],
      last_name: params[:last_name],
      email: params[:email],
      google_id: params[:google_id],
      enrol_year: params[:enrol_year] || current_year, # Set enrol_year or fallback to current year
      grad_year: params[:grad_year] || (current_year + 4),
      enrol_semester: params[:enrol_semester] || current_semester,
      grad_semester: params[:grad_semester] || (current_semester == 'fall' ? 'spring' : 'fall'),
      track_id: params[:track_id],
      emphasis_id: params[:emphasis_id]
    )
  end

  def create
    @student = Student.new(student_params)
    if @student.save
      # Query the DegreeRequirements table based on the student's major_id
      degree_requirements = DegreeRequirement.where(major_id: @student.major_id)

      # Map the degree requirements to StudentCourse records
      degree_requirements.map do |requirement|
        StudentCourse.create(student: @student, course_id: requirement.course_id, sem: requirement.sem)
      end

      if @student.is_admin?
        redirect_to students_path, notice: 'Student added successfully.'
      else
        redirect_to student_dashboard_path(@student.google_id), notice: 'Student added successfully.'
      end
    else
      render :new
    end
  end

  def edit; end

  def update
    if @student.update(student_params)
      if current_student_login.is_admin?
        redirect_to edit_student_path(@student.google_id), notice: 'Student information updated successfully.'
      else
        redirect_to profile_student_path(current_student_login),
                    notice: 'Your information has been updated successfully.'
      end
    else
      render :edit
    end
  end

  def destroy
    @student.destroy
    redirect_to students_path, notice: 'Student deleted successfully.'
  end

  def confirm_destroy
    Rails.logger.debug "Params: #{params.inspect}"
    @student = Student.find_by(google_id: params[:google_id])
    return unless @student.nil?

    redirect_to students_path, alert: 'Student not found.'
  end

  def profile
    # @student = current_student_login
    # @uid = @student.uid
    @student = Student.find_by(google_id: current_student_login.uid)

    return unless @student.nil?

    redirect_to root_path, alert: 'Student not found.'
  end

  def degree_planner
    redirect_to student_degree_planner_path(current_student_login.uid)
  end

  def upload_transcript
    if request.get?
      @parsed_data = []
      @grouped_courses = {}
      render :show_parsed_transcript
      return
    end

    transcript = params[:transcript]
    if transcript
      unless transcript.content_type == 'application/pdf'
        flash[:alert] = "Please upload a PDF file."
        @parsed_data = []
        @grouped_courses = {}
        @parse_error = "Invalid file type: #{transcript.content_type}"
        return render :show_parsed_transcript
      end

      # Create a temporary file for parsing
      temp_file = Tempfile.new(['transcript', '.pdf'])
      begin
        # Read the uploaded file in binary mode
        pdf_data = transcript.read
        # Write to temp file in binary mode
        File.open(temp_file.path, 'wb') do |file|
          file.write(pdf_data)
        end
        temp_file.close

        # Parse the transcript using Python
        Rails.logger.info("Parsing transcript: #{temp_file.path}")
        output = `python3 #{Rails.root.join('python', 'parse.py')} #{temp_file.path} 2> #{Rails.root.join('log', 'transcript_parser.log')}`
        Rails.logger.info("Python script output: #{output}")
        
        begin
          # Parse the JSON data
          @parsed_data = JSON.parse(output)
          
          if @parsed_data.empty?
            flash[:alert] = "No courses were found in the transcript."
            log_content = File.read(Rails.root.join('log', 'transcript_parser.log'))
            @parse_error = "Parser returned empty result. Check logs for details."
            Rails.logger.info("Parsed data preview: #{@parsed_data.first(3).inspect}")
            Rails.logger.error("Parser log: #{log_content}")
          else
            # Group courses by semester for the view
            @grouped_courses = @parsed_data.group_by { |course| course['semester'] }
            
            if @grouped_courses.empty?
              flash[:alert] = "No valid courses were found in the transcript."
              @parse_error = "No courses could be grouped by semester"
            else
              flash[:notice] = "Transcript parsed successfully! Found #{@parsed_data.size} courses. Please review and confirm the courses."
            end
          end
        rescue JSON::ParserError => e
          Rails.logger.error("Transcript parsing error: #{e.message}")
          Rails.logger.error("Python output: #{output}")
          flash[:alert] = "Failed to parse transcript data. Please ensure the transcript is in the correct format."
          @parsed_data = []
          @grouped_courses = {}
          log_content = File.read(Rails.root.join('log', 'transcript_parser.log'))
          @parse_error = "JSON parsing error. Parser output: #{output}. Log: #{log_content}"
        end
      rescue StandardError => e
        Rails.logger.error("File handling error: #{e.message}")
        flash[:alert] = "Error processing the transcript file. Please try again."
        @parsed_data = []
        @grouped_courses = {}
        @parse_error = "File processing error: #{e.message}"
      ensure
        # Clean up the temporary file
        temp_file.unlink
      end
    else
      flash[:alert] = "Please upload a transcript file."
      @parsed_data = []
      @grouped_courses = {}
      @parse_error = "No file uploaded"
    end
    render :show_parsed_transcript
  end

  def save_transcript_courses
    begin
      # Log the incoming parameters
      Rails.logger.info("Received params: #{params.inspect}")

      unless params[:courses].present?
        flash[:alert] = "No course data provided"
        redirect_to view_transcript_courses_student_path(current_student_login)
        return
      end
      
      courses = JSON.parse(params[:courses])
      Rails.logger.info("Processing #{courses.length} courses: #{courses.inspect}")
      
      if courses.empty?
        flash[:alert] = "No courses were selected to save."
        redirect_to view_transcript_courses_student_path(current_student_login)
        return
      end
      
      saved_count = 0
      failed_courses = []
      
      ActiveRecord::Base.transaction do
        # First, remove all existing courses for this student
        PrevStudentCourse.where(uin: current_student_login.uid).destroy_all
        Rails.logger.info("Cleared existing courses for student #{current_student_login.uid}")
        
        courses.each do |course_data|
          # Find or create the course
          db_course = Course.find_or_create_by(
            ccode: course_data['ccode'].upcase,
            cnumber: course_data['cnumber']
          ) do |c|
            c.cname = course_data['cname']
            c.credit_hours = course_data['credit_hours']
            c.uploaded_via_transcript = true
          end
          
          # Create the student course record
          prev_course = PrevStudentCourse.new(
            uin: current_student_login.uid,
            course_id: db_course.id,
            semester: course_data['semester'],
            #uploaded_via_transcript: true
          )
          
          if prev_course.save
            saved_count += 1
            Rails.logger.info("Saved course #{db_course.ccode} #{db_course.cnumber} for semester #{course_data['semester']}")
          else
            Rails.logger.error("Failed to save student course: #{prev_course.errors.full_messages.join(', ')}")
            failed_courses << "#{course_data['ccode']} #{course_data['cnumber']}"
          end
        end

        if saved_count == 0
          raise ActiveRecord::Rollback, "No courses were saved successfully"
        end
      end



      
      if saved_count > 0
        flash[:success] = "Successfully saved #{saved_count} courses!"
        flash[:notice] = "Failed to save: #{failed_courses.join(', ')}" if failed_courses.any?
      else
        flash[:alert] = "Failed to save any courses. Please try again."
      end
      
      redirect_to view_transcript_courses_student_path(current_student_login)
      
    rescue JSON::ParserError => e
      Rails.logger.error "JSON parse error: #{e.message}"
      Rails.logger.error "Params: #{params.inspect}"
      flash[:alert] = "Invalid course data provided. Please try again."
      redirect_to view_transcript_courses_student_path(current_student_login)
    rescue StandardError => e
      Rails.logger.error "Error saving courses: #{e.message}"
      Rails.logger.error "Backtrace: #{e.backtrace.join("\n")}"
      flash[:alert] = "An error occurred while saving the courses. Please try again."
      redirect_to view_transcript_courses_student_path(current_student_login)
    end
  end

  def view_transcript_courses
    @prev_courses = PrevStudentCourse.includes(:course).where(uin: current_student_login.uid)
    @grouped_courses = @prev_courses.group_by(&:semester).transform_values do |courses|
      courses.map do |psc|
        {
          'semester' => psc.semester,
          'ccode' => psc.course.ccode,
          'cnumber' => psc.course.cnumber,
          'cname' => psc.course.cname,
          'credit_hours' => psc.course.credit_hours
        }
      end
    end
    render :show_parsed_transcript
  end

  def remove_transcript_course
    course = PrevStudentCourse.find_by(
      uin: current_student_login.uid,
      course_id: params[:course_id],
      semester: params[:semester]
    )
    
    if course&.destroy
      flash[:notice] = "Course removed successfully"
    else
      flash[:alert] = "Failed to remove course"
    end
    
    redirect_to view_transcript_courses_student_path(current_student_login)
  end

  def add_transcript_course
    course = Course.find_by(ccode: params[:ccode], cnumber: params[:cnumber])
    
    unless course
      # Create a new course if it doesn't exist
      course = Course.create(
        ccode: params[:ccode].upcase,
        cnumber: params[:cnumber],
        cname: params[:cname],
        credit_hours: params[:credit_hours]
      )
      
      unless course.persisted?
        flash[:alert] = "Failed to create course: #{course.errors.full_messages.join(', ')}"
        return redirect_to view_transcript_courses_student_path(current_student_login)
      end
    end

    # If we're editing, first remove the old course
    if params[:edit_mode] == 'true'
      old_course = PrevStudentCourse.find_by(
        uin: current_student_login.uid,
        course_id: course.id,
        semester: params[:semester]
      )
      old_course&.destroy
    end

    # Add the new/updated course
    prev_course = PrevStudentCourse.new(
      uin: current_student_login.uid,
      course_id: course.id,
      semester: params[:semester]
    )

    if prev_course.save
      flash[:notice] = "Course #{params[:edit_mode] == 'true' ? 'updated' : 'added'} successfully"
    else
      flash[:alert] = "Failed to #{params[:edit_mode] == 'true' ? 'update' : 'add'} course: #{prev_course.errors.full_messages.join(', ')}"
    end

    redirect_to view_transcript_courses_student_path(current_student_login)
  end

  def degree_requirements
    # Get the student's major
    student = Student.find(params[:id])
    major = student.major

    # Fetch required courses for the major
    required_courses = DegreeRequirement.where(major: major).includes(:course)
    
    # Format the response
    courses = required_courses.map do |req|
      course = req.course
      {
        ccode: course.ccode,
        cnumber: course.cnumber,
        cname: course.cname,
        credit_hours: course.credit_hours,
        requirement_type: req.requirement_type # e.g., 'core', 'elective', etc.
      }
    end

    render json: { courses: courses }
  rescue => e
    Rails.logger.error "Error fetching degree requirements: #{e.message}"
    render json: { error: 'Unable to fetch degree requirements' }, status: :internal_server_error
  end
  
  private

  def set_student
    @student = Student.find_by(google_id: params[:google_id])
    return unless @student.nil?

    raise ActiveRecord::RecordNotFound, "Couldn't find Student with google_id=#{params[:google_id]}."
  end

  def authenticate_admin!
    return if current_student_login.is_admin?

    redirect_to student_dashboard_path(current_student_login.google_id),
                alert: 'You are not authorized to access this page.'
  end

  def student_params
    params.require(:student).permit(:google_id, :first_name, :last_name, :email, :enrol_year, :grad_year, :enrol_semester,
                                    :grad_semester, :major_id, :emphasis_id, :track_id)
  end
end
