# frozen_string_literal: true
module ControllerMacros
  def login_admin
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in FactoryBot.create(:user, :admin) # Using factory bot as an example
    end
  end

  def login_user
    before do
      @request.env["devise.mapping"] = Devise.mappings[:user]
      user = FactoryBot.create(:user)
      sign_in user
    end
  end
end
