require 'csv'

t_before = Time.now
user_file = ARGV[0]
community_file = ARGV[1]

if ARGV[0].nil? || ARGV[1].nil?
  puts "Usage: data_split_script.rb <user_export.csv> <community_export.csv>"
  exit 0
end

user_csv_text = File.read(user_file)
community_csv_text = File.read(community_file)

user_data = CSV.parse(user_csv_text)
community_data = CSV.parse(community_csv_text)

number_of_users = user_data.size - 1
number_of_communities = community_data.size - 1

user_to_user_friendships = Array.new(number_of_users + 1)
user_to_community_memberships = Array.new(number_of_users + 1)

(0..number_of_users).each do |index|
  user_to_user_friendships[index] = Array.new(number_of_users + 1, 0)
  user_to_community_memberships[index] = Array.new(number_of_communities + 1, 0)
end

ID_INDEX = 0
COMMUNITIES_INDEX = 19
FRIENDS_INDEX = 23

user_to_user_friendships[0][0] = "user ids v user ids >"
user_to_community_memberships[0][0] = "user ids v community ids >"

user_id_to_index = {}
(1..number_of_users).each do |index|
  user_id = user_data[index][ID_INDEX].to_i
  user_id_to_index[user_id] = index
  
  # populate the matrices with the user ids
  user_to_user_friendships[index][0] = user_id
  user_to_user_friendships[0][index] = user_id
  user_to_community_memberships[index][0] = user_id
end

community_id_to_index = {}
(1..number_of_communities).each do |index|
  community_id = community_data[index][ID_INDEX].to_i
  community_id_to_index[community_id] = index
  
  # populate the matrices with the community ids
  user_to_community_memberships[0][index] = community_id
end

(1..number_of_users).each do |index|
  user_id = user_data[index][ID_INDEX].to_i
  friend_ids = user_data[index][FRIENDS_INDEX].split(",").map(&:to_i)
  community_ids = user_data[index][COMMUNITIES_INDEX].split(",").map(&:to_i)
  
  # populate the matrices with the relational data
  friend_ids.each do |friend_id|
    user_to_user_friendships[index][user_id_to_index[friend_id]] = 1
  end
  
  community_ids.each do |community_id|
    user_to_community_memberships[index][community_id_to_index[community_id]] = 1
  end
end

timestamp = Time.now.to_i

user_to_user_csv_file = File.new("User_to_User_Friendships_#{timestamp}.csv",  "w+")
user_to_user_friendships.each do |row|
  user_to_user_csv_file.puts row.to_csv
end
user_to_user_csv_file.close

user_to_community_csv_file = File.new("User_to_Community_Memberships_#{timestamp}.csv",  "w+")
user_to_community_memberships.each do |row|
  user_to_community_csv_file.puts row.to_csv
end
user_to_community_csv_file.close

puts "Created User_to_User_Friendships_#{timestamp}.csv"
puts "Created User_to_Community_Memberships_#{timestamp}.csv"
puts "Time to run #{Time.now - t_before} secs."