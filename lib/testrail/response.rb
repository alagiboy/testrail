require 'forwardable'
require 'json'

module Testrail
  class Response
    attr_reader :http_response
    attr_accessor :success, :payload, :error
    
    extend Forwardable

    def_delegators :http_response, :request, :response, :code

    def initialize(http_response = nil)
      @http_response = http_response
      parse_payload if http_response.respond_to?(:body) && !http_response.body.nil?
      parse_error if Integer(http_response.code) >= 400
    end

    private
    def parse_payload
      result_body = JSON.parse(http_response.body)
      @success = result_body.key?('result') ? result_body.delete('result') : nil
      @payload = @success ? result_body : nil
      @error = result_body.key?('error') ? result_body.delete('error') : nil
    rescue JSON::ParserError
      @success = false
      @error = "Malformed JSON response.\n Received #{http_response.body}"
    end

    def parse_error
      @success = false
      @error = ::Net::HTTPResponse::CODE_TO_OBJ[http_response.code.to_s].name.gsub!(/Net::HTTP/, '')
    end
  end
end