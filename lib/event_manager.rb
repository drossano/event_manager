require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def get_hours(time)
  date_time = Time.strptime(time, "%m/%d/%y %H:%M")
  date_time.hour
end

def clean_phone_number(phone_number)
  number_digits = phone_number.to_s.tr('^0-9','')
  if  number_digits[0] != "1" && number_digits.length == 11 && number_digits.length > 11 || number_digits.length < 10
    "Invalid Number"
  elsif  number_digits[0] == "1" && number_digits.length
    formatted_number(number_digits[1..10])
  else
    formatted_number(number_digits)
  end
end

def formatted_number(digits)
  "(#{digits[0..2]}) #{digits[3..5]}-#{digits[6..9]}"
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting  www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end


puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true, 
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours = Array.new
week_days = Array.new

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phone_number(row[:homephone])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)

  date_time = Time.strptime(row[:regdate], "%m/%d/%y %H:%M")
  hours.push(date_time.hour)
  week_days.push((date_time.wday))
end

def peak_registration(times)
  time_counts = times.tally
  time_counts.max_by{|k,v| v}[0]
end

puts peak_registration(hours)
puts peak_registration(week_days)