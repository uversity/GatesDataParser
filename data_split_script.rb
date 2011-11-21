require 'csv'

class SparseArray
  # This array class is to handle large array of mostly empty data with efficent memory usage.
  #
  # Stucture Example:
  # @array = {0 : 1, 6 : 1}
  # 
  # Represents the array:
  #   [1, 0, 0, 0, 0, 0, 1, 0, 0, 1]
  
  def initialize(array_size = 0, default_value = nil)
    @array_size = array_size
    @array = {}
    @default_value = default_value
  end

  def []=(index, val)
    @array[index] = val
    @array_size = index + 1 if index + 1 > @array_size
  end

  def [](index)
    return nil if index >= self.size
    if @array[index]
      @array[index]
    else
      @default_value
    end
  end
  
  def size
    @array_size
  end
  
  def each
    i = 0
    while i < @array_size
      yield self[i]
      i += 1
    end
  end
  
  def to_csv
    array = []
    self.each {|val| array << val}
    array.to_csv
  end
end

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

user_to_user_friendships = SparseArray.new(number_of_users + 1)
user_to_community_memberships = SparseArray.new(number_of_users + 1)

puts "First dimension allocated"

count = 0
(0..number_of_users).each do |index|
  user_to_user_friendships[index] = SparseArray.new(number_of_users + 1, 0)
  user_to_community_memberships[index] = SparseArray.new(number_of_communities + 1, 0)
  
  if count % 1000 == 0
    print "."
    sleep 2
  end
  
  count += 1
end

puts "\nSecond dimension allocated"

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

puts "Populated the header column and row and indexed ids"

(1..number_of_users).each do |index|
  user_id = user_data[index][ID_INDEX].to_i
  
  if user_data[index][FRIENDS_INDEX]
    friend_ids = user_data[index][FRIENDS_INDEX].split(",").map(&:to_i)
  else
    friend_ids = []
  end
  
  if user_data[index][COMMUNITIES_INDEX]
    community_ids = user_data[index][COMMUNITIES_INDEX].split(",").map(&:to_i)
  else
    community_ids = []
  end
  
  # populate the matrices with the relational data
  friend_ids.each do |friend_id|
    if user_id_to_index[friend_id].nil?
      puts "Error: Invalid friend id. This is most likely the result of the export file being saved from Microsoft Excel."
      puts "Debug info: friend_id #{friend_id} has a nil index for user_id #{user_id} with ids #{friend_ids}"
    else
      user_to_user_friendships[index][user_id_to_index[friend_id]] = 1
    end
  end
  
  community_ids.each do |community_id|
    if community_id_to_index[community_id].nil?
      puts "community_id #{community_id} has a nil index"
    else
      user_to_community_memberships[index][community_id_to_index[community_id]] = 1
    end
  end
end

timestamp = Time.now.to_i
user_to_user_file_name = "User_to_User_Friendships_#{timestamp}.csv"
user_to_community_file_name = "User_to_Community_Memberships_#{timestamp}.csv"

puts "Starting to write the #{user_to_user_file_name}"

user_to_user_csv_file = File.new(user_to_user_file_name, "w+")
user_to_user_friendships.each do |row|
  user_to_user_csv_file.puts row.to_csv
end
user_to_user_csv_file.close

puts "Starting to write the #{user_to_community_file_name}"

user_to_community_csv_file = File.new("User_to_Community_Memberships_#{timestamp}.csv",  "w+")
user_to_community_memberships.each do |row|
  user_to_community_csv_file.puts row.to_csv
end
user_to_community_csv_file.close

puts "Created User_to_User_Friendships_#{timestamp}.csv"
puts "Created User_to_Community_Memberships_#{timestamp}.csv"
puts "Time to run #{Time.now - t_before} secs."