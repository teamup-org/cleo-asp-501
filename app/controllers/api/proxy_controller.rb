# frozen_string_literal: true
require 'httparty'

module Api
  class ProxyController < ApplicationController
    def create
      if request.method != "POST"
        return render json: { error: "Method Not Allowed" }, status: 405
      end

      begin
        # Log request details
        Rails.logger.info("Request headers: #{request.headers.to_h.select { |k,v| k.start_with?('HTTP_') }}")
        Rails.logger.info("Content-Type: #{request.content_type}")
        
        # Get parameters based on content type
        params = if request.content_type&.include?('application/x-www-form-urlencoded')
          request.request_parameters
        elsif request.content_type&.include?('application/json')
          JSON.parse(request.body.read)
        else
          # Try to parse as form data anyway
          request.request_parameters
        end

        Rails.logger.info("Request parameters: #{params.inspect}")

        # Validate required parameters
        unless params['dept'].present? && params['number'].present?
          Rails.logger.warn("Missing required parameters: #{params.inspect}")
          return render json: { error: "Missing required parameters" }, status: 400
        end

        # Make the request to Anex API
        begin
          response = HTTParty.post(
            "https://anex.us/grades/getData/",
            body: {
              dept: params['dept'].upcase,
              number: params['number']
            },
            headers: { 
              "Content-Type" => "application/x-www-form-urlencoded; charset=UTF-8",
              "Accept" => "*/*",
              "X-Requested-With" => "XMLHttpRequest",
              "Origin" => "https://anex.us",
              "Referer" => "https://anex.us/grades/?dept=#{params['dept']}&number=#{params['number']}"
            },
            debug_output: Rails.logger
          )

          Rails.logger.info("Anex API Response Status: #{response.code}")
          Rails.logger.info("Anex API Response Headers: #{response.headers.inspect}")
          Rails.logger.info("Anex API Raw Response Body: #{response.body}")

          # Handle different response codes
          case response.code
          when 200
            begin
              response_data = JSON.parse(response.body)
              Rails.logger.info("Parsed Response Data: #{response_data.inspect}")
              
              if response_data.nil? || response_data.empty?
                return render json: { error: "No data available for the specified course" }, status: 404
              end
              
              render json: response_data
            rescue JSON::ParserError => e
              Rails.logger.error("JSON Parse Error: #{e.message}")
              Rails.logger.error("Raw response that failed to parse: #{response.body}")
              render json: { error: "Invalid JSON response from Anex API" }, status: 500
            end
          when 404
            render json: { error: "Course not found" }, status: 404
          when 500
            render json: { error: "Anex API server error" }, status: 502
          else
            render json: { error: "Unexpected response from Anex API: #{response.code}" }, status: 502
          end
        rescue HTTParty::Error => e
          Rails.logger.error("HTTParty Error: #{e.message}")
          Rails.logger.error("Error backtrace: #{e.backtrace.join("\n")}")
          render json: { error: "Failed to connect to Anex API" }, status: 503
        end
      rescue => e
        Rails.logger.error("Unexpected Error: #{e.message}")
        Rails.logger.error("Error class: #{e.class}")
        Rails.logger.error("Error backtrace: #{e.backtrace.join("\n")}")
        render json: { error: "An unexpected error occurred: #{e.message}" }, status: 500
      end
    end
  end
end 