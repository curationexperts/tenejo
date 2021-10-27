# frozen_string_literal: true

CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a
namespace :cur do
  desc 'Install first user'
  task first_user: :environment do
    pw = random_password
    User.where(email: 'admin@example.com').first.destroy
    User.create!(email: 'admin@example.com', display_name: 'Admin User', password: pw, password_confirmation: pw)
    puts "Password: #{pw}"
  end
  def random_password(length = 16)
    CHARS.sort_by { rand }.join[0...length]
  end
end
