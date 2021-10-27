namespace :cur do
  desc "Install first user"
  task first_user: :environment do
    pw = random_password
    User.where(email: "admin@example.com").first.destroy
    u = User.create!(email: "admin@example.com", display_name: "Admin User", password: pw, password_confirmation: pw)
    puts "Password: #{pw}"
  end
  CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a
  def random_password(length=16)
    CHARS.sort_by { rand }.join[0...length]
  end
end


