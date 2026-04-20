# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Binxtils::ControllerNamespace

  allow_browser versions: :modern if respond_to?(:allow_browser)
end
