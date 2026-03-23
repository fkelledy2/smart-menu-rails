# frozen_string_literal: true

require 'test_helper'
require 'tempfile'

class OpenaiWhisperTranscriptionServiceTest < ActiveSupport::TestCase
  # Helper: create a real temp audio file (just a placeholder, the actual HTTP call is stubbed)
  def create_temp_audio
    file = Tempfile.new(['audio_test', '.mp3'])
    file.write('fake audio bytes')
    file.rewind
    file
  end

  # Helper: build a stub HTTParty response
  def stub_response(body:, code: 200, success: true)
    resp = Object.new
    resp.define_singleton_method(:success?) { success }
    resp.define_singleton_method(:code) { code }
    resp.define_singleton_method(:body) { body.is_a?(Hash) ? body.to_json : body.to_s }
    resp.define_singleton_method(:parsed_response) { body }
    resp
  end

  # =========================================================================
  # initialiser
  # =========================================================================

  test 'initialises with provided api_key and model' do
    service = OpenaiWhisperTranscriptionService.new(api_key: 'sk-test-123', model: 'whisper-2')
    assert_kind_of OpenaiWhisperTranscriptionService, service
  end

  test 'raises when api_key is blank and no env/credential set' do
    # Clear the env var and supply blank key
    ENV.delete('OPENAI_API_KEY')

    service = OpenaiWhisperTranscriptionService.new(api_key: '')

    audio = create_temp_audio
    assert_raises(RuntimeError, /OPENAI_API_KEY missing/) do
      service.transcribe(file_path: audio.path)
    end
  ensure
    audio&.close
    audio&.unlink
  end

  # =========================================================================
  # transcribe — happy path
  # =========================================================================

  test 'returns transcription text from text key in JSON response' do
    service = OpenaiWhisperTranscriptionService.new(api_key: 'sk-test-abc', model: 'whisper-1')
    response_body = { 'text' => 'Hello world' }
    resp = stub_response(body: response_body)

    audio = create_temp_audio
    OpenaiWhisperTranscriptionService.stub(:post, resp) do
      result = service.transcribe(file_path: audio.path)
      assert_equal 'Hello world', result
    end
  ensure
    audio&.close
    audio&.unlink
  end

  test 'returns transcription from nested data.text key' do
    service = OpenaiWhisperTranscriptionService.new(api_key: 'sk-test-abc', model: 'whisper-1')
    response_body = { 'data' => { 'text' => 'Bonjour le monde' } }
    resp = stub_response(body: response_body)

    audio = create_temp_audio
    OpenaiWhisperTranscriptionService.stub(:post, resp) do
      result = service.transcribe(file_path: audio.path)
      assert_equal 'Bonjour le monde', result
    end
  ensure
    audio&.close
    audio&.unlink
  end

  test 'returns empty string when response body is a non-hash' do
    service = OpenaiWhisperTranscriptionService.new(api_key: 'sk-test-abc', model: 'whisper-1')
    resp = stub_response(body: 'some plain text')

    audio = create_temp_audio
    OpenaiWhisperTranscriptionService.stub(:post, resp) do
      result = service.transcribe(file_path: audio.path)
      assert_equal '', result
    end
  ensure
    audio&.close
    audio&.unlink
  end

  test 'sends language parameter when provided' do
    service = OpenaiWhisperTranscriptionService.new(api_key: 'sk-test-abc', model: 'whisper-1')
    response_body = { 'text' => 'Ciao' }
    resp = stub_response(body: response_body)

    audio = create_temp_audio
    captured_options = nil

    OpenaiWhisperTranscriptionService.stub(:post, lambda { |path, opts|
      captured_options = opts
      resp
    },) do
      service.transcribe(file_path: audio.path, language: 'it')
    end

    assert_equal 'it', captured_options[:body][:language]
  ensure
    audio&.close
    audio&.unlink
  end

  # =========================================================================
  # transcribe — error path
  # =========================================================================

  test 'raises when HTTP response is not successful' do
    service = OpenaiWhisperTranscriptionService.new(api_key: 'sk-test-abc', model: 'whisper-1')
    resp = stub_response(body: 'Unauthorized', code: 401, success: false)

    audio = create_temp_audio
    OpenaiWhisperTranscriptionService.stub(:post, resp) do
      assert_raises(RuntimeError, /transcription failed/) do
        service.transcribe(file_path: audio.path)
      end
    end
  ensure
    audio&.close
    audio&.unlink
  end
end
