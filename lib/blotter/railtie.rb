module Blotter
  class Railtie < Rails::Railtie
    initializer "blotter_railtie.initialize_blotter" do
      module BlotterActiveRecordExt
        def blotter(blotter_method)
          blotter_model = caller[0][/`<class:([^']*)>'/, 1]
          Blotter.register_blotter_model(blotter_model.safe_constantize)
          Blotter.register_blotter_method(blotter_method)
        end
      end
      ActiveRecord::Base.extend(BlotterActiveRecordExt)

      module BlotterActionControllerExt
        def blotter(controller_actions = {})
          Blotter.register_controller_actions(controller_actions)
          include Blotter
        end
      end
      ActionController::Base.extend(BlotterActionControllerExt)
    end
  end
end
