
# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Hyrax::Admin::UsersPresenter, type: :model do
  let!(:presenter) { described_class.new }

  it "eagerly loads roles redux" do
    allow(User).to receive(:includes) { User.all }
    presenter.users
    expect(User).to have_received(:includes).with(:roles)
  end

  it 'loads roles' do
    expect(presenter.roles.size).not_to be_nil
  end
end
