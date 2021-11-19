# frozen_string_literal: true
module Extensions
  module Flipflop
    def self.included(k)
      k.class_eval do
        after_action :update_devise, only: :update, if: proc { |c| c.params[:feature_id] == "self_register" }
        private

        def update_devise
          mapping = Devise.mappings[:user]
          if ::Flipflop.self_register? && !mapping.registerable?
            mapping.modules << :registerable
          else
            mapping.modules.delete(:registerable)
          end
          Rails.application.reload_routes!
        end
      end
    end
  end
end
