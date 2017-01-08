# frozen_string_literal: true
require "rails/railtie"
require "democi/view_helpers"
module Democi
  class Railtie < ::Rails::Railtie
    initializer "democi.view_helpers" do
      ActiveSupport.on_load(:action_view) { include Democi::ViewHelpers }
    end
  end
end
