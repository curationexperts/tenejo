# frozen_string_literal: true

CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a
namespace :tenejo do
  desc 'Create  user'
  task :create_user, [:email] => :environment do |_t, args|
    pw = random_password
    email = args[:email] || 'admin@example.com'
    User.where(email: email).first&.destroy
    User.create!(email: email, password: pw, password_confirmation: pw)
    puts "Password: #{pw}"
  end
  def random_password(length = 16)
    CHARS.sort_by { rand }.join[0...length]
  end
end
