require 'pycall/import'
include PyCall::Import

pyimport :sys
sys.path.append(Rails.root.join("python").to_s)

class PythonService
  @helloworld = PyCall.import_module("helloworld")  # Import the actual module

  def self.hello(name)
    @helloworld.hello(name)  # Now it will correctly call the Python function
  end
end
