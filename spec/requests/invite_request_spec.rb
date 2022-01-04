# frozen_string_literal: true
require 'rails_helper'

RSpec.describe "/tenejo/invite", type: :request do
  context "not logged in" do
    it "redirects" do
      get new_user_invitation_path
      expect(response).to redirect_to new_user_session_path
    end
  end
  context "logged in as admin" do
    let(:admin) { User.create(email: 'test@example.com', password: '123456', roles: [Role.create(name: 'admin')]) }
    let(:newuser) { User.new(email: 'newuser@example.com', password: '123456', role_ids: [Role.create(name: 'test').id]) }
    before do
      sign_in admin
    end

    describe "some sort of mailer error" do
      it "handles smtp errors" do
        expect_any_instance_of(Devise::InvitationsController).to receive(:create).and_raise(Net::SMTPFatalError)
        post user_invitation_path, params: { user: { email: 'newuser@example.com', password: '123456', role_ids: [admin.roles.first.id] } }
        expect(response).to redirect_to dashboard_path
        expect(flash[:error]).to eq "There seems to be a problem with the mail system. Invitation was not sent."
      end
    end

    describe "GET /index" do
      it "renders a successful response" do
        get new_user_invitation_path
        expect(response).to be_successful
        expect(assigns(:user)).not_to be_nil
        expect(response).to render_template('devise/invitations/new')
      end
    end
    describe "POST /create" do
      it "renders a successful response" do
        post user_invitation_path, params: { user: { email: 'newuser@example.com', password: '123456', role_ids: [admin.roles.first.id] } }
        expect(assigns(:user)).not_to be_nil
        expect(response).to redirect_to dashboard_path
        expect(User.last.roles.map(&:id)).to eq [admin.roles.first.id]
        expect(flash[:notice]).to eq "An invitation email has been sent to newuser@example.com."
      end
    end
  end
end
