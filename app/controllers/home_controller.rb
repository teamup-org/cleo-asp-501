# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    @greeting = PythonService.hello("Rails User")
  end
end
