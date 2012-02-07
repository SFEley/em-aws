require "eventmachine"
module EventMachineHelper
  # Wrap the given code in an EM.run and EM.stop block
  def event
    EM.run do
      yield
      EM.stop
    end
  end
  
end