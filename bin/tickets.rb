require 'faraday'
require 'json'

def get(path)
  token = ENV.fetch('PRETIX_API_TOKEN')
  conn = Faraday.new(url: 'https://pretix.eu')
  full_path = "/api/v1/organizers/hrx/events/think-about-2019#{path}"

  response = conn.get full_path do |req|
    req.headers['Authorization'] = "Token #{token}"
  end
  JSON.parse response.body, symbolize_names: true
end

result = {
  earlybird: {
    price: get('/items/16885/')[:default_price].to_i
  },
  regular: {
    price: get('/items/16858/')[:default_price].to_i
  },
  supporter: {
    price: get('/items/16886/')[:default_price].to_i
  }
}

early = get('/quotas/11268/availability/')
result[:earlybird][:available_number] = early[:available_number]
result[:earlybird][:total_size] = early[:total_size]
result[:earlybird][:available] = early[:available]

regular = get('/quotas/11263/availability/')
result[:regular][:available] = !early[:available] && regular[:available]
result[:supporter][:available] = regular[:available]

puts JSON.pretty_generate result
