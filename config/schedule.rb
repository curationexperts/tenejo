# frozen_string_literal: true
# Delete blacklight saved searches
every :day, at: '11:55pm' do
  rake "blacklight:delete_old_searches[1]"
end
