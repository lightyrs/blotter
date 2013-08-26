module Blotter
  class Railtie < Rails::Railtie
    initializer "application_controller.initialize_blotter" do
      module ActiveRecord
        class Base
          def self.blotter(blotter_method)
            blotter_model = caller[0][/`<class:([^']*)>'/, 1]
            Blotter.register_blotter_model(blotter_model.safe_constantize)
            Blotter.register_blotter_method(blotter_method)
          end
        end
      end

      module BlotterExtensions
        def blotter(controller_actions = {})
          Blotter.register_controller_actions(controller_actions)
          include Blotter
        end
      end
      ActionController::Base.extend(BlotterExtensions)
    end
  end
end
